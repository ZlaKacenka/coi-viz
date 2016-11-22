# server.R
library(shiny)
library(ggmap)

library(ggmap)

#Nacteni dat
kontroly <- read.csv("data/kontroly.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
kontroly$Id.kontroly <- as.character(kontroly$Id.kontroly)

sankce <- read.csv("data/sankce.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
sankce$ID.kontroly <- as.character(sankce$ID.kontroly)

data <- merge(kontroly, sankce, by.x="Id.kontroly", by.y="ID.kontroly", all.x = TRUE)

souradnice <- read.csv("data/souradnice.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
souradnice <- souradnice[c(2,8,9)]
names(souradnice)[1] <- "NUTS5"

data <-merge(data, souradnice, by.x="NUTS.5", by.y="NUTS5")

#zaklad mapy CR
theme_set(theme_bw(16))
CzMap <- qmap("czech republic", zoom = 7, color = "bw")

shinyServer(
  function(input, output) {
    
    # output$selected_time <- reactive({input$time})
    
    output$map <- renderPlot({
      CzMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty),
                         data = data)
    })
    
    
      
  }
)