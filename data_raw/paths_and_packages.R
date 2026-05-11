if (!"pacman" %in% rownames(installed.packages())) {
  install.packages("pacman")
}

library(pacman)
p_load(
  tidyverse,
  stringr
)

#original text path stored in google drive
if (str_detect(getwd(), "goutsmed")) {
  if (str_detect(getwd(), "agoutsmedt")) {
    ejhet_project <- file.path(
      path.expand("~"),
      "Nextcloud",
      "ejhet_project"
    )
    jstor_data_path <- file.path(
      path.expand("~"),
      "Nextcloud",
      "jstor"
    )
    jstor_raw_data <- file.path(path.expand("~"), "data", "jstor") # I'm storing the raw data in a different folder because it's heavy.

    wos_data_path <- file.path(
      path.expand("~"),
      "data",
      "wos"
    )

    elsevier_data_path <- file.path(
      path.expand("~"),
      "Nextcloud",
      "Research",
      "data",
      "elsevier"
    )
  } else {
    data_path <- file.path(path.expand("~"), "data", "ejhet_project")
    jstor_data_path <- file.path(path.expand("~"), "data", "jstor")
    jstor_raw_data <- jstor_data_path
    wos_data_path <- file.path(path.expand("~"), "data", "wos")
    elsevier_data_path <- file.path(path.expand("~"), "data", "elsevier")
  }
} else if (str_detect(getwd(), "D:/Dropbox/8")) {
  data_path <- "D:/Dropbox/8-Projets Quanti/1-R_Projects/Data/ejhet_quanti_method"
  general_data_path <- "D:/Dropbox/8-Projets Quanti/1-R_Projects/Data/1-General_data"
} else if (str_detect(getwd(), "E:/Dropbox/8")) {
  data_path <- "E:/Dropbox/8-Projets Quanti/1-R_Projects/Data/ejhet_quanti_method"
  general_data_path <- "E:/Dropbox/8-Projets Quanti/1-R_Projects/Data/1-General_data"
} else {
  if (str_detect(getwd(), "github_p")) {
    ejhet_project   <- "C:/cloud/data/ejhet_project"
    wos_db          <- "D:/wos/wos.duckdb"
    jstor_db        <- "D:/jstor/jstor.duckdb"
    istex_db        <- "D:/istex/istex.duckdb"
    elsevier_db     <- "D:/elsevier/scopus.duckdb"
    embeddings_data <- "D:/econ_embeddings"
  } else {
    if (str_detect(getwd(), "github_w")) {
      ejhet_project   <- "C:/cloud/data/ejhet_project"
      wos_db          <- "D:/wos/wos.duckdb"
      jstor_db        <- "D:/jstor/jstor.duckdb"
      istex_db        <- "D:/istex/istex.duckdb"
      elsevier_db     <- "D:/elsevier/scopus.duckdb"
      embeddings_data <- "D:/econ_embeddings"
    }
  }
}
