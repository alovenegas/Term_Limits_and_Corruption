* Corruption and Term Limits: Costa Rica
* Alonso Venegas Cantillano
* Analysis and Policy in Economics
* Paris School of Economics

cd "C:\Users\alove\Desktop\thesis"
include "codes/programs.do"

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
import delimited "data\raw\Rtime.csv", clear varnames(1)
drop v1
rename numero_procedimiento tender_id
recast str24 tender_id
save data/temp/time, replace

* Donation data
import excel "C:\Users\alove\Desktop\thesis\data\raw\acumulado_donations.xlsx", sheet("BBDD") firstrow clear
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
clean_mun
replace fecha_ingreso = substr(fecha_ingreso,1,10)
gen ingreso = date(fecha_ingreso,"YMD")
format ingreso %td
keep municipality ingreso
keep if strpos(municipality,"MUNICIPALIDAD")
drop if strpos(municipality,"FEDERACION")
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

rename (Institución NúmerodeProcedimiento CéduladeProveedorAdjudicado) (municipality tender_id firm_id)
replace municipality = strupper(municipality)

sort tender_id Línea
drop if municipality == ""

bysort tender_id firm_id: gen tag = _N
replace tag = -tag 
sort tender_id tag
drop tag

collapse (first) TipodeProcedimiento municipality DescripcióndeProcedimiento Códigodeproducto BienServicio Monedaadjudicada Fechasolicitudcontratación firm_id Cédularepresentante Representante TipoEmpresa ObjetodelGasto (sum) MontoAdjudicado, by(tender_id)

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
merge 1:1 tender_id using data/temp/invited
drop if _merge ==2 
drop _merge

* Merge time variables
merge 1:1 tender_id using data/temp/time, force
drop if _merge ==2 
drop _merge

* Merge ingreso municipalidades
merge m:1 municipality using data/temp/fecha_ingreso
drop if _merge ==2 
drop _merge

**********************************************************************

foreach i in pub_date contract_date adj_date sol_tec_date res_tec_date {
	replace `i' = substr(`i',1,10)
	gen `i'_f = date(`i',"YMD")
	format `i'_f %td
	drop `i'
}
rename *_f *


* Date issues
rename Fechasolicitudcontratación date
gen year = year(date)
gen short_month = month(date)
gen short_quarter = quarter(date)

gen quarter = yq(year,short_quarter)
gen month = ym(year,short_month)
format quarter %tq
format month %tm 
drop if tender_id == ""

* Merge exchange rates
merge m:1 month using data/temp/exchange_rate
drop if _merge ==  2
replace MontoAdjudicado = MontoAdjudicado*venta if Monedaadjudicada == "USD"

************ clean variables
rename Cédularepresentante rep_id 
gen temp = substr(rep_id,1,1)
replace rep_id = substr(rep_id,2,.) if temp == "0"
drop temp
cap drop _merge
merge m:1 rep_id using data/temp/donations
drop if _merge == 2
gen donate = (_merge == 3)
drop _merge

gen time = (quarter>tq(2022q1))
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
gen tender = inrange(contract_type,3,7)
replace contract_type = 1 if contract_type == 7
replace contract_type = 3 if contract_type == 8
replace contract_type = 2 if contract_type == 9
replace contract_type = 2 if contract_type == 10
gen pyme = inlist(firm_type,3,5)
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

** Treatment
reelec
gen treat = term*time
gen treat2 = reelec*time

gen ln_price = ln(MontoAdjudicado)

* gen days 
gen days_contract = day(contract_date - pub_date)
gen days_adj = day(adj_date - pub_date)
gen days_adj_contract = day(contract_date - adj_date)

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
cap use data/final/final_dta, clear
* Figure 1: Evolution of mean of bidders per month
preserve
keep if contract_type == 3
drop if bidders == .
bysort municipality: egen m_bid = mean(bidders)
replace bidders = bidders - m_bid
collapse bidders, by(term month)
tw line bidders month if term == 0 || line bidders month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if ofertas == .
bysort municipality: egen m_bid = mean(ofertas)
replace ofertas = ofertas - m_bid
collapse ofertas, by(term month)
tw line ofertas month if term == 0 || line ofertas month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if perc_response == .
bysort municipality: egen m_bid = mean(perc_response)
replace perc_response = perc_response - m_bid
collapse perc_response, by(term month)
tw line perc_response month if term == 0 || line perc_response month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 3: Evolution of mean of days to write contract
preserve
drop if days_contract == .
bysort municipality: egen m_bid = mean(days_contract)
replace days_contract = days_contract - m_bid
collapse days_contract, by(term quarter)
tw line days_contract quarter if term == 0 || line days_contract quarter if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 4: Evolution of mean of days to write contract
preserve
drop if days_adj == .
bysort municipality: egen m_bid = mean(days_adj_contract)
replace days_adj_contract = days_adj_contract - m_bid
collapse days_adj, by(term month)
tw line days_adj month if term == 0 || line days_adj month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore


* Figure 5: Evolution of donations when 2022 
preserve 
gen t1 = year(dntn_date)
gen t2 = quarter(dntn_date)
gen dntn_quarter = yq(t1,t2)
format dntn_quarter 
drop t1 t2 
format dntn_quarter %tq
collapse (sum) dntn , by(term dntn_quarter)
tw line dntn dntn_quarter if term == 0 || line dntn dntn_quarter if term == 1, tline(2022m3)
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
drop if inlist(municipality,"BELEN","SANTA ANA","ESCAZU","CURRIDABAT")
cap gen one = 1
collapse ln_price, by(term month)
tw line ln_price month if term == 0 || line ln_price month if term == 1, tline(2022m3)
restore


********************* DID ********************************
**********************************************************
global outcomes days_contract days_adj bidders invitados perc_response donate len_description pyme

estimates clear
* BASIC DID
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	quiet areg `i' treat i.quarter, absorb(mun_id) cluster(mun_id)
	estimates store `i'

}
esttab *, keep(treat)

* BASIC DID - Controls
estimates clear
foreach i in $outcomes {
	dis "Estimating effects for: `i'"
 quiet areg `i' treat ln_price i.contract_type i.firm_type i.quarter i.exp_type_1dig age, absorb(mun_id)  cluster(mun_id)
 estimates store `i'

}

esttab *, keep(treat age) 

* BASIC DID - Controls with dynamic effects
* gen placebo and dynamic
cap drop event_time
cap drop e_*
gen event_time = month - tm(2022m3)

gen e_m9 = (event_time == -9) * term
gen e_m8 = (event_time == -8) * term
gen e_m7 = (event_time == -7) * term
gen e_m6 = (event_time == -6) * term
gen e_m5 = (event_time == -5) * term
gen e_m4 = (event_time == -4) * term
gen e_m3 = (event_time == -3) * term
gen e_m2 = (event_time == -2) * term
gen e_m1 = (event_time == -1) * term
gen e_m0 = (event_time == 0) * term //not included
gen e_1 = (event_time == 1) * term
gen e_2 = (event_time == 2) * term
gen e_3 = (event_time == 3) * term
gen e_4 = (event_time == 4) * term
gen e_5 = (event_time == 5) * term
gen e_6 = (event_time == 6) * term
gen e_7 = (event_time == 7) * term
gen e_8 = (event_time == 8) * term
gen e_9 = (event_time == 9) * term

estimates clear
foreach i in $outcomes {
areg `i' e_m9 e_m8 e_m7 e_m6 e_m5 e_m4 e_m3 e_m2 e_m0 e_1 e_2 e_3 e_4 e_5 e_6 e_7 e_8 e_9 ln_price i.contract_type i.firm_type i.exp_type_1dig i.short_month i.quarter, absorb(mun_id) cluster(mun_id)

coefplot, keep(e_m9 e_m8 e_m7 e_m6 e_m5 e_m4 e_m3 e_m2 e_m0 e_1 e_2 e_3 e_4 e_5 e_6 e_7 e_8 e_9) vertical ///
    xline(9, lcolor(red)) title("Event-Study: `i'") ///
	ciopts(recast(rcap) lcolor(black))
	sleep 10000
}

** ROBUSTNESS CHECKS FOR PERC OF RESPONSE ***
* list of municipalities that incorporated last to SICOP
drop if inlist(municipality,"ACOSTA","MONTES DE ORO","LA CRUZ","DOTA","LEON CORTES","RIO CUARTO","POCOCI","BAGACES")
areg perc_response treat time i.short_month ln_price i.contract_type i.firm_type i.year, absorb(mun_id) cluster(mun_id)


************ RANDOM TREATMENT CHECKS **************************
quiet{
forvalues i = 1(1)100 {
use data/final/final_dta, replace
preserve
tempfile test
collapse term, by(mun_id)
replace term = runiform(0,1)
replace term = 0 if term < 0.5
replace term = 1 if term >= 0.5
save `test', replace 
restore

cap drop term
cap drop _merge
merge m:1 mun_id using `test'

replace treat = term*time

areg perc_response treat i.short_month ln_price i.contract_type i.firm_type i.year, absorb(mun_id) cluster(mun_id)

global t = _b[treat]

clear
set obs 100
cap use data/final/random_check, replace
cap gen test = .
replace test = $t if _n == `i'
save data/final/random_check, replace
noi dis `i'
}
}
sort test
gen n = _n 
line n test, xline(-0.044, lcolor(red))

