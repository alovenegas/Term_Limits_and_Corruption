* Corruption and Term Limits: Costa Rica
* Alonso Venegas-Cantillano
* Analysis and Policy in Economics
* Paris School of Economics

cd "C:/Users/alove/Desktop/thesis"
include "C:\Users\alove\Documents\GitHub\Term_Limits_and_Corruption\programs.do"

* Prepare temp files from raw data
import excel "data/raw/bidders.xlsx", clear firstrow
rename (NúmerodeProcedimiento Cantidaddeparticipantesenel) (tender_id bidders)
keep tender_id bidders
duplicates drop tender_id, force
drop if bidders == .
recast str24 tender_id
save data/temp/bidders, replace

* Invited to tenders
import excel "data/raw/invited.xlsx", clear firstrow
rename (NúmerodeProcedimiento Institución CantidaddeInvitados CantidaddeOfertaspresentadas CantidaddeProveedoresquepres) (tender_id municipality invitados ofertas ofertas_prov)
drop if invitados == .
recast str24 tender_id
save data/temp/invited, replace

* Contracts with time 
import excel "data/raw/days1.xlsx", sheet("Export") firstrow clear
save data/temp/time, replace
import excel "data/raw/days2.xlsx", sheet("Export") firstrow clear
append using data/temp/time
rename NúmeroProcedimiento tender_id

drop if tender_id == ""
collapse (mean) DifAperturaDías DifNotificaciónDías DifAdjudicaciónDías (first) FechaPublicaciónBase , by(tender_id)
save "data/temp/time", replace


* Donation data
import excel "data\raw\acumulado_donations.xlsx", sheet("BBDD") firstrow clear
keep if TIPOCONTRIBUCIÓN == "EFECTIVO"
keep if FECHA > td(01jan2020)
rename (CÉDULA MONTO PARTIDOPOLÍTICO FECHA) (rep_id dntn dntn_pp dntn_date)
sort rep_id dntn_date
collapse (first) dntn_date dntn_pp (sum) dntn, by(rep_id)
save data/temp/donations, replace
tab rep_id

* Municipalities date of SICOP inscription
import delimited "data\raw\fecha_ingreso_munis.csv", clear varnames(1)
drop v1
rename nombre_institucion municipality
replace municipality = strupper(municipality)
keep if strpos(municipality,"MUNICIPALIDAD")
drop if strpos(municipality,"FEDERACIóN")
clean_mun
replace fecha_ingreso = substr(fecha_ingreso,1,10)
gen fecha_ingreso1 = date(fecha_ingreso,"YMD")
format fecha_ingreso1 %td
keep municipality fecha_ingreso1
recast str20 municipality 
save data/temp/fecha_ingreso, replace


* Exchange rate for contracts in dollars
import delimited "data\raw\exchange_rate.csv", varnames(1) clear 
replace date_exr = lower(subinstr(date_exr,"-","",.))
gen date = date(date_exr,"DM20Y")
format date %td
gen month = month(date)
gen year = year(date)
replace date = ym(year,month)
format date %tm
tostring year, replace
replace month = date
collapse compra venta , by(date)
rename date month

save data/temp/exchange_rate, replace

*** Income of municipalities
import delimited "data\raw\income2020.csv", clear
save data/temp/income, replace

forvalues i = 2021/2024 {
import delimited "data/raw/income`i'.csv", clear
append using data/temp/income
save data/temp/income, replace
}
rename inst municipality
clean_mun
drop if strpos(municipality,"COMITE")
drop if strpos(municipality,"FEDERACION")
drop if strpos(municipality,"JUNTA")
drop if strpos(municipality,"UNION")

* clean prices
split ejecutado, parse(",")
keep año cuenta descripc municipality ejecutado1
replace ejecutado1 = subinstr(ejecutado,".","",.)
destring ejecutado1, replace
rename ejecutado1 ejecutado

keep if inlist(descripcióncuenta,"INGRESOS DE CAPITAL","INGRESOS CORRIENTES")

cap drop id
egen id = group(municipality año)
replace cuenta = substr(cuenta,1,1)
drop descripc

reshape wide ejecutado año, i(id) j(cuenta) string
drop año2
rename (ejecutado1 año1 ejecutado2) (corriente year capital)
drop id
treatment

gen price_index = 100 if year == 2020
replace price_index = 103.3 if year == 2021
replace price_index = 111.44 if year == 2022
replace price_index = 109.47 if year == 2023
replace price_index = 110.39 if year == 2024

replace corriente = ln(100*(corriente/price_index))
replace capital = ln(100*(capital/price_index))

reg corriente term#year
reg capital term#year

preserve
collapse corriente capital  , by(term year)
tw line corriente year if term == 0 || line capital year if term == 1
tw line capital year if term == 0 || line capital year if term == 1
restore
save data/temp/mun_income, replace

*** Price index
import excel "data/raw/price_index_bccr", firstrow clear
keep month Nivel
cap drop month1
gen month1 = monthly(month,"YM")
drop month
rename month1 month
format month %tm
save data/temp/price_index, replace

** Clean days to deliver the service
import excel "data/raw/delivery.xlsx", sheet("Export") firstrow clear
keep Númerodeprocedimiento Cantidadsolicitada Cantidadentregada Cantidaddedíasadelantoatras CédulayNombredelcontratista
rename (Númerodeprocedimiento Cantidadsolicitada Cantidadentregada Cantidaddedíasadelantoatras CédulayNombredelcontratista) (tender_id q_solicited q_delivered delay_days firm_id)
drop if _n >= 110224
recast str24 tender_id
split firm_id, limit(1)
drop firm_id
rename firm_id1 firm_id

collapse delay_days , by(tender_id firm_id)

save data/temp/delivery, replace

*** Readjustment prices from OCP Costa Rica
import excel "data/raw/reajusteprecios_ocpcr.xlsx", sheet("Export") firstrow clear
rename (Númerodeprocedimiento NúmerodeLíneadeContrato PrecioAdjudicado NúmerodeReajuste MontodelReajuste PrecioAnteriorÚltimoReajuste NuevoPrecio deIncrImentodelÚltimoReaju) (tender_id line p_adj numero_reajuste monto_reajuste precio_anterior new_price perc_change)
keep tender_id line p_adj numero_reajuste monto_reajuste precio_anterior new_price perc_change

collapse (max) numero_reajuste (sum) precio_anterior new_price  (mean) perc_change, by(tender_id line)

save data/temp/reajusteprecios, replace

*****
* SICOP CONTRACTS
*****
import excel "data/raw/sicop1.xlsx", sheet("Export") firstrow clear
save data/final/sicop, replace

import excel "data/raw/sicop2.xlsx", sheet("Export") firstrow clear
append using data/final/sicop
save data/final/sicop, replace

import excel "data/raw/sicop3.xlsx", sheet("Export") firstrow clear
append using data/final/sicop
save data/final/sicop, replace

rename (Institución NúmerodeProcedimiento CéduladeProveedorAdjudicado Línea) (municipality tender_id firm_id line)
replace municipality = strupper(municipality)

*keep only firm with more lines
drop if line == .
drop if municipality == ""

sort municipality firm_id tender_id
egen ID = group(tender_id municipality firm_id) 

collapse (first) tender_id TipodeProcedimiento municipality DescripcióndeProcedimiento Códigodeproducto BienServicio Monedaadjudicada Fechasolicitudcontratación firm_id Cédularepresentante Representante TipoEmpresa ObjetodelGasto (sum) MontoAdjudicado MontoUnitario, by(ID)

clean_mun
treatment

save data/temp/sicop, replace
*********************************************************************

use data/temp/sicop, clear

* Merge bidders
merge m:1 tender_id using data/temp/bidders
drop if _merge == 2
drop _merge

* Merge invited
merge m:1 tender_id using data/temp/invited
drop if _merge ==2 
drop _merge

* Merge time variables
merge m:1 tender_id using data/temp/time
drop if _merge ==2 
drop _merge

* Merge incorporation date of local governments to procurement system
merge m:1 municipality using data/temp/fecha_ingreso
drop if _merge ==2 
drop _merge

* Merge delay in days
merge m:1 tender_id firm_id using data/temp/delivery
drop if _merge == 2
drop _merge

**********************************************************************
/*

foreach i in pub_date contract_date adj_date sol_tec_date res_tec_date {
	replace `i' = substr(`i',1,10)
	gen `i'_f = date(`i',"YMD")
	format `i'_f %td
	drop `i'
}
rename *_f *


foreach i in pub_date contract_date adj_date sol_tec_date res_tec_date {
	codebook `i'
}
*/
	
* Date issues
rename Fechasolicitudcontratación date
gen year = year(date)
gen short_month = month(date)
gen short_quarter = quarter(date)
gen short_semester = halfyear(date)

gen quarter = yq(year,short_quarter)
gen month = ym(year,short_month)
gen semester = yh(year,short_semester)

format quarter %tq
format month %tm 
drop if tender_id == ""


****  Fix prices with exchange rates and price index
* Merge exchange rates
merge m:1 month using data/temp/exchange_rate
drop if _merge ==  2
drop _merge
replace MontoAdjudicado = MontoAdjudicado*venta if Monedaadjudicada == "USD"
replace MontoUnitario = MontoUnitario*venta if Monedaadjudicada == "USD"
drop if Monedaadjudicada == "EUR"

* Merge price index
merge m:1 month using data/temp/price_index
drop if _merge == 2
drop _merge
replace MontoAdjudicado = 100*(MontoAdjudicado/Nivel)
replace MontoUnitario = 100*(MontoUnitario/Nivel)

* Merge municipalities income
merge m:1 municipality year using data/temp/mun_income
drop if _merge == 2


************ clean variables
rename Cédularepresentante rep_id 
gen temp = substr(rep_id,1,1)
replace rep_id = substr(rep_id,2,.) if temp == "0"
drop temp
cap drop _merge

encode municipality, gen(mun_id)
keep if inrange(date,td(1apr2020),td(1apr2024))

* Merge controls | Municipal level merge |  
	cap drop _merge
	merge m:1 municipality using "data/temp/elections2020"
	drop _merge 

*  Control variables
**  Tender type and firm size
encode TipodeProcedimiento, gen(contract_type)
encode TipoEmpresa, gen(firm_type)
replace contract_type = 1 if contract_type == 7
replace contract_type = 3 if contract_type == 8
replace contract_type = 2 if contract_type == 9
replace contract_type = 2 if contract_type == 10
gen pyme = inlist(firm_type,3,5)
gen direct = (contract_type == 1)

** Length of description
gen len_description = strlen(DescripcióndeProcedimiento)

** Experience
replace first_term = 2020 if first_term == 2022
gen exp = year - first_term

** Age
replace age = age + 1 if year == 2021
replace age = age + 2 if year == 2022
replace age = age + 3 if year == 2023
replace age = age + 4 if year == 2024

*TREATMENT: 8 April 2022 Carlos Alvarado signed the change in law
reelec
cap drop time 
gen time_1 = 0
replace time_1 = 1 if quarter > tq(2022q1)

gen time_2 = 0
replace time_2 = 1 if quarter > tq(2021q4)

label var time_1 "After 2022q1"
label var time_2 "After 2021q4"

cap drop treat*
gen treat11 = term*time_1
gen treat21 = reelec*time_1
gen treat12 = term*time_2
gen treat22 = reelec*time_2

* Log price of contract
rename (MontoAdjudicado MontoUnitario) (price unit_price)
gen ln_price = ln(price)
gen ln_unit_price = ln(unit_price)

* gen days 
/*
gen days_contract = day(contract_date - pub_date)
gen days_adj = day(adj_date - pub_date)
gen days_adj_contract = day(contract_date - adj_date)
*/

* porc respuesta
destring Porcentajederespuesta, replace
rename Porcentajederespuesta perc_response
drop if quarter == tq(2024q2)

* Expenditure target
cap drop exp_type exp_type_*
rename ObjetodelGasto exp_type
replace exp_type = subinstr(exp_type,".","",.)
gen exp_type_3dig = substr(exp_type,1,3)
gen exp_type_2dig = substr(exp_type,1,2)
gen exp_type_1dig = substr(exp_type,1,1)

destring exp_type_*, replace
destring exp_type_3dig, replace

* Save final data
save data/final/final_dta, replace


*********************************************************************
*********************************************************************
*********************************************************************
* DESCRIPTIVE STATS
*********************************************************************
*********************************************************************
*********************************************************************

cap use data/final/final_dta, clear

tabstat ln_price ln_unit_price bidders perc_response delay_days, by(year) s(mean sd median max min n)


* Figure 1: Evolution of mean of bidders per month
preserve
drop if bidders == .
bysort municipality: egen m_bid = mean(bidders)
replace bidders = bidders - m_bid
collapse bidders, by(term month)
tw line bidders month if term == 0 || line bidders month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck")) graphregion(color(white))
graph export "figures/lineplot_bidders.pdf", as(pdf) name(Graph) replace
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if ofertas == .
bysort municipality: egen m_bid = mean(ofertas)
replace ofertas = ofertas - m_bid
collapse ofertas, by(term month)
tw line ofertas month if term == 0 || line ofertas month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of perc of response per quarter
preserve
drop if perc_response == .
bysort municipality: egen m_bid = mean(perc_response)
replace perc_response = perc_response - m_bid
collapse perc_response, by(term month)
tw line perc_response month if term == 0 || line perc_response month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 6: Evolution of contracts that won from a donator
preserve 
collapse donate , by(term month)
tw line donate month if term == 0 || line donate month if term == 1, tline(2022m3)
restore

* Figure 7: Evolution of new contracts 
preserve 
drop if inlist(municipality,"BELEN","SANTA ANA","ESCAZU","CURRIDABAT")
cap gen one = 1
collapse (sum) one, by(term month)
tw line one month if term == 0 || line one month if term == 1, tline(2022m3)
restore

* Figure 8: Evolution of the price of contracts
preserve 
cap gen one = 1
collapse ln_price, by(term quarter)
tw line ln_price quarter if term == 0 || line ln_price quarter if term == 1, tline(2022m3) graphregion(color(white)) legend(label(1 "First term") label(2 "Lame duck"))
*graph export "figures/lineplot_price.pdf", as(pdf) name(Graph) replace
restore

** Figure 9: Evolution of mean firm size
preserve
drop if pyme == .
collapse pyme, by(term quarter)
tw line pyme quarter if term == 0 || line pyme quarter if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

*** Figure 10: Evolution of income 
preserve
collapse (mean) corriente capital, by(term year)
tw line corriente year if term == 0 || line corriente year if term == 1 || line capital year if term == 0 || line capital year if term == 1
restore


