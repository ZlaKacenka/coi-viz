library(shiny)

shinyUI(fluidPage(
  titlePanel("Vizualizace kontrol COI v case"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Mapa zobrazuje..."),
      
      p("Puvodni data:", a("COI", href = "http://www.coi.cz/cz/spotrebitel/otevrena-data/")),
      
      sliderInput("time", 
                  label = "Mapa ke dni:",
                  timeFormat = "%d. %m. %Y",
                  min = as.Date("2012-01-01"), max = as.Date("2015-09-09"), value = as.Date("2012-01-01"),
                  animate = animationOptions(loop = TRUE, interval = 1000)),
      
      p("Legenda:", fluidRow(
        splitLayout(cellWidths = c("50%", "50%"), plotOutput("legend_fine"), plotOutput("legend_law"))
      ))
      #p("velikost kulicek"),
      #p("barva kulicek")
    ),
    
    
    mainPanel(plotOutput("map")#,
              #textOutput("selected_time")
    )
  )
))