# modules/textual/view_textual_network.R
view_textual_network_ui <- function(id) {
  ns <- NS(id)

  div(
    style = "
      border: 2px solid #D4D4D4;
      border-radius: 10px;
      padding: 20px;
      background-color: #FDFDFD;
      height: 100%;
    ",

    # ---- Title ----
    div(
      style = "
        font-size: 20px;
        font-weight: 600;
        padding: 4px 0 4px 12px;
        border-left: 5px solid #00897B;
        margin-bottom: 15px;
      ",
      "Network of semantic clusters"
    ),

    # ---- Explanations using callout boxes ----
    callout_box(
      title = "Interpretation",
      icon = "\U0001F4DA",
      text = "Each node is a group of sentences discussing rationality in a similar way, identified within a given decade. Node size reflects how many sentences belong to that group. Colors indicate broader thematic clusters that persist across decades — nodes sharing the same color address rationality in comparable ways across time. See the paper for the full methodology.

Two visualization modes are available. Static mode positions clusters using a force-directed layout that reflects overall semantic proximity. Temporal mode groups clusters by decade along the x-axis (1900–1919, 1920–1929, …, 2000–2009), with thematic clusters separated along the y-axis, making it easier to follow how topics evolve over time.",
      border = "#00796B",
      bg = "#E0F2F1"
    ),

    # ---- Switch between static and temporal ----
    radioButtons(
      inputId = ns("mode"),
      label = "Visualization mode",
      choices = c("Static", "Temporal"),
      selected = "Static",
      inline = TRUE
    ),

    br(),

    # ---- Plot ----
    div(
      style = "
        border:1px solid #D0D0D0;
        border-radius:8px;
        padding:2px;
        background:#FFF;
      ",
      shinycssloaders::withSpinner(
        girafeOutput(ns("plot"), height = '550px'),
        type = 4,
        color = '#607D8B'
      )
    )
  )
}


# ======================================================================
# SERVER
# ======================================================================

view_textual_network_server <- function(
  id,
  backbone_network = NULL,
  temporal_backbone_network = NULL,
  static_plot = NULL,
  temporal_plot = NULL
) {
  moduleServer(id, function(input, output, session) {
    # ------------------------------------------------------------------
    # Render network plot
    # ------------------------------------------------------------------
    output$plot <- ggiraph::renderGirafe({
      if (input$mode == "Static") {
        if (!is.null(static_plot)) {
          static_plot
        } else {
          if (is.null(backbone_network)) {
            stop("Missing backbone_network for static plot rendering.")
          }
          plot_textual_network_static(
            graph = backbone_network
          )
        }
      } else {
        if (!is.null(temporal_plot)) {
          temporal_plot
        } else {
          if (is.null(temporal_backbone_network)) {
            stop("Missing temporal_backbone_network for temporal plot rendering.")
          }
          plot_textual_network_dynamic(
            temporal_backbone_network = temporal_backbone_network
          )
        }
      }
    })

    # ------------------------------------------------------------------
    # Return selected node cluster_id to parent module
    # ------------------------------------------------------------------
    reactive(input$plot_selected)
  })
}
