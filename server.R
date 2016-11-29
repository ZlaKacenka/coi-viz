# server.R
library(shiny)
library(ggmap)

library(ggplot2)

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
cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", size = c(640, 420), scale = 2)
CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)

shinyServer(
  function(input, output) {
    
    #output$selected_time <- reactive({input$time})
    points_data <- reactive({
      subset(data, as.Date(Datum.kontroly, format="%d. %m. %Y") == as.Date(input$time))
    })
    
    
    output$map <- renderPlot({
      CZMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty),
                         data = points_data()) + theme(legend.position = "none")
    })
    
    
      
  }
)