# One Sentence at a Time — Interactive Dashboard

Shiny app for exploring ~290,000 full-text English-language economics journal articles (1900–2009), built for the research project *"One Sentence at a Time: A Quantitative History of Rationality in Economic Thought"*.

## Features

- **Textual network** — semantic clusters of sentences extracted via LLM embeddings and HDBSCAN clustering, with TF-IDF keywords, representative sentences, top articles, and references per cluster.
- **Citation network** — bibliographic coupling communities across 8-year time windows, with cluster shares, closest sentences, top references, and flow tables.

## Run locally

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

## Data

Pre-built `.rds` files in `data/` are committed to this repository and loaded at startup. They cover:

| File | Contents |
|---|---|
| `backbone_network.rds` | Force-directed layout of the textual network |
| `temporal_backbone_network.rds` | Chronological layout of the textual network |
| `cluster_sentences.rds` | Sentences with cluster assignments and similarity scores |
| `tfidf_tables.rds` | TF-IDF top terms per cluster |
| `cluster_top_articles.rds` / `cluster_top_references.rds` | Top articles and references per textual cluster |
| `cluster_labels.rds` | AI-generated cluster labels |
| `cluster_colors.rds` | Cluster colour palette |
| `bibliometrics/` | Bibliographic coupling index, tables, and per-window graphs |
| `plots/` | Pre-rendered `ggiraph` plot objects |

> Rebuilding the data from raw sources requires access to internal datasets and is reserved for project maintainers.
