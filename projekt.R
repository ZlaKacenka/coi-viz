library(ggmap)

#Nacteni dat
kontroly <- read.csv("data/kontroly.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
kontroly$Id.kontroly <- as.character(kontroly$Id.kontroly)

sankce <- read.csv("data/sankce.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
sankce$ID.kontroly <- as.character(sankce$ID.kontroly)

data <- merge(kontroly, sankce, by.x="Id.kontroly", by.y="ID.kontroly")

souradnice <- read.csv("data/souradnice.csv", sep=",", header = TRUE, fileEncoding = "UTF-8")
souradnice <- souradnice[c(2,8,9)]

data <-merge(data, souradnice, by.x="NUTS.5", by.y="Kód.obce")

#vykresleni mapy CR se vsemi pokutami
theme_set(theme_bw(16))
CzMap <- qmap("czech republic", zoom = 7, color = "bw", legend="none")
CzMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty),
                        data = data)

cz_lok <- get_googlemap("czech republic", zoom = 7, color = "bw", size = c(600, 300))
CZMap <- ggmap(cz_lok, legend="none", extent = "device", maprange = TRUE)
CZMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty),
                   data = data) + theme(legend.position = "none")

ggmap(
  get_googlemap(
    center=c(-3.17486, 55.92284), #Long/lat of centre, or "Edinburgh"
    zoom=14, 
    maptype='satellite', #also hybrid/terrain/roadmap
    scale = 2), #resolution scaling, 1 (low) or 2 (high)
  size = c(200, 100), #size of the image to grab
  extent='device', #can also be "normal" etc
  darken = 0) #you can dim the map when plotting on top

install.packages("leaflet")
library(leaflet)

m <- leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=15.25, lat=49.59, popup="The birthplace of R")

m %>% addCircles(data = data, lat = ~ Latitude, lng = ~ Longitude, radius = ~Vyse.pokuty/100, color = ~Zakon)
m  # Print the map
