# utils/plot_citation_network.R

plot_citation_network_girafe <- function(
  graph,
  cluster_id = "value_col",
  node_id = "ID_Art",
  node_tooltip = NULL,
  node_size = NULL,
  label_size = 2.2,
  node_size_range = c(1.5, 7),
  color_map = NULL
) {
  g_tbl <- tidygraph::activate(graph, "nodes")

  if (is.null(node_size)) {
    g_tbl <- dplyr::mutate(g_tbl, size = 1)
  } else {
    if (!(node_size %in% colnames(as.data.frame(g_tbl)))) {
      stop(
        "The column specified in node_size does not exist in the node data.",
        call. = FALSE
      )
    }
    g_tbl <- dplyr::mutate(g_tbl, size = !!rlang::sym(node_size))
  }

  nodes_df <- as.data.frame(tidygraph::activate(g_tbl, "nodes"))

  required_cols <- c(cluster_id, node_id, "size", "x", "y")
  missing_main <- setdiff(required_cols, colnames(nodes_df))
  if (length(missing_main) > 0) {
    stop(
      paste(
        "Missing required columns in nodes:",
        paste(missing_main, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (!"color" %in% names(nodes_df)) {
    cluster_vals <- as.character(nodes_df[[cluster_id]])
    if (!is.null(color_map)) {
      nodes_df$color <- dplyr::coalesce(
        unname(color_map[cluster_vals]),
        "white"
      )
    } else {
      uniq_clusters <- unique(cluster_vals)
      pal <- grDevices::hcl.colors(length(uniq_clusters), palette = "Dark 3")
      local_color_map <- setNames(pal, uniq_clusters)
      nodes_df$color <- unname(local_color_map[cluster_vals])
    }
    g_tbl <- g_tbl %>% dplyr::mutate(color = nodes_df$color)
  }

  color_sym <- rlang::sym("color")
  cluster_sym <- rlang::sym(cluster_id)
  id_sym <- rlang::sym(node_id)
  tooltip_sym <- if (!is.null(node_tooltip)) rlang::sym(node_tooltip) else NULL

  node_aes <- list(
    x = quote(x),
    y = quote(y),
    fill = color_sym,
    size = quote(size)
  )
  if (!is.null(tooltip_sym)) {
    node_aes$tooltip <- tooltip_sym
  } else {
    node_aes$tooltip <- id_sym
  }

  label_data <- nodes_df %>%
    dplyr::group_by(!!cluster_sym) %>%
    dplyr::summarise(
      label_x = mean(x, na.rm = TRUE),
      label_y = mean(y, na.rm = TRUE),
      color = first(!!color_sym),
      cluster_label = first(!!cluster_sym),
      .groups = "drop"
    ) %>%
    dplyr::mutate(label_id = paste0("cluster:", cluster_label))

  label_aes <- list(
    x = quote(label_x),
    y = quote(label_y),
    label = quote(cluster_label),
    data_id = quote(label_id),
    fill = quote(color)
  )

  g <- ggraph::ggraph(g_tbl, layout = "manual", x = x, y = y) +
    ggiraph::geom_point_interactive(
      mapping = do.call(ggplot2::aes, node_aes),
      shape = 21,
      alpha = 0.8,
      show.legend = FALSE
    ) +
    ggiraph::geom_label_repel_interactive(
      data = label_data,
      mapping = do.call(ggplot2::aes, label_aes),
      alpha = 0.9,
      fontface = "bold",
      show.legend = FALSE,
      size = label_size
    ) +
    ggplot2::scale_size_continuous(range = node_size_range) +
    ggplot2::scale_fill_identity() +
    ggplot2::theme_void()

  ggiraph::girafe(
    ggobj = g,
    width_svg = 10,
    height_svg = 6,
    options = list(
      ggiraph::opts_selection(type = "single"),
      ggiraph::opts_zoom(min = 1, max = 12),
      ggiraph::opts_toolbar(position = "topright")
    )
  )
}
