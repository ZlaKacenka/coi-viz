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
CzMap <- qmap("czech republic", zoom = 7, color = "bw")
CzMap + geom_point(aes(x = Longitude, y = Latitude, colour = Zakon, size = Vyse.pokuty),
                        data = data)



