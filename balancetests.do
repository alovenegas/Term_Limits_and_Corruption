clear all 
global path "C:\Users\alove\Desktop\thesis"
global indepvars "remu serv maint ext_time roads goods abs k12 salaries"
global prod_vars "taxes value_added"
cd ${path}

cap program drop clean_mun term
include "codes/programs.do"

*************************************************************************
*https://services.inec.go.cr/proyeccionpoblacion/frmproyec.aspx
import excel "data/raw/pob_inec.xlsx", sheet("Sheet1") firstrow clear
clean_mun

reshape long pop, i(municipality) j(year)
save data/pob_canton, replace

***********************************************************************
import excel "data/raw/Datos IPS Cantonal 2024 vF.xlsx", sheet("Datos") firstrow clear
drop if Cantones == ""

cap rename Cantones municipality

clean_mun
treatment

keep Salud Seguridad DerechosyVoz NecesidadesHumanas ÍndicedeProgresoSocial Emunicipalidad Estadodelaredvialcantonal EducaciónBásica Datosabiertosdegobierno Datosabiertosdegobierno Participaciónciudadana Rendicióndecuentas Accesoalainformación Participacióneneleccionesmuni Estadodelaredvialcantonal Escolaridaddelapoblaciónadul SociedadIncluyente term
save data/temp/ips_cantonal, replace

pstest Salud Seguridad DerechosyVoz NecesidadesHumanas ÍndicedeProgresoSocial Emunicipalidad Estadodelaredvialcantonal EducaciónBásica Datosabiertosdegobierno Datosabiertosdegobierno Participaciónciudadana Rendicióndecuentas Accesoalainformación Participacióneneleccionesmuni Estadodelaredvialcantonal Escolaridaddelapoblaciónadul SociedadIncluyente, raw t(term) saving("tables/balancetable.tex") 

********************************************************************************
import excel "data\raw\elections2020.xlsx", sheet("votes") firstrow clear
rename (Provincia Canton Votos Partido) (province municipality votes party)
collapse (sum) votes, by(province municipality party)
bysort municipality: egen abs = max(votes)
bysort municipality: egen total = sum(votes)
gen abs_share = abs/total
drop if inlist(party,"Abstencionismo","Votos nulos","Votos en blanco")
replace total = total - abs
gen vote_share = votes / total
sort province municipality vote_share
bysort municipality (vote_share): gen margin = vote_share[_n] - vote_share[_n-1]
bysort municipality: keep if _n == _N
clean_mun

preserve
tempfile mayors
import excel "data\raw\elections2020.xlsx", sheet("mayors") firstrow clear
clean_mun
save `mayors', replace
restore

merge 1:1 municipality using `mayors', nogen

save data/temp/elections2020, replace

 
*Adding GDP per canton
clear
import excel "data/raw/gdp_canton.xlsx", sheet("Base_PIB_regional") firstrow clear
rename (Año Cantón PIB Impuestosalosproducto ValorAgregado) (year municipality gdp taxes value_added)

clean_mun

keep year municipality gdp taxes value_added

merge m:1 municipality year using data/temp/pob_canton, keep(3) nogen

gen price_index = 99.12 if year == 2019
replace price_index = 100 if year == 2020
replace price_index = 103.298 if year == 2021

foreach i in $prod_vars{
	replace `i' = 100 * (`i'/(pop*price_index))
}

* Gen term dummy variables
treatment

graph box gdp, by(year) over(term) graphregion(color(white))

save data/temp/gdp_canton, replace
 
***********************************************************************
***********************************************************************
************************** INCOME PER MUN *****************************
import delimited data/raw/income2020, clear

save data/temp/income_cgr, replace

foreach i in 2021 2022 2023 2024  {
import delimited data/raw/income`i', clear
append using data/temp/income_cgr
save data/temp/income_cgr, replace
}

rename (institución año cuenta ejecutado) (municipality year account income)
keep if strpos(municipality,"MUNICIPALIDAD")
drop if strpos(municipality, "COMITE")
drop if strpos(municipality, "FEDERACION")

clean_mun

sort municipality cuenta año

save data/final/income_cgr

***********************************************************************
***********************************************************************
***********************************************************************


clear 
*Adding 2020 to 2023
import delimited "data/raw/cgr_2020_2025.csv", clear 
rename institución municipality
drop if strpos(municipality,"FEDERACION")
drop if strpos(municipality,"COMITE")
clean_mun
drop if inlist(año,2020,2024,2025)
keep if inlist(descripcióncuenta,"REMUNERACIONES","ADQUISICIÓN DE BIENES Y SERVICIOS","Sueldos y Salarios","Vías de Comunicación")
replace descripcióncuenta = "remu" if descripcióncuenta == "REMUNERACIONES"
replace descripcióncuenta = "d_goods" if descripcióncuenta == "ADQUISICIÓN DE BIENES Y SERVICIOS"
replace descripcióncuenta = "salaries" if descripcióncuenta == "Sueldos y Salarios"
replace descripcióncuenta = "cap_roads" if descripcióncuenta == "Vías de Comunicación"

replace ejecutado = subinstr(ejecutado,".","",.)
destring ejecutado, replace dpcomma
rename año year

gen price_index = 103.3 if year == 2021
replace price_index = 111.44 if year == 2022
replace price_index = 109.47 if year == 2023

cap drop cuenta presupuestado 

reshape wide ejecutado, i(municipality year) j(descripcióncuenta) string
rename ejecutado* *

tempfile temp
save `temp', replace

* Jose Ignacio website
use data/raw/base_regresiones, clear
cap drop pop* share
encode Gender, gen(sex)
encode type, gen(party_type)
egen mun_id = group(municipality)

global expenditures "remu serv d_goods total_expenses remu_bas remu_ev rentals serv_cf cap_prot maintenance cap_mef cap_cai salaries ext_time sub_all rent_mef publicity activities main_bcl cap_roads gdp value_added"

global controles_exo "Age i.sex k_12centers gdp interest_rate debt deficit"
global controles_pre "i.party_type win_margin abstentionism pop_share014 pop_share65plus"

* Clean municipalities
clean_mun
append using `temp'
merge m:1 municipality year using data/temp/pob_canton, keep(3) nogen
merge m:1 municipality year using data/temp/gdp_canton

foreach var of varlist $expenditures{
	gen r_`var' = 100 * `var' / price_index
	gen l_rpc_`var' = log(r_`var' / pop)
}

* Treated municipalities
treatment

collapse (mean) gdp taxes value_added remu = l_rpc_remu serv = l_rpc_serv goods = l_rpc_d_goods maint = l_rpc_maintenance salaries = l_rpc_salaries ext_time = l_rpc_ext_time roads = l_rpc_cap_roads k12 = k_12centers abs = abstentionism (sd) sd_gdp = gdp sd_taxes = taxes sd_value_added = value_added sd_remu = l_rpc_remu sd_serv = l_rpc_serv  sd_goods = l_rpc_d_goods sd_maint = l_rpc_maintenance  sd_salaries = l_rpc_salaries  sd_ext_time = l_rpc_ext_time sd_roads=l_rpc_cap_roads sd_k12=k_12centers sd_abs=k_12centers , by(term year)

reshape wide remu serv goods maint salaries gdp taxes value_added ext_time roads k12 abs sd_serv sd_goods sd_maint sd_salaries sd_ext_time sd_roads sd_k12 sd_abs sd_remu sd_gdp sd_taxes sd_value_added, i(year) j(term)

foreach i in $indepvars {
	gen upper_`i'0 = `i'0 + 1.96*sd_`i'0
    gen upper_`i'1 = `i'1 + 1.96*sd_`i'1
	gen lower_`i'0 = `i'0 - 1.96*sd_`i'0
	gen lower_`i'1 = `i'1 - 1.96*sd_`i'1
}

tw rarea upper_serv0 lower_serv0 year , color(gs13%50)|| rarea upper_serv1 lower_serv1 year, color(red%20) || line serv0 year|| line serv1 year , graphregion(color(white)) xscale(range(2006(1)2020))

foreach i in $indepvars {
tw rarea upper_`i'0 lower_`i'0 year , color(blue%20) || rarea upper_`i'1 lower_`i'1 year, color(red%20) || line `i'0 year|| line `i'1 year , legend(off)
graph export "figures/`i'.pdf" , name("Graph") as(pdf) replace
}


