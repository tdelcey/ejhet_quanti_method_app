# R/app_ui.R
app_ui <- function() {
  shiny::fluidPage(
    shiny::titlePanel("Network Explorer"),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        width = 3,
        networkSidebarUI("net_sidebar"),
        shiny::hr(),
        DT::DTOutput("cluster_share")
      ),
      shiny::mainPanel(
        shiny::div(
          style = "border: 1px solid #ccc; padding: 10px; border-radius: 5px;",
          shinycssloaders::withSpinner(networkPlotUI("net_plot"))
        ),
        shiny::hr(),
        clusterUI("cluster")
      )
    )
  )
}
