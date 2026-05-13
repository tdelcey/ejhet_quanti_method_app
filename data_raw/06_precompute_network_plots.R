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

plots_dir <- here::here("data", "plots")
dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Textual network plots (static + temporal)
# ------------------------------------------------------------
message("Precomputing textual network plots...")

backbone_network <- readRDS(here::here("data_raw", "backbone_network.rds"))
cluster_colors <- readRDS(here::here("data_raw", "cluster_colors.rds"))
temporal_backbone_network <- readRDS(here::here(
  "data_raw",
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

# Build a global color map across all time windows so that:
#   - natural language labels get a fixed color (same label = same color)
#   - cl_X clusters (unlabelled) get white (rendered as empty nodes)
all_value_cols <- unique(unlist(lapply(citation_graphs, function(g) {
  as.character(as.data.frame(tidygraph::activate(g, "nodes"))$value_col)
})))

natural_labels <- sort(all_value_cols[!grepl("^cl_\\d", all_value_cols)])
set.seed(42)
natural_labels_shuffled <- sample(natural_labels)
pal <- grDevices::hcl(
  h = seq(0, 360, length.out = length(natural_labels) + 1)[-1],
  c = 65,
  l = 58
)
citation_color_map <- stats::setNames(pal, natural_labels_shuffled)

cl_labels <- all_value_cols[grepl("^cl_\\d", all_value_cols)]
citation_color_map[cl_labels] <- "white"

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
      node_size_range = c(1.5, 7),
      color_map = citation_color_map
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
    node_size_range = c(1.5, 7),
    color_map = citation_color_map
  )
}

saveRDS(
  citation_plots,
  file.path(plots_dir, "citation_network_plots.rds")
)
