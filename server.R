# server.R
library(shiny)
library(ggmap)
library(plyr)
library(ggplot2)
library(RColorBrewer)
library(gridExtra)

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
data$alfa <- 0.9

#nastaveni barev
#data$color <- data$Zakon
#zak <- unique(data$color)
#col <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7",  "#D95EC0", "#CC32A2",
#         "#959595", "#E99A03", "#56D4E8", "#059E33", "#F0D544", "#0372B9", "#D73E01", "#CC76D7",  "#B95EC6", "#C132C2",
#         "#818181", "#E99A09", "#36D4E4")
#data$color <- mapvalues(data$color, from=zak, to=col)

#nastaveni velikosti
#data$velikost <- data$Vyse.pokuty
#vyse <- unique(data$velikost)
# vyplneni NA
#data$velikost[is.na(data$velikost)] <- 0
#data$velikost <- as.integer(((data$velikost-min(data$velikost))/(max(data$velikost)-min(data$velikost)))*1000)
# vychozi hodnota pro kontroly
#data$velikost[data$velikost == 0] <- 10
data$Vyse.pokuty[is.na(data$Vyse.pokuty)] <- 300

# factor potreba pro jednoznacene určení barvy napric daty
data$Zakon <- factor(data$Zakon)
customColorPalette <- colorRampPalette(brewer.pal(12, 'Paired'))(length(unique(data$Zakon)))
names(customColorPalette) <- levels(data$Zakon)
customColorScale <- scale_color_manual(name="Zákon", values=customColorPalette)

#zaklad mapy CR
cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", size = c(640, 420), scale = 1)
CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)

g_legend<-function(a.gplot){ 
  tmp <- ggplot_gtable(ggplot_build(a.gplot)) 
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box") 
  legend <- tmp$grobs[[leg]] 
  return(legend)} 

shinyServer(
  function(input, output) {
    
    points_data <- reactive({
      datasubset <- subset(data, (as.Date(Datum.kontroly, format="%d. %m. %Y") == as.Date(input$time)) | (as.Date(Datum.kontroly, format="%d. %m. %Y") <= as.Date(input$time) & as.Date(Datum.kontroly, format="%d. %m. %Y") >= as.Date(input$time)-3) & Zakon != "kontrola")
      datasubset$alfa <- as.double(0.9 - ((as.Date(input$time) - as.Date(datasubset$Datum.kontroly, format="%d. %m. %Y"))*0.2))
      return(datasubset)
    })
    
   
    output$map <- renderPlot({
      plot <- CZMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty, alpha = alfa), data = points_data())
      plot <- plot + theme(legend.position = "none") + customColorScale + scale_size_area(name="Výše pokuty", trans="sqrt", limits=range(data$Vyse.pokuty), max_size=20)
      return(plot)
    })
    
    output$legend_fine <- renderPlot({
      plot <- ggplot(data) + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty, alpha = alfa), data = data)
      plot <- plot + customColorScale + scale_size_area(name="Výše pokuty", limits=range(data$Vyse.pokuty), max_size=40)
      return(plot(legend[5]))
    })
    
    output$legend_law <- renderPlot({
      plot <- ggplot(data) + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty, alpha = alfa), data = data)
      plot <- plot + customColorScale + scale_size_area(name="Výše pokuty", limits=range(data$Vyse.pokuty), max_size=40)
      return(plot(legend[7]))
    })
    
    
      
  }
)