# One Sentence at a Time — Interactive Dashboard

Shiny app for exploring ~250,000 full-text English-language economics journal articles (1900–2009), built for the research project *"One Sentence at a Time: A Quantitative History of Rationality in Economic Thought"*.

## Features

- **Textual network** — semantic clusters of sentences extracted via LLM embeddings and HDBSCAN clustering, with TF-IDF keywords, representative sentences, top articles, and references per cluster.
- **Citation network** — bibliographic coupling communities across 8-year time windows, with cluster shares, closest sentences, top references, and flow tables.

## Run the app 

**Requirements:** R ≥ 4.4

Install dependencies once:

```r
install.packages("pacman")
pacman::p_load(
  shiny, shinyWidgets, shinycssloaders,
  ggiraph, ggraph, ggrepel,
  here, tidyverse, tidygraph,
  DT, bs4Dash
)
```

Then launch the app from the project root:

```r
shiny::runApp()
```

All pre-built data files are included in `data/`. No additional setup is required. 

An online version heberged by Posit Connect Cloud is available at [https://019adac8-81d4-aa0e-808c-08861c261fd2.share.connect.posit.cloud](https://019adac8-81d4-aa0e-808c-08861c261fd2.share.connect.posit.cloud).

## Data

Pre-built `.rds` files in `data/` are committed to this repository and loaded at startup. They cover:

| File | Contents |
|---|---|
| `cluster_sentences.rds` | Sentences with cluster assignments and similarity scores |
| `tfidf_tables.rds` | TF-IDF top terms per cluster |
| `cluster_top_articles.rds` / `cluster_top_references.rds` | Top articles and references per textual cluster |
| `cluster_labels.rds` | Manual cluster labels |
| `bibliometrics/` | Bibliographic coupling index, tables, and per-window graphs |
| `plots/` | Pre-rendered `ggiraph` plot objects |

## Rebuilding the data

The `data_raw/` folder contains the full data pipeline (scripts `01` through `06`) for maintainers with access to the raw datasets. They cannot be run if you have not an access to original data. Run `data_raw/create_update_data.R` to rebuild all files in `data/` from scratch. Machine-specific paths are configured in `data_raw/paths_and_packages.R`.
