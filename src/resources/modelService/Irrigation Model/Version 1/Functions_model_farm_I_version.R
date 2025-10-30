
#### Calculate ET0 with FAO method

FAO_ET0_function <- function (lat,temp,sw_rad,wind,RH,elev,date,hh,Units_T,Units_Rs,Units_wind,Units_RH,Units_z) 
{

  Units_T="C"
  Units_Rs="W/m2"
  Units_wind="m/s"
  Units_RH="%"
  Units_z="m"
  
  
  #convertire dati climatici nell'unità di misura corretta
  

  
  units(temp)<-Units_T
  units(temp)<-"C"
  temp<-drop_units(temp)
  units(SW_rad)<-Units_Rs
  units(SW_rad)<-"MJ/m2/h"
  SW_rad<-drop_units(SW_rad)
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
  Rns <- (1 - 0.23) * SW_rad
  sigma <- 4.903 * 10^-9/24 #Stefan Boltzman constant for hourly time step
  
  ratio<-SW_rad/rso
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

P_eff<-function(daily_rooting_depth,soil_AWC,moisture_mean,ET0,a,precipitation){
  
    #ETa_full[i,day]=ifelse(day==1,0,ETa_full[i,day]) #if day=1 there is no ETa
    #deficit=ifelse(a==1,(soil_AWC-moisture_mean)*1000*daily_rooting_depth,deficit_final)
    deficit=(soil_AWC-moisture_mean)*1000*daily_rooting_depth
    
    prec_eff=ifelse(precipitation[a]<=0.2*ET0[a],0,ifelse(precipitation[a]<deficit,precipitation[a],deficit)) 
    
  
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

ws_coeff<-function(TAW,deficit_meteo,RAW){
  ks <- (TAW - deficit_meteo) / (TAW - RAW)
  ks[is.nan(ks)] <- 0
  ks[ks<0] <-0
  ks[ks > 1] <- 1
  
  return(ks)
}



#### Deficit final & deficit_final_limit

def_function<-function(deficit_meteo,TAW,ETa){
  deficit_final <- ifelse(deficit_meteo >= 0 & deficit_meteo <= TAW,
                          deficit_meteo + ETa,
                          ifelse(deficit_meteo > TAW,
                                 TAW,
                                 deficit_meteo))
  return(deficit_final)
}

def_lim_function<-function(TAW,ks,RAW){
  deficit_final_limit <- TAW - ks * (TAW - RAW) #Deficit_max=RAW
  return(deficit_final_limit)
}


#### irrigation requirement

irrigation_function<-function(ETa_rf,a,ETa_full,deficit_final,deficit_final_limit,ETa){
  irrigation <- ifelse(ETa_rf[a]<=ETa_full[a],ETa_full[a]-ETa_rf[a],0) #irrigazione da applicare per riportare ETa alle condizioni di field capacity. 
  
  

  
  # - wat_soil: additional water required to bring soil moisture at the specific defined level, when the deficit exceedes the
  # evapotranspiration 
  # !!! THIS SITUATION TYPICALLY HAPPENS ON THE SOWING DAY, WHEN INITIAL SOIL MOISTURE CAN BE VERY LOW, AND irrigation MAY BE INSUFFICIENT TO BRING SOIL MOISTURE OUT OF STRESS LIMITS.
  
  #wat_soil = ifelse((deficit_final-deficit_final_limit)>=0 & (deficit_final-deficit_final_limit)>=ETa, deficit_final-deficit_final_limit-irrigation,0)
  
  Irr_req[a] <- irrigation #+ wat_soil
  
  return(Irr_req[a])
}


