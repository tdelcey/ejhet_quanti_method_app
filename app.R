# inst/app/app.R
pkgload::load_all()
rationality.app::run_app()


# # to update data of the package
# 
# data <- readRDS(here::here("data", "data_for_app_bibliometrics.RDS"))
# 
# # ungroup all data
# 
# list2env(data, envir = environment())
# 
# closest_sentences <- closest_sentences %>% dplyr::ungroup()
# cluster_destinies <- cluster_destinies %>% dplyr::ungroup()
# cluster_origins <- cluster_origins %>% dplyr::ungroup()
# top_refs <- top_refs %>% dplyr::ungroup()
# 
# # save in rda
# 
# usethis::use_data(
#   graphs,
#   closest_sentences,
#   cluster_destinies,
#   cluster_origins,
#   top_refs,
#   overwrite = TRUE
# )
# 

# add dependencies for connect 

# rsconnect::writeManifest(appDir = ".")
