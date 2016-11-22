library(shiny)

shinyUI(fluidPage(
  titlePanel("Projekt vizualizace"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Tady bude krasny popis, co ta mapa umi?"),
      
      sliderInput("time", 
                  label = "Mapa ke dni:",
                  timeFormat = "%d. %m. %Y",
                  min = as.Date("2013-01-01"), max = as.Date("2015-09-09"), value = as.Date("2013-01-01"),
                  animate = animationOptions(loop = TRUE, interval = 100))
      ),
    
    
    mainPanel(plotOutput("map")#,
              #textOutput("selected_time")
    )
  )
))