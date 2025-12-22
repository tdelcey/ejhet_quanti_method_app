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
    div(
      style = "font-size:14px; margin-bottom:6px;",
      strong("Authors: "),
      "Thomas Delcey (a), Aurelien Goutsmedt (b), Alexandre Truc (c)"
    ),
    div(
      style = "font-size:14px; margin-bottom:16px;",
      strong("Affiliations: "),
      "(a) Universite de Bourgogne, LEDI; (b) UC Louvain, ISPOLE; ICHEC; (c) Université Côte d'Azur, CNRS, GREDEG"
    ),
    callout_box(
      title = "Abstract",
      text = "This paper provides a concrete, method-driven account of how unsupervised classification models can illuminate the history of a capacious concept in economics--rationality. We assemble a large full-text corpus paired with structured citation data and use large language models to trace semantic shifts since 1900. Combining semantic analysis with bibliometrics and network methods, we document how methodological choices shape both corpus construction and results. We show that unsupervised models, when combined with close reading, function as tools of both confirmation and discovery in the history of economics. We also release a free-open source application that allows scholars to explore the identified clusters and the indicators used to interpret them.",
      border = "#607D8B",
      bg = "#F5F7FA"
    )
  )
}
