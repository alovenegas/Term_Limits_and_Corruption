**********************************************************
********************* DID ********************************
**********************************************************

cd "C:/Users/alove/Desktop/thesis"

use data/final/final_dta, clear

global outcomes bidders perc_response delay_days DifAdjudicaciónDías pyme 
winsor2 ln_price, cuts(5 95) by(year)

estimates clear

* MAIN RESULTS : INCREASE IN GENERAL PRICES

	dis "Estimating effects for: ln_price"
	reghdfe ln_price treat11, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store ln_price
	
	dis "Estimating effects for: ln_price"
	reghdfe ln_unit_price treat11, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store ln_unit_price
	
	
	* Event study
	q_event_study, outcome(ln_price) controls(mun_id short_quarter year exp_type_3dig) 

	
	* Alternative outcomes
preserve
collapse (first) $outcomes mun_id short_quarter year exp_type* treat11, by(tender_id)

* BASIC DID - OPTION TO REELECT
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	qui reghdfe `i' treat11, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store `i'
}
esttab *, keep(treat11) star(* 0.10 ** 0.05 *** 0.01)

tabstat ${outcomes}

* Event study
foreach i in $outcomes {
	keep if exp_type_3dig == 104
q_event_study, outcome(`i') controls(mun_id short_quarter year exp_type_1dig) 
*graph export "figures/`i'_eventstudy.pdf", as(pdf) name(Graph) replace
} 

* Heterogeneous Analysis
foreach i in 10 20 29 50 59 {
preserve 
keep if exp_type_2dig == `i'
event_study, outcome(ln_price) controls(mun_id short_quarter year firm_type)
graph export "figures/ln_price_`i'_eventstudy.pdf", as(pdf) name(Graph) replace
restore
}


* Heterogeneous Analysis in "Mantenimiento y Reparación"
foreach i in 101 103 104 107 108 {
preserve 
keep if exp_type_3dig == `i'
q_event_study, outcome(ln_price) controls(mun_id short_quarter year firm_type)
graph export "figures/ln_price_`i'_eventstudy.pdf", as(pdf) name(Graph) replace
restore
}



* BASIC DID - INTENTION TO REELECT
estimates clear
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	quiet reghdfe `i' treat21, absorb(mun_id short_quarter year ) cluster(mun_id)
	estimates store `i' 
}
esttab *, keep(treat21) star(* 0.10 ** 0.05 *** 0.01)

* BASIC DID - Controls
estimates clear

foreach i in ln_price perc_response {
	
if  `i' == ln_price {
 dis "Estimating effects for: `i'"
  qui reghdfe `i' treat11, absorb(mun_id short_quarter year) cluster(mun_id)
 estimates store `i'
} 

else {
 dis "Estimating effects for: `i'"
 qui reghdfe `i' treat11 ln_price, absorb(mun_id short_quarter year firm_type exp_type_1dig contract_type) cluster(mun_id)
 estimates store `i'
}
}
esttab *, keep(treat11) star(* 0.10 ** 0.05 *** 0.01)

* BASIC DID - INTENTION TO REELECT
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	quiet reghdfe `i' treat2, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store `i'
}
esttab *, keep(treat2) star(* 0.10 ** 0.05 *** 0.001)

* BASIC DID QUARTERLY - Controls with dynamic effects
* gen placebo and dynamic


** ROBUSTNESS CHECKS FOR PERC OF RESPONSE ***
* list of municipalities that incorporated last to SICOP
preserve
drop if inlist(municipality,"BELEN","SANTA ANA","ESCAZU","CURRIDABAT")

reghdfe ln_price treat11, ///
    absorb(mun_id short_quarter year) ///
    cluster(mun_id)

restore

***************************************************************
************ RANDOM TREATMENT CHECKS **************************
***************************************************************
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

cap drop treat
gen treat = term*time_1

reghdfe ln_price treat, absorb(mun_id short_quarter year exp_type_1dig firm_type) cluster(mun_id)

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

twoway line cdf_test test, sort xline(0.118) ylabel(, grid) graphregion(color(white))

graph export "figures/random_check_ln_price.pdf", as(pdf) name(Graph) replace

***************************************************************
***************************************************************
******  What Mechanisms Explain the Rise in Prices? ***********
***************************************************************
***************************************************************

use data/final/final_dta, clear
keep if exp_type_2dig == 104
bysort month mun_id : gen contracts = _N
bysort month mun_id firm_id: gen links = _N
gen market_share = floor((links/contracts)*100)
bysort month mun_id market_share: gen firms = _N

collapse (first) year short_month firms, by(municipality mun_id month market_share)
gen index = market_share^2 * firms

collapse (first) short_month year (sum) index, by(municipality mun_id month)

treatment
gen time = (month > tm(2022m3))
gen treat = term*time

collapse index, by(municipality month)
tw line index quarter if term == 0 || line index quarter if term == 1
restore
* Main regression
reghdfe index treat, absorb(mun_id year short_month) cluster(mun_id)


