# modules/mod_about.R

mod_about_ui <- function(id) {
  ns <- NS(id)

  div(
    style = "
      border:2px solid #D4D4D4;
      border-radius:10px;
      padding:20px;
      background-color:#FAFAFA;
    ",
    div(
      style = "font-size:24px; font-weight:600; margin-bottom:8px;",
      "One Sentence at a Time: A Quantitative History of Rationality in Economic Thought"
    ),
    div(
      style = "font-size:14px; color:#555; margin-bottom:14px;",
      "Compiled December 21, 2025"
    ),
    # div(
    #   style = "font-size:14px; margin-bottom:6px;",
    #   strong("Authors: "),
    #   "Thomas Delcey (a), Aurelien Goutsmedt (b), Alexandre Truc (c)"
    # ),
    # div(
    #   style = "font-size:14px; margin-bottom:16px;",
    #   strong("Affiliations: "),
    #   "(a) Universite de Bourgogne, LEDI; (b) UC Louvain, ISPOLE; ICHEC; (c) Université Côte d'Azur, CNRS, GREDEG"
    # ),
    callout_box(
      title = "Abstract",
      text = "This article offers a concrete, method-driven demonstration of how unsupervised quantitative methods can enrich the history of economic thought. Focusing on the long and shifting history of rationality in economics, we assemble and analyze the most extensive English-language corpus ever used for a historical study of economics, with nearly 290,000 full-text journal articles published between 1900 and 2009, paired with structured citation data. Combining large language model–based semantic analysis with bibliometric and network methods, we trace how economists have discussed, reformulated, and contested rationality over more than a century. Our approach identifies sentences and articles most closely associated with rationality, groups them into semantic clusters and bibliometric communities within short time windows, and then aggregates these groupings over time. This multi-scale design makes it possible to both “zoom out” to capture broad intellectual transformations and “zoom in” to examine specific debates, research programs, and moments of reception. Beyond substantive findings—illustrated through the contrasting trajectories of bounded rationality and behavioral economics—the article advances a broader methodological argument. We show that unsupervised quantitative methods, when combined with close reading and historiographical expertise, function not only as tools of confirmation but also as genuine discovery devices, revealing patterns, continuities, and tensions that remain difficult to grasp through traditional approaches alone. To foster transparency and reuse, we also release an open-source interactive application that allows readers to explore the clusters, indicators, and interpretive pathways underlying our analysis.",
      border = "#607D8B",
      bg = "#F5F7FA"
    )
  )
}
