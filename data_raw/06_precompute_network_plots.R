# ============================================================
# 06_precompute_network_plots.R
# Precompute interactive network plots for the Shiny app
# ============================================================

source(here::here("data_raw", "paths_and_packages.R"))
p_load(
  tidyverse,
  tidygraph,
  ggraph,
  ggiraph,
  ggrepel
)

source(here::here("utils", "plot_textual_network.R"))
source(here::here("utils", "plot_citation_network.R"))

plots_dir <- here::here("data_raw", "plots")
dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Textual network plots (static + temporal)
# ------------------------------------------------------------
message("Precomputing textual network plots...")

backbone_network <- readRDS(here::here("data", "backbone_network.rds"))
cluster_colors <- readRDS(here::here("data", "cluster_colors.rds"))
temporal_backbone_network <- readRDS(here::here(
  "data",
  "temporal_backbone_network.rds"
))

textual_static <- plot_textual_network_static(
  graph = backbone_network
)

textual_dynamic <- plot_textual_network_dynamic(
  temporal_backbone_network = temporal_backbone_network
)

saveRDS(
  list(static = textual_static, temporal = textual_dynamic),
  file.path(plots_dir, "textual_network_plots.rds")
)

# ------------------------------------------------------------
# Citation network plots (per time window)
# ------------------------------------------------------------

message("Precomputing citation network plots...")

biblio_dir <- here::here("data", "bibliometrics")
graphs_dir <- file.path(biblio_dir, "graphs")
biblio_index <- readRDS(file.path(biblio_dir, "index.rds"))

citation_graphs <- lapply(biblio_index$key, function(k) {
  readRDS(file.path(graphs_dir, paste0(k, ".rds")))
})
names(citation_graphs) <- biblio_index$key

if (is.list(citation_graphs)) {
  if (is.null(names(citation_graphs))) {
    names(citation_graphs) <- as.character(seq_along(citation_graphs))
  }
  citation_plots <- purrr::imap(citation_graphs, function(g, nm) {
    plot_citation_network_girafe(
      graph = g,
      cluster_id = "value_col",
      node_id = "ID_Art",
      node_tooltip = "nodes_tooltip",
      node_size = "node_size",
      label_size = 2.2,
      node_size_range = c(1.5, 7)
    )
  })
} else {
  citation_plots <- plot_citation_network_girafe(
    graph = citation_graphs,
    cluster_id = "value_col",
    node_id = "ID_Art",
    node_tooltip = "nodes_tooltip",
    node_size = "node_size",
    label_size = 2.2,
    node_size_range = c(1.5, 7)
  )
}

saveRDS(
  citation_plots,
  file.path(plots_dir, "citation_network_plots.rds")
)
