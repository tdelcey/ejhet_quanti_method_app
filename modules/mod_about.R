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
      text = "This article demonstrates how unsupervised quantitative methods can enrich the history of economic thought. Using the largest English-language corpus ever assembled for the field—nearly 290,000 economics journal articles from 1900 to 2009 with citation data—we analyze the evolution of the concept of rationality. Combining large language model–based semantic analysis with bibliometric and network methods, we identify and cluster discussions of rationality across time and scales, such as the circulation of bounded rationality and the emergence of behavioral economics. We provide an open-source interactive tool to support transparency and reuse.",
      border = "#607D8B",
      bg = "#F5F7FA"
    )
  )
}
