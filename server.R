# server.R
library(shiny)
library(ggmap)
library(plyr)
library(ggplot2)
library(RColorBrewer)
library(gridExtra)

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

souradnice <- read.csv("data/souradnice.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
souradnice <- souradnice[c(2,8,9)]
names(souradnice)[1] <- "NUTS5"

data <-merge(data, souradnice, by.x="NUTS.5", by.y="NUTS5")

#zakladni nastaveni alfy a velikosti
data$alfa <- 0.9
data$Vyse.pokuty[is.na(data$Vyse.pokuty)] <- 300

#factor potreba pro jednoznacene urcene barvy napric daty
data$Zakon <- factor(data$Zakon)
customColorPalette <- colorRampPalette(brewer.pal(12, 'Paired'))(length(unique(data$Zakon)))
names(customColorPalette) <- levels(data$Zakon)
customColorScale <- scale_color_manual(name="Zakon", values=customColorPalette, guide = FALSE)

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
      plot <- plot + theme(legend.position = "bottom") + customColorScale + scale_alpha_continuous(guide = FALSE) +  scale_size_area(name="Vyse pokuty", limits=range(data$Vyse.pokuty), max_size=20, breaks=c(2000, 15000, 200000, 1000000), trans="sqrt", labels= c("2000", "15 000", "200 000", "1 000 000"))
      return(plot)
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