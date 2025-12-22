pacman::p_load(
  shiny,
  shinyWidgets,
  shinycssloaders,
  ggiraph,
  ggraph,
  here,
  tidyverse,
  tidygraph,
  ggrepel,
  DT,
  bs4Dash
)
source(here::here("data_raw", "paths_and_packages.R"))

# load any helper functions and modules
list_files_helpers <- list.files(
  "utils",
  pattern = "*.R",
  full.names = TRUE,
  recursive = TRUE
)

list_files_modules <- list.files(
  "modules",
  pattern = "*.R",
  full.names = TRUE,
  recursive = TRUE
)
list_files <- c(list_files_helpers, list_files_modules)
invisible(lapply(list_files, source))


#' load data
#' ⚠️ `create_update_data()` must have been run once before launching the app ⚠️
#' The script creates/updates all the data needed for the app using a path to the ejhet_project folder.

#' `rsconnect::writeManifest(appDir = ".", appFiles = NULL)` can be used to create a manifest file for deployment on cloud.

# general ui

ui <- fluidPage(
  # Nouveau titre général
  div(
    style = "text-align:center; margin-bottom:30px; margin-top:10px;",

    div(
      style = "font-size:32px; font-weight:700; margin-bottom:6px;",
      "One sentence at a time"
    ),

    div(
      style = "font-size:20px; color:#555; font-weight:400;",
      "A quantitative history of rationality"
    )
  ),
  tabsetPanel(
    type = "pills",
    selected = "Textual network",
    tabPanel("Textual network", modules_textual_network_ui("textnet")),
    tabPanel("Citation network", modules_citation_network_ui("citnet")),
    tabPanel("About", mod_about_ui("about"))
  )
)


server <- function(input, output, session) {
  # réseau
  backbone_network <- load_data("backbone_network")
  cluster_colors <- load_data("cluster_colors")
  temporal_backbone_network <- load_data("temporal_backbone_network")
  community_label_positions <- load_data("community_label_positions")
  window_levels <- load_data("window_levels")

  # tables pour les DT
  tfidf_hdbscan <- load_data("tfidf_tables")$top_terms_hdbscan_cluster
  sentences_tbl <- load_data("cluster_sentences")
  top_articles <- load_data("cluster_top_articles")
  top_refs <- load_data("cluster_top_references")

  # precomputed plots
  textual_plots <- readRDS(here::here(
    "data_raw",
    "plots",
    "textual_network_plots.rds"
  ))

  # citation network
  bibliometrics_index_path <- here::here("data", "bibliometrics", "index.rds")
  bibliometrics_tables_path <- here::here("data", "bibliometrics", "tables.rds")
  bibliometrics_graphs_dir <- here::here("data", "bibliometrics", "graphs")

  if (
    !file.exists(bibliometrics_index_path) ||
      !file.exists(bibliometrics_tables_path) ||
      !dir.exists(bibliometrics_graphs_dir)
  ) {
    stop(
      "Missing lazy bibliometrics files. Run the data prep scripts to create ",
      "data/bibliometrics/index.rds, data/bibliometrics/tables.rds, and ",
      "data/bibliometrics/graphs/.",
      call. = FALSE
    )
  }

  biblio_index <- readRDS(bibliometrics_index_path)
  biblio_tables <- readRDS(bibliometrics_tables_path)

  graph_loader <- function(key) {
    readRDS(file.path(bibliometrics_graphs_dir, paste0(key, ".rds")))
  }

  citation_graphs <- NULL
  closest_sentences <- biblio_tables$closest_sentences
  top_refs_citation <- biblio_tables$top_refs
  top_refs_without_id <- biblio_tables$top_refs_without_id
  cluster_origins <- biblio_tables$cluster_origins
  cluster_destinies <- biblio_tables$cluster_destinies
  tf_idf <- biblio_tables$tf_idf
  citation_plots <- readRDS(
    here::here("data_raw", "plots", "citation_network_plots.rds")
  )

  citation_cluster_information <- c(
    "name",
    "bibliographic_year",
    "title",
    "role",
    "participation_coefficient",
    "z_within",
    "cit_from_cluster",
    "share_ref_cluster"
  )

  modules_textual_network_server(
    id = "textnet",
    backbone_network = backbone_network,
    temporal_backbone_network = temporal_backbone_network,
    cluster_colors = cluster_colors,
    community_label_positions = community_label_positions,
    window_levels = window_levels,
    tfidf_hdbscan = tfidf_hdbscan,
    sentences_tbl = sentences_tbl,
    top_articles = top_articles,
    top_refs = top_refs,
    static_plot = textual_plots$static,
    temporal_plot = textual_plots$temporal
  )

  modules_citation_network_server(
    id = "citnet",
    graph_tbl = citation_graphs,
    graph_index = biblio_index,
    graph_loader = graph_loader,
    cluster_id = "value_col",
    cluster_information = citation_cluster_information,
    node_id = "ID_Art",
    cluster_sentences = closest_sentences,
    top_references = top_refs_citation,
    top_references_without_id = top_refs_without_id,
    cluster_origins = cluster_origins,
    cluster_destinies = cluster_destinies,
    tf_idf_data = tf_idf,
    node_tooltip = "nodes_tooltip",
    node_size = "node_size",
    precomputed_plots = citation_plots
  )
}

shiny::shinyApp(ui = ui, server = server)
