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


wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
in_dir=paste(wd,"/Input_data/",sep="")
out_dir=paste(wd,"/Output_data/",sep="")
json_data <- fromJSON("config.input.json")  # Replace with your actual JSON file path

source(paste(wd,"/Functions/Functions_model_BASIN_II.r",sep=""))




  
  
  




########################################## CROP ##########################################################

#import crop table -------------------------------------------

crop_table=read.csv(paste(in_dir,"crop_data/crop_table_REVIEWED.csv",sep=""),sep = ";") 

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

cultivated_area_basin <-read.csv(paste(in_dir,"crop_data/cultivated_area_basin_jordan.csv",sep=""),header = TRUE)


############################################### SOIL DATA #################################################

P_sand=json_data$P_sand #percentage of sand (%)
P_clay=json_data$P_clay #percentage of clay
P_silt=json_data$P_silt #percentage of silt
P_om=json_data$P_om #% percentage of organic matter


Ks=json_data$Ks #cm/h   #Saturdated hydraulic conductivity
Pb=json_data$Pb #g/cm3  #Bulk density









############################################ CLIMATE DATA ##################################################

#Define climatic zone in which I will insert appropriate values of Kc and duration of the growing period

#In this case, we imagine dealing with 2 climatic zones. 
# 1. Mediterranean
# 2. Arid

climate_zone=json_data$climate_zone #in this case we are focusing on Tunisia
lat=json_data$lat 
elev=json_data$elev


#loop through scenarios (historical ssp126 ssp370)

scenario_list=list("historical", "ssp126", "ssp370")
for (scenario in scenario_list){

# Import CLIMATE data--------------------------------------

dataset_model <- read.csv(paste(in_dir,"climate_data/",scenario,"_allvars_avg.csv",sep=""))



#split the dataset into single variables ===========
date<-as.POSIXct(dataset_model$date) 
tmin=dataset_model$tasmin
tmax=dataset_model$tasmax
precipitation=dataset_model$pr
RH=dataset_model$hurs
wind=dataset_model$wind
Rs=dataset_model$SW_rad

# Check if columns Rs and wind exist, otherwise create them
if (!"Rs" %in% names(dataset_model)) {
  Rs <- rep(NA, nrow(dataset_model))
} 
if (!"wind" %in% names(dataset_model)) {
  wind <- rep(NA, nrow(dataset_model))
}




############################### PREPARE THE DATA ############################################################################



########### DEFINE SOIL WATER CONTENT (SATURATION, FIELD CAPACITY AND WILTING POINT) ==========================

WRP=PTFs_function(P_sand,P_silt,P_clay,P_om,Pb) # Function to estimate ensemble mean of the Pedotransfer Functions

theta_fc=WRP$FC
theta_wp=WRP$WP
soil_SAT=WRP$SAT

crop_AWC= theta_fc - theta_wp #available water capacity for the crop









# DEFINE THE OUTPUT FILES ##############################################################

Irr_req=as.numeric(array(0,dim=nrow(dataset_model)))
ETa_rf=as.numeric(array(0,dim=nrow(dataset_model)))
ETa_full=as.numeric(array(0,dim=nrow(dataset_model)))
Dr=as.numeric(array(0,dim=nrow(dataset_model)))


Irr_sched=as.numeric(array(0,dim=nrow(dataset_model)))
Irr_vol_matrix<-data.frame(matrix(nrow = nrow(dataset_model), ncol = nrow(cultivated_area_basin)))
colnames(Irr_vol_matrix)<-cultivated_area_basin$crop





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
variables_st=list("Date","precipitation","P_eff","ponding","DP","moisture","ET0","Deficit meteo","SAT_daily","theta_fc","TAW","RAW","kc","ETc","ks","Dr","ETa","Irr_req","Irr_sched","Deficit final","moisture_new")
summary_table=data.frame(matrix(NA,nrow = nrow(dataset_model),ncol = length(variables_st)))
colnames(summary_table)=variables_st  















 ################################################ RUN MODEL ##################################################################

  
  
  for (i in 1:nrow(cultivated_area_basin)){
    


    crop=cultivated_area_basin$crop[i]
    
    in_greenhouse=cultivated_area_basin[i,3]
    if(in_greenhouse==1){
      precipitation=rep(0,nrow(dataset_model))
    }
    
    
    
    
    
    # CALCULATION ET0 ########################################################################
    
    Evapotranspiration <- FAO_ET0_function(lat, tmin, tmax, Rs, wind, RH, RH_type, elev, date, in_greenhouse, "°C","W/m2","m/s","%","m")
    ET0=Evapotranspiration$ET0
    OWET=Evapotranspiration$OWET
    
    
    
    
    
    
    
    

    
    
    r_crop=which(crop_table$Crop==crop & crop_table$Clim==climate_zone) #Define the r_crop where to take the data
    type=crop_table[r_crop,which(colnames(crop_table)=="Type")]
    
    
    season_start <- crop_table[r_crop,which(colnames(crop_table)=="Season_start")]
    season_end <- crop_table[r_crop,which(colnames(crop_table)=="Season_End")]
    
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
    
    
    #First of all, select irrigation method among the following
    # sprinkler
    # drip
    # subterranean
    
    irr_method=crop_table[r_crop,which(colnames(crop_table)=="Irrigation")] #irrigation method
      
       if(irr_method=="drip" | irr_method=="subterranean"){
        
        if(type==1){
          d_spacing=0.3 #dripper spacing (m)
          d_rate=2.6 #dripper flowrate (l/h)
          d_depth=0.2 #depth of drippers (m)
          p_spacing=0.5 #distance of the plants within a line (m)
          l_spacing=1 #distance of each line (m)
          
        } else if(type==2){
          d_spacing=0.3 #dripper spacing (m)
          d_rate=2.6 #dripper flowrate (l/h)
          d_depth=0.2 #depth of drippers (m)
          p_spacing=0.5 #distance of the plants within a line (m)
          l_spacing=1 #distance of each line (m)
        }
      
}

    
    
    
    
    
    
    
    #irrigation deficit. If the user does not define his/her own coefficient, the default from fìcrop table are used

      irr_def_array=as.numeric(crop_table[r_crop,which(colnames(crop_table) %in% c("Irr_def_1", "Irr_def_2", "Irr_def_3"))])

    
      #Full and deficit irrigation threshold
      irr_threshold_array=as.numeric(crop_table[r_crop,which(colnames(crop_table) %in% c("Early_irr", "Late_irr"))])
      
    
    
    
    #Initialize variables
    
    ponding_in=0
    kc_correction=0
    moisture_i=theta_fc
    
    

      
      
    # SOIL WATER BALANCE ############################################################## 
     #loop through past and future data
     for(a in 1:length(l)){ 
          day <- j[a]
          
          
          #Define moisture at the beginning of the day
          moisture <- moisture_i
          
          
        #Increment of Rooting depth--------------------------------------------------------------------------------------------------------
        daily_rooting_depth<-RD_increment(s,h,day,L12,RD,L12_den,type) 
        daily_rooting_depth <- ifelse(daily_rooting_depth !=0, daily_rooting_depth, RD[2]) #Assumption: if we are outside the growing period, we make the soil water balance over the portion of soil where roots are supposed to grow
    

        
        
        
        # Determination of effective rainfall prec_eff (from Ali&Mubarak, 2017) ------------------------------------------------------------
        
        prec_eff<-P_eff(daily_rooting_depth,soil_SAT,moisture,ET0,a,precipitation)
        prec_eff<- prec_eff+ponding_in #the water that doesn't evaporate, then constitutes the "precipitation" of the following hour
        
        
        ponding_gross=ifelse((precipitation[a])>prec_eff,precipitation[a]-prec_eff,0) #define runoff/water that remains on the surface and doesn't infiltrate
        if(irr_method=="subterranean"){
          ponding_net=ponding_gross
        } else{
          ponding_net=ifelse(OWET[a]<=ponding_gross, ponding_gross-OWET[a], 0)
        }
        ponding_in=ponding_net
        
        

        
        
        
        
        # 1st step. increment of Soil Moisture due to Precipitation input----------------------------------------------------------------------
        
        deficit_meteo <- (soil_SAT-moisture) * daily_rooting_depth * 1000 - prec_eff
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
        
        
        

        
        
        
        # 6th step. calculation of Actual Evapotranspiration
        ETc <-ET0[a] * kc  
        ETa <- ET0[a] * kc  * ks
        
        
        
        
        
        
        
        # 7th step. reduction of Soil Moisture due to Actual Evapotranspiration-----------------------------------------------------------
        
        deficit_final<-def_function(deficit_meteo,SAT_daily_limit,ETa,DP)
        deficit_final_limit<-def_lim_function(TAW,ks,RAW)
        
   
        
        
        
        
        
        # 8th step. Calculation of evapotranspiration components and irrigation requirements------------------------------------------------------
        
        ETa_rf[a] <-ETa #ETa rainfed (If i never irrigate, but it only depends on precipitation)
        
        ETa_full[a] <-ETc #ETa in field capacity condition (ks=1)
    
        Irr_req[a] <- irrigation_function(Dr,a)
        
        
        
        
        
        #Decide when to assess the irrigation
        Irr_sched[a] <-irr_sched_function(RAW,irr_threshold_array,a,duration_past,Dr,date,Irr_req)
        
      
  
        
        
        # Re-initialize the loop for the the calculation of soil moisture of the next step (for future data, where SM is unknown)
        
          moisture_new <- soil_SAT - (deficit_final - Irr_sched[a])/daily_rooting_depth/1000
          moisture_new <- ifelse(moisture_new>soil_SAT,soil_SAT,ifelse(moisture_new<theta_wp,theta_wp,moisture_new))
          
          
          moisture_i=moisture_new
        
        
        
        
    
        
        # update summary table
        summary_table[a,which(colnames(summary_table)=="Date")]=as.character(date[a])
        summary_table[a,which(colnames(summary_table)=="ET0")]=ET0[a]
        summary_table[a,which(colnames(summary_table)=="precipitation")]=precipitation[a]
        summary_table[a,which(colnames(summary_table)=="P_eff")]=prec_eff
        summary_table[a,which(colnames(summary_table)=="ponding")]=ponding_net
        summary_table[a,which(colnames(summary_table)=="DP")]=DP
        summary_table[a,which(colnames(summary_table)=="moisture")]=moisture
        summary_table[a,which(colnames(summary_table)=="Deficit meteo")]=deficit_meteo
        summary_table[a,which(colnames(summary_table)=="SAT_daily")]=SAT_daily
        summary_table[a,which(colnames(summary_table)=="theta_fc")]=theta_fc*daily_rooting_depth*1000
        summary_table[a,which(colnames(summary_table)=="TAW")]=TAW
        summary_table[a,which(colnames(summary_table)=="RAW")]=RAW
        summary_table[a,which(colnames(summary_table)=="kc")]=kc
        summary_table[a,which(colnames(summary_table)=="ks")]=ks
        summary_table[a,which(colnames(summary_table)=="Dr")]=Dr[a]
        summary_table[a,which(colnames(summary_table)=="ETc")]=ETc
        summary_table[a,which(colnames(summary_table)=="ETa")]=ETa
        summary_table[a,which(colnames(summary_table)=="Deficit final")]=deficit_final
        summary_table[a,which(colnames(summary_table)=="Irr_req")]=Irr_req[a]
        summary_table[a,which(colnames(summary_table)=="Irr_sched")]=Irr_sched[a]
        summary_table[a,which(colnames(summary_table)=="moisture_new")]=moisture_new
     }
    
    
    #### ESTIMATE IRRIGATION VOLUME OVER THE IRRIGATED AREAS OF THE BASIN
    
    
  
    
    
    
    # DEFINE WETTED AREA (percentage of irrigated area with respect to crop area ###########################################################
    
    Area_crop <- cultivated_area_basin[which(cultivated_area_basin$crop ==crop),2]
    
    #fraction of area which is irrigated 
    if (irr_method=="S"){
      f=1
    } else if (irr_method=="D" | irr_method=="Sub"){
      f=0.5
    } else{
      f=1
    }
    
    Area_irr=Area_crop*f
    
    
    # IRRIGATION VOLUME----------------------------------------
    # irrigation efficiency ---
    if(irr_method=="SUR"){
      eff_irr=0.65
      
    } else if(irr_method=="SPR"){
      eff_irr=0.75
      
    } else if(irr_method=="DRIP"){
      eff_irr=0.90
      
    } else if(irr_method=="SUB"){
      eff_irr=0.95
      
    }
    #BUILD IRRIGATION ARRAY 
    
    Irr_vol_matrix[which(colnames(Irr_vol_matrix)==crop)]= Irr_sched*Area_irr/eff_irr
    
    
    
  } 

 Irr_vol_tot=data.frame(Irr_tot =rowSums(Irr_vol_matrix,na.rm = TRUE))
 Irr_vol_tot<-cbind(date,Irr_vol_tot)

 Irr_vol_matrix<-cbind(date,Irr_vol_matrix)



#################################################################################################################    
################################# RESULTS EXPORT #############################################################

write.table(Irr_vol_tot,paste(out_dir,"Irr_vol_tot",scenario,".csv",sep=""),row.names = FALSE,col.names = FALSE,sep = ";")
write.table(Irr_vol_matrix,paste(out_dir,"Irr_vol_matrix",scenario,".csv",sep=""),row.names = FALSE,col.names = TRUE,sep = ";")
 

}

