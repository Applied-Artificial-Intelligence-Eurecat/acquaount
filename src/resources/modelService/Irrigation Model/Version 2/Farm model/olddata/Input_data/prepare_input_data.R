rm(list = ls())

######### Import data #################################################################################################################################################
in_dir<-"C:/Users/Andrea/OneDrive - Università degli Studi di Sassari/Desktop/Dottorato_Sassari/modello_ACQUAOUNT/SWB_model_I_version/Input_data/"

library(dplyr)
library(lubridate)


# if data come from different files, import them separately and merge them into a single file
#data from 13/10 to 31/10
rojbani_clim <- read.csv(paste(in_dir, "weather_station.csv", sep=""))
rojbani_rain <- read.csv(paste(in_dir, "precipitation.csv", sep=""))
rojbani_water <- read.csv(paste(in_dir, "water_flow.csv", sep=""))
rojbani_soil1 <- read.csv(paste(in_dir, "soil_moisture1.csv", sep=""))
rojbani_soil2 <- read.csv(paste(in_dir, "soil_moisture2.csv", sep=""))

#Also import the previous time step (from 05/10 to 13/10)
rojbani_clim1 <- read.csv(paste(in_dir, "weather_station(1).csv", sep=""))
rojbani_rain1 <- read.csv(paste(in_dir, "precipitation(1).csv", sep=""))
rojbani_water1 <- read.csv(paste(in_dir, "water_flow(1).csv", sep=""))
rojbani_soil11 <- read.csv(paste(in_dir, "soil_moisture1(1).csv", sep=""))
rojbani_soil21 <- read.csv(paste(in_dir, "soil_moisture2(1).csv", sep=""))

rojbani_clim1<-rojbani_clim1[which(rojbani_clim1$Timestamp=="2024-10-08T07:00:00"):which(rojbani_clim1$Timestamp=="2024-10-13T07:00:00"),]
rojbani_rain1<-rojbani_rain1[which(rojbani_rain1$Timestamp=="2024-10-08T07:00:00"):which(rojbani_rain1$Timestamp=="2024-10-13T07:00:00"),]
rojbani_water1<-rojbani_water1[which(rojbani_water1$Timestamp=="2024-10-08T07:00:01"):which(rojbani_water1$Timestamp=="2024-10-13T07:00:01"),]
rojbani_soil11<-rojbani_soil11[which(rojbani_soil11$Timestamp=="2024-10-08T07:00:00"):which(rojbani_soil11$Timestamp=="2024-10-13T07:00:00"),]
rojbani_soil21<-rojbani_soil21[which(rojbani_soil21$Timestamp=="2024-10-08T07:00:00"):which(rojbani_soil21$Timestamp=="2024-10-13T07:00:00"),]

#merge all data in one file
rojbani_clim<-rbind(rojbani_clim1,rojbani_clim)
rojbani_rain<-rbind(rojbani_rain1,rojbani_rain)
rojbani_water<-rbind(rojbani_water1,rojbani_water)
rojbani_soil1<-rbind(rojbani_soil11,rojbani_soil1)
rojbani_soil2<-rbind(rojbani_soil21,rojbani_soil2)

################################################################################################


# weather
rojbani_clim$Timestamp=as.POSIXct(rojbani_clim$Timestamp,format="%Y-%m-%dT%H:%M:%S")
date=as.POSIXct(rojbani_clim$Timestamp,format="%Y-%m-%dT%H:%M:%S")

hourly_average_clim <- rojbani_clim %>%
  mutate(TIME = floor_date(Timestamp,"hour")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    temperature=mean(Noureddine_Rojbani_TS01_temperature, na.rm= TRUE),
    humidity=mean(Noureddine_Rojbani_TS01_air_humidity, na.rm= TRUE),
    wind_speed=mean(Noureddine_Rojbani_TS01_wind_speed,na.rm = TRUE),
    solar_rad=mean(Noureddine_Rojbani_TS01_solar_radiation, na.rm = TRUE)

  )


hourly_average_clim <- hourly_average_clim %>%
  mutate(
    date=format(TIME, "%Y-%m-%d"),
    hour=hour(ymd_hms(TIME)),
    TIME=as.numeric(TIME)
  )

# rain
rojbani_rain$Timestamp=as.POSIXct(rojbani_rain$Timestamp,format="%Y-%m-%dT%H:%M:%S")
date=as.POSIXct(rojbani_rain$Timestamp,format="%Y-%m-%dT%H:%M:%S")
rojbani_rain$istantaneous=c(0,diff(rojbani_rain$Noureddine_Rojbani_TS02_cumulative_rainfall))

hourly_average_rain <- rojbani_rain %>%
  mutate(TIME = floor_date(Timestamp,"hour")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    precipitation=sum(istantaneous, na.rm= TRUE),
    #precipitation=sum(Noureddine_Rojbani_TS02_cumulative_rainfall, na.rm= TRUE), # cumulative rainfall
    #precipitation=sum(Noureddine_Rojbani_TS02_rain_intensity, na.rm= TRUE),     # irain intensity

    
  )


hourly_average_rain <- hourly_average_rain %>%
  mutate(
    date=format(TIME, "%Y-%m-%d"),
    hour=hour(ymd_hms(TIME)),
    TIME=as.numeric(TIME)
  )

# water
rojbani_water$Timestamp=as.POSIXct(rojbani_water$Timestamp,format="%Y-%m-%dT%H:%M:%S")
date=as.POSIXct(rojbani_water$Timestamp,format="%Y-%m-%dT%H:%M:%S")

rojbani_water$istantaneous=c(0,diff(rojbani_water$Noureddine_Rojbani_TS032_water_flow))
hourly_average_water <- rojbani_water %>%
  mutate(TIME = floor_date(Timestamp,"hour")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    water_flow=sum(istantaneous, na.rm= TRUE),
    
    
  )


hourly_average_water <- hourly_average_water %>%
  mutate(
    date=format(TIME, "%Y-%m-%d"),
    hour=hour(ymd_hms(TIME)),
    TIME=as.numeric(TIME)
  )


# soil moisture 1
rojbani_soil1$Timestamp=as.POSIXct(rojbani_soil1$Timestamp,format="%Y-%m-%dT%H:%M:%S")
date=as.POSIXct(rojbani_soil1$Timestamp,format="%Y-%m-%dT%H:%M:%S")


hourly_average_soil1 <- rojbani_soil1 %>%
  mutate(TIME = floor_date(Timestamp,"hour")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    SM_10cm=mean(Noureddine_Rojbani_TS06_soil_moisture_10cm,na.rm=TRUE),
    SM_20cm=mean(Noureddine_Rojbani_TS07_soil_moisture_20cm,na.rm=TRUE),
    SM_30cm=mean(Noureddine_Rojbani_TS08_soil_moisture_30cm,na.rm=TRUE)
    
    
  )


hourly_average_soil1 <- hourly_average_soil1 %>%
  mutate(
    
    date=format(TIME, "%Y-%m-%d"),
    hour=hour(ymd_hms(TIME)),
    TIME=as.numeric(TIME)
  )


# soil moisture 2
rojbani_soil2$Timestamp=as.POSIXct(rojbani_soil2$Timestamp,format="%Y-%m-%dT%H:%M:%S")
date=as.POSIXct(rojbani_soil2$Timestamp,format="%Y-%m-%dT%H:%M:%S")


hourly_average_soil2 <- rojbani_soil2 %>%
  mutate(TIME = floor_date(Timestamp,"hour")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    SM_10cm=mean(Noureddine_Rojbani_TS03_soil_moisture_10cm,na.rm=TRUE),
    SM_20cm=mean(Noureddine_Rojbani_TS04_soil_moisture_20cm,na.rm=TRUE),
    SM_30cm=mean(Noureddine_Rojbani_TS05_soil_moisture_30cm,na.rm=TRUE)
    
    
  )


hourly_average_soil2 <- hourly_average_soil2 %>%
  mutate(
    
    date=format(TIME, "%Y-%m-%d"),
    hour=hour(ymd_hms(TIME)),
    TIME=as.numeric(TIME)
  )



# Merge all data together #########################à
hourly_average_clim <- hourly_average_clim %>%
  select(TIME,date,hour,everything())



hourly_average <- hourly_average_clim %>%
  merge(hourly_average_rain[,1:2], by = "TIME") %>%
  merge(hourly_average_water[,1:2], by = "TIME") %>%
  merge(hourly_average_soil1[,1:4], by = "TIME") #%>%        # IF I INSTEAD I WANT DATA FROM hourly_average_soil2 I have to uncomment it
  #merge(hourly_average_soil2[,1:4], by = "TIME") 








###########################################################################################################################
# If data are already grouped start from here


# rojbani <- read.csv(paste(in_dir,"rojbani_platform2.csv",sep=""))
# 
# 
# 
# 
# 
# 
# 
# rojbani$Timestamp=as.POSIXct(rojbani$Timestamp,format="%Y-%m-%dT%H:%M:%S")
# date=as.POSIXct(rojbani$Timestamp,format="%Y-%m-%dT%H:%M:%S")
# 
# hourly_average<-rojbani %>%
#   mutate(TIME = floor_date(Timestamp,"hour")
#          ) %>%
#   group_by(TIME) %>%
#   summarize(
#     
#     temperature=mean(Noureddine_Rojbani_TS01_temperature, na.rm= TRUE),
#     precipitation=sum(Noureddine_Rojbani_TS02_rain_intensity, na.rm= TRUE),
#     humidity=mean(Noureddine_Rojbani_TS01_air_humidity, na.rm= TRUE),
#     wind_speed=mean(Noureddine_Rojbani_TS01_wind_speed,na.rm = TRUE),
#     solar_rad=mean(Noureddine_Rojbani_TS01_solar_radiation, na.rm = TRUE),
#     water_flow=sum(Noureddine_Rojbani_TS032_water_flow, na.rm = TRUE),
#     SM_10cm=mean(Noureddine_Rojbani_TS06_soil_moisture_10cm,na.rm=TRUE),
#     SM_20cm=mean(Noureddine_Rojbani_TS07_soil_moisture_20cm,na.rm=TRUE),
#     SM_30cm=mean(Noureddine_Rojbani_TS08_soil_moisture_30cm,na.rm=TRUE)
#     )
# 
# 
# hourly_average <- hourly_average %>%
#   mutate(
#     date=as.Date(TIME),
#     hour=hour(ymd_hms(TIME)),
#   )
# 
# 
# hourly_average <- hourly_average %>%
#   select(TIME,date,hour,everything())
# 
# 
# 
# 
# 
# 




##############################################################################################
####################     PERFORM THE PREPARATION OF PAST AND FUTURE DATA ####################



past_data<-hourly_average[1:168,]
future_data<-hourly_average[169:337,]

#climate data
cl_dir=paste(in_dir,"climate_data/",sep="")
write.table(past_data$date,paste(cl_dir,"date_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$hour,paste(cl_dir,"hour_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$temperature,paste(cl_dir,"temperature_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$precipitation,paste(cl_dir,"precipitation_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$humidity,paste(cl_dir,"humidity_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$wind_speed,paste(cl_dir,"wind_speed_Tunisia.csv",sep=""),row.names = FALSE)
write.table(past_data$solar_rad,paste(cl_dir,"solar_rad_Tunisia.csv",sep=""),row.names = FALSE)

#future meteo forecast
write.table(future_data$date,paste(cl_dir,"date_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$hour,paste(cl_dir,"hour_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$temperature,paste(cl_dir,"temperature_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$precipitation,paste(cl_dir,"precipitation_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$humidity,paste(cl_dir,"humidity_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$wind_speed,paste(cl_dir,"wind_speed_Tunisia_fut.csv",sep=""),row.names = FALSE)
write.table(future_data$solar_rad,paste(cl_dir,"solar_rad_Tunisia_fut.csv",sep=""),row.names = FALSE)

#irrigation data
irr_dir=paste(in_dir,"irrigation_data/",sep="")
irr_given<-past_data$water_flow
write.csv(irr_given,paste(irr_dir,"water_flow_Tunisia.csv",sep=""),row.names = FALSE)

#soil moisture data
soil_dir=paste(in_dir,"soil_moisture_data/",sep="")
soil_moisture=cbind(SM_10cm = past_data$SM_10cm,
                    SM_20cm=past_data$SM_20cm,
                    SM_30cm=past_data$SM_30cm)
write.table(soil_moisture,paste(soil_dir,"SM_Tunisia.csv",sep=""),row.names = FALSE)

soil_moisture_fut=cbind(SM_10cm = future_data$SM_10cm,
                    SM_20cm=future_data$SM_20cm,
                    SM_30cm=future_data$SM_30cm)
write.table(soil_moisture_fut,paste(soil_dir,"SM_Tunisia_fut.csv",sep=""),row.names = FALSE)

