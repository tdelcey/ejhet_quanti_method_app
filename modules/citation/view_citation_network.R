# modules/citation/view_citation_network.R

view_citation_network_ui <- function(id) {
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
      "Network of bibliographic coupling"
    ),

    callout_box(
      title = "Interpretation",
      icon = "\U0001F4DA",
      text = "Each node is an article. Articles are connected when they cite similar references — a proxy for shared intellectual background. Colors indicate communities of articles that recurrently cluster together across consecutive 8-year time windows. Uncolored nodes belong to communities that are too small or too short-lived to be considered substantive. The spatial layout positions articles with similar citation profiles in close proximity. See the paper for the full methodology.

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

view_citation_network_server <- function(
  id,
  graph_tbl = NULL,
  graph_index = NULL,
  graph_loader = NULL,
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
    has_lazy_graphs <- is.null(graph_tbl_local) &&
      !is.null(graph_index) &&
      is.function(graph_loader)

    if (has_lazy_graphs) {
      if (
        is.data.frame(graph_index) &&
          all(c("key", "label") %in% names(graph_index))
      ) {
        graph_keys <- as.character(graph_index$key)
        graph_labels <- as.character(graph_index$label)
      } else {
        graph_keys <- as.character(graph_index)
        graph_labels <- ifelse(
          grepl("^\\d{4}$", graph_keys),
          paste0(graph_keys, "-", as.integer(graph_keys) + 7),
          graph_keys
        )
      }
    }

    is_list_graph <- if (has_lazy_graphs) {
      TRUE
    } else {
      is.list(graph_tbl_local) &&
        all(purrr::map_lgl(graph_tbl_local, ~ inherits(.x, "tbl_graph")))
    }
    if (!has_lazy_graphs && is_list_graph && is.null(names(graph_tbl_local))) {
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
      if (has_lazy_graphs) {
        window_vals <- graph_keys
        window_labels <- graph_labels
      } else {
        window_vals <- names(graph_tbl_local)
        window_labels <- ifelse(
          grepl("^\\d{4}$", window_vals),
          paste0(window_vals, "-", as.integer(window_vals) + 7),
          window_vals
        )
      }
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
        if (has_lazy_graphs) {
          graph_keys[[match(input$selected_graph, graph_labels)]]
        } else {
          window_vals <- names(graph_tbl_local)
          window_labels <- ifelse(
            grepl("^\\d{4}$", window_vals),
            paste0(window_vals, "-", as.integer(window_vals) + 7),
            window_vals
          )
          window_vals[[match(input$selected_graph, window_labels)]]
        }
      } else {
        NULL
      }
    })

    active_graph <- reactive({
      if (is_list_graph) {
        req(selected_graph())
        if (has_lazy_graphs) {
          graph_loader(selected_graph())
        } else {
          graph_tbl_local[[selected_graph()]]
        }
      } else {
        graph_tbl_local
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
      is_list_graph = reactive(is_list_graph),
      id_chr = id_chr,
      cluster_chr = cluster_chr
    )
  })
}
