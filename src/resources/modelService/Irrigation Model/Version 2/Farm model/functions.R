###################################################################################################################################à
#################################### FUNCTION FOR SOIL WATER BALANCE MODEL ##################################################



#### Estimate future soil moisture with Random forest regression

forecast_SM <- function(duration_past,sensor_levels,moisture_sensor_raw,duration_fut){
  
  
  
  
  

  
  for(ii in 1:ncol(moisture_sensor_raw)){
    
    
    
    #create lagged SM variables
    dataset_model$SM_min1 <-dplyr::lag(dataset[,ii],n=1)
    dataset_model$SM_min2 <-dplyr::lag(dataset[,ii],n=2)
    dataset_model$SM_min3 <-dplyr::lag(dataset[,ii],n=3)
    
    
    predictions=NA

    
    for (i in 1:duration_fut){
      
      train_size <-ceiling(0.8*(duration_past-3)) #80% of dataset is for training
      
      #split into training and testing
      train_data <- dataset_model[(i+3):(i+3+train_size),]
      test_data <- dataset_model[(i+3+train_size+1):(duration_past+i),]
      
      
      #Create model
      rf_model <- randomForest(data= train_data, 
                               train_data[,ii] ~  SM_min1 + SM_min2 + SM_min3 + temp + prec + SW + RH + wind + irrigation,
                               ntree=500, #number of trees
                               mtry=3,    #numero di variabili usate per ogni split
                               importance=TRUE) #importance of variables
      
      predictions <- predict(rf_model, newdata = test_data)

      
      #Compare results with real data
      #test_actual <- dataset[(i+3+train_size+1):(duration_past+i),ii]

      
      dataset_model[duration_past+i,ii]=predictions[length(predictions)]
    }
    
    
    
  }
  
  
  return(dataset_model)
}





#### Calculate ET0 with FAO method

FAO_ET0_function <- function (lat,temp,sw_rad,wind,RH,elev,date,hh,Units_T,Units_Rs,Units_wind,Units_RH,Units_z) 
{

  # Units_T="°C"
  # Units_Rs="W/m2"
  # Units_wind="m/s"
  # Units_RH="%"
  # Units_z="m"
  
  
  #convertire dati climatici nell'unità di misura corretta
  

  
  units(temp)<-Units_T
  units(temp)<-"°C"
  temp<-drop_units(temp)
  units(sw_rad)<-Units_Rs
  units(sw_rad)<-"MJ/m2/h"
  sw_rad<-drop_units(sw_rad)
  units(wind)<-Units_wind
  units(wind)<-"m/s"
  wind<-drop_units(wind)
  units(elev)<-Units_z
  units(elev)<-"m"
  elev<-drop_units(elev)
  
    RH<-as.numeric(unlist(RH))
    units(RH)<-Units_RH
    units(RH)<-"%"
    RH<-drop_units(RH)

  
  #ET0 calculation
  
  delta <- (4098 * (0.6108 * exp(17.27 * temp/(temp + 237.3))))/(temp + 
                                                                     237.3)^2
  # atmospheric pressure [KPa]
  Patm <- 101.3 * ((293 - 0.0065 * elev) / 293)^5.26
  
  psy_constant <- 0.000665 * Patm
  DT = (delta/(delta + psy_constant * (1 + 0.34 * wind)))
  PT <- (psy_constant)/(delta + psy_constant * (1 + 0.34 * 
                                                  wind))
  TT <- (37/(temp + 273)) * wind
  
  # Saturation vapor Pressure [KPa]
  es_Tx <- 0.6108 * exp((17.27 * temp)/(temp + 237.3))   
  
  
  #Relative humidity

  ea <- RH/100 * (es_Tx) # if we have relative humidity as an input
  
  
  
  j <- as.numeric(strftime(date, format= "%j"))
  dr <- 1 + 0.033 * cos(2 * pi * j/365)
  solar_decli <- 0.409 * sin((2 * pi * j/365) - 1.39)
  lat_rad <- (pi/180) * lat
  ws <- acos(-tan(lat_rad) * tan(solar_decli))
  N=24/pi*ws #number of daylight hours
  
  Lz=15
  Lm=8.6
  b=2*pi*(j-81)/364
  Sc=0.1645*sin(2*b)-0.1255*cos(b)-0.025*sin(b)
  t=hh+0.5
  w=pi/12*((t+0.06667*(Lz-Lm)+Sc)-12)
  w1=w-pi*1/24
  w2=w+pi*1/24
  Gsc=0.0820
  
  ra <- (12 * (60)/pi) * Gsc * dr * (((w2-w1) * sin(lat_rad) * 
                                        sin(solar_decli)) + (cos(lat_rad) * cos(solar_decli) * (sin(w2)-sin(w1))))
  rso <- (0.75 + (2 * 10^-5) * elev) * ra
  Rns <- (1 - 0.23) * sw_rad
  sigma <- 4.903 * 10^-9/24 #Stefan Boltzman constant for hourly time step
  
  ratio<-sw_rad/rso
  ratio[w>ws | w< -ws] <- 0.5
  ratio[ratio>=1]=1
 
  Rnl <- sigma * temp^4 * 
    (0.34 - 0.14 * sqrt(ea)) * (1.35 * ratio - 0.35)
  Rn <- Rns - Rnl
  
  G=array(0.5*Rn,dim=length(j)) #create array of solar latent heat flux (0.5*Rn refers to daylight values)
  G[w>ws | w< -ws]=0.1*Rn[w>ws | w< -ws] #correct the value for nighttime period
  
  Rng <- 0.408 * (Rn-G)
  ETrad <- DT * Rng
  ETwind <- PT * TT * (es_Tx - ea)
  ET0 <- ETwind + ETrad
  ET0[ET0<0]=0
  ET0=as.numeric(ET0)
  
  #Calculation of Open water evaporation
  #Vapor pressure deficit
  VPD= es_Tx - ea
  # Bulk Aerodynamic Expression [Mj m-2]
  Ba = 6.43 * (0.5 + (0.54 * wind * 0.75)) * VPD

  emiss_water <- 0.92   #NB: costant
  Rls <- (Rnl * emiss_water) - (0.0000000567 * emiss_water * ((temp + 273.15) ^ 4))
  Qt <- array(0,dim=length(temp))
  for (i in 1:length(j)) {
    #if the month is July or not
    if (j[i] < 183) {Qt[i] = (0.5 * Rns + 0.8 * Rls)}
    if (j[i] >= 183) {Qt[i] = (0.5 * Rns + 1.3 * Rls)}
  }
  # Open Water ET [mm day-1], hourly
  OWET = ((0.408 * 0.0864 * ((Rns + Rls)- Qt) * delta) + (Ba * psy_constant)) / (delta + psy_constant)
  OWET[OWET<0]=0
  OWET=as.numeric(OWET)
  
  
  Evapotranspiration <- list("ET0"=ET0,"OWET"=OWET)
  
  return(Evapotranspiration)
}



#### Calculate Rooting depth development 

RD_increment<-function(s,h,day,L12,RD,L12_den,type){
  if (type==1){
    
    #annual crops
    daily_rooting_depth <- ifelse(s<h & s<=day & (s+L12-1)>day,((RD[2]-RD[1])/(L12_den))*(day-s+1)+RD[1],0)+
      ifelse(s<h & (s+L12-1)<=day & day<=h, RD[2],0)+
      
      ifelse(s>h & s<=day & (s+L12-1)>day, ((RD[2]-RD[1])/(L12_den))*(day-s+1)+RD[1],0)+
      ifelse(s>h & (h-(LGP-L12))>day,((RD[2]-RD[1])/(L12_den))*(day-s+1)+RD[1],0)+
      
      ifelse(s>h & (s+L12-1)<=day, RD[2],0)+
      ifelse(s>h & h>=day & (h-(LGP-L12))<=day,RD[2],0)
    
    
  } else if(type==2){
    #perennial crops
    
    daily_rooting_depth <- RD[2]
    
    
  }
  
  return(daily_rooting_depth)
  
}




#### Effective precipitation

P_eff<-function(daily_rooting_depth,soil_AWC,moisture_mean,ET0,a,precipitation,irr_given_mm){
  
    #ETa_full[i,day]=ifelse(day==1,0,ETa_full[i,day]) #if day=1 there is no ETa
    #deficit=ifelse(a==1,(soil_AWC-moisture_mean)*1000*daily_rooting_depth,deficit_final)
    deficit=(soil_AWC-moisture_mean)*1000*daily_rooting_depth
    
    prec_eff=ifelse((precipitation[a]+irr_given_mm)<=0.2*ET0[a],0,ifelse((precipitation[a]+irr_given_mm)<deficit,precipitation[a]+irr_given_mm,deficit)) 
    
  
  return(prec_eff)
} 



#### Crop coefficient

crop_coeff<-function(s,h,day,L1,L12,L123,L2_den,L4_den,LGP,kc_in,kc_mid,kc_end){
  #Le prime 4 righe rappresentano un crop che si sviluppa nell'anno
  kc= ifelse(h>s & day>=s & day<(s+L1-1), kc_in,0) +
    ifelse(h>s & day>=(s+L1-1) & day<(s+L12-1), kc_in+((day-(s+L1)+1)/L2_den)*(kc_mid-kc_in),0) +
    ifelse(h>s & day>=(s+L12-1) & day<(s+L123-1), kc_mid,0)+
    ifelse(h>s & day>=(s+L123-1) & day<=h, kc_mid+((day-(s+L123)+1)/L4_den)*(kc_end-kc_mid),0) +
    
    #Queste righe rappresentano un crop che si sviluppa a cavallo di 2 anni
    #L1
    ifelse(h<s & day>=s & day<(s+L1-1), kc_in,0) + #i giorni da s a fine anno
    ifelse(h<s & day<(h-(LGP-L1)), kc_in,0) + #i giorni da fine anno a L1
    #L2
    ifelse(h<s & day>=(s+L1-1) & day<(s+L12-1), kc_in+((day-(s+L1)+1)/L2_den)*(kc_mid-kc_in),0) +
    ifelse(h<s & day>=(h-(LGP-L1)) & day<(h-(LGP-L12)), kc_in+((366-s-L1+day)/L2_den)*(kc_mid-kc_in),0) +
    #L3
    ifelse(h<s & day>=(s+L12-1) & day<(s+L123-1), kc_mid,0)+
    ifelse(h<s & day>=(h-(LGP-L12)) & day<(h-(LGP-L123)), kc_mid,0)+
    #L4
    ifelse(h<s & day>=(s+L123-1) & day<=(s+LGP-1), kc_mid+((day-(s+L123)+1)/L4_den)*(kc_end-kc_mid),0) +
    ifelse(h<s & day>=(h-(LGP-L123)) & day<=h, kc_mid+((366-s-L123+day)/L4_den)*(kc_end-kc_mid),0)
  
  return(kc)
}



#### water stress coefficient

ws_coeff<-function(TAW,Dr,RAW){
  ks <- (TAW - Dr) / (TAW - RAW)
  ks[is.nan(ks)] <- 0
  ks[ks<0] <-0
  ks[ks > 1] <- 1
  
  return(ks)
}






### kc corrected function 

kc_corr_function=function(a,kc,kc_corr,irr_given_vol,moisture_LOW,duration_past){
  
  
  
  #=======================================================================================================
  ####### find natural fluctuations (standard deviation) of moisture_LOW levels far from irrigation events ===========================================================================
  
  irrigation_past<-irr_given_vol[1:duration_past]
  
  #Find all the time steps before an irrigation event 
  x_prev<-NULL
  for(pos in 1:duration_past){
    if (pos > 24 && sum(irrigation_past[(pos-24):pos]) == 0) {     # if there is no irrigation in the 24 h before position x, then pick up the 5 last 5 values
      x <- c((pos - 5):(pos - 1),x_prev)
    } else {
      x <-x_prev
    }
    x_prev<-x
  }
  x<-sort(unique(x))
  
  if(length(x)<24){
    
    #cat("Irrigation events are happening for most (or all) the time period, so it's not possible to detect fluctuations of moisture_LOW levels")
    sd_base=sd(moisture_LOW[irrigation_past==0])
    
  }else{
  
      sd_base=sd(moisture_LOW[x]) 
  
  }
  
  
  
  #==================================================================================================================
  # Perform the assessment of kc correction
  
  if( a < duration_past | a > (duration_past+24) ){
    
    kc_corrected=1
    
  } else{
    
    #do the ratio between the standard deviation of moisture_LOW of the last 48 hours over the base one (with natual fluctuations)
    ratio_sd=sd(moisture_LOW[(a-24):a])/sd_base
    
    ## If there is percolation
    if(ratio_sd>2){ 
      #if the ratio between the standard deviation of moisture level (at 80 cm below surface) 24 hours after irrigation and the standard deviation of moisture in a period without irrigation is greater than 2, then correct kc
      
      kc_corrected=kc_corr[a-1]*0.9 #or write kc=kc-0.1?
      
    } else{ ## No percolation
      
        kc_corrected=1
      
    }
    
  }
  
  # CHeck that kc_corrected doesn't diverge too much (or too big or too low)
  if(kc_corrected<(0.5*kc)){
    kc_corrected=0.5*kc
  } else{
    kc_corrected = kc_corrected
  }
  
  return(kc_corrected)
  
}



#### Deficit final & deficit_final_limit

def_function<-function(deficit_meteo,AWC_limit,ETa,DP){
  deficit_final <- ifelse(deficit_meteo >= 0 & deficit_meteo <= AWC_limit,
                          deficit_meteo + ETa + DP,
                          ifelse(deficit_meteo > AWC_limit,
                                 AWC_limit,
                                 deficit_meteo+ETa+DP))
  return(deficit_final)
}

def_lim_function<-function(TAW,ks,a,RAW){
  deficit_final_limit <- TAW - ks[a] * (TAW - RAW) #Deficit_min=RAW
  return(deficit_final_limit)
}


#### irrigation requirement

irrigation_function<-function(ETa_rf,a,ETa_full,Dr,RAW){
  if(ETa_rf[a]<ETa_full[a]){
    irrigation <-  Dr - RAW #irrigazione da applicare per riportare ETa alle condizioni di field capacity. 
  } else{
    irrigation <- 0
  }
  
  

  
  # - wat_soil: additional water required to bring soil moisture at the specific defined level, when the deficit exceedes the
  # evapotranspiration 
  # !!! THIS SITUATION TYPICALLY HAPPENS ON THE SOWING DAY, WHEN INITIAL SOIL MOISTURE CAN BE VERY LOW, AND irrigation MAY BE INSUFFICIENT TO BRING SOIL MOISTURE OUT OF STRESS LIMITS.
  
  #wat_soil = ifelse((deficit_final-deficit_final_limit)>=0 & (deficit_final-deficit_final_limit)>=ETa, deficit_final-deficit_final_limit-irrigation,0)
  
  Irr_req[a] <- irrigation #+ wat_soil
  
  return(Irr_req[a])
}




#### irrigation volume 

Irr_vol_function<-function(irr_method,Irr_req,a,Area_irr){
  
  
  # irrigation efficiency ---
  if(irr_method=="sprinkler"){
    eff_irr=0.75
  
    Irr_vol[a] <- (Irr_req[a]/eff_irr) * (Area_irr) /1000  #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    
    } else if(irr_method=="drip"){
    eff_irr=0.90
    

    Irr_vol[a] <- (Irr_req[a]/eff_irr) * (Area_irr) /1000  #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    # I divide for the number of drip per line so that the wetted length reduces if there are 2 dripping lines per crop line 
    
    
  } else if(irr_method=="subterranean"){
    eff_irr=0.99
    

    Irr_vol[a] <- (Irr_req[a]/eff_irr) * (Area_irr) /1000  #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    # I divide for the number of drip per line so that the wetted length reduces if there are 2 dripping lines per crop line 
    
  }
  
  
  
  return(Irr_vol[a])
  
  
}





#### Deep percolation

percolation_function=function(DP,irr_method,Area_irr,daily_rooting_depth){
  if(irr_method=="sprinkler"){

    
    Irr_vol_percolated <- DP /1000 /daily_rooting_depth * (Area_irr)  #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    
  } else if(irr_method=="drip"){
    
    
    
    Irr_vol_percolated <- DP /1000 /daily_rooting_depth * (Area_irr) #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    
    
  } else if(irr_method=="subterranean"){
    
    
    Irr_vol_percolated <- DP /1000 /daily_rooting_depth * (Area_irr) #irrigation volume in m3 (1000 is for the passage from mm of Irr_req to m)
    
  }
}
