# inst/app/app.R
pkgload::load_all()
rationality.app::run_app()


# to update data of the package

# data <- readRDS(here::here("data", "data_for_app_bibliometrics.RDS"))
# 
# usethis::use_data(
#   graphs,
#   closest_sentences,
#   cluster_destinies,
#   cluster_origins,
#   top_refs, 
#   overwrite = TRUE
# )

