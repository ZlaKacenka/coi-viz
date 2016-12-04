library(shiny)

shinyUI(fluidPage(
  includeCSS("styles.css"),
  
  titlePanel("Vizualizace kontrol COI v case"),
  
  sidebarLayout(
    sidebarPanel(
      tags$head(tags$style("#map{height:100vh !important;}")),
      helpText("Mapa zobrazuje..."),
      
      p("Puvodni data:", a("COI", href = "http://www.coi.cz/cz/spotrebitel/otevrena-data/")),
      
      sliderInput("time", 
                  label = "Mapa ke dni:",
                  timeFormat = "%d. %m. %Y",
                  min = as.Date("2012-01-01"), max = as.Date("2015-09-09"), value = as.Date("2012-01-01"),
                  animate = animationOptions(loop = TRUE, interval = 1000)),
      
      #p("Legenda:"),
      withTags({
        div(class="legend",
          #div(class="left_column",
              p("Barevná legenda:"),
              htmlOutput("legend_law")
          #)
        )
      })
      #p("velikost kulicek"),
      #p("barva kulicek")
    ),
    
    
    mainPanel(plotOutput("map", width = "100%")
    )
  )
))