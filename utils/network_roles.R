#: Network role helpers-------------------------

#' Fast P and z metrics for Guimera-Amaral role analysis
#'
#' Compute, for every node, total strength, participation coefficient, and
#' within-cluster z-score using a single pass over the edge list.
#'
#' @param graph An igraph or tidygraph::tbl_graph object.
#' @param comm_attr Character scalar. Vertex attribute holding cluster ids.
#' @param weight_attr Character scalar. Edge attribute holding weights.
#'
#' @return A list with total_strength, participation_coefficient, z_within.
#' @export
compute_role_fast <- function(
  graph,
  comm_attr = "cluster_leiden",
  weight_attr = "weight"
) {
  cli::cli_alert_info(
    "Computing roles for graph with {igraph::gorder(graph)} nodes and {igraph::gsize(graph)} edges."
  )

  n <- igraph::gorder(graph)
  comm <- igraph::vertex_attr(graph, comm_attr)
  if (is.null(comm)) {
    stop("vertex attribute ", comm_attr, " missing", call. = FALSE)
  }
  comm <- as.integer(factor(comm, levels = unique(comm)))

  el <- igraph::as_edgelist(graph, names = FALSE)
  w <- igraph::edge_attr(graph, weight_attr)
  if (is.null(w)) {
    w <- rep(1, nrow(el))
  }

  dt <- data.table::data.table(
    node = c(el[, 1], el[, 2]),
    other = c(el[, 2], el[, 1]),
    w = c(w, w)
  )
  dt[, comm_other := comm[other]]
  dt[, other := NULL]

  s_ic <- dt[, .(s = sum(w)), by = .(node, comm = comm_other)]

  s_i <- s_ic[, .(total_strength = sum(s)), by = node]
  total_strength <- numeric(n)
  if (nrow(s_i)) {
    total_strength[s_i$node] <- s_i$total_strength
  }

  tmp <- s_ic[s_i, on = "node"]
  tmp[, frac2 := (s / total_strength)^2]
  Ptab <- tmp[, .(P = 1 - sum(frac2)), by = node]
  P <- rep(NA_real_, n)
  if (nrow(Ptab)) {
    P[Ptab$node] <- Ptab$P
  }
  P[total_strength == 0] <- NA_real_

  data.table::setkey(s_ic, node, comm)
  idx <- data.table::data.table(node = seq_len(n), comm = comm)
  own <- s_ic[idx, .(node, s_in = s), nomatch = 0L]
  s_in <- numeric(n)
  if (nrow(own)) {
    s_in[own$node] <- own$s_in
  }

  nd <- data.table::data.table(node = seq_len(n), comm = comm, s_in = s_in)
  nd[, mu := mean(s_in), by = comm]
  nd[, sdv := stats::sd(s_in), by = comm]
  nd[, z := ifelse(is.finite(sdv) & sdv > 0, (s_in - mu) / sdv, 0)]
  z <- nd$z

  list(
    total_strength = total_strength,
    participation_coefficient = P,
    z_within = z
  )
}

#' Data-driven cut points for Guimera-Amaral role assignment
#'
#' @param z Numeric vector of within-cluster z-scores.
#' @param P Numeric vector of participation coefficients.
#' @param hub_q Quantile used as hub cutoff.
#' @param k_nonhub Number of k-means clusters for non-hub P values.
#' @param k_hub Number of k-means clusters for hub P values.
#'
#' @return A list with hub_z, nonhub_P, hub_P thresholds.
#' @export
choose_role_thresholds <- function(
  z,
  P,
  hub_q = 0.975,
  k_nonhub = 4,
  k_hub = 3
) {
  stopifnot(length(z) == length(P))
  z <- z[is.finite(z)]
  P <- P[is.finite(P)]
  if (!length(z)) {
    stop("empty z", call. = FALSE)
  }

  hub_thr <- unname(stats::quantile(z, hub_q, na.rm = TRUE))

  nonhub_P <- P[z < hub_thr]
  hub_P <- P[z >= hub_thr]

  get_breaks <- function(x, k, fallback) {
    if (length(x) >= k && length(unique(x)) >= k) {
      km <- stats::kmeans(x, centers = k, iter.max = 100)
      centers <- sort(as.numeric(km$centers))
      sort((centers[-k] + centers[-1]) / 2)
    } else {
      fallback
    }
  }

  nonhub_brks <- get_breaks(nonhub_P, k_nonhub, c(0.05, 0.62, 0.80))
  hub_brks <- get_breaks(hub_P, k_hub, c(0.30, 0.75))

  list(hub_z = hub_thr, nonhub_P = nonhub_brks, hub_P = hub_brks)
}
