# modules/citation/tables_citation_cluster.R

tables_citation_cluster_ui <- function(id) {
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
        border-left:5px solid #3F51B5;
        margin-bottom:15px;
      ",
      "Cluster details"
    ),

    uiOutput(ns("selected_cluster_label")),

    p("Click a cluster label to explore its content."),

    tabsetPanel(
      id = ns("tabs"),
      tabPanel(
        "Cluster share",
        callout_box(
          "Interpretation",
          "Share of articles per cluster within the selected time window."
        ),
        DTOutput(ns("cluster_share"))
      ),
      tabPanel(
        "TF-IDF",
        callout_box(
          "Interpretation",
          "TF-IDF highlights terms that are specific to a cluster compared to all articles across all time windows."
        ),
        DTOutput(ns("cluster_tf_idf"))
      ),
      tabPanel(
        "Closest sentences",
        callout_box(
          "Interpretation",
          "Sentences most representative of the cluster content for the period."
        ),
        DTOutput(ns("cluster_sentences"))
      ),
      tabPanel(
        "Top references",
        callout_box(
          "Interpretation",
          "Most cited references among articles in the selected cluster."
        ),
        shinyWidgets::prettySwitch(
          inputId = ns("refs_with_id_only"),
          label = "Only references with a known ID",
          value = FALSE,
          status = "primary",
          inline = TRUE
        ),
        DTOutput(ns("cluster_refs"))
      ),
      tabPanel(
        "Flows",
        callout_box(
          "Interpretation",
          "Origins show where articles came from (t-1), destinies show where they go (t+1)."
        ),
        tabsetPanel(
          id = ns("flow_tabs"),
          tabPanel(
            "Origins",
            DTOutput(ns("cluster_origins_table"))
          ),
          tabPanel(
            "Destinies",
            DTOutput(ns("cluster_destinies_table"))
          )
        )
      )
    )
  )
}

tables_citation_cluster_server <- function(
  id,
  view_state,
  cluster_id,
  cluster_information,
  node_id,
  cluster_sentences,
  top_references,
  top_references_without_id,
  cluster_origins,
  cluster_destinies,
  tf_idf_data,
  node_size = NULL
) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    selected_cluster <- view_state$selected_cluster
    selected_graph <- view_state$selected_graph
    active_graph <- view_state$active_graph
    is_list_graph <- view_state$is_list_graph
    id_chr <- view_state$id_chr
    cluster_chr <- view_state$cluster_chr

    cluster_sym <- rlang::sym(cluster_id)

    make_dt <- function(
      data,
      ...,
      options = list(),
      escape = TRUE,
      rownames = FALSE
    ) {
      dt <- DT::datatable(
        data,
        options = options,
        escape = escape,
        rownames = rownames,
        ...
      )
      DT::formatStyle(dt, columns = names(data), fontSize = "11px")
    }

    output$selected_cluster_label <- renderUI({
      cid <- selected_cluster()
      label <- if (is.null(cid) || cid == "") {
        "Selected cluster: none"
      } else {
        paste0("Selected cluster: ", cid)
      }
      div(
        style = "margin:6px 0 12px; font-size:13px; color:#444;",
        label
      )
    })

    output$cluster_share <- DT::renderDT({
      g_tbl <- active_graph()
      nodes <- tidygraph::activate(g_tbl, "nodes") %>% as.data.frame()

      tab <- nodes %>%
        dplyr::count(!!cluster_sym, name = "n") %>%
        dplyr::mutate(
          prop = n / sum(n),
          pct = sprintf("%.1f%%", 100 * prop)
        ) %>%
        dplyr::arrange(dplyr::desc(prop)) %>%
        dplyr::rename(Cluster = !!cluster_sym) %>%
        dplyr::select(Cluster, n, pct)

      DT::datatable(
        tab,
        options = list(dom = "t", paging = FALSE),
        rownames = FALSE
      ) %>%
        DT::formatStyle(columns = names(tab), fontSize = "11px")
    })

    output$cluster_sentences <- DT::renderDT({
      req(selected_cluster())
      g_tbl <- active_graph()

      nodes_keys <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        dplyr::mutate(
          time_window = if ("time_window" %in% names(.)) {
            as.character(.data$time_window)
          } else {
            as.character(selected_graph())
          }
        ) %>%
        dplyr::distinct(!!cluster_sym, time_window)

      sentences <- nodes_keys %>%
        dplyr::left_join(
          cluster_sentences %>%
            dplyr::mutate(time_window = as.character(.data$time_window)),
          by = setNames(c(cluster_id, "time_window"), c(cluster_id, "time_window"))
        )

      tab <- sentences %>%
        dplyr::filter(
          as.character(.data[[cluster_id]]) == as.character(selected_cluster())
        ) %>%
        dplyr::select(dplyr::any_of(c(
          cluster_information,
          "sentence",
          "journal",
          "similarity_rv"
        ))) %>%
        dplyr::rename(cosine_similarity = similarity_rv)

      make_dt(
        tab,
        escape = FALSE,
        options = list(pageLength = 15),
        rownames = FALSE
      )
    })

    output$cluster_refs <- DT::renderDT({
      req(selected_cluster())
      g_tbl <- active_graph()
      main_refs_cluster <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        distinct(!!cluster_sym, time_window) %>%
        dplyr::left_join(top_references) %>%
        dplyr::mutate(has_id = TRUE)

      no_id_refs <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        distinct(!!cluster_sym, time_window) %>%
        dplyr::left_join(top_references_without_id) %>%
        dplyr::mutate(has_id = FALSE)

      combined_refs <- dplyr::bind_rows(main_refs_cluster, no_id_refs)
      tab <- combined_refs %>%
        dplyr::filter(
          as.character(.data[[cluster_id]]) == as.character(selected_cluster())
        ) %>%
        dplyr::select(name, year, journal_abbrev, nb_cit, has_id) %>%
        dplyr::arrange(dplyr::desc(nb_cit))

      if (isTRUE(input$refs_with_id_only)) {
        tab <- dplyr::filter(tab, has_id)
      }

      tab <- dplyr::select(tab, -has_id)
      make_dt(tab, options = list(pageLength = 20), rownames = FALSE)
    })

    output$cluster_tf_idf <- DT::renderDT({
      req(selected_cluster())
      g_tbl <- active_graph()
      tf_idf_for_cluster <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        distinct(!!cluster_sym, time_window) %>%
        dplyr::left_join(tf_idf_data) %>%
        dplyr::filter(!is.na(term))
      tab <- tf_idf_for_cluster %>%
        dplyr::filter(
          as.character(.data[[cluster_id]]) == as.character(selected_cluster())
        ) %>%
        dplyr::select(term, tf_idf) %>%
        dplyr::mutate(tf_idf = round(tf_idf, 4))
      make_dt(tab, options = list(pageLength = 20), rownames = FALSE)
    })

    output$cluster_origins_table <- DT::renderDT({
      req(selected_cluster())
      g_tbl <- active_graph()
      origins <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        distinct(!!cluster_sym, time_window) %>%
        dplyr::left_join(cluster_origins)
      tab <- origins %>%
        dplyr::filter(
          as.character(.data[[cluster_id]]) == as.character(selected_cluster())
        ) %>%
        dplyr::select(previous_cluster, origin_percent) %>%
        dplyr::mutate(origin_percent = sprintf("%.1f%%", 100 * origin_percent))
      make_dt(tab, options = list(pageLength = 10), rownames = FALSE)
    })

    output$cluster_destinies_table <- DT::renderDT({
      req(selected_cluster())
      g_tbl <- active_graph()
      destinies <- g_tbl %>%
        tidygraph::activate("nodes") %>%
        as.data.frame() %>%
        distinct(!!cluster_sym, time_window) %>%
        dplyr::left_join(cluster_destinies)

      tab <- destinies %>%
        dplyr::filter(
          as.character(.data[[cluster_id]]) == as.character(selected_cluster())
        ) %>%
        dplyr::select(forward_cluster, destiny_percent) %>%
        dplyr::mutate(
          destiny_percent = sprintf("%.1f%%", 100 * destiny_percent)
        )

      make_dt(
        tab,
        options = list(pageLength = 10),
        rownames = FALSE
      )
    })
  })
}
