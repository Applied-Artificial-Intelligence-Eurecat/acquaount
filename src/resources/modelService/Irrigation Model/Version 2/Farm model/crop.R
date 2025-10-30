##############################################   DATI DI INPUT  ###########################################################################################################
rm(list = ls())

library(tictoc)
library(readxl)
library(units)
library(lubridate)
library(dplyr)
library(randomForest)
library(outliers)

#tic()


wd="/"
in_dir=paste(wd,"data/Input_data/",sep="")
out_dir=paste(wd,"data/Output_data/",sep="")

source(paste(wd,"functions.R",sep=""))


########################################## CROP ##########################################################

#import crop table -------------------------------------------

crop_table=read.csv(paste(in_dir,"crop_data/crop_table.csv",sep="")) 

#Select a crop according to one of the following:
# wheat
# maize
# rice
# barley
# sorghum
# soybean
# sunflower
# onion
# lettuce
# carrot
# watermelon
# potato
# tomato
# citrus
# almond
# date_palm
# peach
# wine_grapes
# olives
# cotton
# alfalfa
# pastures
# perennial
# temporary

crop_list=list("potato") #select crop

season_start="15/03/2024" #Planting/budbreak date
season_end="31/12/2024" #harvesting date



# Sesto d'impianto
plant_spacing=0.4 #distance between each plant (m)
line_spacing=0.8 #distance between lines (m)
Area_crop=2500#cultivated area of the field in m2
n_plants=Area_crop/(plant_spacing*line_spacing) #number of plants





############################################### SOIL DATA #################################################

P_sand=60 #percentage of sand (%)
P_clay=30 #percentage of clay
P_silt=10 #percentage of silt

#P_om=6 #percentage of organic matter

soil_AWC=30 #total available water content at saturation (soil porosity)
Ks=2.78 #cm/h   #Saturdated hydraulic conductivity
Pb=1.06 #g/cm3  #Bulk density


#derive coefficients of field capacity (-33 kPa) and wilting point (-1500 kPa) from Rawls et al. (1982) 
#theta_fc=0.2576 - 0.0020*P_sand/100 + 0.0336*P_clay/100 + 0.0299*P_om/100 #field capacity (the water content that can be host by the soil without deep percolation)
#theta_wp=0.026 + 0.005*P_clay/100 + 0.0158*P_om/100 #wilting point
theta_fc=28 #%
theta_wp=10 #%

theta_fc=theta_fc/100
theta_wp=theta_wp/100
soil_AWC=soil_AWC/100 


crop_AWC= theta_fc - theta_wp #available water capacity for the crop

if(theta_fc>soil_AWC){
  soil_AWC=theta_fc
}else{
  soil_AWC=soil_AWC
}






############################################ CLIMATE DATA ##################################################

#Define climatic zone in which I will insert appropriate values of Kc and duration of the growing period

#In this case, we imagine dealing with 2 climatic zones: 
# 1: Mediterranean
# 2: Arid

climate_zone=2 #in this case we are focusing on Tunisia
lat=33 
elev=15




# Import SENSOR data--------------------------------------

temp_past <- read.csv(paste(in_dir,"climate_data/temperature.csv",sep=""))
precipitation_past <- read.csv(paste(in_dir,"climate_data/precipitation.csv",sep=""))
sw_rad_past <- read.csv(paste(in_dir,"climate_data/solar_rad.csv",sep=""))
RH_past <- read.csv(paste(in_dir,"climate_data/humidity.csv",sep=""))
wind_past <- read.csv(paste(in_dir,"climate_data/wind_speed.csv",sep=""))

temp_past<-as.numeric(unlist(temp_past))
sw_rad_past<-as.numeric(unlist(sw_rad_past))
wind_past<-as.numeric(unlist(wind_past))
RH_past<-as.numeric(unlist(RH_past))
precipitation_past<-as.numeric(unlist(precipitation_past))

date_past <-read.csv(paste(in_dir,"climate_data/date.csv",sep=""))
date_past <- ymd(as.character(unlist(date_past)))
hh_past <- read.csv(paste(in_dir,"climate_data/hour.csv",sep=""))
hh_past<-as.numeric(unlist(hh_past))

duration_past <- length(temp_past)

# Import WEATHER FORECAST data -----------------------------

temp_fut <- read.csv(paste(in_dir,"climate_data/temperature_fut.csv",sep=""))
precipitation_fut <- read.csv(paste(in_dir,"climate_data/precipitation_fut.csv",sep=""))
sw_rad_fut <- read.csv(paste(in_dir,"climate_data/solar_rad_fut.csv",sep=""))
RH_fut <- read.csv(paste(in_dir,"climate_data/humidity_fut.csv",sep=""))
wind_fut <- read.csv(paste(in_dir,"climate_data/wind_speed_fut.csv",sep=""))

temp_fut<-as.numeric(unlist(temp_fut))
sw_rad_fut<-as.numeric(unlist(sw_rad_fut))
wind_fut<-as.numeric(unlist(wind_fut))
RH_fut<-as.numeric(unlist(RH_fut))
precipitation_fut<-as.numeric(unlist(precipitation_fut))

date_fut <-read.csv(paste(in_dir,"climate_data/date_fut.csv",sep=""))
date_fut <- ymd(as.character(unlist(date_fut)))
hh_fut <- read.csv(paste(in_dir,"climate_data/hour_fut.csv",sep=""))
hh_fut<-as.numeric(unlist(hh_fut))

duration_fut<-length(temp_fut)



########################################## IRRIGATION ##########################################################


#First of all, select irrigation method among the following
# sprinkler
# drip
# subterranean

irr_method="drip" #irrigation method
irrigation_scenario=list("Suggested","Limit") # Define irrigation scenarios for future irrigation profiles

if(irr_method=="sprinkler"){
  n_emitter=10
  s_rate=100 #sprikler flowrate (l/h)
  
  Flow_rate=n_emitter*s_rate/1000 #flowrate of the system #m^3/h
  
  
} else if(irr_method=="drip"){
  
  n_drip_per_line=1
  d_spacing=0.4 #dripper spacing (m)
  d_rate=2.6 #dripper flowrate (l/h)
  w_length=2000 #wetted length (m)
  n_emitter=w_length/d_spacing #number of emitter
  
  Flow_rate=n_emitter*d_rate/1000 #flowrate of the system #m^3/h
  
    
    
} else if (irr_method=="subterranean"){
  
  n_drip_per_line=2
  d_depth=0.2 #depth of drippers (m)
  d_spacing=0.6 #dripper spacing (m)
  d_rate=2.6 #dripper flowrate (l/h)
  w_length=2000 #wetted length (m)
  n_emitter=w_length/d_spacing #number of emitter
  
  Flow_rate=n_emitter*d_rate/1000 #flowrate of the system #m^3/h
  
}



# Historical irrigation given to the crop and recorded by sensors (in m3)
irr_given_vol_original=read.csv(paste(in_dir,"irrigation_data/Water_Flow.csv",sep=""))
irr_given_vol_original=as.numeric(unlist(irr_given_vol_original))

            


############################################ MOISTURE DATA ##################################################

#moisture_sensor <- read.table(paste(in_dir,"soil_moisture_data/soil_moisture.csv",sep=""),sep=";"RUE) 
moisture_sensor_raw <- read.table(paste(in_dir,"soil_moisture_data/SM.csv",sep=""),sep="",header = TRUE)
sensor_spacing=0.10 # spacing between each point of measurement (m)
max_previous_run <- as.numeric(unlist(read.table(paste(in_dir,"soil_moisture_data/SM_max_previous_run.csv",sep=""),sep="",header = FALSE)))


#Identify the maximum value of Soil Moisture ----------
soil_AWC_sensor=max(c(max(moisture_sensor_raw),max_previous_run)) #total available water content at saturation BUT RECORDED BY SENSOR!!!
#soil_AWC_sensor=soil_AWC_sensor/100

#This value is the maximum between the value recorded in the previous run and the max of moisture_sensor_raw
#soil_AWC_sensor=soil_AWC_sensor/100

sensor_levels=ncol(moisture_sensor_raw) #number of measuring levels of the sensor
sensor_level=rep(sensor_spacing,sensor_levels) #these are the m between each level of recording of the sensor (eg., Soil_1=10-30 cm, Soil_2=30-50, ...)
level=cumsum(sensor_level) #depth at which each sensor is located


# #import the data of initial mean and low level soil moisture to initialize the loop
# initial_SM_array=read.csv(paste(in_dir,"soil_moisture_data/initial_SM_array.csv",sep=""), header = F)
# initial_SM_array=as.numeric(initial_SM_array$V1)
# initial_SM_mean=initial_SM_array[1]
# initial_SM_LOW=initial_SM_array[2]
# moisture_mean_min1=initial_SM_array[3]
# moisture_LOW_min1=initial_SM_array[4]


###### Calibration of soil moisture data -------------------------------------------------------------------------
#Find the parameters of the linear equation
m <- (soil_AWC - theta_wp) / (soil_AWC_sensor - theta_wp*100) #Angular coefficient
q <- theta_wp - m * (theta_wp*100) #known term

moisture_sensor <- m * moisture_sensor_raw + q  #Linear equation y=m*x+q
moisture_sensor[moisture_sensor>soil_AWC]=soil_AWC
######


##### Predict future forecast of soil moisture according to past data and weather data -------------------------


#combine data----
# PAST
past_data=cbind(moisture_sensor,data.frame(date=date_past,
                     hh=hh_past,
                     temp=temp_past,
                     prec=precipitation_past,
                     SW=sw_rad_past,
                     RH=RH_past,
                     wind=wind_past,
                     irrigation=irr_given_vol_original
                     ))
#Import the data of future moisture (it's just to check if the model is performing well the prediction)
moisture_sensor_fut <- read.table(paste(in_dir,"soil_moisture_data/SM_fut.csv",sep=""),header = TRUE)
#moisture_sensor_fut <- as.numeric(unlist(moisture_sensor_fut))
moisture_sensor_fut<- m * moisture_sensor_fut + q  

# FUTURE ----
future_data=cbind(moisture_sensor_fut,data.frame(date=date_fut,
                                            hh=hh_fut,
                                            temp=temp_fut,
                                            prec=precipitation_fut,
                                            SW=sw_rad_fut,
                                            RH=RH_fut,
                                            wind=wind_fut,
                                            irrigation=rep(0,length(duration_fut))
                    ))
dataset=rbind(past_data,future_data) #combine dataframe of past and future



# Create "model dataframe", a dataframe that contains past observations of variables recorded by sensors,
# plus the future weather forecast and an estimation of future soil moisture obtained with RANDOM FOREST ALGHORITM
dataset_model=dataset
dataset_model[(duration_past+1):nrow(dataset),1:sensor_levels]=NA

# #### RANDOM FOREST FORECAST ####
# dataset_model=forecast_SM(duration_past,sensor_levels,moisture_sensor_raw,duration_fut)
# ###############################
# 
# #Accuracy of estimation --------------------------------------------------------
# Accuracy_of_est=data.frame(SM_10=c(NA,NA),
#                            SM_20=c(NA,NA),
#                            SM_30=c(NA,NA),
#                            row.names = list("RMSE","nRMSE"))
# 
# for(ii in 1:ncol(moisture_sensor_raw)){
#   Accuracy_of_est[1,ii]=sqrt(mean(dataset[duration_past:nrow(dataset),ii] - dataset_model[duration_past:nrow(dataset),ii])^2) 
#   Accuracy_of_est[2,ii]=Accuracy_of_est[1,ii] / (max(dataset[duration_past:nrow(dataset),ii])-min(dataset[duration_past:nrow(dataset),ii]))
#   
# }
# 
# par(mfrow=c(3,1), mar = c(1, 4, 1, 1))
# plot(dataset$SM_10cm,type = "l",col="blue", lty=1 , lwd=2, xlab= "time", ylab = "SM 10 cm")
# lines(dataset_model$SM_10cm, col="red",lty=2, lwd=2)
# legend("topright",legend = c("real","forecast"),col = c("blue","red"),lty=c(1,2), cex= 0.8, bty = "n")
# plot(dataset$SM_20cm,type = "l",col="blue", lty=1 , lwd=2, xlab= "time", ylab = "SM 20 cm")
# lines(dataset_model$SM_20cm, col="red",lty=2, lwd=2)
# legend("topright",legend = c("real","forecast"),col = c("blue","red"),lty=c(1,2),cex= 0.8, bty = "n")
# plot(dataset$SM_30cm,type = "l",col="blue", lty=1 , lwd=2, xlab= "time", ylab = "SM 30 cm")
# lines(dataset_model$SM_30cm, col="red",lty=2, lwd=2)
# legend("topright",legend = c("real","forecast"),col = c("blue","red"),lty=c(1,2),cex= 0.8, bty = "n")
# #par(mfrow=c(1,1))
# #----------------------------------------------------------------------------------






############################### PREPARE THE DATA ############################################################################

#split the dataset into single variables ===========
date<-dataset_model$date
hh=dataset_model$hh
temp=dataset_model$temp
precipitation=dataset_model$prec
RH=dataset_model$RH
wind=dataset_model$wind
sw_rad=dataset_model$SW
moisture_sensor=dataset_model[,1:3]
irr_given_vol=dataset_model$irrigation

#moisture_sensor=moisture_sensor*0.8

#convert dates into DOY =====================================

season_start=as.Date(season_start,format = "%d/%m/%Y") #convert date in date format
season_end=as.Date(season_end,format = "%d/%m/%Y")
season_start=yday(season_start) #convert into DOY (day of the year)
season_end=yday(season_end)























################################################ RUN MODEL ##################################################################




# CALCULATION ET0 ########################################################################

Evapotranspiration <- FAO_ET0_function(lat,temp,sw_rad,wind,RH,elev,date,hh,"°C","W/m2","m/s","%","m")
ET0=Evapotranspiration$ET0
OWET=Evapotranspiration$OWET









# DEFINE THE OUTPUT FILES ##############################################################

Irr_req=as.numeric(array(0,dim=length(ET0)))
ETa_rf=as.numeric(array(0,dim=length(ET0)))
ETa_full=as.numeric(array(0,dim=length(ET0)))
ks=as.numeric(array(0,dim=length(ET0)))
kc_corr=as.numeric(array(0,dim=length(ET0)))
Irr_vol=as.numeric(array(0,dim=length(ET0)))
Irr_vol_def=as.numeric(array(0,dim=length(ET0)))
moisture_mean_array=as.numeric(array(0,dim=length(ET0)))
Irr_vol_percolated=as.numeric(array(0,dim=length(ET0)))

Irr_to_apply=data.frame(matrix(0,nrow = length(ET0), ncol = length(irrigation_scenario)))
colnames(Irr_to_apply)=list("Suggested","Limit")

Irr_volume=as.numeric(array(0,dim=length(ET0)))
Irr_hours=as.numeric(array(0,dim=length(ET0)))



# Convert the date into specific formats
j <- as.numeric(format(date, "%j")) #Julian day
year=as.numeric(format(date, "%Y")) #year
year_list=unique(year) #list of years of the simulation

l<-c(1:length(date)) #posizioni delle righe nel dataframe

#define the last day of each year, to understand if it's 365 or 366 days
end<-array(0,length(year_list))
end[length(year_list)]<-j[length(j)]
for (p in 1:(length(l)-1)){
  if(j[p]>j[p+1]){
    end[round(l[p]/365)]<-j[p]
  }
}


 

# Create summary table with main variables
variables_st=list("Date","Hour","precipitation","P_eff","ponding","DP","moisture_LOW","moisture_mean","ET0","Deficit meteo","AWC","theta_fc","TAW","RAW","kc","kc_corr","ETc","ks","ETa","Irr_req","Deficit final","Irr_vol","Irr_vol_percolated","moisture_new")
summary_table=data.frame(matrix(NA,nrow = length(ET0),ncol = length(variables_st)))
colnames(summary_table)=variables_st  

  
# SOIL WATER BALANCE ##############################################################
  
  
  
  
  for (crop in crop_list){
    

    
    i=which(crop==crop_list)
    r_crop=which(crop_table$Crop==crop & crop_table$Clim==climate_zone) #Define the r_crop where to take the data
    type=crop_table[r_crop,16]
    
    # Length of Growing Periods, kc values and rooting depth

    
    if (season_start<season_end){
      
      LGP=season_end-season_start+1
    } else if (season_start>season_end){
      
      LGP=season_end-season_start+366
    }
    
    
    #%definition of kc
    kc_in=crop_table[r_crop,4]
    kc_mid=crop_table[r_crop,5]
    kc_end=crop_table[r_crop,6]
    
    #Definition of period
    L1=round(LGP*crop_table[r_crop,7]) #Stage 1, that corresponds to LGP (in days) for the percentage of stage 1
    L2=round(LGP*crop_table[r_crop,8])
    L3=round(LGP*crop_table[r_crop,9])
    L4=LGP-(L1+L2+L3)
    
    L12=L1+L2
    L123=L1+L2+L3
    
    L2_den=L2
    ifelse(L2_den==0,NA,L2_den)
    L4_den=L4
    ifelse(L4_den==0,NA,L4_den)
    
    s=season_start
    h=season_end
    
    
    #definition of rooting depth
    
    RD=as.numeric(crop_table[r_crop,c(13,14)])
    
  
    
    L12_den=L12
    ifelse(L12_den==0,NA,L12_den)
    
    #Depletion factor
    DF=crop_table[r_crop,15]
    
    
    
    #irrigation deficit
    irr_def_array=as.numeric(crop_table[r_crop,c(18:20)])
    
    
    
    
    
    # Define lower level of soil where we record data of deep percolation, "moisture_LOW"
    r=ifelse(level[length(level)]>RD[2],which(level>RD[2]+0.3),level[length(level)]) #if the root depth is deeper than the deepest recording sensor, then choose the deepest recording sensor, otherwise choose the sensor that is 30 cm below root zone
    r=as.array(r)
    # moisture_LOW0<-as.numeric(moisture_sensor[,which(level==r[1])]) #the soil moisture recorded at 30 cm below the root zone 
    moisture_LOW<-as.numeric(moisture_sensor[,which(level==r[1])]) #the soil moisture recorded at 30 cm below the root zone 
     
    
    
    
    
    #moisture_LOW=as.numeric(array(0,dim=length(ET0)))
    
    ponding_in=0
    
    
    
    
    for(scenario in irrigation_scenario){
      
      
      
     #loop through past and future data
     for(a in 1:length(l)){ 
          day <- j[a]
          
          
          # DEFINE WIDTH OF WETTED AREA (ONLY IF THE IRRIGATION IS DRIP OR SUBTERRANEAN) ###########################################################
          #reconstruct the hourly wetting front of the subsurface drip irrigation from Al‐Ogaidi et al. (2015)
          #radius of wetted front
          if(irr_method=="drip" | irr_method=="subterranean"){
            r_width=(40.489*d_rate^0.2717*Ks^(-0.2435)*moisture_sensor[a,1]^0.1122*Pb^2.077*P_sand^(-0.1082)*P_silt^0.0852*P_clay^(-0.154)) /100 #moisture_sensor[,3]=initial soil moisture at 20 cm. /100 because we convert from cm to m
            w_width=r_width * 2      # *2 is because from radius we convert it to diameter. 
            
          } 
          
          #Define the irrigated area ---------------
          if(irr_method=="sprinkler"){
            Area_irr<-rep(Area_crop,length(ET0)) #irrigated area
            
          } else if(irr_method=="drip"){
            
            overlap=ifelse(n_drip_per_line==2,1.5,1)
            Area_irr<- (w_width * w_length * overlap) / n_drip_per_line #irrigated area
            # I divide for the number of drip per line so that the wetted length reduces if there are 2 dripping lines per crop line 
            
          } else if (irr_method=="subterranean"){
            
            overlap=ifelse(n_drip_per_line==2,1.5,1)
            Area_irr<- (w_width * w_length * overlap) / n_drip_per_line #irrigated area
            # I divide for the number of drip per line so that the wetted length reduces if there are 2 dripping lines per crop line 
            
          }
          
          #Determination of irrigation given converted from m3 to mm -----------
          irr_given_mm=irr_given_vol[a]/Area_irr * 1000
          
          
          
          
          
        #Increment of Rooting depth--------------------------------------------------------------------------------------------------------
        daily_rooting_depth<-RD_increment(s,h,day,L12,RD,L12_den,type) 
        

        
        
        
        
        #Calculation of mean soil moisture in the soil--------------------------------------------------------------------------------------
        
        if(daily_rooting_depth < sum(sensor_level)){
          ll=c(sensor_level[which(daily_rooting_depth>level)],sensor_level[min(which(daily_rooting_depth<level))]) #select the levels covered by RD
          ll[length(ll)]=level[min(which(daily_rooting_depth<level))] - daily_rooting_depth # subtract the part which is below rooting depth
          
          
          if(a==1){
            moisture_a <- as.numeric(moisture_sensor[a,])
          }else{
            moisture_a <- as.numeric(moisture_sensor[a,]) #select the levels of moisture of the previous time step
          }
          moisture <- as.numeric(moisture_a[c(which(daily_rooting_depth>level),min(which(daily_rooting_depth<level)))])   
          
          moisture_mean=as.numeric(((moisture %*% ll)/daily_rooting_depth)) #here I'm making the weighted average of soil moisture over the levels covered by the RD. I divide by 100 because I want the result to be adimensional
          moisture_mean=ifelse(moisture_mean==Inf,0,moisture_mean)
          
        }else{
          ll=sensor_level
          if(a==1){
            moisture_a <- as.numeric(moisture_sensor[a,])
          }else{
            moisture_a <- as.numeric(moisture_sensor[a,]) 
          }
          moisture <- moisture_a
          
          moisture_mean=as.numeric(((moisture %*% ll)/sum(ll))) #here I'm making the weighted average of soil moisture over the levels covered by the RD. I divide by 100 because I want the result to be adimensional
          moisture_mean=ifelse(moisture_mean==Inf,0,moisture_mean)
        }
        
        
        # moisture_mean0=as.numeric(((moisture %*% ll)/daily_rooting_depth)) #here I'm making the weighted average of soil moisture over the levels covered by the RD. I divide by 100 because I want the result to be adimensional
        # moisture_mean0=ifelse(moisture_mean0==Inf,0,moisture_mean0)

        
        # #######################
        # ######CALIBRATION######
        # #calculate mean and LOW soil moisture as a sum of the initial moisture calculated in the previous run + the difference between the value recorded by the sensor in the i-th step and the value recorded in ith-1 step
        # moisture_mean=(initial_SM_mean + (moisture_mean0 - moisture_mean_min1)) / 100
        # moisture_LOW[a] <- (initial_SM_LOW + (moisture_LOW0[a] - moisture_LOW_min1)) / 100
        # #######################
        
        #moisture_mean <- moisture_mean / 100
        moisture_mean_array[a]=moisture_mean
        
        
        
        
        
        
        # Determination of effective rainfall prec_eff (from Ali&Mubarak, 2017) ------------------------------------------------------------
        
        prec_eff<-P_eff(daily_rooting_depth,soil_AWC,moisture_mean,ET0,a,precipitation,irr_given_mm)
        prec_eff<- prec_eff+ponding_in #the water that doesn't evaporate, then constitutes the "precipitation" of the following hour
        
        
        ponding_gross=ifelse((precipitation[a]+irr_given_mm)>prec_eff,precipitation[a]+irr_given_mm-prec_eff,0) #define runoff/water that remains on the surface and doesn't infiltrate
        if(irr_method=="subterranean"){
          ponding_net=ponding_gross
        } else{
          ponding_net=ifelse(OWET[a]<=ponding_gross, ponding_gross-OWET[a], 0)
        }
        ponding_in=ponding_net
        
        

        
        
        
        
        # 1st step: increment of Soil Moisture due to Precipitation input----------------------------------------------------------------------
        
        deficit_meteo <- (soil_AWC-moisture_mean) * daily_rooting_depth * 1000 - prec_eff
        deficit_meteo[deficit_meteo<0]=0
        deficit_meteo=round(deficit_meteo,2)
        
        # calculate eventual deep percolation
        
          if(deficit_meteo<(soil_AWC-theta_fc)*daily_rooting_depth*1000){
            
            DP<- (soil_AWC-theta_fc)*daily_rooting_depth*1000 - deficit_meteo   #deep percolation (the component of water that can't be hold in the soil and percolates due to gravity)
          } else{
            DP <-0
          }
        

        #DP=ifelse(deficit_meteo < 0, abs(deficit_meteo),0) #deep percolation (the component of water that can't be hold in the soil and percolates due to gravity)
        
        #deficit_meteo=ifelse(deficit_meteo<0,0,ifelse(deficit_meteo>TAW,TAW,deficit_meteo))
        
     
        
        
        
        
           
        # 2nd step: calculation of daily crop coefficient--------------------------------------------------------------------------------------
        
        kc<-crop_coeff(s,h,day,L1,L12,L123,L2_den,L4_den,LGP,kc_in,kc_mid,kc_end)
        
        
        
        
        
        
        # 3rd step: calculation of daily maximum water capacity in the rooting zone (TAW) and amount of water available until water stress occurs (RAW)
        
        TAW <- crop_AWC * 1000 * daily_rooting_depth
        RAW <- crop_AWC * 1000 * daily_rooting_depth * DF
        
        
        AWC <- (soil_AWC) * 1000 * daily_rooting_depth # total available water in the soil (up to saturation)
        AWC_limit <- (soil_AWC - theta_wp) * 1000 * daily_rooting_depth #total available water that could be depleted (up to wilting point)
        
        
        # 4th step: water-stress coefficient---------------------------------------------------------------------------------------------------
        Dr=ifelse(deficit_meteo > (soil_AWC-theta_fc)*daily_rooting_depth*1000, deficit_meteo - (soil_AWC-theta_fc)*daily_rooting_depth*1000, 0) #Root zone depletion, calculated as the deficit_meteo excluding the %of water that percolates (soil_AWC-theta_fc)
        ks[a]<-ws_coeff(TAW,Dr,RAW)
        
        
        
        
        
        
        #5th step: correction of kc according to soil moisture  ---------------------------------------------------------------------------------
        #(ONLY TO BE APPLIED IN THE LAST 24 HOURS OF PAST DATA)
        
        kc_corr[a]=kc_corr_function(a,kc,kc_corr,irr_given_vol,moisture_LOW,duration_past)
        #kc_corr[a]=ifelse(a<duration_past,kc_corr[a],kc)
        
        
        
           
        
        
        
        # 6th step: calculation of Actual Evapotranspiration
        ETc <-ET0[a] * kc_corr[a]
        ETa <- ET0[a] * kc_corr[a] * ks[a]
        
        
        
        
        
        
        
        # 7th step: reduction of Soil Moisture due to Actual Evapotranspiration-----------------------------------------------------------
        
        deficit_final<-def_function(deficit_meteo,AWC_limit,ETa,DP)
        deficit_final_limit<-def_lim_function(TAW,ks,a,RAW)
        
   
        
        
        
        
        
        # 8th step: Calculation of evapotranspiration components and irrigation requirements------------------------------------------------------
        
        ETa_rf[a] <-ETa #ETa rainfed (If i never irrigate, but it only depends on precipitation)
        
        ETa_full[a] <-ETc #ETa in field capacity condition (ks=1)
    
        Irr_req[a] <- irrigation_function(ETa_rf,a,ETa_full,Dr,RAW)
        
        
        
        
        
        
        
        #9th step: define suggested irrigation volume -----------------------------------------------------------------------------------------------
        
        
        
        Irr_vol[a]=Irr_vol_function(irr_method,Irr_req,a,Area_irr)
        
        
        #Deficit irrigation ----
        if(day>s & day<s+L12){
          irr_def<-irr_def_array[1]
        } else if(day>s+L12 & day<s+L123){
          irr_def<-irr_def_array[2]
        } else if(day>s+L123 & day<h){
          irr_def<-irr_def_array[3]
        } else{
          irr_def<-1
        }
        
        Irr_vol_def[a] <-Irr_vol[a]*irr_def  #deficit irrigation volume 
        
        
        
        
        
        
        
        
        
        #10th step: Assess the days for suggested and limit irrigation --------------------------------------------------------------------------------------
        
        #Irrigation to apply
        
        # Decide which limit of ks to impose for suggested or late irrigation
        if(scenario=="Suggested"){
          b=1
          ks_lim=0.9 
        } else if(scenario=="Limit"){
          b=2
          ks_lim=0.85
        }
        
        if(a<duration_past){
          Irr_to_apply[a,b]=irr_given_vol[a] # For the past period Irr_to_apply corresponds to the irr_given in volume (m3)
        }else{
          if(a < length(ET0)){
            if(ks[a]==1){
              Irr_to_apply[a,b]=0
            } else{
              if(mean(ks[(a-12):a]) < ks_lim){
                
                                  
                Irr_volume[a]=Irr_vol[a]    #Volume of suggested irrigation (m3)
                Irr_hours[a]=Irr_volume[a]/Flow_rate #suggested irrigation hours (h)
                Irr_to_apply[a,b]=Irr_volume[a]           #Irrigation given
              } else{
                Irr_to_apply[a,b]=0
              }
            }
            
            irr_given_vol[a+1]=Irr_to_apply[a,b] #The estimated irrigation to apply that day becomes the new irrigation given
          } 
          
        }
        
        
        
        
        
       
       
        
        
        
       #11th step: calculate volume percolated [m3] ---------------------------------------------------------------------------------------
        # if(a<48){
        #   Irr_vol_percolated[a]=0
        # }else{
        #   
        #   
        #   mean_moisture_nat=mean(moisture_LOW[z])  # mean moisture_LOW in the z days (natural, i.e. far from irrigation events)
        #   mean_moisture_irr=mean(moisture_LOW[(a-48):a]) # mean moisture level 48 hours before step a
        #   
        #   if(mean_moisture_irr> 2*mean_moisture_nat){
        #     Irr_vol_percolated[a] <- (mean_moisture_irr - mean_moisture_nat) * 0.2 * (w_width[a] * w_length) #the difference of the mean natural moisture at 0.8 m and moisture after irrigation times 20 cm (the depth of that level) and the surface
        #   }
        # }
        
        Irr_vol_percolated[a]<- percolation_function(DP,irr_method,Area_irr,daily_rooting_depth) #deep percolation (the component of water that can't be hold in the soil and percolates due to gravity)
        
        
        
        # Re-initialize the loop for the the calculation of soil moisture of the next step (for future data, where SM is unknown)
        
        if(a>=duration_past){
          if(a < length(ET0)){
          moisture_new <- soil_AWC - (deficit_final)/daily_rooting_depth/1000
          moisture_new <- ifelse(moisture_new>soil_AWC,soil_AWC,ifelse(moisture_new<theta_wp,theta_wp,moisture_new))
          moisture_sensor[a+1,]=rep(moisture_new,sensor_levels)
          moisture_LOW[a+1]=moisture_new
          }
          
        }
        
        
        
    
        
        # update summary table
        summary_table[a,which(colnames(summary_table)=="Date")]=as.character(date[a])
        summary_table[a,which(colnames(summary_table)=="Hour")]=hh[a]
        summary_table[a,which(colnames(summary_table)=="moisture_LOW")]=moisture_LOW[a]
        summary_table[a,which(colnames(summary_table)=="ET0")]=ET0[a]
        summary_table[a,which(colnames(summary_table)=="precipitation")]=precipitation[a]
        summary_table[a,which(colnames(summary_table)=="P_eff")]=prec_eff
        summary_table[a,which(colnames(summary_table)=="ponding")]=ponding_net
        summary_table[a,which(colnames(summary_table)=="DP")]=DP
        summary_table[a,which(colnames(summary_table)=="moisture_mean")]=moisture_mean
        summary_table[a,which(colnames(summary_table)=="Deficit meteo")]=deficit_meteo
        summary_table[a,which(colnames(summary_table)=="AWC")]=AWC
        summary_table[a,which(colnames(summary_table)=="theta_fc")]=theta_fc*daily_rooting_depth*1000
        summary_table[a,which(colnames(summary_table)=="TAW")]=TAW
        summary_table[a,which(colnames(summary_table)=="RAW")]=RAW
        summary_table[a,which(colnames(summary_table)=="kc")]=kc
        summary_table[a,which(colnames(summary_table)=="ks")]=ks[a]
        summary_table[a,which(colnames(summary_table)=="kc_corr")]=kc_corr[a]
        summary_table[a,which(colnames(summary_table)=="ETc")]=ETc
        summary_table[a,which(colnames(summary_table)=="ETa")]=ETa
        summary_table[a,which(colnames(summary_table)=="Deficit final")]=deficit_final
        summary_table[a,which(colnames(summary_table)=="Irr_req")]=Irr_req[a]
        summary_table[a,which(colnames(summary_table)=="Irr_vol")]=Irr_vol[a]
        summary_table[a,which(colnames(summary_table)=="irr_given_mm")]=irr_given_mm
        summary_table[a,which(colnames(summary_table)=="Irr_vol_percolated")]=Irr_vol_percolated[a]
        #summary_table[a,which(colnames(summary_table)=="Irr_suggested")]=Irr_to_apply[a,1]
        #summary_table[a,which(colnames(summary_table)=="Irr_limit")]=Irr_to_apply[a,2]
        summary_table[a,which(colnames(summary_table)=="moisture_new")]=ifelse(a<=duration_past,NA,moisture_new)
     }
      
      # Create summary table according to the scenario
      xx=data.frame(Irr_to_apply[,b])
      colnames(xx)=as.character(irrigation_scenario[b])
      summary_table=cbind(summary_table,xx)
      assign(paste("summary_table_",irrigation_scenario[b],sep = ""),summary_table)
      
      summary_table<-summary_table[,1:23]
      summary_table[] <- NA
      
      
      
      
      #Find the irrigation events in the arrays according to the scenario
      
      if(sum(Irr_volume)>0){
        Irr_event_final <- data.frame(matrix(NA,nrow = length(Irr_volume[Irr_volume != 0]), ncol= 3))
        colnames(Irr_event_final)= list("Day","Volume","Hours")
        Irr_event_final[,1]<-date[ Irr_volume>0 ]
        Irr_event_final[,2]<-Irr_volume[Irr_volume != 0]
        Irr_event_final[,3]<-Irr_hours[Irr_hours != 0]
        
      } else{
        Irr_event_final<-data.frame(matrix(NA,nrow = 1, ncol= 3))
        colnames(Irr_event_final)= list("Day","Volume","Hours")
      }
      
      
      assign(paste("Irr_event_final_",irrigation_scenario[b],sep = ""),Irr_event_final)
      
      Irr_volume[] <-0
      Irr_hours[] <-0
      
    }
                            

    
  } 



#################################################################################################################    
################################# RESULTS EXPORT #############################################################


## Aggregate results to be exported ----------------------------------------------------------------
Export_table<-data.frame(
                    as.POSIXct(paste(summary_table_Suggested$Date,summary_table_Suggested$Hour,sep="T"),format="%Y-%m-%dT%H"),
                    summary_table_Suggested$Date,
                    summary_table_Suggested$Hour,
                    summary_table_Suggested$Irr_vol,
                    summary_table_Suggested$moisture_mean*100,
                    summary_table_Suggested$Suggested,
                    summary_table_Limit$Limit)    
colnames(Export_table)=list("TIME","Date","Hour","Hourly irrigation requirements (m3)","Suggested Soil Moisture (%)", "Irrigation Suggested (m3)","Irrigation Limit (m3)")

      
  

## Aggregate data to daily values -------------------------------------------------------------------
summary_table_Suggested$Date=paste(summary_table_Suggested$Date,summary_table_Suggested$Hour,sep="T")
summary_table_Suggested$Date=as.POSIXct(summary_table_Suggested$Date,format="%Y-%m-%dT%H")

summary_table_Limit$Date=paste(summary_table_Limit$Date,summary_table_Limit$Hour,sep="T")
summary_table_Limit$Date=as.POSIXct(summary_table_Limit$Date,format="%Y-%m-%dT%H")


daily_variables<-summary_table_Suggested %>%
  mutate(TIME = floor_date(Date,"day")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    #ET0=sum(ET0, na.rm= TRUE),
    #ETa=sum(ETa, na.rm= TRUE),
    
    Irr_vol=Irr_vol[which.max(Irr_vol)],
    moisture_mean=mean(moisture_mean,na.rm = TRUE)*100,
    Irr_suggested=sum(Suggested, na.rm= TRUE),
    
  )

daily_variables_lim<-summary_table_Limit %>%
  mutate(TIME = floor_date(Date,"day")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    Irr_Limit=sum(Limit, na.rm= TRUE),
    
  )

daily_variables_final<-cbind(daily_variables,daily_variables_lim$Irr_Limit)
colnames(daily_variables_final)=list("Date","Daily irrigation requirements (m3)","Suggested Soil Moisture (%)", "Irrigation Suggested (m3)","Irrigation Limit (m3)")





####### EXPORT RESULTS ######################################################################################################

write.table(summary_table_Suggested$Date,paste(out_dir,"Date_array.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(summary_table_Suggested$moisture_mean,paste(out_dir,"moisture_mean.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(Irr_vol,paste(out_dir,"Irr_vol.csv",sep=""),row.names = FALSE,col.names = FALSE)
#write.table(Irr_vol_percolated,paste(out_dir,"Irr_vol_percolated.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(Irr_to_apply[,1],paste(out_dir,"Irr_suggested.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(Irr_to_apply[,2],paste(out_dir,"Irr_limit.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(Irr_event_final_Suggested,paste(out_dir,"Irrigation_event_Suggested.csv",sep=""),row.names = FALSE,col.names = TRUE)
write.table(Irr_event_final_Limit,paste(out_dir,"Irrigation_event_Limit.csv",sep=""),row.names = FALSE,col.names = TRUE)
write.table(soil_AWC_sensor*100,paste(out_dir,"SM_max_previous_run.csv",sep=""),row.names = FALSE,col.names = FALSE)

write.table(daily_variables_final,paste(out_dir,"daily_variables_final.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
write.table(Export_table,paste(out_dir,"hourly_variables_final.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
