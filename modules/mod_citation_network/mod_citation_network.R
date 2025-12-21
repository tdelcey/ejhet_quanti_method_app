# modules/mod_citation_network.R

modules_citation_network_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(6, mod_citation_network_view_ui(ns("view"))),
    column(6, mod_citation_cluster_tables_ui(ns("tables")))
  )
}

modules_citation_network_server <- function(
  id,
  graph_tbl,
  cluster_id,
  cluster_information,
  node_id,
  cluster_sentences,
  top_references,
  top_references_without_id,
  cluster_origins,
  cluster_destinies,
  tf_idf_data,
  cluster_tooltip = NULL,
  node_tooltip = NULL,
  node_size = NULL,
  precomputed_plots = NULL
) {
  moduleServer(id, function(input, output, session) {
    view_state <- mod_citation_network_view_server(
      "view",
      graph_tbl = graph_tbl,
      cluster_id = cluster_id,
      node_id = node_id,
      cluster_tooltip = cluster_tooltip,
      node_tooltip = node_tooltip,
      node_size = node_size,
      precomputed_plots = precomputed_plots
    )

    mod_citation_cluster_tables_server(
      "tables",
      view_state = view_state,
      cluster_id = cluster_id,
      cluster_information = cluster_information,
      node_id = node_id,
      cluster_sentences = cluster_sentences,
      top_references = top_references,
      top_references_without_id = top_references_without_id,
      cluster_origins = cluster_origins,
      cluster_destinies = cluster_destinies,
      tf_idf_data = tf_idf_data,
      node_size = node_size
    )
  })
}
