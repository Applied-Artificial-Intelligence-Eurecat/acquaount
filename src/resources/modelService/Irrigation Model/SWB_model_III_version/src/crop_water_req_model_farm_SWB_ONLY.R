##############################################   DATI DI INPUT  ###########################################################################################################
rm(list = ls())

library(tictoc)
library(readxl)
library(units)
library(lubridate)
library(dplyr)
library(randomForest)
library(outliers)
library(soilDB)
library(aqp)
library(ranger)
library(parallel)
library(jsonlite)

#tic()

# wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
#wd="C:/Users/Andrea/OneDrive - Università degli Studi di Sassari/Desktop/Dottorato_Sassari/modello_ACQUAOUNT/SWB_model_III_version/"
# COMENT OUT THIS LINE IF RUNNING IN DOCKER
wd <- getwd()


in_dir=paste(wd,"/Input_data/",sep="")
out_dir=paste(wd,"/Output_data/",sep="")
json_data <- fromJSON("config.input.json")  # Replace with your actual JSON file path


source(paste(wd,"/Functions/Functions_model_farm.R",sep=""))


########################################## CROP ##########################################################

#import crop table -------------------------------------------

crop_table=read.csv(paste(in_dir,"crop_data/crop_table.csv",sep="")) 

#Select a crop according to one of the following.
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

crop_list=list(json_data$crop_name) #select crop

season_start=json_data$season_start #Planting/budbreak date
season_end=json_data$season_end #harvesting date



# Sesto d'impianto
plant_spacing=json_data$plant_spacing #distance between each plant (m)
line_spacing=json_data$line_spacing #distance between lines (m)
Area_crop=json_data$Area_crop #cultivated area of the field in m2
n_plants=Area_crop/(plant_spacing*line_spacing) #number of plants

#import the corrected kc from previous run
kc_corr<-as.numeric(unlist(read.table(paste(in_dir,json_data$kc_correction_filepath,sep=""), quote="\"", comment.char="")))


############################################### SOIL DATA #################################################

P_sand=json_data$P_sand #percentage of sand (%)
P_clay=json_data$P_clay #percentage of clay
P_silt=json_data$P_silt #percentage of silt
P_om=json_data$P_om #% percentage of organic matter


Ks=json_data$Ks #cm/h   #Saturdated hydraulic conductivity
Pb=json_data$Pb #g/cm3  #Bulk density

soil_SAT_user=json_data$soil_SAT_user #total available water content at saturation (soil porosity)
theta_fc_user=json_data$theta_fc_user #%
theta_wp_user=json_data$theta_wp_user #%










############################################ CLIMATE DATA ##################################################

#Define climatic zone in which I will insert appropriate values of Kc and duration of the growing period

#In this case, we imagine dealing with 2 climatic zones. 
# 1. Mediterranean
# 2. Arid

climate_zone=json_data$climate_zone #in this case we are focusing on Tunisia
lat=json_data$lat 
elev=json_data$elev




# Import SENSOR data--------------------------------------

temp_past <- read.csv(paste(in_dir,"climate_data/temperature_Tunisia.csv",sep="")) 
precipitation_past <- read.csv(paste(in_dir,"climate_data/precipitation_Tunisia.csv",sep=""))
sw_rad_past <- read.csv(paste(in_dir,"climate_data/solar_rad_Tunisia.csv",sep=""))
RH_past <- read.csv(paste(in_dir,"climate_data/humidity_Tunisia.csv",sep=""))
wind_past <- read.csv(paste(in_dir,"climate_data/wind_speed_Tunisia.csv",sep=""))

temp_past<-as.numeric(unlist(temp_past))
sw_rad_past<-as.numeric(unlist(sw_rad_past))
wind_past<-as.numeric(unlist(wind_past))
RH_past<-as.numeric(unlist(RH_past))
precipitation_past<-as.numeric(unlist(precipitation_past))

date_past <- as.character(unlist(read.csv(paste(in_dir,"climate_data/date_Tunisia.csv",sep=""))))
date_past <- parse_date_time(date_past, orders = c("ymd", "dmy", "mdy", "ydm"))
hh_past <- read.csv(paste(in_dir,"climate_data/hour_Tunisia.csv",sep=""))
hh_past<-as.numeric(unlist(hh_past))


duration_past <- length(temp_past)

# Import WEATHER FORECAST data -----------------------------

temp_fut <- read.csv(paste(in_dir,"climate_data/temperature_Tunisia_fut.csv",sep="")) 
precipitation_fut <- read.csv(paste(in_dir,"climate_data/precipitation_Tunisia_fut.csv",sep=""))
sw_rad_fut <- read.csv(paste(in_dir,"climate_data/solar_rad_Tunisia_fut.csv",sep=""))
RH_fut <- read.csv(paste(in_dir,"climate_data/humidity_Tunisia_fut.csv",sep=""))
wind_fut <- read.csv(paste(in_dir,"climate_data/wind_speed_Tunisia_fut.csv",sep=""))

temp_fut<-as.numeric(unlist(temp_fut))
sw_rad_fut<-as.numeric(unlist(sw_rad_fut))
wind_fut<-as.numeric(unlist(wind_fut))
RH_fut<-as.numeric(unlist(RH_fut))
precipitation_fut<-as.numeric(unlist(precipitation_fut))

date_fut <- as.character(unlist(read.csv(paste(in_dir,"climate_data/date_Tunisia_fut.csv",sep=""))))
date_fut <- parse_date_time(date_fut, orders = c("ymd", "dmy", "mdy", "ydm"))
hh_fut <- read.csv(paste(in_dir,"climate_data/hour_Tunisia_fut.csv",sep=""))
hh_fut<-as.numeric(unlist(hh_fut))

duration_fut<-length(temp_fut)



########################################## IRRIGATION ##########################################################


#First of all, select irrigation method among the following
# sprinkler
# drip
# subterranean

irr_method=json_data$irr_method #irrigation method

if(irr_method=="sprinkler"){
  n_emitter=json_data$n_emitter
  s_rate=json_data$s_rate #sprikler flowrate (l/h)
  
  Flow_rate=n_emitter*s_rate/1000 #flowrate of the system #m^3/h
  
  
} else if(irr_method=="drip"){
  
  n_drip_per_line=json_data$n_drip_per_line
  d_spacing=json_data$d_spacing #dripper spacing (m)
  d_rate=json_data$d_rate #dripper flowrate (l/h)
  w_length=json_data$w_length #wetted length (m)
  n_emitter=w_length/d_spacing #number of emitter
  
  Flow_rate=n_emitter*d_rate/1000 #flowrate of the system #m^3/h
  
    
    
} else if (irr_method=="subterranean"){
  
  n_drip_per_line=json_data$n_drip_per_line
  d_depth=json_data$d_depth #depth of drippers (m)
  d_spacing=json_data$d_spacing #dripper spacing (m)
  d_rate=json_data$d_rate #dripper flowrate (l/h)
  w_length=json_data$w_length #wetted length (m)
  n_emitter=w_length/d_spacing #number of emitter
  
  Flow_rate=n_emitter*d_rate/1000 #flowrate of the system #m^3/h
  
}


# irrigation deficit array. If the user defines an amount of irrigation deficit, it is imported here, otherwise, the default values from crop_table are used
irr_def_user <-c(NA,NA,NA)


# IRRIGATION CALENDAR (Date, hour and duration of irrigation)
irr_given_vol_calendar=read.csv(paste(in_dir,"irrigation_data/water_Flow_Tunisia_Calendar.csv",sep=""))


            


############################################ MOISTURE DATA ##################################################

SM_previous_run <- as.numeric(unlist(read.table(paste(in_dir,"soil_moisture_data/SM_Tunisia_SWB_past.csv",sep=""),sep="",header = FALSE)))








############################### PREPARE THE DATA ############################################################################



########### DEFINE SOIL WATER CONTENT (SATURATION, FIELD CAPACITY AND WILTING POINT) ==========================

WRP=PTFs_function(P_sand,P_silt,P_clay,P_om,Pb,theta_fc_user,theta_wp_user,soil_SAT_user) # Function to estimate ensemble mean of the Pedotransfer Functions

theta_fc=WRP$FC
theta_wp=WRP$WP
soil_SAT=WRP$SAT

crop_AWC= theta_fc - theta_wp #available water capacity for the crop




# ####### Calibration of soil moisture data ============================================================================
# #Find the parameters of the linear equation
# m <- (soil_SAT - theta_wp) / (soil_SAT_sensor - soil_WP_sensor) #Angular coefficient
# q <- theta_wp - m * (soil_WP_sensor) #known term
# 
# moisture_sensor <- m * moisture_sensor_raw + q  #Linear equation y=m*x+q
# moisture_sensor[moisture_sensor>soil_SAT]=soil_SAT
# ######




#############   COMBINE DATA ===================================================================================


# PAST
past_data=data.frame(date=date_past,
                     hh=hh_past,
                     temp=temp_past,
                     prec=precipitation_past,
                     SW=sw_rad_past,
                     RH=RH_past,
                     wind=wind_past)
                                           
# FUTURE ----
future_data=data.frame(date=date_fut,
                       hh=hh_fut,
                       temp=temp_fut,
                       prec=precipitation_fut,
                       SW=sw_rad_fut,
                       RH=RH_fut,
                       wind=wind_fut)   
                                                              

dataset_model=rbind(past_data,future_data) #combine dataframe of past and future


#split the dataset into single variables ===========
date<-dataset_model$date
hh=dataset_model$hh
temp=dataset_model$temp
precipitation=dataset_model$prec
RH=dataset_model$RH
wind=dataset_model$wind
sw_rad=dataset_model$SW

moisture=data.frame(SM_I=c(SM_previous_run,rep(0,length(date)-1)),
                    SM_II=c(SM_previous_run,rep(0,length(date)-1)),
                    SM_III=c(SM_previous_run,rep(0,length(date)-1))) 
moisture=moisture/100
                    


#convert dates into DOY =====================================

season_start=as.Date(season_start,format = "%d/%m/%Y") #convert date in date format
season_end=as.Date(season_end,format = "%d/%m/%Y")
season_start=yday(season_start) #convert into DOY (day of the year)
season_end=yday(season_end)




# CONVERT IRRIGATION CALENDAR INTO AN ARRAY ============================ 
time_steps <- paste(date, sprintf("%02d:00", hh))
time_steps <- as.POSIXct(time_steps, format = "%Y-%m-%d %H:%M")

irr_given_vol <- rep(0, length(date))

# Iterate over each irrigation event
for (i in 1:length(irr_given_vol_calendar$Date)) {
  start_time <- as.POSIXct(paste(irr_given_vol_calendar$Date[i], sprintf("%02d:00", irr_given_vol_calendar$Hour[i])), 
                           format = "%d/%m/%Y %H:%M")
  start_index <- which(time_steps==start_time)
  
  # Apply irrigation volume over the specified hours
  irr_given_vol[start_index:(start_index + irr_given_vol_calendar$Hours_irr[i] - 1)] <- Flow_rate
}








################################################ RUN MODEL ##################################################################




# CALCULATION ET0 ########################################################################

Evapotranspiration <- FAO_ET0_function(lat,temp,sw_rad,wind,RH,elev,date,hh,"°C","W/m2","m/s","%","m")
ET0=Evapotranspiration$ET0
OWET=Evapotranspiration$OWET









# DEFINE THE OUTPUT FILES ##############################################################

Irr_req=as.numeric(array(0,dim=length(ET0)))
ETa_rf=as.numeric(array(0,dim=length(ET0)))
ETa_full=as.numeric(array(0,dim=length(ET0)))
Dr=as.numeric(array(0,dim=length(ET0)))
Irr_vol=as.numeric(array(0,dim=length(ET0)))
Irr_vol_def=as.numeric(array(0,dim=length(ET0)))
moisture_mean_array=as.numeric(array(0,dim=length(ET0)))
Irr_vol_percolated=as.numeric(array(0,dim=length(ET0)))
Date_irr=data.frame(Today=date[duration_past],
                    Early=NA,
                    Late=NA,
                    Limit=NA, row.names = "Date")

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
variables_st=list("Date","Hour","precipitation","P_eff","ponding","DP","moisture_mean","ET0","Deficit meteo","SAT_daily","theta_fc","TAW","RAW","kc","kc_correction","ETc","ks","Dr","ETa","Irr_req","Deficit final","Irr_vol","Irr_deficit","Irr_vol_percolated","moisture_new")
summary_table=data.frame(matrix(NA,nrow = length(ET0),ncol = length(variables_st)))
colnames(summary_table)=variables_st  

  
# SOIL WATER BALANCE ##############################################################
  
  
  
  
  for (crop in crop_list){
    

    
    i=which(crop==crop_list)
    r_crop=which(crop_table$Crop==crop & crop_table$Clim==climate_zone) #Define the r_crop where to take the data
    type=crop_table[r_crop,which(colnames(crop_table)=="Type")]
    
    # Length of Growing Periods, kc values and rooting depth

    
    if (season_start<season_end){
      
      LGP=season_end-season_start+1
    } else if (season_start>season_end){
      
      LGP=season_end-season_start+366
    }
    
    
    #%definition of kc
    kc_in=crop_table[r_crop,which(colnames(crop_table)=="Kc_in")]
    kc_mid=crop_table[r_crop,which(colnames(crop_table)=="Kc_mid")]
    kc_end=crop_table[r_crop,which(colnames(crop_table)=="Kc_end")]
    
    #Definition of period
    L1=round(LGP*crop_table[r_crop,which(colnames(crop_table)=="lgp_f1")]) #Stage 1, that corresponds to LGP (in days) for the percentage of stage 1
    L2=round(LGP*crop_table[r_crop,which(colnames(crop_table)=="lgp_f2")])
    L3=round(LGP*crop_table[r_crop,which(colnames(crop_table)=="lgp_f3")])
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
    
    RD=as.numeric(crop_table[r_crop,which(colnames(crop_table) %in% c("RD1", "RD2"))])
    
  
    
    L12_den=L12
    ifelse(L12_den==0,NA,L12_den)
    
    #Depletion factor
    DF=crop_table[r_crop,which(colnames(crop_table)=="DF")]
    
    
    
    #irrigation deficit. If the user does not define his/her own coefficient, the default from fìcrop table are used
    if(is.na(sum(irr_def_user))==TRUE){
      irr_def_array=as.numeric(crop_table[r_crop,which(colnames(crop_table) %in% c("Irr_def_1", "Irr_def_2", "Irr_def_3"))])
    } else{
      irr_def_array=irr_def_user
    }
    
    
    #Early, Late and Limit irrigation parameters
    irr_threshold_array=as.numeric(crop_table[r_crop,which(colnames(crop_table) %in% c("Early_irr", "Late_irr", "Limit_irr"))])
    
    
    
    # Define lower level of soil where we record data of deep percolation, "moisture_LOW"
    #r=ifelse(level[length(level)]>RD[2],which(level>RD[2]+0.3),level[length(level)]) #if the root depth is deeper than the deepest recording sensor, then choose the deepest recording sensor, otherwise choose the sensor that is 30 cm below root zone
    #r=as.array(r)
    # moisture_LOW0<-as.numeric(moisture_sensor[,which(level==r[1])]) #the soil moisture recorded at 30 cm below the root zone 
    moisture_LOW<-as.numeric(moisture[,3]) #the soil moisture recorded at 30 cm below the root zone 
     
    
    
    
    
    #Initialize variables
    
    ponding_in=0
    kc_correction=0
   
    
    

      
      
      
     #loop through past and future data
     for(a in 1:length(l)){ 
          day <- j[a]
          
          
          # DEFINE WETTED AREA (percentage of irrigated area with respect to crop area ###########################################################
          
          Area_irr <- irrigated_area_function(irr_method,d_rate,Ks,moisture,a,Pb,P_sand,P_silt,P_clay,Area_crop,ET0,n_drip_per_line,w_length)
          
          
          #Determination of irrigation given converted from m3 to mm -----------
          irr_given_mm=irr_given_vol[a]/Area_irr * 1000
          
          
          
          
          
        #Increment of Rooting depth--------------------------------------------------------------------------------------------------------
        daily_rooting_depth<-RD_increment(s,h,day,L12,RD,L12_den,type) 
        

        
        
        
        
        #Calculation of mean soil moisture in the soil--------------------------------------------------------------------------------------
        
        moisture_mean <- moisture$SM_II[a]
        
        
        

        
        #moisture_mean <- moisture_mean / 100
        moisture_mean_array[a]=moisture_mean
        
        
        
        
        
        
        # Determination of effective rainfall prec_eff (from Ali&Mubarak, 2017) ------------------------------------------------------------
        
        prec_eff<-P_eff(daily_rooting_depth,soil_SAT,moisture_mean,ET0,a,precipitation,irr_given_mm)
        prec_eff<- prec_eff+ponding_in #the water that doesn't evaporate, then constitutes the "precipitation" of the following hour
        
        
        ponding_gross=ifelse((precipitation[a]+irr_given_mm)>prec_eff,precipitation[a]+irr_given_mm-prec_eff,0) #define runoff/water that remains on the surface and doesn't infiltrate
        if(irr_method=="subterranean"){
          ponding_net=ponding_gross
        } else{
          ponding_net=ifelse(OWET[a]<=ponding_gross, ponding_gross-OWET[a], 0)
        }
        ponding_in=ponding_net
        
        

        
        
        
        
        # 1st step. increment of Soil Moisture due to Precipitation input----------------------------------------------------------------------
        
        deficit_meteo <- (soil_SAT-moisture_mean) * daily_rooting_depth * 1000 - prec_eff
        deficit_meteo[deficit_meteo<0]=0
        deficit_meteo=round(deficit_meteo,2)
        
        # calculate eventual deep percolation
        
          if(deficit_meteo<(soil_SAT-theta_fc)*daily_rooting_depth*1000){
            
            DP<- (soil_SAT-theta_fc)*daily_rooting_depth*1000 - deficit_meteo   #deep percolation (the component of water that can't be hold in the soil and percolates due to gravity)
          } else{
            DP <-0
          }
      
        
        
        
           
        # 2nd step. calculation of daily crop coefficient--------------------------------------------------------------------------------------
        
        kc<-crop_coeff(s,h,day,L1,L12,L123,L2_den,L4_den,LGP,kc_in,kc_mid,kc_end)
        
        
        
        
        
        
        # 3rd step. calculation of daily maximum water capacity in the rooting zone (TAW) and amount of water available until water stress occurs (RAW)
        
        TAW <- crop_AWC * 1000 * daily_rooting_depth
        RAW <- crop_AWC * 1000 * daily_rooting_depth * DF
        
        
        SAT_daily <- (soil_SAT) * 1000 * daily_rooting_depth # total available water in the soil (up to saturation)
        SAT_daily_limit <- (soil_SAT - theta_wp) * 1000 * daily_rooting_depth #total available water that could be depleted (up to wilting point)
        
        
        # 4th step. water-stress coefficient---------------------------------------------------------------------------------------------------
        Dr[a]=ifelse(deficit_meteo > (soil_SAT-theta_fc)*daily_rooting_depth*1000, deficit_meteo - (soil_SAT-theta_fc)*daily_rooting_depth*1000, 0) #Root zone depletion, calculated as the deficit_meteo excluding the %of water that percolates (soil_SAT-theta_fc)
        ks<-ws_coeff(TAW,Dr,a,RAW)
        
        
        
        
        
        
        #5th step. correction of kc according to soil moisture  ---------------------------------------------------------------------------------
        #(ONLY TO BE APPLIED IN THE LAST 24 HOURS OF PAST DATA)
        
        #kc_corr[a]=kc_corr_function(a,kc,kc_corr,irr_given_vol,moisture_LOW,duration_past,moisture_sensor,sensor_levels)
        #kc_corr[a]=ifelse(a<duration_past,kc_corr[a],kc)
        kc_correction=kc_corr_function(a,kc_corr,kc_correction,irr_given_vol,moisture_LOW,duration_past,moisture_sensor,sensor_levels)
        
        
        
           
        
        
        
        # 6th step. calculation of Actual Evapotranspiration
        ETc <-ET0[a] * kc * kc_correction
        ETa <- ET0[a] * kc * kc_correction * ks
        
        
        
        
        
        
        
        # 7th step. reduction of Soil Moisture due to Actual Evapotranspiration-----------------------------------------------------------
        
        deficit_final<-def_function(deficit_meteo,SAT_daily_limit,ETa,DP)
        deficit_final_limit<-def_lim_function(TAW,ks,RAW)
        
   
        
        
        
        
        
        # 8th step. Calculation of evapotranspiration components and irrigation requirements------------------------------------------------------
        
        ETa_rf[a] <-ETa #ETa rainfed (If i never irrigate, but it only depends on precipitation)
        
        ETa_full[a] <-ETc #ETa in field capacity condition (ks=1)
    
        Irr_req[a] <- irrigation_function(Dr,a)
        
        
        
        
        
        
        
        
        #9th step. define suggested irrigation volume -----------------------------------------------------------------------------------------------
        
        
        
        Irr_vol[a]=Irr_vol_function(irr_method,Irr_req,a,Area_irr)
        
        
        #Deficit irrigation ----
        
        
        Irr_vol_def[a] <-Irr_def_function(day,s,L12,L123,irr_def_array,h, Irr_vol, a, irr_def,RAW, Dr,irr_threshold_array)  #deficit irrigation volume 
        
        
        
        
        #10th step. Decide when to assess the EARLY, LATE AND LIMIT irrigation -------------------------------------------------------------------
      
        Date_irr <- irr_suggestion_function(RAW,irr_threshold_array,a,duration_past,Dr,date)
        
        
    
        
        
       #11th step. calculate volume percolated [m3] ---------------------------------------------------------------------------------------
        
        Irr_vol_percolated[a]<- percolation_function(DP,irr_method,Area_irr,daily_rooting_depth) #deep percolation (the component of water that can't be hold in the soil and percolates due to gravity)
        
        
        
        # Re-initialize the loop for the the calculation of soil moisture of the next step (for future data, where SM is unknown)
        
 
          if(a < length(ET0)){
          moisture_new <- soil_SAT - (deficit_final)/daily_rooting_depth/1000
          moisture_new <- ifelse(moisture_new>soil_SAT,soil_SAT,ifelse(moisture_new<theta_wp,theta_wp,moisture_new))
          moisture[a+1,]=rep(moisture_new,ncol(moisture))
          moisture_LOW[a+1]=moisture_new
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
        summary_table[a,which(colnames(summary_table)=="SAT_daily")]=SAT_daily
        summary_table[a,which(colnames(summary_table)=="theta_fc")]=theta_fc*daily_rooting_depth*1000
        summary_table[a,which(colnames(summary_table)=="TAW")]=TAW
        summary_table[a,which(colnames(summary_table)=="RAW")]=RAW
        summary_table[a,which(colnames(summary_table)=="kc")]=kc
        summary_table[a,which(colnames(summary_table)=="ks")]=ks
        summary_table[a,which(colnames(summary_table)=="Dr")]=Dr[a]
        summary_table[a,which(colnames(summary_table)=="kc_correction")]=kc_correction
        summary_table[a,which(colnames(summary_table)=="ETc")]=ETc
        summary_table[a,which(colnames(summary_table)=="ETa")]=ETa
        summary_table[a,which(colnames(summary_table)=="Deficit final")]=deficit_final
        summary_table[a,which(colnames(summary_table)=="Irr_req")]=Irr_req[a]
        summary_table[a,which(colnames(summary_table)=="Irr_vol")]=Irr_vol[a]
        summary_table[a,which(colnames(summary_table)=="Irr_deficit")]=Irr_vol_def[a]
        summary_table[a,which(colnames(summary_table)=="irr_given_mm")]=irr_given_mm
        summary_table[a,which(colnames(summary_table)=="Irr_vol_percolated")]=Irr_vol_percolated[a]
        summary_table[a,which(colnames(summary_table)=="moisture_new")]=moisture_new
     }

    
  } 








#################################################################################################################    
################################# RESULTS EXPORT #############################################################


## Aggregate results to be exported ----------------------------------------------------------------
hourly_variables_final<-data.frame(
                    as.POSIXct(paste(summary_table$Date,summary_table$Hour,sep="T"),format="%Y-%m-%dT%H"),
                    summary_table$Date,
                    summary_table$Hour,
                    summary_table$Irr_vol,
                    summary_table$Irr_deficit,
                    summary_table$moisture_mean*100)    
colnames(hourly_variables_final)=list("TIME","Date","Hour","Irr_vol_m3","Irr_deficit_m3","Soil_moisture")

      
  

## Aggregate data to daily values -------------------------------------------------------------------
summary_table$Date=paste(summary_table$Date,summary_table$Hour,sep="T")
summary_table$Date=as.POSIXct(summary_table$Date,format="%Y-%m-%dT%H")



daily_variables_final<-hourly_variables_final %>%
  mutate(TIME = floor_date(TIME,"day")
  ) %>%
  group_by(TIME) %>%
  summarize(
    
    Irr_vol_m3=Irr_vol_m3[which.max(Irr_vol_m3)],
    Irr_deficit_m3=Irr_deficit_m3[which.max(Irr_deficit_m3)],
    Soil_moisture=mean(Soil_moisture,na.rm = TRUE)
  )

colnames(daily_variables_final)=list("Date","Daily irrigation requirements (m3)","Irrigation deficit (m3)","Soil Moisture (%)")





####### EXPORT RESULTS ######################################################################################################


write.table(daily_variables_final,paste(out_dir,"daily_variables_final.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
write.table(hourly_variables_final,paste(out_dir,"hourly_variables_final.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
write.table(Date_irr,paste(out_dir,"Irrigation_dates.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
write.table(kc_correction,paste(in_dir,"crop_data/kc_correction.csv",sep=""),row.names = FALSE,col.names = FALSE)
write.table(summary_table$moisture_mean[12],paste(in_dir,"soil_moisture_data/SM_Tunisia_SWB_past.csv",sep=""),row.names = FALSE,col.names = FALSE)












# # 
# # 
# # #############################################################################################################
# 
# 
# # Obtain daily values of irrigation recorded by the sensors
# irr_given_vol_original=read.csv(paste(in_dir,"irrigation_data/water_Flow_Tunisia.csv",sep=""))
# irrigation_fut <- read.csv(paste(in_dir,"irrigation_data/water_Flow_Tunisia_fut.csv",sep=""))
# Date=summary_table$Date
# 
# irr_given_tot=rbind(irr_given_vol_original,irrigation_fut)
# irr_given_tot=cbind(Date,irr_given_tot)
# colnames(irr_given_tot)=list("Date","Irr_given")
# 
# irr_daily <- irr_given_tot %>%
#   mutate(Date = floor_date(Date,"day")
#   ) %>%
#   group_by(Date) %>%
#   summarize(
#     
#     Irr_given=Irr_given[which.max(Irr_given)]
#   )
# write.table(irr_daily,paste(out_dir,"Irr_daily.csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
