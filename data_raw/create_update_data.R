# Run this script to rebuild all app data from scratch.
# Requires machine-specific paths defined in paths_and_packages.R.
# Do NOT run this as part of the Shiny app — it is for maintainers only.

source(here::here("data_raw", "paths_and_packages.R"))

scripts <- list.files(
  path    = here::here("data_raw"),
  pattern = "^[0-9]+.*\\.R$",
  full.names = TRUE
)

script_numbers <- as.numeric(gsub("^([0-9]+).*", "\\1", basename(scripts)))
scripts <- scripts[order(script_numbers)]

for (s in scripts) {
  message("Running: ", basename(s))
  source(s, local = TRUE)
}

message("Data build complete.")
