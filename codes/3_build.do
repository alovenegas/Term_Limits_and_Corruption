* Corruption and Term Limits: Costa Rica
* Alonso Venegas-Cantillano
* Analysis and Policy in Economics
* Paris School of Economics
*****
* SICOP CONTRACTS
*****
cd "C:/Users/alove/Desktop/thesis"

import excel "data/raw/sicop1.xlsx", sheet("Export") firstrow clear
save data/temp/sicop, replace

import excel "data/raw/sicop2.xlsx", sheet("Export") firstrow clear
append using data/final/sicop
save data/temp/sicop, replace

import excel "data/raw/sicop3.xlsx", sheet("Export") firstrow clear
append using data/temp/sicop

save data/temp/sicop, replace

* Start cleaning and eliminate duplicates
cap use data/temp/sicop, clear

* Rename variables
rename (Institución NúmerodeProcedimiento CéduladeProveedorAdjudicado Línea) (municipality tender_id firm_id line)

* Eliminate duplicated contracts
duplicates drop tender_id firm_id line, force
replace municipality = strupper(municipality)
rename Cédularepresentante rep_id 
destring rep_id, replace

drop if line == .
drop if municipality == ""

sort municipality tender_id firm_id
egen ID = group(municipality tender_id firm_id) 


collapse (first) tender_id TipodeProcedimiento municipality DescripcióndeProcedimiento Códigodeproducto BienServicio Monedaadjudicada Fechasolicitudcontratación firm_id rep_id Representante TipoEmpresa ObjetodelGasto (sum) MontoAdjudicado, by(ID)

clean_mun
treatment

preserve
keep tender_id
duplicates drop
merge 1:m tender_id using data/temp/siac
keep if _merge == 2
drop _merge
save data/temp/siac, replace
restore 

gen sicop = 1
append using data/temp/siac, force


*********************************************************************
* Merge bidders
merge m:1 tender_id using data/temp/bidders
drop if _merge == 2
drop _merge

* Merge invited
merge m:1 tender_id using data/temp/invited
drop if _merge ==2 
drop _merge

* Merge time variables
merge m:1 tender_id using data/temp/time, force
drop if _merge ==2 
drop _merge

* Merge ingreso municipalidades
merge m:1 municipality using data/temp/fecha_ingreso
drop if _merge ==2 
drop _merge

* Merge delivery 
merge 1:1 tender_id firm_id using data/temp/delivery
drop if _merge == 2
drop _merge

* Merge price adjustments
merge m:1 tender_id using data/temp/reajusteprecios
drop if _merge == 2
drop _merge

* Merge sanctions
destring firm_id, replace
merge m:1 firm_id using "data/temp/prov_penalty"
drop if _merge == 2
drop _merge
replace sanction = 0 if sanction == .
replace sanction = 1 if sanction > 0

* Merge donations
merge m:1 rep_id using data/temp/donations
drop if _merge == 2
rename _merge donation
replace donation = 0 if donation == 1
replace donation = 1 if donation == 3

*********************************************************************
* Merge bidders
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
*rename Fechasolicitudcontratación date
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
gen exchange_rate = (compra + venta)/2
replace MontoAdjudicado = MontoAdjudicado*exchange_rate if Monedaadjudicada == "USD"
drop if Monedaadjudicada == "EUR"

* Merge price index
merge m:1 month using data/temp/price_index
drop if _merge == 2
drop _merge
replace MontoAdjudicado = 100*(MontoAdjudicado/Nivel)

* Merge municipalities income
merge m:1 municipality year using data/temp/mun_income
drop if _merge == 2
cap drop _merge

/*
************ clean variables
rename Cédularepresentante rep_id 
gen temp = substr(rep_id,1,1)
replace rep_id = substr(rep_id,2,.) if temp == "0"
drop temp
*/

* Municipality fixed effects
encode municipality, gen(mun_id)
keep if inrange(date,td(1may2020),td(30apr2024))

* Merge controls | Municipal level merge |  
	cap drop _merge
	merge m:1 municipality using "data/temp/elections2020"
	drop _merge 

*  Control variables
**  Tender type and firm size
encode TipodeProcedimiento, gen(contract_type)
encode TipoEmpresa, gen(firm_type)
replace firm_type = . if firm_type == 4
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
cap drop term
treatment
treatment2
cap drop time_treat treat*
gen time_treat = 0
replace time_treat = 1 if quarter > tq(2022q1)

gen treat = term * time_treat


* Log price of contract
rename (MontoAdjudicado) (price)
gen ln_price = ln(price)

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

