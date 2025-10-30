rm(list = ls())

######### Import data #################################################################################################################################################
in_dir<-"/data/Input_data/"

library(dplyr)
library(lubridate)
library(zoo)

# if data come from different files, import them separately and merge them into a single file
#data from 13/10 to 31/10
rojbani_clim <- read.csv(paste(in_dir,"Weather Measuring-data-02-12-2024 11_35_54.csv",sep=""))
rojbani_rain <- read.csv(paste(in_dir,"Pluviométrie journalières-data-02-12-2024 11_32_26.csv",sep=""))
rojbani_water <- read.csv(paste(in_dir,"Plot Water Meter-data-02-12-2024 11_33_35.csv",sep=""))
rojbani_soil <- read.csv(paste(in_dir,"SM_dataframe.csv",sep=""))
#rojbani_soil2 <- read.csv(paste(in_dir,"soil_moisture2.csv",sep=""))



################################################################################################


# weather
rojbani_clim$Time=as.POSIXct(rojbani_clim$Time,format="%d-%m-%Y %H:%M:%S")
rojbani_clim<-rojbani_clim[which(rojbani_clim$Time=="2024-10-21 07:00:00") : which(rojbani_clim$Time=="2024-11-21 07:00:00"),]
# Generate a sequence of hourly timestamps from the first to the last datetime
start_time <- min(rojbani_clim$Time,na.rm = T)
end_time <- max(rojbani_clim$Time,na.rm = T)
hourly_sequence <- data.frame( Time=seq(from = start_time, to = end_time, by = "hour"))
# Interpolate data to hourly intervals using the zoo package
hourly_average_clim<-merge(hourly_sequence,rojbani_clim,by="Time",all.x=TRUE)
hourly_average_clim[,-1]<-lapply(hourly_average_clim[,-1],function(column){
  if(is.numeric(column)){
    na.approx(column,na.rm=FALSE,rule=2) #linear interpolation
  }else{
    column
  }
  
}) 







# rain

rojbani_rain$Time=as.POSIXct(rojbani_rain$Time,format="%d-%m-%Y %H:%M:%S")
rojbani_rain<-rojbani_rain[which(rojbani_rain$Time=="2024-10-21 01:00:00") : which(rojbani_rain$Time=="2024-11-22 01:00:00"),]
# Generate a sequence of hourly timestamps from the first to the last datetime
start_time <- min(rojbani_rain$Time,na.rm = T)
end_time <- max(rojbani_rain$Time,na.rm = T)
hourly_sequence <- data.frame( Time=seq(from = start_time, to = end_time, by = "hour"))
# Interpolate data to hourly intervals using the zoo package
hourly_average_rain<-merge(hourly_sequence,rojbani_rain,by="Time",all.x=TRUE)
hourly_average_rain[is.na(hourly_average_rain)]=0
hourly_average_rain<-hourly_average_rain[which(hourly_average_rain$Time=="2024-10-21 07:00:00") : which(hourly_average_rain$Time=="2024-11-21 07:00:00"),]



# water
rojbani_water$Time=as.POSIXct(rojbani_water$Time,format="%d-%m-%Y %H:%M:%S")
rojbani_water<-rojbani_water[which(rojbani_water$Time=="2024-10-21 07:00:00") : which(rojbani_water$Time=="2024-11-21 07:00:00"),]

# Generate a sequence of hourly timestamps from the first to the last datetime
start_time <- min(rojbani_water$Time,na.rm = T)
end_time <- max(rojbani_water$Time,na.rm = T)
hourly_sequence <- data.frame( Time=seq(from = start_time, to = end_time, by = "hour"))
# Generate a sequence of hourly timestamps from the first to the last datetime

hourly_average_water <- rojbani_water %>%
  mutate(Time = floor_date(Time,"hour")
  ) %>%
  group_by(Time) %>%
  summarize(
    
    Volume=max(Count ,na.rm=TRUE)

  )
# Interpolate data to hourly intervals using the zoo package
hourly_average_water<-merge(hourly_sequence,hourly_average_water,by="Time",all.x=TRUE)
hourly_average_water[is.na(hourly_average_water)]=0
# convert data from cumulative to istantaneous
hourly_average_water$Volume <- c(0,diff(hourly_average_water$Volume))







# soil moisture 


rojbani_soil <- rojbani_soil %>%
  mutate(
    Time = as.POSIXct(paste(Date, hour), format = "%Y-%m-%d %H:%M:%S")
  ) %>%
  select(Time, SM_10cm, SM_20cm, SM_30cm)  # Keep only relevant columns
rojbani_soil<-rojbani_soil[which(rojbani_soil$Time=="2024-10-21 07:00:00") : which(rojbani_soil$Time=="2024-11-21 07:00:00"),]

# Generate a sequence of hourly timestamps from the first to the last datetime
start_time <- min(rojbani_soil$Time,na.rm = T)
end_time <- max(rojbani_soil$Time,na.rm = T)
hourly_sequence <- data.frame( Time=seq(from = start_time, to = end_time, by = "hour"))
# Interpolate data to hourly intervals using the zoo package
hourly_average_soil<-merge(hourly_sequence,rojbani_soil,by="Time",all.x=TRUE)
hourly_average_soil[,-1]<-lapply(hourly_average_soil[,-1],function(column){
  if(is.numeric(column)){
    na.approx(column,na.rm=FALSE,rule=2) #linear interpolation
  }else{
    column
  }
  
}) 








# Merge all data together #########################à

hourly_average_clim <- hourly_average_clim %>%
  mutate(
    date = as.Date(Time),           # Extract only the date
    hour = format(Time, "%H:%M:%S") # Extract only the time (hour)
  ) %>%
  select(Time,date,hour,everything())


hourly_average <- hourly_average_clim[,c(1,2,3,4,6,7,9)] %>%
  merge(hourly_average_rain[,c(1,3)], by = "Time") %>%
  merge(hourly_average_water[,1:2], by = "Time") %>%
  merge(hourly_average_soil[,1:4], by = "Time") #%>%        # IF I INSTEAD I WANT DATA FROM hourly_average_soil2 I have to uncomment it
colnames(hourly_average)=list("Time","date","hour","wind_speed","temperature","humidity","solar_rad","precipitation","water_flow","SM_10cm","SM_20cm","SM_30cm")



hourly_average$hour <- sapply(hourly_average$hour, function(time) {
  hour <- as.numeric(substr(time, 1, 2)) # Extract hour
})




###########################################################################################################################

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
irr_given_fut<-future_data$water_flow
write.csv(irr_given,paste(irr_dir,"water_flow_Tunisia.csv",sep=""),row.names = FALSE)
write.csv(irr_given_fut,paste(irr_dir,"water_flow_Tunisia_fut.csv",sep=""),row.names = FALSE)

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

