# Corruption and Term Limits
# Alonso Venegas
# APE-M2
# PSE
# Set library

for (lib in c("readxl","tidyr","dplyr","ggplot2","broom","stargazer","lmtest","readr")) {
  library(lib, character.only = TRUE)
  
}
# Here the journey starts
setwd("C:/Users/alove/Desktop/thesis/data/raw")
temp <- tempfile()
download.file("https://dlsaobservatorioprod.blob.core.windows.net/fs-synapse-observatorio-produccion/Zip/202001.zip",temp)
sicop <- read.csv(unz(temp, "Contratos.csv"),sep = ";")
bidders <- read.csv(unz(temp, "Ofertas.csv"),sep = ";")
price_change <- read.csv(unz(temp, "ReajustePrecios.csv"),sep = ";")
time <- read.csv(unz(temp, "FechaPorEtapas.csv"),sep = ";")
firms <- read.csv(unz(temp, "Proveedores.csv"),sep = ";")

sicop <- sicop %>% arrange(NRO_SICOP,SECUENCIA)
unlink(temp)

for (i in 2020:2024) {
  for (j in 1:12) {

    if (j < 10) {
      
        temp <- tempfile()
        download.file(paste0("https://dlsaobservatorioprod.blob.core.windows.net/fs-synapse-observatorio-produccion/Zip/",i,"0",j,".zip"),temp)
        
        #try(data <- read.csv(unz(temp, "Contratos.csv"),sep=";"), silent = TRUE)
        #try(b <- read.csv(unz(temp, "Ofertas.csv"),sep=";"), silent = TRUE)
        try(pc <- read.csv(unz(temp, "ReajustePrecios.csv"),sep=";"), silent = TRUE)
        #try(ftemp <- read.csv(unz(temp, "Proveedores.csv"),sep=";"), silent = TRUE)
        #try(temp_time <- read.csv(unz(temp,"FechaPorEtapas.csv"),sep = ";"), silent = TRUE)
        
        #sicop <- rbind(sicop,data)
        #bidders <- rbind(bidders,b) 
        price_change <- rbind(price_change,pc)
        #firms <- rbind(firms,ftemp)
        #time <- rbind(time,temp_time)
    
    }
          
    if (j >= 10) {
      
        temp <- tempfile()
        download.file(paste0("https://dlsaobservatorioprod.blob.core.windows.net/fs-synapse-observatorio-produccion/Zip/",i,j,".zip"),temp)
        
        #try(data <- read.csv(unz(temp, "Contratos.csv"),sep=";"), silent = TRUE)
        #try(b <- read.csv(unz(temp, "Ofertas.csv"),sep=";"), silent = TRUE)
        try(pc <- read.csv(unz(temp, "ReajustePrecios.csv"),sep=";"), silent = TRUE)
        #try(ftemp <- read.csv(unz(temp, "Proveedores.csv"),sep=";"), silent = TRUE)
        #try(temp_time <- read.csv(unz(temp,"FechaPorEtapas.csv"),sep = ";"), silent = TRUE)
        
        #sicop <- rbind(sicop,data)
        #bidders <- rbind(bidders,b)
        price_change <- rbind(price_change,pc)
        #firms <- rbind(firms,ftemp)
        #time <- rbind(time,temp_time)
        
    }
  unlink(temp)
  #data <- NULL
  #b <- NULL
  #ftemp <- NULL
  #temp_time <- NULL
  pc <- NULL
  #firms <- firms %>% distinct(CEDULA_PROVEEDOR, .keep_all = TRUE)
}
}



download.file(paste0("https://dlsaobservatorioprod.blob.core.windows.net/fs-synapse-observatorio-produccion/Zip/202204.zip"),temp)
mun <- read.csv(unz(temp,"InstitucionesRegistradas.csv"),sep = ";")

colnames(mun)[1] <- c("CEDULA_INSTITUCION")

# Clean institution names
mun <- mun %>%
  select(CEDULA_INSTITUCION,NOMBRE_INSTITUCION,FECHA_INGRESO)
  
# Generate number of bidders
bidders_clean <- bidders %>%
  select(NRO_SICOP) %>%
  mutate(tag = 1) %>%
  group_by(NRO_SICOP) %>%
  summarise(bidders = sum(tag)) %>%
  mutate(NRO_SICOP = as.numeric(NRO_SICOP)) %>%
  
  
bidders_clean <- bidders_clean %>%
  left_join(sicop[,c("NRO_SICOP","NUMERO_PROCEDIMIENTO")],by = "NRO_SICOP")


# Price changes
price_change_clean <- price_change %>%
  select(NRO_SICOP, PRECIO_ANT_ULT_RJ, MONTO_REAJUSTE, PORC_INCR_ULT_RJ) %>%
  rename(price_change = PORC_INCR_ULT_RJ) %>%
  mutate(NRO_SICOP = as.numeric(NRO_SICOP)) %>%
  left_join(sicop[,c("NRO_SICOP","NUMERO_PROCEDIMIENTO")],by = "NRO_SICOP")

# Bidders
bidders_clean <- bidders_clean %>%
  left_join(sicop[,c("NRO_SICOP","NUMERO_PROCEDIMIENTO")],by = "NRO_SICOP")

# Clean firms
firms_clean <- firms %>%
  select(CEDULA_PROVEEDOR,NOMBRE_PROVEEDOR,zona_geo_prov,TAMAÃ.O_PROVEEDOR)%>%
  rename(firm_size = TAMAÃ.O_PROVEEDOR, firm_loc = zona_geo_prov) %>%
  mutate(firm_size = sub("Ã±","n",firm_size))

# Clean time
time_clean <- time %>%
  select(NUMERO_PROCEDIMIENTO,PUBLICACION,FECHA_ELABORACION_CONTRATO, 
         ADJUDICACION_FIRME,SOLICITUD_ESTUDIOS_TECNICOS,RESPUESTA_ESTUDIOS_TECNICOS) %>%
  group_by(NUMERO_PROCEDIMIENTO) %>%
  summarise(pub_date = first(PUBLICACION), contract_date = first(FECHA_ELABORACION_CONTRATO), 
            adj_date = first(ADJUDICACION_FIRME),
            sol_tec_date = first(SOLICITUD_ESTUDIOS_TECNICOS),
            res_tec_date = first(RESPUESTA_ESTUDIOS_TECNICOS))


final_sicop <- sicop %>% 
  
  left_join(mun, by  = "CEDULA_INSTITUCION", keep = FALSE) %>%
  left_join(firms_clean, by = "CEDULA_PROVEEDOR", ) %>%
  left_join(price_change_clean, by = "NRO_SICOP") %>%
  left_join(bidders_clean,by="NRO_SICOP") %>%
  left_join(time_clean, by = "NRO_SICOP")

write.csv(bidders_clean,"Rbidders.csv",sep = ",", na = "")
write.csv(price_change_clean,"Rprice_change.csv",sep = ",", na = "")
write.csv(time_clean,"Rtime.csv",sep = ",", na = "")
write.csv(mun,"fecha_ingreso_munis.csv",sep = ",", na = "")

write.csv(final_sicop,"RSICOP.csv",sep = ",", na = "")




