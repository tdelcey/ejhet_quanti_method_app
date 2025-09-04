clusterUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    # shiny::uiOutput(ns("role_filter_ui")),
    # shiny::h4("Documents"),
    # DT::DTOutput(ns("cluster_docs")),
    shiny::h4("Closest sentences"),
    DT::DTOutput(ns("cluster_sentences")),
    shiny::h4("Top References"),
    DT::DTOutput(ns("cluster_refs")),
    # shiny::h4("Top References (without ID)"),
    # DT::DTOutput(ns("cluster_refs_without_id")),
    # shiny::h4("Cluster tf-idf"),
    # DT::DTOutput(ns("cluster_tf_idf")),
    # shiny::h4("Cluster origins (t-1 → t)"),
    # DT::DTOutput(ns("cluster_origins_table")),
    shiny::h4("Cluster destinies (t → t+1)"),
    DT::DTOutput(ns("cluster_destinies_table"))
  )
}

clusterServer <- function(
    id,
    all_nodes_flat,
    sentences_joined,
    refs_joined,
    refs_wo_id_joined,
    tf_idf_joined,
    origins_joined,
    destinies_joined,
    cluster_information,
    selected_graph, # reactive
    selected_cluster # reactive
) {
  shiny::moduleServer(id, function(input, output, session) {

    coerce_value_col <- function(df) {
      df %>% dplyr::mutate(value_col = as.character(value_col),
                           time_window = substr(time_window, 1, 4))
    }

    # --- Role filter UI (disabled)
    # output$role_filter_ui <- shiny::renderUI({...})

    # --- Documents (disabled)
    # output$cluster_docs <- DT::renderDT({...}, server = TRUE)

    # --- Sentences
    output$cluster_sentences <- DT::renderDT({
      shiny::req(selected_cluster(), selected_graph())
      sc <- as.character(selected_cluster())

      tab <- sentences_joined %>%
        coerce_value_col() %>%
        dplyr::filter(value_col == sc, time_window == selected_graph()) %>%
        dplyr::select(dplyr::any_of(c(
          cluster_information,
          "sentence",
          "similarity"
        )))

      DT::datatable(
        tab,
        escape = FALSE,
        options = list(pageLength = 10),
        rownames = FALSE
      )
    }, server = TRUE)

    # --- References with ID
    output$cluster_refs <- DT::renderDT({
      shiny::req(selected_cluster(), selected_graph())
      sc <- as.character(selected_cluster())

      tab <- refs_joined %>%
        coerce_value_col() %>%
        dplyr::filter(value_col == sc, time_window == selected_graph()) %>%
        dplyr::select(Nom, Annee, Revue_Abbrege, nb_cit)

      DT::datatable(tab, options = list(pageLength = 20))
    }, server = TRUE)

    # --- References without ID (disabled)
    # output$cluster_refs_without_id <- DT::renderDT({...}, server = TRUE)

    # --- TF-IDF (disabled)
    # output$cluster_tf_idf <- DT::renderDT({...}, server = TRUE)

    # --- Origins (disabled)
    # output$cluster_origins_table <- DT::renderDT({...}, server = TRUE)

    # --- Destinies
    output$cluster_destinies_table <- DT::renderDT({
      shiny::req(selected_cluster(), selected_graph())
      sc <- as.character(selected_cluster())

      tab <- destinies_joined %>%
        coerce_value_col() %>%
        dplyr::filter(value_col == sc, time_window == selected_graph()) %>%
        dplyr::select(forward_cluster, destiny_percent) %>%
        dplyr::mutate(destiny_percent = sprintf("%.1f%%", 100 * destiny_percent))

      DT::datatable(tab, options = list(pageLength = 10))
    }, server = TRUE)
  })
}
