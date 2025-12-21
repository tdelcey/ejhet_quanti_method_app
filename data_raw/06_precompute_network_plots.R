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

source(here::here("utils", "plot_backbone.R"))
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
community_label_positions <- readRDS(here::here(
  "data",
  "community_label_positions.rds"
))
window_levels <- readRDS(here::here("data", "window_levels.rds"))

textual_static <- plot_network_interactive_static(
  graph = backbone_network,
  cluster_colors = cluster_colors
)

textual_dynamic <- plot_network_interactive_dynamic(
  temporal_backbone_network = temporal_backbone_network,
  cluster_colors = cluster_colors,
  community_label_positions = community_label_positions,
  window_levels = window_levels
)

saveRDS(
  list(static = textual_static, temporal = textual_dynamic),
  file.path(plots_dir, "textual_network_plots.rds")
)

# ------------------------------------------------------------
# Citation network plots (per time window)
# ------------------------------------------------------------

message("Precomputing citation network plots...")

bibliometrics_data <- readRDS(file.path(
  "data",
  "data_for_app_bibliometrics.RDS"
))

citation_graphs <- bibliometrics_data$graphs

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
