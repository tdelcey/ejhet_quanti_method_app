# modules/mod_citation_network_view.R

mod_citation_network_view_ui <- function(id) {
  ns <- NS(id)

  div(
    style = "
      border:2px solid #D4D4D4;
      border-radius:10px;
      padding:15px;
      background-color:#FAFAFA;
      height:100%;
    ",

    div(
      style = "
        font-size:20px;
        font-weight:600;
        padding-left:10px;
        border-left:5px solid #00897B;
        margin-bottom:15px;
      ",
      "Citation network"
    ),

    callout_box(
      title = "Interpretation",
      icon = "\U0001F4DA",
      text = "Each node represents an article and edges represent shared references between articles. 
              Colors indicate bibliometric communities. 
              Nodes with no colors are communities representing less than 5% of the window's articles or existing in only one time window.
              Use the time window selector to explore how the citation structure changes across periods.",
      border = "#00695C",
      bg = "#E0F2F1"
    ),

    uiOutput(ns("graph_selector")),

    div(
      style = "
        border:1px solid #D0D0D0;
        border-radius:8px;
        padding:2px;
        background:#FFF;
        margin-top:10px;
      ",
      shinycssloaders::withSpinner(
        girafeOutput(ns("plot"), height = "550px"),
        type = 4,
        color = "#607D8B"
      )
    )
  )
}

mod_citation_network_view_server <- function(
  id,
  graph_tbl,
  cluster_id,
  node_id,
  cluster_tooltip = NULL,
  node_tooltip = NULL,
  node_size = NULL,
  precomputed_plots = NULL
) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    graph_tbl_local <- graph_tbl

    is_list_graph <- is.list(graph_tbl_local) &&
      all(purrr::map_lgl(graph_tbl_local, ~ inherits(.x, "tbl_graph")))
    if (is_list_graph && is.null(names(graph_tbl_local))) {
      stop(
        "The list of graphs must be named so time windows can be selected.",
        call. = FALSE
      )
    }

    color_sym <- rlang::sym("color")
    cluster_sym <- rlang::sym(cluster_id)
    id_sym <- rlang::sym(node_id)
    tooltip_sym <- if (!is.null(node_tooltip)) {
      rlang::sym(node_tooltip)
    } else {
      NULL
    }
    id_chr <- rlang::as_name(id_sym)
    cluster_chr <- rlang::as_name(cluster_sym)

    output$graph_selector <- renderUI({
      if (!is_list_graph) {
        return(NULL)
      }
      window_vals <- names(graph_tbl_local)
      window_labels <- ifelse(
        grepl("^\\d{4}$", window_vals),
        paste0(window_vals, "-", as.integer(window_vals) + 7),
        window_vals
      )
      shinyWidgets::sliderTextInput(
        inputId = ns("selected_graph"),
        label = "Time window",
        choices = window_labels,
        selected = window_labels[1],
        grid = FALSE,
        width = "100%"
      )
    })
    selected_cluster <- reactiveVal(NULL)
    selected_graph <- reactive({
      if (is_list_graph) {
        req(input$selected_graph)
        window_vals <- names(graph_tbl_local)
        window_labels <- ifelse(
          grepl("^\\d{4}$", window_vals),
          paste0(window_vals, "-", as.integer(window_vals) + 7),
          window_vals
        )
        window_vals[[match(input$selected_graph, window_labels)]]
      } else {
        NULL
      }
    })

    active_graph <- reactive({
      if (is_list_graph) {
        req(selected_graph())
        graph_tbl_local[[selected_graph()]]
      } else {
        graph_tbl_local
      }
    })

    all_nodes_df <- reactive({
      if (is_list_graph) {
        purrr::imap_dfr(graph_tbl_local, function(g, nm) {
          df <- tidygraph::activate(g, "nodes") |> as.data.frame()
          df$.graph <- nm
          if (!"time_window" %in% names(df)) {
            df$time_window <- nm
          }
          df
        })
      } else {
        df <- tidygraph::activate(graph_tbl_local, "nodes") |> as.data.frame()
        df$.graph <- "graph"
        if (!"time_window" %in% names(df)) {
          df$time_window <- NA_character_
        }
        df
      }
    })

    output$plot <- ggiraph::renderGirafe({
      if (!is.null(precomputed_plots)) {
        if (is.list(precomputed_plots)) {
          req(selected_graph())
          return(precomputed_plots[[selected_graph()]])
        }
        return(precomputed_plots)
      }

      g_tbl <- active_graph()
      g_tbl <- tidygraph::activate(g_tbl, "nodes")

      if (is.null(node_size)) {
        g_tbl <- dplyr::mutate(g_tbl, size = 1)
      } else {
        if (!(node_size %in% colnames(as.data.frame(g_tbl)))) {
          stop(
            "The column specified in node_size does not exist in the node data.",
            call. = FALSE
          )
        }
        g_tbl <- dplyr::mutate(g_tbl, size = !!rlang::sym(node_size))
      }

      nodes_df <- as.data.frame(tidygraph::activate(g_tbl, "nodes"))

      required_cols <- c(cluster_id, node_id, "size", "x", "y")
      missing_main <- setdiff(required_cols, colnames(nodes_df))
      if (length(missing_main) > 0) {
        stop(
          paste(
            "Missing required columns in nodes:",
            paste(missing_main, collapse = ", ")
          ),
          call. = FALSE
        )
      }

      if (!"color" %in% names(nodes_df)) {
        cluster_vals <- as.character(nodes_df[[cluster_id]])
        uniq_clusters <- unique(cluster_vals)
        pal <- grDevices::hcl.colors(length(uniq_clusters), palette = "Dark 3")
        color_map <- setNames(pal, uniq_clusters)
        nodes_df$color <- unname(color_map[cluster_vals])
        g_tbl <- g_tbl %>% dplyr::mutate(color = nodes_df$color)
      }

      node_aes <- list(
        x = quote(x),
        y = quote(y),
        fill = color_sym,
        size = quote(size)
      )
      if (!is.null(tooltip_sym)) {
        node_aes$tooltip <- tooltip_sym
      } else {
        node_aes$tooltip <- id_sym
      }

      label_data <- nodes_df %>%
        dplyr::group_by(!!cluster_sym) %>%
        dplyr::summarise(
          label_x = mean(x, na.rm = TRUE),
          label_y = mean(y, na.rm = TRUE),
          color = first(!!color_sym),
          cluster_label = first(!!cluster_sym),
          .groups = "drop"
        ) %>%
        dplyr::mutate(label_id = paste0("cluster:", cluster_label))

      if (
        !is.null(cluster_tooltip) &&
          cluster_tooltip %in% names(nodes_df)
      ) {
        tooltip_sym_lbl <- rlang::sym(cluster_tooltip)
        label_data <- label_data %>%
          left_join(
            nodes_df %>%
              dplyr::distinct(!!cluster_sym, !!tooltip_sym_lbl),
            by = setNames(cluster_id, cluster_id)
          )
      }

      label_aes <- list(
        x = quote(label_x),
        y = quote(label_y),
        label = quote(cluster_label),
        data_id = quote(label_id),
        fill = quote(color)
      )
      if (
        !is.null(cluster_tooltip) &&
          cluster_tooltip %in% names(label_data)
      ) {
        label_aes$tooltip <- rlang::sym(cluster_tooltip)
      }

      node_size_range <- c(1.5, 7)
      g <- ggraph::ggraph(g_tbl, layout = "manual", x = x, y = y) +
        ggiraph::geom_point_interactive(
          mapping = do.call(ggplot2::aes, node_aes),
          shape = 21,
          alpha = 0.8,
          show.legend = FALSE
        ) +
        ggiraph::geom_label_repel_interactive(
          data = label_data,
          mapping = do.call(ggplot2::aes, label_aes),
          alpha = 0.9,
          fontface = "bold",
          show.legend = FALSE,
          size = 2.2
        ) +
        ggplot2::scale_size_continuous(range = node_size_range) +
        ggplot2::scale_fill_identity() +
        ggplot2::theme_void()

      ggiraph::girafe(
        ggobj = g,
        width_svg = 10,
        height_svg = 6,
        options = list(
          ggiraph::opts_selection(type = "single"),
          ggiraph::opts_zoom(min = 1, max = 12),
          ggiraph::opts_toolbar(position = "topright")
        )
      )
    })

    observeEvent(input$plot_selected, {
      sel <- input$plot_selected
      if (!is.null(sel) && startsWith(sel, "cluster:")) {
        selected_cluster(sub("^cluster:", "", sel))
      } else {
        selected_cluster(NULL)
      }
    })

    list(
      selected_cluster = selected_cluster,
      selected_graph = selected_graph,
      active_graph = active_graph,
      all_nodes_df = all_nodes_df,
      is_list_graph = reactive(is_list_graph),
      id_chr = id_chr,
      cluster_chr = cluster_chr
    )
  })
}
