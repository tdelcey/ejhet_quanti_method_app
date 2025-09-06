app_ui <- function(request) {
  shiny::fluidPage(
    shiny::navbarPage(
      "Rationality App",
      
      tabPanel(
        "Bibliometric communities",
        networkSidebarUI("net_sidebar"),
        networkPlotUI("net_plot"),
        clusterUI("cluster")
      ),
      
      # NEW TAB
      tabPanel(
        "Textual clusters",
        # fill viewport height under the navbar; tweak the 120px if needed
        div(
          style = "height: calc(100vh - 120px);",
          tags$iframe(
            src = "data/textual_cluster.html",   # file at project/data/textual_cluster.html
            style = "width:100%; height:100%; border:0;",
            loading = "lazy"
          )
        )
      )
    )
  )
}