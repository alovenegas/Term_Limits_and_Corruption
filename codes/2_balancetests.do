clear all 
global path "C:\Users\alove\Desktop\thesis"
global indepvars "remu serv maint ext_time roads goods abs k12 salaries"
global prod_vars "taxes value_added"
cd ${path}

cap program drop clean_mun term
include "codes/programs.do"

* MAP OF COSTA RICA: TREATED AND CONTROL MUNICIPALITIES

set scheme white_tableau
cd "C:\Users\alove\Desktop\thesis"
spshape2dta data/shape/Cantones_de_Costa_Rica, replace saving(cantones)

use data/shape/cantones_shp, clear
drop if _ID == 57 & _X < 200000
save, replace

use data/shape/cantones, clear
rename NOM_CANT_1 municipality
clean_mun
cap drop term
treatment

spmap term using data/shape/cantones_shp, id(_ID) fcolor(Blues) legend(label(2 "First-term")) legend(label(3 "Lame Duck"))

graph export "figures/map_term_limits.pdf", as(pdf) name("Graph") replace



* POPULATION DATA
*https://services.inec.go.cr/proyeccionpoblacion/frmproyec.aspx
import excel "data/raw/pob_inec.xlsx", sheet("Sheet1") firstrow clear
clean_mun

reshape long pop, i(municipality) j(year)
save data/temp/pob_canton, replace

***********************************************************************
import excel "data/raw/Datos IPS Cantonal 2024 vF.xlsx", sheet("Datos") firstrow clear
drop if Cantones == ""

cap rename Cantones municipality

clean_mun
treatment

keep Salud Seguridad DerechosyVoz NecesidadesHumanas ÍndicedeProgresoSocial Emunicipalidad Estadodelaredvialcantonal EducaciónBásica Datosabiertosdegobierno Datosabiertosdegobierno Participaciónciudadana Rendicióndecuentas Accesoalainformación Participacióneneleccionesmuni Estadodelaredvialcantonal Escolaridaddelapoblaciónadul SociedadIncluyente term
save data/temp/ips_cantonal, replace

pstest Salud Seguridad DerechosyVoz NecesidadesHumanas ÍndicedeProgresoSocial Emunicipalidad Estadodelaredvialcantonal EducaciónBásica Datosabiertosdegobierno Datosabiertosdegobierno Participaciónciudadana Rendicióndecuentas Accesoalainformación Participacióneneleccionesmuni Estadodelaredvialcantonal Escolaridaddelapoblaciónadul SociedadIncluyente, raw t(term) saving("tables/balancetable.tex") 

*********************************************************************
import excel "data/raw/icc2021", sheet("Valores") firstrow clear
rename CANTON municipality
clean_mun
treatment

pstest Pilar1Instituciones Pilar2Infraestructura Pilar3Adopcióndelastecnolog Pilar4Salud Pilar5Habilidades Pilar6Económicoydemercados Fortalezamunicipal Transparenciamunicipal Administraciónpresupuestaria Compromisoconlasostenibilida Infraestructuradetransporte Conectividadvial Accesoaserviciospúblicos Serviciospúblicosmunicipales Participaciónestructuralenele Participaciónactualeneleccion AR AS Promocióndelaparticipaciónci EMunicipalidad Autocontrolmunicipal Autoevaluaciónderiesgos Rendicióndecuentas Datosabiertosdegobierno Inversiónpercápitaenservicio Inversióndecapitalpercápita Dependenciafinancieradetransf Coberturadelservicioderecol Sostenibilidaddeoperacióndel BI InversiónmediaporKmenredy Coberturadelserviciodeparque Coberturadelserviciodeaseod Inversiónpercápitaeninfraest , raw t(term) saving("tables/balancetable.tex") 

*****************************************************************
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

treatment

preserve
tempfile mayors
import excel "data\raw\elections2020.xlsx", sheet("mayors") firstrow clear
clean_mun
save `mayors', replace
restore

merge 1:1 municipality using `mayors', nogen


gen pln = 0
replace pln = 1 if party == "Liberación Nacional"
replace pln = 1 if party == "Unidad Social Cristiana"
pstest abs_share margin age pln woman, t(term) raw 

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

global prod_var gdp taxes value_added

foreach i in $prod_var {
	replace `i' = 100 * (`i'/(pop*price_index))
}

* Gen term dummy variables
treatment

graph box gdp, by(year) over(term) graphregion(color(white))

foreach var in $prod_var {
ttest `var' if year == 2019, by(term)
ttest `var' if year == 2020, by(term)
ttest `var' if year == 2021, by(term)
}

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

sort municipality year account

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
keep if inlist(descripcióncuenta,"REMUNERACIONES","Sueldos y Salarios","Vías de Comunicación","GASTOS CORRIENTES","GASTOS DE CAPITAL","""BIENES DURADEROS")
replace descripcióncuenta = "remu" if descripcióncuenta == "REMUNERACIONES"
replace descripcióncuenta = "d_goods" if descripcióncuenta == "BIENES DURADEROS"
replace descripcióncuenta = "salaries" if descripcióncuenta == "Sueldos y Salarios"
replace descripcióncuenta = "cap_roads" if descripcióncuenta == "Vías de Comunicación"
replace descripcióncuenta = "serv" if descripcióncuenta == "GASTOS CORRIENTES"
replace descripcióncuenta = "cap" if descripcióncuenta == "GASTOS DE CAPITAL"



replace ejecutado = subinstr(ejecutado,".","",.)
destring ejecutado, replace dpcomma
rename año year

gen price_index = 103.3 if year == 2021
replace price_index = 111.44 if year == 2022
replace price_index = 109.47 if year == 2023

cap drop cuenta presupuestado 

reshape wide ejecutado, i(municipality year) j(descripcióncuenta) string
rename ejecutado* *


clean_mun

tempfile temp
save `temp', replace

* Jose Ignacio website
use data/raw/base_regresiones, clear
cap drop pop* share
encode Gender, gen(sex)
encode type, gen(party_type)
egen mun_id = group(municipality)

global expenditures remu serv d_goods total_expenses remu_bas remu_ev rentals serv_cf cap_prot maintenance cap_mef cap_cai salaries ext_time sub_all rent_mef publicity activities main_bcl cap_roads

global controles_exo "Age i.sex k_12centers gdp interest_rate debt deficit"
global controles_pre "i.party_type win_margin abstentionism pop_share014 pop_share65plus"

* Clean municipalities
clean_mun
*append using `temp'
drop pop
merge m:1 municipality year using data/temp/pob_canton


keep $expenditures price_index pop municipality year abs

foreach var of varlist $expenditures {
	replace `var' = 100 * `var' / price_index
	replace `var' = log(`var' / pop)
}

* Treated municipalities
treatment

collapse (mean) $expenditures, by(term year)

reshape wide $expenditures, i(year) j(term)

drop if year > 2020

foreach i in $expenditures {
	
	tw line `i'0 year, legend(label(1 "First-Term")) || line `i'1 year,  legend(label(2 "Lame Duck")) graphregion(color(white))
	sleep 2000
	
}


foreach i in remu serv roads salaries abs {
tw rarea upper_`i'0 lower_`i'0 year , color(blue%20) legend(off) || rarea upper_`i'1 lower_`i'1 year, color(red%20) legend(off) || line `i'0 year, legend(label(1 "Term-limited mayors")) || line `i'1 year , legend(label(2 "Lame ducks")) graphregion(color(white))

graph export "figures/`i'.pdf" , name("Graph") as(pdf) replace
sleep 5000
}





