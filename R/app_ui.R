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
        div(style = "height: calc(100vh - 120px);",
            tags$iframe(
              src   = "bightml/textual_cluster.html",
              style = "width:100%; height:100%; border:0;",
              loading = "lazy"
            )
        ),
        tags$p(tags$a(href = "bightml/textual_cluster.html", target = "_blank", "Open full screen"))
      )
    )
  )
}