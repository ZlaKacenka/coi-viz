# server.R
library(shiny)
library(ggmap)
library(plyr)
library(ggplot2)

#Nacteni dat
kontroly <- read.csv("data/kontroly.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
kontroly$Id.kontroly <- as.character(kontroly$Id.kontroly)

sankce <- read.csv("data/sankce.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
sankce$ID.kontroly <- as.character(sankce$ID.kontroly)

data <- merge(kontroly, sankce, by.x="Id.kontroly", by.y="ID.kontroly", all.x = TRUE)
#data[is.na(data$Vyse.pokuty),]$Vyse.pokuty <- 100
data$Zakon <- as.character(data$Zakon)
data$Zakon[is.na(data$Zakon)] <- "kontrola"

souradnice <- read.csv("data/souradnice.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
souradnice <- souradnice[c(2,8,9)]
names(souradnice)[1] <- "NUTS5"

data <-merge(data, souradnice, by.x="NUTS.5", by.y="NUTS5")

#zakladni nastaveni alfy
data$alfa <- 100

#nastaveni barev
data$color <- data$Zakon
zak <- unique(data$color)
col <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7",  "#D95EC0", "#CC32A2",
         "#959595", "#E99A03", "#56D4E8", "#059E33", "#F0D544", "#0372B9", "#D73E01", "#CC76D7",  "#B95EC6", "#C132C2",
         "#818181", "#E99A09", "#36D4E4")
data$color <- mapvalues(data$color, from=zak, to=col)

#nastaveni velikosti
data$velikost <- data$Vyse.pokuty
vyse <- unique(data$velikost)
data$velikost[is.na(data$velikost)] <- 0
data$velikost <- as.integer(((data$velikost-min(data$velikost))/(max(data$velikost)-min(data$velikost)))*1000)



#zaklad mapy CR
cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", size = c(640, 420), scale = 1)
CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)

shinyServer(
  function(input, output) {
    
    #output$selected_time <- reactive({input$time})
    points_data <- reactive({
      data$alfa <- as.integer(100 - ((as.Date(input$time) - as.Date(data$Datum.kontroly, format="%d. %m. %Y"))*20))
      subset(data, as.Date(Datum.kontroly, format="%d. %m. %Y") <= as.Date(input$time) & as.Date(Datum.kontroly, format="%d. %m. %Y") >= as.Date(input$time)-3)
    })
    
    
    output$map <- renderPlot({
      CZMap + geom_point(aes(x = Longitude, y = Latitude, colour = color, size = velikost, alpha = alfa),
                         data = points_data()) + theme(legend.position = "none")
    })
    
    
      
  }
)