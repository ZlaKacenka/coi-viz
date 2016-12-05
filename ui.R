library(shiny)

shinyUI(fluidPage(
  includeCSS("styles.css"),
  
  titlePanel("Vizualizace kontrol COI v case"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Mapa zobrazuje kontroly "),
      
      p("Puvodni data:", a("COI", href = "http://www.coi.cz/cz/spotrebitel/otevrena-data/")),
      
      sliderInput("time", 
                  label = "Mapa ke dni:",
                  timeFormat = "%d. %m. %Y",
                  min = as.Date("2012-01-01"), max = as.Date("2015-09-09"), value = as.Date("2012-01-01"),
                  animate = animationOptions(loop = TRUE, interval = 1000)),
      
      withTags({
        div(class="legend",
              p("Barevná legenda:"),
              htmlOutput("legend_law")
        )
      })
    ),
    
    
    mainPanel(plotOutput("map", width = "100%")
    )
  )
))