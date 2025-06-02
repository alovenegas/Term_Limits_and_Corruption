**********************************************************
********************* ID STRATEGY ************************
**********************************************************

use data/final/final_dta, clear

cap winsor2 ln_price, cuts(5 95) by(year)
cap drop time
gen time = (quarter>=tq(2022q2))
replace treat = term*time

global outcomes ln_price ln_price_w
label var ln_price "Log Price"
global mechanism bidders perc_response DifAdjudicaciónDías pyme ofertas ofertas_prov delay_days sanction donation

lab var bidders "Bidders"
lab var perc_response "Response Rate"
lab var DifAdjudicaciónDías "Days to award contract"
lab var pyme "PYME share"
lab var ofertas "Offers"
lab var ofertas_prov "Offers by Suppliers"
lab var delay_days "Delay of Days"
lab var donation "Share of contracts by donors"


* MAIN REGRESSIONS ON TOTAL PANEL
estimates clear
reghdfe ln_price treat, absorb(mun_id quarter short_quarter) cluster(mun_id)
est store ln_price

reghdfe ln_price treat, absorb(mun_id short_quarter year exp_type_3dig firm_type) cluster(mun_id)
est store ln_price_c
* reelect
reelec
cap gen time = (quarter>=tq(2022q2))
replace reelec = reelec*time
reghdfe ln_price reelec, absorb(short_quarter year mun_id exp_type_3dig firm_type) cluster(mun_id)

* Table Main
esttab * using "tables/main_prices.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace

* Winsorize prices
reghdfe ln_price_w treat, absorb(mun_id year short_quarter exp_type_3dig firm_type) cluster(mun_id)
est store ln_price_w_c

* Removing top gdp municipalities
cap gen ln_price_low = ln_price

replace ln_price_low = . if inlist(municipality,"BELEN","CURRIDABAT","SANTA ANA","ESCAZU")

reghdfe ln_price_low treat, absorb(mun_id short_quarter year exp_type_3dig firm_type) cluster(mun_id)
est store ln_price_low_c

* Restricted sample
preserve
drop if inlist(municipality,"ABANGARES","DOTA","GUATUSO","JIMENEZ","LA CRUZ","LEON CORTES","MONTES DE ORO")
drop if inlist(municipality,"NICOYA","NANDAYURE","PUNTARENAS","SAN PABLO","SIQUIRRES")
reghdfe ln_price treat, absorb(mun_id year short_quarter exp_type_3dig firm_type) cluster(mun_id)
tabstat ln_price
restore

* Table Robust
esttab *
esttab * using "tables/robust.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace

tabstat ln_price ln_price_low ln_price_w
estimates clear

tabstat ln_price, by(exp_type_2dig)


**********************************************************
* MAIN RESULTS
**********************************************************

cap gen one =1 
collapse (mean) ln_price year term short_quarter first_term $mechanism (sum) one, by(mun_id quarter)
xtset mun_id quarter, quarterly
tsfill, full
sort mun_id quarter

decode mun_id, gen(municipality)
cap drop term
treatment
gen time = (quarter>=tq(2022q2))
gen treat = term*time
reelec
replace reelec = reelec*time


	estimates clear
	dis "Estimating effects for: ln_price"
	
	reghdfe ln_price treat [fweight = one], absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store ln_price
	
	winsor2 ln_price, cuts(5 95) by(year)
	reghdfe ln_price_w treat, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store ln_price_w
	esttab *, keep(treat) star(* 0.10 ** 0.05 *** 0.01)
	
	* Event study
	qui xtevent ln_price [fweight = one], policyvar(treat) window(max)  impute(stag) cluster(mun_id) 
    xteventplot, nosupt graphregion(color(white))
	graph export "figures/ln_price_eventstudy.pdf", as(pdf) name(Graph) replace
	
	* Alternative outcomes: mechanisms
* BASIC DID - OPTION TO REELECT

use data/final/final_dta, clear
sort mun_id quarter tender_id firm_type
collapse $mechanism  treat term ln_price short_quarter year (first) exp_type_2dig contract_type firm_type , by(mun_id quarter tender_id)
replace perc_response = 1 if perc_response > 1
estimates clear 

foreach i in $mechanism {
	
	dis "Estimating effects for: `i'"
	qui reghdfe `i' treat, absorb(mun_id year short_quarter exp_type_2dig firm_type) cluster(mun_id)
	estimates store `i'
	
}
* Table Mechanisms
esttab*, se

esttab * using "tables/mechanisms.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace

tabstat ${mechanism}, s(mean median)


cap gen one = 1
collapse $mechanism ln_price treat short_quarter year (sum) one, by(mun_id quarter)
xtset mun_id quarter, quarterly

foreach i in $mechanism {
	* Event study
	qui xtevent `i' ln_price [fweight = one], policyvar(treat) window(max) impute(stag) cluster(mun_id) reghdfe addabsorb(short_quarter year)
    qui xteventplot, nosupt graphregion(color(white))
	
	graph export "figures/`i'_eventstudy.pdf", as(pdf) name(Graph) replace
}


*************************
* Heterogeneous Analysis by Expenditure Type
*************************
use data/final/final_dta, clear

estimates clear

foreach i in 10 20 29 50 59 {
preserve 
keep if exp_type_2dig == `i'
cap gen one =1 
collapse (mean) ln_price year term short_quarter first_term $mechanism (sum) one, by(mun_id quarter)
xtset mun_id quarter, quarterly
tsfill, full
sort mun_id quarter

decode mun_id, gen(municipality)
cap drop term
treatment
gen time = (quarter>=tq(2022q2))
gen treat = term*time

qui reghdfe ln_price treat [fweight = one], absorb(mun_id short_quarter year)
estimates store ln_price_`i'

xtevent ln_price , policyvar(treat) cluster(mun_id) addabsorb(short_quarter year) reghdfe window(max) imput(stag)
xteventplot, nosupt graphregion(color(white))
graph export "figures/ln_price_`i'_eventstudy.pdf", as(pdf) name(Graph) replace
restore
}
esttab * using "tables/exp_type_2dig.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace


use data/final/final_dta, clear
estimates clear

* Heterogeneous Analysis in "Mantenimiento y Reparación"
foreach i in 101 103 104 107 108 201 203 204 299 501 502 {
preserve 
keep if exp_type_3dig == `i'
tab contract_type, gen(ct)
tabstat ct*
cap gen one =1 
collapse (mean) ln_price year term short_quarter first_term $mechanism (sum) one, by(mun_id quarter)
xtset mun_id quarter, quarterly
tsfill, full
sort mun_id quarter

decode mun_id, gen(municipality)
cap drop term
treatment
gen time = (quarter>=tq(2022q2))
gen treat = term*time
qui reghdfe ln_price treat [fweight = one], absorb(mun_id short_quarter year)
estimate store ln_price_`i'

qui xtevent ln_price , policyvar(treat) cluster(mun_id) addabsorb(short_quarter year) reghdfe window(max) imput(stag)
dis "Log prices for exp type `i'"
xteventplot, nosupt graphregion(color(white))
graph export "figures/ln_price_`i'_eventstudy.pdf", as(pdf) name(Graph) replace
restore
}

esttab * using "tables/exp_type_3dig", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace

*************************
* Heterogeneous Analysis by Contract Type
*************************
use data/final/final_dta, clear
estimates clear

* Heterogeneous Analysis in "Mantenimiento y Reparación"
foreach i in 1 3  {
preserve 
keep if contract_type == `i'
cap gen one =1 
collapse (mean) ln_price year term short_quarter first_term $mechanism (sum) one, by(mun_id quarter)
xtset mun_id quarter, quarterly
tsfill, full
sort mun_id quarter

decode mun_id, gen(municipality)
cap drop term
treatment
gen time = (quarter>=tq(2022q2))
gen treat = term*time
qui reghdfe ln_price treat [fweight = one], absorb(mun_id short_quarter year)
estimate store ln_price_`i'

qui xtevent ln_price , policyvar(treat) cluster(mun_id) addabsorb(short_quarter year) reghdfe window(max) imput(stag)
dis "Log prices for exp type `i'"
xteventplot, nosupt graphregion(color(white)) 
graph export "figures/ln_price_contracttype`i'_eventstudy.pdf", as(pdf) name(Graph) replace
restore
}

dis "Results of the effect by expenditure type"
esttab * using "tables/contract_type.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace


***************************************************************
************ RANDOM TREATMENT CHECKS **************************
***************************************************************
quiet{
forvalues i = 1(1)1000 {
use data/final/final_dta, replace
set seed 12071999
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

cap drop treat
gen treat = term*time_1

reghdfe ln_price treat, absorb(mun_id short_quarter year exp_type_2dig firm_type) cluster(mun_id)

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
kdensity test
cumul test, gen(cdf_test) 

twoway line cdf_test test, sort xline(0.1343) ylabel(, grid) graphregion(color(white)) xtitle("Estimated Coeff")

graph export "figures/random_check_ln_price.pdf", as(pdf) name(Graph) replace

save data/temp/cdf_check, replace


***************************************************************
***************************************************************
******  MARKET CONCENTRATION INDICATORS             ***********
***************************************************************
***************************************************************

use data/final/final_dta, clear

preserve
tempfile firms
collapse (count) firm_id, by(mun_id quarter)
save `firms', replace
restore


bysort mun_id quarter: egen total_exp = sum(price)
bysort mun_id firm_id quarter: egen total_firm = sum(price)
gen market_share = (total_firm/total_exp)*100

bysort mun_id quarter: egen max_MS = max(market_share)
gen index = market_share^2 

collapse (first) short_quarter year index max_MS, by(mun_id firm_id quarter)
collapse (first) short_quarter year max_MS (sum) index, by(mun_id quarter)

decode mun_id, gen(municipality)
treatment

cap drop time
gen time = (quarter>=tq(2022q2))
gen treat = time*term

merge 1:1 mun_id quarter using `firms', nogen


preserve
collapse index max_MS firm_id, by(term quarter)
tw line max_MS quarter if term == 0 || line max_MS quarter if term == 1, graphregion(color(white)) xline(249)  legend(label(1 "First term") label(2 "Lame duck"))
graph export "figures/max_MS_lineplot.pdf", as(pdf) name(Graph) replace
tw line index quarter if term == 0 || line index quarter if term == 1, graphregion(color(white)) xline(249)  legend(label(1 "First term") label(2 "Lame duck"))
graph export "figures/hhindex_lineplot.pdf", as(pdf) name(Graph) replace
tw line firm_id quarter if term == 0 || line firm_id quarter if term == 1, graphregion(color(white)) xline(249)  legend(label(1 "First term") label(2 "Lame duck"))
graph export "figures/firms_lineplot.pdf", as(pdf) name(Graph) replace

restore

xtset mun_id quarter, quarterly

estimates clear

foreach j in index max_MS firm_id {
	
	reghdfe `j' treat, absorb(short_quarter year mun_id) cluster(mun_id)
	est store `j'

xtevent `j', policyvar(treat) reghdfe addabsorb(short_quarter year) window(max) imput(stag) 

xteventplot, nosupt graphregion(color(white))
graph export "figures/`j'_eventstudy.pdf", as(pdf) name(Graph) replace

}

esttab * using "tables/market.tex", keep(treat) star(* 0.10 ** 0.05 *** 0.01) se booktabs replace


*********************************************************************
* Placebo Tests
********************************************************************
use data/final/final_dta, clear

foreach time in 2021q1 2021q2 2021q3 2021q4 2022q1 2022q2 2022q3 2022q4 2023q1 2023q2 2023q3 2023q4 {

cap drop time
gen time = (quarter>=tq(`time'))
gen treat_`time' = term*time
dis "Placebo checks for `time'"
qui reghdfe ln_price treat_`time', absorb(mun_id year short_quarter exp_type_2dig firm_type) cluster(mun_id)
est store ln_price_`time'

}

coefplot ln_price_2021q1 ln_price_2021q2 ln_price_2021q3 ln_price_2021q4 ln_price_2022q1 ln_price_2022q2, keep(treat*) vertical graphregion(color(white)) plotregion(margin(zero)) scheme(s1mono) yline(0, lpattern(dash) lcolor(gs8)) legend(off)  xlabel(1 "2021q1" 2 "2021q2" 3 "2021q3" 4 "2021q4" 5 "2022q1" 6 "2022q2", angle(45)) 

graph export "figures/placebotests.pdf", as(pdf) name(Graph) replace






