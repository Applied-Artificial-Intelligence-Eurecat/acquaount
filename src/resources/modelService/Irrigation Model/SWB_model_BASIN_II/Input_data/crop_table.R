##################################### CREAZIONE DATI DI INPUT #############################################



###################################### AWC ##########################################################à
#Selezioniamo i punti di interesse e la loro AWC (in questo esempio, prendiamo solo 5 punti)
#I dati di AWC vengono presi dalla mappa di available soil water capacity di zenodo 

# 
# library(raster)
# AWC_raster=raster("C:/Users/Andrea/Desktop/Dottorato_Sassari/modello ACQUAOUNT/sol_available.water.capacity_usda.mm_m_250m_0..200cm_1950..2017_v0.1.tif")
# AWC_crop=crop(AWC_raster,extent(c(-11,29,41,51))) #qui abbiamo definito l'intervallo del mediterraneo nel raster di Zenodo
# AWC_mediterranean=rasterToPoints(AWC_crop) #Questa fiunzione converte il raster in una tabella/array con x,y,AWC
# 
# 
# lon_user=c(-4.151) #longitudine
# lat_user=c(41.314) #inserire latitudine delle zone di interesse
# lon=AWC_mediterranean[which.min(abs(AWC_mediterranean[,1]-lon_user)),1] #estrai il valore più vicino a quelli inseriti dall'user
# lat=AWC_mediterranean[which.min(abs(AWC_mediterranean[,2]-lat_user)),2]
# 
# AWC=as.numeric(AWC_mediterranean[AWC_mediterranean[,1]==lon & AWC_mediterranean[,2]==lat,3])/1000 #estrai il punto di AWC del punto selezionato e converti in m3/m3 (da mm/m)








########################################## CROP ##########################################################à
# % 1 - wheat
# % 2 - maize
# % 3 - rice
# % 4 - barley
# % 5 - sorghum
# % 6 - soybean
# % 7 - sunflower
# % 8 - potato
# % 9 - citrus
# % 10 - date palm
# % 11 - grapes
# % 12 - cotton
# % 14 - fodder  grasses
# % 15 - others perennial
# % 16 - others annual


#Definire zona climatica in cui andrò ad inserire dei valori di Kc e rooting depth per ogni zona
#In questo caso immaginiamo di avere a che fare con 3 zone climatiche: 

# 1: Mediterranean
# 2: Arid
# 3: -

clim=c(1,2,3) #3 climatic zones
code=c(rep(1111,length(clim)),rep(113,length(clim)),rep(112,length(clim)),rep(114,length(clim)),rep(1152,length(clim)),
       rep(14202,length(clim)),rep(14204,length(clim)),rep(121,length(clim)),rep(15210,length(clim)),rep(2113,length(clim)),rep(21605,length(clim)),
       rep(2141,length(clim)),rep(2223,length(clim)),rep(1441,length(clim)),rep(1711,length(clim)),rep(991,length(clim)),rep(992,length(clim)),rep(991,length(clim))) #FAO codes https://www.fao.org/3/a0135e/A0135E10.htm#note13.2 . I codici di Perennial e temporary crops sono inventati
crop_list=list("wheat","maize","rice","barley","sorghum","soybean","sunflower","potato","tomato","citrus","date_palm","wine_grapes","olives","cotton","alfalfa","pastures", "perennial","temporary")

crop=rep(crop_list,each=length(clim))

#Adesso bisogna solo riempire la tabella dei Kc di numeri per ogni zona climatica + la percentuale degli stage del length of growing period


columns=list("Code","Crop","Clim","Kc_in","Kc_mid","Kc_end","lgp_f1","lgp_f2","lgp_f3","lgp_f4","Season_start","Season_End","RD1","RD2","DF","Type","Irrigation","Irr_def_1","Irr_def_2","Irr_def_3","Early_irr", "Late_irr", "Limit_irr") 
crop_table=data.frame(matrix(nrow=length(code),ncol=length(columns)))#creo dataframe
colnames(crop_table)=columns
  
crop_table$Code <- code
crop_table$Crop <-crop
crop_table$Clim <-rep(clim,length(crop_list))





#Type 1: annual crop, type 2: perennial crop
#Wheat
valori_kc_wheat=matrix(c(0.700000000000000,1.15000000000000,0.300000000000000,0.700000000000000,1.15000000000000,0.300000000000000,0.700000000000000,1.15000000000000,0.300000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_wheat=matrix(c(0.111111111111111,0.333333333333333,0.388888888888889,0.166666666666667,0.477611940298507,0.223880597014925,0.223880597014925,0.0746268656716418,0.111111111111111,0.333333333333333,0.388888888888889,0.166666666666667),nrow=3,ncol=4,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_season_wheat=rep(c(335,167),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_wheat=rep(c(0.2,1.25),each=length(clim))
valori_DF_wheat=rep(0.55,each=length(clim))
valori_type_wheat=rep(1,each=length(clim))
valori_irr_wheat=rep("SPR",each=length(clim))
valori_irr_def_wheat=rep(0.5,each=length(clim))
valori_irr_thresh_wheat=rep(c(0,0.2,0.5),each=length(clim))

#Maize
valori_kc_maize=matrix(c(0.300000000000000,1.20000000000000,0.500000000000000, 0.300000000000000,1.20000000000000,0.500000000000000, 0.300000000000000,1.20000000000000,0.500000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_maize=matrix(c(0.200000000000000,0.266666666666667,0.333333333333333,0.200000000000000,0.200000000000000,0.266666666666667,0.333333333333333,0.200000000000000,0.200000000000000,0.266666666666667,0.333333333333333,0.200000000000000),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_maize=rep(c(150,300),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_maize=rep(c(0.2,1),each=length(clim))
valori_DF_maize=rep(0.55,each=length(clim))
valori_type_maize=rep(1,each=length(clim))
valori_irr_maize=rep("SPR",each=length(clim))
valori_irr_def_maize=rep(1,each=length(clim))
valori_irr_thresh_maize=rep(c(0,0.2,0.5),each=length(clim))

#Rice
valori_kc_rice=matrix(c(1.05000000000000,1.20000000000000,0.600000000000000,1.05000000000000,1.20000000000000,0.900000000000000,1.05000000000000,1.20000000000000,0.900000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_rice=matrix(c(0.166666666666667,0.166666666666667,0.444444444444444,0.222222222222222,0.166666666666667,0.166666666666667,0.444444444444444,0.222222222222222,0.200000000000000,0.200000000000000,0.400000000000000,0.200000000000000),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_rice=rep(c(116,270),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_rice=rep(c(0.2,0.5),each=length(clim))
valori_DF_rice=rep(0.2,each=length(clim))
valori_type_rice=rep(1,each=length(clim))
valori_irr_rice=rep("SUR",each=length(clim))
valori_irr_def_rice=rep(1,each=length(clim))
valori_irr_thresh_rice=rep(c(0,0.2,0.5),each=length(clim))

#Barley
valori_kc_barley=matrix(c(0.300000000000000,1.15000000000000,0.250000000000000,0.300000000000000,1.15000000000000,0.250000000000000,0.300000000000000,1.15000000000000,0.250000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_barley=matrix(c(0.111111111111111,0.333333333333333,0.388888888888889,0.166666666666667,0.477611940298507,0.223880597014925,0.223880597014925,0.0746268656716418,0.111111111111111,0.333333333333333,0.388888888888889,0.166666666666667),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_barley=rep(c(335,167),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_barley=rep(c(0.2,1),each=length(clim))
valori_DF_barley=rep(0.55,each=length(clim))
valori_type_barley=rep(1,each=length(clim))
valori_irr_barley=rep("SPR",each=length(clim))
valori_irr_def_barley=rep(0.5,each=length(clim))
valori_irr_thresh_barley=rep(c(0,0.2,0.5),each=length(clim))

#Sorghum
valori_kc_sorghum=matrix(c(0.300000000000000,1,0.550000000000000,0.300000000000000,1,0.550000000000000,0.300000000000000,1,0.550000000000000,0.300000000000000,1,0.550000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_sorghum=matrix(c(0.160000000000000,0.280000000000000,0.320000000000000,0.240000000000000,0.160000000000000,0.280000000000000,0.320000000000000,0.240000000000000,0.153846153846154,0.269230769230769,0.346153846153846,0.230769230769231),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_sorghum=rep(c(92,245),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_sorghum=rep(c(0.2,1),each=length(clim))
valori_DF_sorghum=rep(0.55,each=length(clim))
valori_type_sorghum=rep(1,each=length(clim))
valori_irr_sorghum=rep("SPR",each=length(clim))
valori_irr_def_sorghum=rep(0.2,each=length(clim))
valori_irr_thresh_sorghum=rep(c(0,0.2,0.5),each=length(clim))

#Soybean
valori_kc_soybean=matrix(c(0.400000000000000,1.15000000000000,0.500000000000000,0.400000000000000,1.15000000000000,0.500000000000000,0.400000000000000,1.15000000000000,0.500000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_soybean=matrix(c(0.148148148148148,0.222222222222222,0.444444444444444,0.185185185185185,0.133333333333333,0.166666666666667,0.500000000000000,0.200000000000000,0.133333333333333,0.166666666666667,0.500000000000000,0.200000000000000),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_soybean=rep(c(122,274),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_soybean=rep(c(0.2,0.6),each=length(clim))
valori_DF_soybean=rep(0.50,each=length(clim))
valori_type_soybean=rep(1,each=length(clim))
valori_irr_soybean=rep("SPR",each=length(clim))
valori_irr_def_soybean=rep(1,each=length(clim))
valori_irr_thresh_soybean=rep(c(0,0.2,0.5),each=length(clim))

#Sunflower
valori_kc_sunflower=matrix(c(0.350000000000000,1.15000000000000,0.350000000000000,0.350000000000000,1.15000000000000,0.350000000000000,0.350000000000000,1.15000000000000,0.350000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_sunflower=matrix(c(0.192307692307692,0.269230769230769,0.346153846153846,0.192307692307692,0.192307692307692,0.269230769230769,0.346153846153846,0.192307692307692,0.192307692307692,0.269230769230769,0.346153846153846,0.192307692307692),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_sunflower=rep(c(75,228),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_sunflower=rep(c(0.2,0.8),each=length(clim))
valori_DF_sunflower=rep(0.45,each=length(clim))
valori_type_sunflower=rep(1,each=length(clim))
valori_irr_sunflower=rep("SPR",each=length(clim))
valori_irr_def_sunflower=rep(1,each=length(clim))
valori_irr_thresh_sunflower=rep(c(0,0.2,0.5),each=length(clim))

#Potato
valori_kc_potato=matrix(c(0.500000000000000,1.15000000000000,0.750000000000000,0.500000000000000,1.15000000000000,0.750000000000000,0.500000000000000,1.15000000000000,0.750000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_potato=matrix(c(0.192307692307692,0.230769230769231,0.346153846153846,0.230769230769231,0.206896551724138,0.241379310344828,0.344827586206897,0.206896551724138,0.192307692307692,0.230769230769231,0.346153846153846,0.230769230769231),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_potato=rep(c(75,167),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_potato=rep(c(0.2,0.4),each=length(clim))
valori_DF_potato=rep(0.35,each=length(clim))
valori_type_potato=rep(1,each=length(clim))
valori_irr_potato=rep("DRIP",each=length(clim))
valori_irr_def_potato=rep(0.7,each=length(clim))
valori_irr_thresh_potato=rep(c(0,0.2,0.5),each=length(clim))

#tomato
valori_kc_tomato=matrix(c(0.15,1.10,0.7, 0.15,1.10,0.7, 0.15,1.10,0.7),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_tomato=matrix(c(0.206896552,0.275862069,0.310344828,0.206896552, 0.206896552,0.275862069,0.310344828,0.206896552, 0.206896552,0.275862069,0.310344828,0.206896552),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_tomato=rep(c(121,227),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_tomato=rep(c(0.4,1.5),each=length(clim))
valori_DF_tomato=rep(0.4,each=length(clim))
valori_type_tomato=rep(1,each=length(clim))
valori_irr_tomato=rep("DRIP",each=length(clim))
valori_irr_def_tomato=rep(1,each=length(clim))
valori_irr_thresh_tomato=rep(c(0,0.2,0.5),each=length(clim))

#Citrus
valori_kc_citrus=matrix(c(0.700000000000000,0.650000000000000,0.700000000000000,0.700000000000000,0.650000000000000,0.700000000000000,0.700000000000000,0.650000000000000,0.700000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_citrus=matrix(c(0.164383561643836,0.246575342465753,0.328767123287671,0.260273972602740,0.164383561643836,0.246575342465753,0.328767123287671,0.260273972602740,0.164383561643836,0.246575342465753,0.328767123287671,0.260273972602740),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_citrus=rep(c(75,335),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_citrus=rep(c(1.1,1.1),each=length(clim))
valori_DF_citrus=rep(0.5,each=length(clim))
valori_type_citrus=rep(2,each=length(clim))
valori_irr_citrus=rep("DRIP",each=length(clim))
valori_irr_def_citrus=rep(1,each=length(clim))
valori_irr_thresh_citrus=rep(c(0,0.2,0.5),each=length(clim))

#Date Palm
valori_kc_date_palm=matrix(c(0.900000000000000,0.950000000000000,0.950000000000000,0.900000000000000,0.950000000000000,0.950000000000000,0.900000000000000,0.950000000000000,0.950000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_date_palm=matrix(c(0.328767123287671,0.164383561643836,0.493150684931507,0.0136986301369863,0.328767123287671,0.164383561643836,0.493150684931507,0.0136986301369863,0.328767123287671,0.164383561643836,0.493150684931507,0.0136986301369863),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_date_palm=rep(c(150,300),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_date_palm=rep(c(1.5,1.5),each=length(clim))
valori_DF_date_palm=rep(0.5,each=length(clim))
valori_type_date_palm=rep(2,each=length(clim))
valori_irr_date_palm=rep("DRIP",each=length(clim))
valori_irr_def_date_palm=rep(1,each=length(clim))
valori_irr_thresh_date_palm=rep(c(0,0.2,0.5),each=length(clim))

#Grapes
valori_kc_wine_grapes=matrix(c(0.400000000000000,0.850000000000000,0.400000000000000,0.400000000000000,0.850000000000000,0.400000000000000,0.400000000000000,0.850000000000000,0.400000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_wine_grapes=matrix(c(0.0833333333333333,0.166666666666667,0.500000000000000,0.250000000000000,0.142857142857143,0.285714285714286,0.190476190476190,0.380952380952381,0.142857142857143,0.285714285714286,0.190476190476190,0.380952380952381),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_wine_grapes=rep(c(75,245),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_wine_grapes=rep(c(1,1),each=length(clim))
valori_DF_wine_grapes=rep(0.4,each=length(clim))
valori_type_wine_grapes=rep(2,each=length(clim))
valori_irr_wine_grapes=rep("DRIP",each=length(clim))
valori_irr_def_wine_grapes=rep(0.4,each=length(clim))
valori_irr_thresh_wine_grapes=rep(c(0,0.2,0.5),each=length(clim))

#Olives
valori_kc_olives=matrix(c(0.55,0.65,0.65, 0.55,0.65,0.65, 0.55,0.65,0.65),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_olives=matrix(c(0.111111111,0.333333333,0.222222222,0.333333333, 0.111111111,0.333333333,0.222222222,0.333333333, 0.111111111,0.333333333,0.222222222,0.333333333),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_olives=rep(c(75,245),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_olives=rep(c(1.5,1.5),each=length(clim))
valori_DF_olives=rep(0.65,each=length(clim))
valori_type_olives=rep(2,each=length(clim))
valori_irr_olives=rep("DRIP",each=length(clim))
valori_irr_def_olives=rep(1,each=length(clim))
valori_irr_thresh_olives=rep(c(0,0.2,0.5),each=length(clim))

#Cotton
valori_kc_cotton=matrix(c(0.350000000000000,1.20000000000000,0.600000000000000,0.350000000000000,1.20000000000000,0.600000000000000,0.350000000000000,1.20000000000000,0.600000000000000),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_cotton=matrix(c(0.153846153846154,0.256410256410256,0.307692307692308,0.282051282051282,0.153846153846154,0.256410256410256,0.307692307692308,0.282051282051282,0.153846153846154,0.256410256410256,0.307692307692308,0.282051282051282),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_cotton=rep(c(150,300),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_cotton=rep(c(0.2,1),each=length(clim))
valori_DF_cotton=rep(0.65,each=length(clim))
valori_type_cotton=rep(1,each=length(clim))
valori_irr_cotton=rep("SPR",each=length(clim))
valori_irr_def_cotton=rep(1,each=length(clim))
valori_irr_thresh_cotton=rep(c(0,0.2,0.5),each=length(clim))

#alfalfa
valori_kc_alfalfa=matrix(c(1,1,1,1,1,1,1,1,1),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_alfalfa=matrix(c(0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259,0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259,0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_alfalfa=rep(c(1,365),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_alfalfa=rep(c(1,1),each=length(clim))
valori_DF_alfalfa=rep(0.5,each=length(clim))
valori_type_alfalfa=rep(2,each=length(clim))
valori_irr_alfalfa=rep("SPR",each=length(clim))
valori_irr_def_alfalfa=rep(1,each=length(clim))
valori_irr_thresh_alfalfa=rep(c(0,0.2,0.5),each=length(clim))

#pastures
valori_kc_pastures=matrix(c(1,1,1,1,1,1,1,1,1),nrow=3,ncol=3,byrow=T) #specifica i valori più appropriati per il caso di studio
valori_lgp_pastures=matrix(c(0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259,0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259,0.0740740740740741,0.111111111111111,0.555555555555556,0.259259259259259),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_pastures=rep(c(1,365),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_pastures=rep(c(1,1),each=length(clim))
valori_DF_pastures=rep(0.6,each=length(clim))
valori_type_pastures=rep(2,each=length(clim))
valori_irr_pastures=rep("SPR",each=length(clim))
valori_irr_def_pastures=rep(0.4,each=length(clim))
valori_irr_thresh_pastures=rep(c(0,0.2,0.5),each=length(clim))

# others perennial
valori_kc_perennial=matrix(c(0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000,0.850000000000000),nrow=3,ncol=3,byrow=T)
valori_lgp_perennial=matrix(c(0.295890410958904,0.180821917808219,0.460273972602740,0.0630136986301370,0.295890410958904,0.180821917808219,0.460273972602740,0.0630136986301370,0.295890410958904,0.180821917808219,0.460273972602740,0.0630136986301370),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_perennial=rep(c(75,245 ),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_perennial=rep(c(0.8,0.8),each=length(clim))
valori_DF_perennial=rep(0.5,each=length(clim))
valori_type_perennial=rep(2,each=length(clim))
valori_irr_perennial=rep("DRIP",each=length(clim))
valori_irr_def_perennial=rep(1,each=length(clim))
valori_irr_thresh_perennial=rep(c(0,0.2,0.5),each=length(clim))

# others annual
valori_kc_temporary=matrix(c(0.700000000000000,1.05000000000000,0.950000000000000,0.700000000000000,1.05000000000000,0.950000000000000,0.700000000000000,1.05000000000000,0.950000000000000),nrow=3,ncol=3,byrow=T)
valori_lgp_temporary=matrix(c(0.150078988941548,0.235387045813586,0.396524486571880,0.218009478672986,0.220979020979021,0.232167832167832,0.337062937062937,0.209790209790210,0.160063391442155,0.242472266244057,0.366085578446910,0.231378763866878),nrow=3,ncol=4,byrow=T)#specifica i valori più appropriati per il caso di studio
valori_season_temporary=rep(c(121,227 ),each=length(clim)) #valori season per la Sardegna (per adesso)
valori_RD_temporary=rep(c(0.2,1),each=length(clim))
valori_DF_temporary=rep(0.5,each=length(clim))
valori_type_temporary=rep(1,each=length(clim))
valori_irr_temporary=rep("SPR",each=length(clim))
valori_irr_def_temporary=rep(1,each=length(clim))
valori_irr_thresh_temporary=rep(c(0,0.2,0.5),each=length(clim))




# Assegnazione valori nella tabella  
for(c in crop_list){
  i=which(c==crop_list)
  
  a=i*2+i-2
  b=i*3

  crop_table[c(a:b),c(4:6)]=get(paste("valori_kc_",c,sep=""))   #colonne da 3 a 5: kc values
  crop_table[c(a:b),c(7:10)]=get(paste("valori_lgp_",c,sep=""))  #colonne da 6 a 9: LGP values
  crop_table[c(a:b),c(11:12)]=get(paste("valori_season_",c,sep=""))  #colonne da 10 a 11: season values
  crop_table[c(a:b),c(13:14)]=get(paste("valori_RD_",c,sep=""))  #colonne da 12 a 13: rooting depth
  crop_table[c(a:b),15]=get(paste("valori_DF_",c,sep=""))  #colonne 14: Depletion factor
  crop_table[c(a:b),16]=get(paste("valori_type_",c,sep=""))  #colonne 15: Type (1, annual, 2, perennial)
  crop_table[c(a:b),17]=get(paste("valori_irr_",c,sep=""))  #colonne 17: irrigation type
  crop_table[c(a:b),c(18:20)]=get(paste("valori_irr_def_",c,sep=""))  #colonne 18-20: irrigation deficit
  crop_table[c(a:b),c(21:23)]=get(paste("valori_irr_thresh_",c,sep=""))  #colonne 21-23: irrigation thresholds

}

crop_table$Crop<-as.character(crop_table$Crop)

#FILTER THE CROP TABLE TO THE PARAMETERS YOU ARE INTERESTED IN -------

#crop_table <- crop_table[,-which(colnames(crop_table) %in% c("Code","Season_start","Season_End","Irrigation"))]



#library(writexl)

write.csv(crop_table,file="C:/Users/Andrea/OneDrive - Università degli Studi di Sassari/Desktop/Dottorato_Sassari/modello_ACQUAOUNT/SWB_model_BASIN_II/Input_data/crop_data/crop_table.csv",row.names = F)

















################ AREE IRRIGATE ###########################################################################################

# Load library stringr
library("stringr") 



in_dir="C:/Users/Andrea/OneDrive - Università degli Studi di Sassari/Desktop/Dottorato_Sassari/modello_ACQUAOUNT/Sardinia_data/Confini_tirso/"

comuni_tirso=read.csv(paste(in_dir,"Tirso_municipalities.csv",sep="")) 
comuni_elev=read.csv(paste(in_dir,"Tirso_municipalities_elev.csv",sep="")) 

crop_list=list("maize","rice","barley","potato","tomato","alfalfa","wine_grapes","olives","citrus","fruit","pastures")


#Cultivated area in the basin--------------------------------
cultivated_area <- data.frame(matrix(nrow=nrow(comuni_tirso),ncol=length(crop_list)+2)) #define the area of the analysed location (an array with 1 value per crop, so same length of crop_list), in m^2
colnames(cultivated_area)=c("Municipality","Elevation",crop_list)

cultivated_area$Municipality<-comuni_tirso$COMUNE.C.58
cultivated_area$Elevation=comuni_elev[,2]

# assign crops to the municipalities
cultivated_area[,-c(1,2)]=comuni_tirso[,c(12:22)]

library(writexl)

write_xlsx(cultivated_area,"C:/Users/Andrea/OneDrive - Università degli Studi di Sassari/Desktop/Dottorato_Sassari/modello_ACQUAOUNT/cultivated_area.xlsx")










