clear all

set scheme white_tableau
cd "C:\Users\alove\Desktop\thesis"
include "codes/programs"
spshape2dta data/Cantones_de_Costa_Rica, replace saving(cantones)

use data/shape/cantones_shp, clear
drop if _ID == 57 & _X < 200000
save, replace

use data/shape/cantones, clear
rename NOM_CANT_1 municipality
term_limits

spmap term_limit using data/shape/cantones_shp, id(_ID) fcolor(Blues) 

graph export "figures/map_term_limits.pdf", as(pdf) name("Graph") replace

*****************************************************************************

clear all 
import delimited "C:\Users\alove\Downloads\Gastos según Clasificación Económica (C.E.)- Por institución (2).csv", varnames(1) clear
keep if año <= 2024
drop if _n < 378

keep if descripcióncuenta == "ADQUISICIÓN DE BIENES Y SERVICIOS" | descripcióncuenta == "FORMACION DE CAPITAL" 
drop cuenta 
rename año year
drop presupuestado
reshape 
replace ejecutado = subinstr(ejecutado,".","",.)
destring ejecutado, replace dpcomma

use gasto, clear

cd "C:\Users\alove\Desktop\thesis\data"
import delimited "cgr_clean (Agregado Medio).csv", clear 
program define clean_mun
cap rename institución municipality
replace municipality = strupper(municipality)
keep if strpos(municipality,"MUNICIPALIDAD")
replace municipality = subinstr(municipality,"MUNICIPALIDAD DE","",.)
replace municipality = subinstr(municipality,"MUNICIPALIDAD","",.)
replace municipality = subinstr(municipality,"GUANACASTE","",.)
replace municipality = subinstr(municipality,"DE HEREDIA","",.)
replace municipality = subinstr(municipality,"CANAS","CAÑAS",.)
replace municipality = subinstr(municipality,"í","I",.)
replace municipality = subinstr(municipality,"ú","U",.)
replace municipality = subinstr(municipality,"á","A",.)
replace municipality = subinstr(municipality,"ó","O",.)
replace municipality = subinstr(municipality,"é","E",.)
replace municipality = subinstr(municipality,"ñ","Ñ",.)
replace municipality = subinstr(municipality,"L CANTON DE","",.)
replace municipality = subinstr(municipality,".","",.)
replace municipality = subinstr(municipality,"ALVARADO DE PACAYAS","ALVARADO",.)
replace municipality = subinstr(municipality,"VAZQUEZ","VASQUEZ",.)
replace municipality = strtrim(municipality)
end


gen capital = cap_mef + cap_cai
rename serv_cf serv

append using mun_2020_2023

program term_limit 
gen term_limit = 0
replace term_limit = 1 if inlist(municipality,"HEREDIA","BELEN","FLORES","CARTAGO","SAN PABLO","CURRIDABAT","SANTO DOMINGO","PALMARES","BARVA")
replace term_limit = 1 if inlist(municipality,"SAN CARLOS","GRECIA","GOICOECHEA","LA UNION","ALAJUELA","POAS","TIBAS","DESAMPARADOS","OREAMUNO")
replace term_limit = 1 if inlist(municipality,"SARCHI","PARAISO","SANTA BARBARA","MORA","PURISCAL","SANTA CRUZ","POCOCI","LIBERIA","NICOYA")
replace term_limit = 1 if inlist(municipality,"BAGACES","CAÑAS","RIO CUARTO","PUNTARENAS","SARAPIQUI","QUEPOS","ABANGARES","DOTA","COTO BRUS")
replace term_limit = 1 if inlist(municipality,"MATINA","UPALA","GOLFITO","LA CRUZ","TALAMANCA")
end
sarchi quepos

preserve
keep if cuenta_2 == "GASTOS CORRIENTES" | cuenta_2 == "GASTOS DE CAPITAL"
replace ejecutado = subinstr(ejecutado,".","",.)
destring ejecutado, replace dpcomma
collapse ejecutado , by(year cuenta_2 term_limit)

tw line ejecutado year if cuenta_2 == "GASTOS CORRIENTES", by(term_limit)
tw line ejecutado year if cuenta_2 == "GASTOS DE CAPITAL", by(term_limit)

restore



merge m:1 municipality using pob_canton

preserve 
replace serv = serv/pob
replace capital = capital/pob
collapse serv capital , by(term_limit year)
tw line serv year if term_limit == 0 || line serv year if term_limit == 1 
sleep 10000
tw line capital year if term_limit == 0 || line capital year if term_limit == 1 
restore

use data/cantones, clear
rename NOM_CANT_1 municipalidad


********************************************************************************

use pob_canton, clear
replace municipality = subinstr(municipality,"í","I",.)
replace municipality = subinstr(municipality,"ú","U",.)
replace municipality = subinstr(municipality,"á","A",.)
replace municipality = subinstr(municipality,"ó","O",.)
replace municipality = subinstr(municipality,"é","E",.)
replace municipality = subinstr(municipality,"ñ","Ñ",.)
replace municipality = subinstr(municipality,"L CANTON DE","",.)
replace municipality = subinstr(municipality,".","",.)
replace municipality = subinstr(municipality,"ALVARADO","ALVARADO DE PACAYAS",.)
replace municipality = subinstr(municipality,"VAZQUEZ","VASQUEZ",.)

save, replace


rename descripcióncuenta cuenta
replace cuenta = "serv" if cuenta == "ADQUISICIÓN DE BIENES Y SERVICIOS"
replace cuenta = "capital" if cuenta == "FORMACION DE CAPITAL"
reshape wide ejecutado, i(municipality year) j(cuenta) string


preserve
collapse (sum) Diferencia, by(term_limit year)
tw line Diferencia year if term_limit == 0 || line Diferencia year if term_limit == 1
restore

save mun_2020_2023, replace

**************************************************************************
import excel "C:\Users\alove\Downloads\data.xlsx", sheet("Export") firstrow clear
rename Institución municipality
keep if strpos(municipality,"MUNICIPALIDAD") | strpos(municipality,"Municipalidad")
replace municipality = strupper(municipality)

gen year = substr(NúmerodeProcedimiento,1,4)
destring year, replace
rename I perc

preserve
collapse (mean) perc (sum) Diferencia_w, by(term_limit year)
*tw line perc year if term_limit == 0 || line perc year if term_limit == 1
tw line Diferencia_w year if term_limit == 0 || line Diferencia year if term_limit == 1
restore


*********************************************************************
*** DONATIONS
*********************************************************************
import delimited "C:\Users\alove\Desktop\thesis\data\raw\donations.csv", varnames(1) clear 

rename (cédula partidopolítico) (rep_id party)
replace rep_id = "0" + rep_id

collapse (max )(max) fecha party, by(rep_id)

save data/temp/donations, replace










