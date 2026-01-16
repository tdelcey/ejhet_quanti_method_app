# modules/textual/page_textual_network.R

page_textual_network_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(6, view_textual_network_ui(ns("net"))),
    column(6, tables_textual_cluster_ui(ns("tables")))
  )
}

page_textual_network_server <- function(
  id,
  backbone_network = NULL,
  temporal_backbone_network = NULL,
  tfidf_hdbscan,
  sentences_tbl,
  top_articles,
  top_refs,
  cluster_labels,
  static_plot = NULL,
  temporal_plot = NULL
) {
  moduleServer(id, function(input, output, session) {
    selected_cluster <- view_textual_network_server(
      "net",
      backbone_network,
      temporal_backbone_network,
      static_plot = static_plot,
      temporal_plot = temporal_plot
    )

    tables_textual_cluster_server(
      "tables",
      selected_cluster,
      tfidf_hdbscan,
      sentences_tbl,
      top_articles,
      top_refs,
      cluster_labels
    )
  })
}
