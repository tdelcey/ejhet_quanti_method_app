plot_textual_network_static <- function(graph) {
  # 1. Apply node colors (fallback) + tooltip
  graph <- graph %>%
    tidygraph::activate("nodes")

  graph <- graph %>%
    dplyr::mutate(
      tooltip = paste0(
        "Period: ",
        window,
        "\n",
        "TF-IDF: ",
        tfidf_label,
        "\n",
        "Proportion of sentences: ",
        round(proportion_global * 100, 2),
        "%"
      )
    )

  # 2. Nodes table
  nodes_df <- graph %>%
    tidygraph::activate("nodes") %>%
    dplyr::as_tibble()

  # 3 Label table
  label_df <- nodes_df %>%
    dplyr::group_by(backbone_community) %>%
    dplyr::summarise(
      label_x = mean(x),
      label_y = mean(y),
      label = first(label_backbone_community),
      fill_color = first(fill_color),
      .groups = "drop"
    )

  # 4. Plot
  p <- ggraph::ggraph(graph, layout = "manual", x = x, y = y) +
    ggraph::geom_edge_link0(
      ggplot2::aes(
        color = I(edge_color),
        width = edge_width
      ),
      alpha = 0.9,
      show.legend = FALSE
    ) +
    scale_size_continuous(range = c(2, 15)) +
    scale_edge_width(range = c(0.3, 1.2)) +
    ggplot2::theme_void() +
    ggiraph::geom_point_interactive(
      data = nodes_df,
      ggplot2::aes(
        x = x,
        y = y,
        fill = I(fill_color),
        data_id = cluster_id,
        tooltip = tooltip,
        size = proportion_global
      ),
      shape = 21,
      alpha = 0.9,
      show.legend = FALSE,
    ) +
    ggrepel::geom_label_repel(
      data = label_df,
      ggplot2::aes(
        x = label_x,
        y = label_y,
        label = label,
        fill = I(fill_color)
      ),
      color = "black",
      size = 4.2,
      fontface = "bold",
      label.size = 0.3,
      label.r = unit(0.15, "lines"),
      alpha = 0.70,
      seed = 42
    )

  # 6. Girafe interactive
  ggiraph::girafe(
    ggobj = p,
    width_svg = 16,
    height_svg = 10,
    options = list(
      ggiraph::opts_selection(type = "single"),
      ggiraph::opts_zoom(min = 1, max = 12),
      ggiraph::opts_toolbar(position = "topright")
    )
  )
}


plot_textual_network_dynamic <- function(
  temporal_backbone_network
) {
  community_label_positions <- attr(
    temporal_backbone_network,
    "community_label_positions"
  )
  window_levels <- attr(temporal_backbone_network, "window_levels")
  if (is.null(community_label_positions) || is.null(window_levels)) {
    stop(
      "Missing temporal inputs: set attributes on temporal_backbone_network ",
      "for community_label_positions and window_levels."
    )
  }
  # 1. Add node colors (fallback) + tooltip
  graph <- temporal_backbone_network %>%
    tidygraph::activate("nodes")
  if (!"fill_color" %in% colnames(graph %>% dplyr::as_tibble())) {
    cluster_colors <- attr(temporal_backbone_network, "cluster_colors")
    if (is.null(cluster_colors)) {
      stop("Missing cluster_colors attribute for temporal_backbone_network.")
    }
    graph <- graph %>%
      mutate(
        fill_color = cluster_colors[as.character(backbone_community)]
      )
  }
  graph <- graph %>%
    mutate(
      tooltip = paste0(
        "Period: ",
        window,
        "\n",
        "TF-IDF: ",
        tfidf_label,
        "\n",
        "Proportion of sentences in this time window: ",
        round(proportion_hdbscan_cluster * 100, 2),
        "%"
      )
    )

  # 2. Edge colors are expected to be precomputed in the graph
  graph <- graph %>%
    tidygraph::activate("edges")

  nodes_df <- graph %>%
    tidygraph::activate("nodes") %>%
    as_tibble()

  # 3. Plot
  p <- ggraph(
    graph,
    layout = "manual",
    x = x,
    y = y
  ) +
    geom_edge_link(
      aes(
        color = I(edge_color),
        width = edge_width
      ),
      alpha = 0.9,
      show.legend = FALSE
    ) +
    ggiraph::geom_point_interactive(
      data = nodes_df,
      aes(
        x = x,
        y = y,
        fill = I(fill_color),
        size = proportion_hdbscan_cluster,
        tooltip = tooltip,
        data_id = cluster_id
      ),
      shape = 21,
      alpha = 0.9,
      show.legend = FALSE
    ) +
    scale_size_continuous(range = c(2, 15)) +
    scale_edge_width(range = c(0.3, 1.2)) +
    scale_x_continuous(
      breaks = seq_along(window_levels),
      labels = window_levels
    ) +
    scale_y_continuous(
      breaks = community_label_positions$baseline,
      labels = community_label_positions$label,
      expand = expansion(add = c(0.9, 0.9))
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 20) +
    theme(
      panel.grid = element_blank(),
      axis.text.y = element_text(size = 13, hjust = 1),
      axis.text.x = element_text(
        angle = 45,
        hjust = 1,
        vjust = 1,
        size = 13
      ),
      axis.ticks = element_line(color = "grey50"),
      axis.line = element_line(color = "grey50")
    )

  # 4. Return girafe widget
  ggiraph::girafe(
    ggobj = p,
    width_svg = 16,
    height_svg = 10,
    options = list(
      ggiraph::opts_selection(type = "single"),
      ggiraph::opts_zoom(min = 1, max = 12),
      ggiraph::opts_tooltip(use_fill = TRUE),
      ggiraph::opts_toolbar(position = "topright")
    )
  )
}
