# server.R
library(shiny)
library(ggmap)
library(plyr)
library(ggplot2)
library(RColorBrewer)
library(data.table)
library(Cairo) # lepsi vykreslovani ggplotu na Linuxu

#nacteni dat
kontroly <- read.csv("data/kontroly.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
kontroly$Id.kontroly <- as.character(kontroly$Id.kontroly)

sankce <- read.csv("data/sankce.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
sankce$ID.kontroly <- as.character(sankce$ID.kontroly)

data <- merge(kontroly, sankce, by.x="Id.kontroly", by.y="ID.kontroly", all.x = TRUE)
data$Zakon <- as.character(data$Zakon)
data$Zakon[is.na(data$Zakon)] <- "kontrola"

#data2 <- subset(data, data$IC.subjektu == "28220854")
data$Zakon[data$Id.kontroly=="211503260034701"] <- "zak. 22/1997"

#predspracovani datumu na Date
data$Datum.kontroly <- as.Date(data$Datum.kontroly, format="%d. %m. %Y")

souradnice <- read.csv("data/souradnice.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
souradnice <- souradnice[c(2,8,9)]
names(souradnice)[1] <- "NUTS5"

data <-merge(data, souradnice, by.x="NUTS.5", by.y="NUTS5")

#zakladni nastaveni alfy a velikosti
data$alfa <- 0.9
data$Vyse.pokuty[is.na(data$Vyse.pokuty)] <- 300

#factor potreba pro jednoznacene urcene barvy napric daty
data$Zakon <- factor(data$Zakon)
customColorPalette <- colorRampPalette(brewer.pal(8, 'Set1'))(length(unique(data$Zakon)))
names(customColorPalette) <- levels(data$Zakon)
customColorScale <- scale_color_manual(name="Zakon", values=customColorPalette, guide = FALSE)

#zaklad mapy CR
#cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", maptype = "roadmap", size = c(640, 420), scale = 1)
#CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)

# konverze na data.table pro maximalni rychlost
DT <- as.data.table(data)

shinyServer(
  function(input, output) {
    
    points_data <- function(dateStart, dateEnd) {
      datasubset <- DT[(Datum.kontroly == dateStart) | (Datum.kontroly < dateStart & Datum.kontroly >= dateEnd & Zakon != "kontrola"),]
      datasubset$alfa <- as.double(0.9 - ((dateStart - datasubset$Datum.kontroly)*0.2))
      return(datasubset)
    }
    
    heat_data <- function(dateStart, dateEnd) {
      datasubset <- DT[(Datum.kontroly <= dateStart & Datum.kontroly >= dateEnd & Zakon == "kontrola"),]
      datasubset$alfa <- as.double(0.7 - ((dateStart - datasubset$Datum.kontroly)*0.1))
      return(datasubset)
    }
    
    get_bubble_scatter_plot <- function(startDate) {
      current_points <- points_data(startDate, startDate-3)
      plot <- CZMap() + 
        geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty, alpha = alfa), data = current_points) +
        theme(legend.position = "bottom") + customColorScale + scale_alpha_continuous(guide = FALSE) + 
        scale_size_area(name="Vyse pokuty", limits=range(data$Vyse.pokuty), max_size=20, breaks=c(2000, 15000, 200000, 1000000), trans="sqrt", labels= c("2000", "15 000", "200 000", "1 000 000"))
      return(plot)
    }
    
    get_heatmap <- function(startDate) {
      current_points <- heat_data(startDate, startDate-3)
      plot <- CZMap() + 
        stat_density_2d(
          data=current_points,
          aes(x=Longitude, y=Latitude, fill=..level.., alpha=..level..),
          size=1,
          bins=20,
          geom="polygon") + 
        scale_fill_gradientn(colours=brewer.pal(8, 'Reds'), guide=FALSE) +
        scale_alpha(range=c(0, 0.7), guide=FALSE)
      # z nejakeho duvodu hlasi chybu pro prazdny data.table
      if (nrow(current_points) > 0) {
        plot <- plot + geom_point(aes(x = Longitude, y = Latitude, colour = "red", size = 1, alpha = alfa), data = current_points) +
        scale_size_area(max_size = 1, guide=FALSE) + scale_color_discrete(guide=FALSE)
      }
      return(plot)
    }
    
    CZMap <- reactive({
      if (input$map_type == 'roadmap') {
        cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", maptype = "roadmap", size = c(640, 420), scale = 1)
        CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)
      } else if (input$map_type == 'satellite') {
        cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", maptype = "satellite", size = c(640, 420), scale = 1)
        CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)
      } else if (input$map_type == 'terrain') {
        cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", maptype = "terrain", size = c(640, 420), scale = 1)
        CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)
      } else {
        cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", maptype = "hybrid", size = c(640, 420), scale = 1)
        CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)
      }
       
    })
    
    output$map <- renderPlot({
      startDate <- as.Date(input$time)
      
      if (input$plot_type == 'scatter') {
        get_bubble_scatter_plot(startDate)
      } else {
        get_heatmap(startDate)
      }
      
    }, width="auto", height="auto")
    
    output$legend_law <- renderText({
      plot <- ggplot(data) + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty, alpha = alfa), data = data)
      plot <- plot + customColorScale + scale_size_area(name="Vyse pokuty", limits=range(data$Vyse.pokuty), max_size=40)
      g <- ggplot_build(plot)
      legend_colours <- data.frame(colours = customColorPalette,label = levels(g$plot$data[, g$plot$labels$colour]))
      fun <- function(row){sprintf('<div class="legend_item"><div class="box" style="background: %s"></div><div class="legend_label">%s</div></div>', row$colour, row$label)}
      rows <- split(legend_colours, seq(nrow(legend_colours)))
      paste(lapply(rows, fun), collapse='')
    })
      
  }
)
