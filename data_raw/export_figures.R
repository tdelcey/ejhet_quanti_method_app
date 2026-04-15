# ============================================================
# export_figures.R
# Export static versions of network plots for the paper
# ============================================================

source(here::here("data_raw", "paths_and_packages.R"))
p_load(tidyverse, tidygraph, ggraph, ggrepel)

pictures_dir <- file.path(
  dirname(here::here()),
  "ejhet_quanti_method",
  "paper",
  "images"
)

# ============================================================
# 1. Static backbone network
# ============================================================

backbone_network <- readRDS(here::here("data", "backbone_network.rds"))

nodes_df <- backbone_network %>%
  tidygraph::activate("nodes") %>%
  dplyr::as_tibble()

label_df <- nodes_df %>%
  dplyr::group_by(backbone_community) %>%
  dplyr::summarise(
    label_x = mean(x),
    label_y = mean(y),
    label = dplyr::first(label_backbone_community),
    fill_color = dplyr::first(fill_color),
    .groups = "drop"
  )

p_static <- ggraph::ggraph(backbone_network, layout = "manual", x = x, y = y) +
  ggraph::geom_edge_link0(
    ggplot2::aes(color = I(edge_color), width = edge_width),
    alpha = 0.9,
    show.legend = FALSE
  ) +
  ggplot2::scale_size_continuous(range = c(2, 15)) +
  ggraph::scale_edge_width(range = c(0.3, 1.2)) +
  ggplot2::geom_point(
    data = nodes_df,
    ggplot2::aes(x = x, y = y, fill = I(fill_color), size = proportion_global),
    shape = 21,
    alpha = 0.9,
    show.legend = FALSE
  ) +
  ggrepel::geom_label_repel(
    data = label_df,
    ggplot2::aes(x = label_x, y = label_y, label = label, fill = I(fill_color)),
    color = "black",
    size = 6,
    fontface = "bold",
    label.size = 0.4,
    label.r = ggplot2::unit(0.15, "lines"),
    alpha = 1,
    seed = 42
  ) +
  ggplot2::theme_void()

ggsave(
  file.path(pictures_dir, "backbone_communities_network.png"),
  plot = p_static,
  width = 20,
  height = 14,
  dpi = 300
)
message("Saved: backbone_communities_network.png")

# ============================================================
# 2. Temporal backbone network
# ============================================================

temporal_backbone_network <- readRDS(here::here(
  "data",
  "temporal_backbone_network.rds"
))

community_label_positions <- attr(
  temporal_backbone_network,
  "community_label_positions"
)
window_levels <- attr(temporal_backbone_network, "window_levels")

graph <- temporal_backbone_network %>%
  tidygraph::activate("nodes")

if (!"fill_color" %in% colnames(graph %>% dplyr::as_tibble())) {
  cluster_colors <- attr(temporal_backbone_network, "cluster_colors")
  graph <- graph %>%
    dplyr::mutate(fill_color = cluster_colors[as.character(backbone_community)])
}

nodes_df_t <- graph %>%
  tidygraph::activate("nodes") %>%
  dplyr::as_tibble()

p_temporal <- ggraph::ggraph(
  temporal_backbone_network,
  layout = "manual",
  x = x,
  y = y
) +
  ggraph::geom_edge_link(
    ggplot2::aes(color = I(edge_color), width = edge_width),
    alpha = 0.9,
    show.legend = FALSE
  ) +
  ggplot2::geom_point(
    data = nodes_df_t,
    ggplot2::aes(
      x = x,
      y = y,
      fill = I(fill_color),
      size = proportion_hdbscan_cluster
    ),
    shape = 21,
    alpha = 0.9,
    show.legend = FALSE
  ) +
  ggplot2::scale_size_continuous(range = c(2, 15)) +
  ggraph::scale_edge_width(range = c(0.3, 1.2)) +
  ggplot2::scale_x_continuous(
    breaks = seq_along(window_levels),
    labels = window_levels
  ) +
  ggplot2::scale_y_continuous(
    breaks = community_label_positions$baseline,
    labels = community_label_positions$label,
    expand = ggplot2::expansion(add = c(0.9, 0.9))
  ) +
  ggplot2::labs(x = NULL, y = NULL) +
  ggplot2::theme_minimal(base_size = 16) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_text(size = 16, hjust = 1),
    axis.text.x = ggplot2::element_text(
      angle = 45,
      hjust = 1,
      vjust = 1,
      size = 14
    ),
    axis.ticks = ggplot2::element_line(color = "grey50"),
    axis.line = ggplot2::element_line(color = "grey50")
  )

ggsave(
  file.path(pictures_dir, "temporal_network_plot.png"),
  plot = p_temporal,
  width = 20,
  height = 12,
  dpi = 300
)
message("Saved: temporal_network_plot.png")

# ============================================================
# 3. Citation network — 1994-2001 with edges
# ============================================================

g_cit <- readRDS(here::here("data", "bibliometrics", "graphs", "1994.rds"))

nodes_cit <- as.data.frame(tidygraph::activate(g_cit, "nodes"))
edges_cit <- as.data.frame(tidygraph::activate(g_cit, "edges"))

# Color map: natural labels get a fixed color, cl_X clusters get white
cluster_vals <- as.character(nodes_cit[["value_col"]])
natural_labels <- sort(unique(cluster_vals[!grepl("^cl_\\d", cluster_vals)]))
set.seed(42)
natural_shuffled <- sample(natural_labels)
pal_cit <- grDevices::hcl(
  h = seq(0, 360, length.out = length(natural_labels) + 1)[-1],
  c = 65,
  l = 58
)
color_map_cit <- stats::setNames(pal_cit, natural_shuffled)
color_map_cit[unique(cluster_vals[grepl("^cl_\\d", cluster_vals)])] <- "white"

nodes_cit$color <- dplyr::coalesce(unname(color_map_cit[cluster_vals]), "white")
g_cit <- g_cit %>%
  tidygraph::activate("nodes") %>%
  dplyr::mutate(
    color = nodes_cit$color,
    size = node_size
  )

label_data_cit <- nodes_cit %>%
  dplyr::mutate(color = nodes_cit$color) %>%
  dplyr::group_by(value_col) %>%
  dplyr::summarise(
    label_x = mean(x, na.rm = TRUE),
    label_y = mean(y, na.rm = TRUE),
    color = dplyr::first(color),
    .groups = "drop"
  ) %>%
  dplyr::filter(!grepl("^cl_\\d", value_col))

p_cit <- ggraph::ggraph(g_cit, layout = "manual", x = x, y = y) +
  ggraph::geom_edge_link(
    ggplot2::aes(alpha = weight, width = weight),
    color = "grey60",
    show.legend = FALSE
  ) +
  ggplot2::geom_point(
    data = nodes_cit %>% dplyr::mutate(color = nodes_cit$color),
    ggplot2::aes(x = x, y = y, fill = I(color), size = node_size),
    shape = 21,
    alpha = 0.8,
    show.legend = FALSE
  ) +
  ggrepel::geom_label_repel(
    data = label_data_cit,
    ggplot2::aes(x = label_x, y = label_y, label = value_col, fill = I(color)),
    alpha = 1,
    fontface = "bold",
    size = 4,
    show.legend = FALSE
  ) +
  ggplot2::scale_size_continuous(range = c(1.5, 7)) +
  ggraph::scale_edge_width(range = c(0.1, 1)) +
  ggraph::scale_edge_alpha(range = c(0.05, 0.4)) +
  ggplot2::scale_fill_identity() +
  ggplot2::theme_void()

ggsave(
  file.path(pictures_dir, "citation_network_1994_2001.png"),
  plot = p_cit,
  width = 20,
  height = 14,
  dpi = 300
)
message("Saved: citation_network_1994_2001.png")
