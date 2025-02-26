
**********************************************************
********************* DID ********************************
**********************************************************
cap use data/final/final_dta, clear

global outcomes ln_price perc_response days_contract days_adj bidders invitados perc_response donate len_description pyme
global outcomes_sig ln_price perc_response 
estimates clear

* BASIC DID - OPTION TO REELECT
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	reghdfe `i' treat, absorb(mun_id short_quarter year)
	estimates store `i'
}
esttab *, keep(treat) star(* 0.10 ** 0.05 *** 0.001)


estimates clear

* BASIC DID - INTENTION TO REELECT
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	quiet reghdfe `i' treat2, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store `i'
}
esttab *, keep(treat2) star(* 0.10 ** 0.05 *** 0.001)


* BASIC DID - Controls
preserve
keep if inlist(exp_type_1dig,1,2,5)
estimates clear
foreach i in $outcomes {
	
if  `i' == pyme | `i' == ln_price {
 dis "Estimating effects for: `i'"
  reghdfe `i' treat, absorb(mun_id short_quarter year) cluster(mun_id)
 estimates store `i'
} 

else {
 dis "Estimating effects for: `i'"
 areg `i' treat i.short_quarter i.year ln_price i.firm_type  i.contract_type , absorb(mun_id) cluster(mun_id)
 estimates store `i'
}

}
esttab *, keep(treat) 
restore

* BASIC DID - INTENTION TO REELECT
foreach i in $outcomes {
	
	dis "Estimating effects for: `i'"
	quiet reghdfe `i' treat2, absorb(mun_id short_quarter year) cluster(mun_id)
	estimates store `i'
}
esttab *, keep(treat2) star(* 0.10 ** 0.05 *** 0.001)



* BASIC DID MONTHLY - Controls with dynamic effects
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
foreach i in $outcomes_sig {
areg `i' e_m9 e_m8 e_m7 e_m6 e_m5 e_m4 e_m3 e_m2 e_m0 e_1 e_2 e_3 e_4 e_5 e_6 e_7 e_8 e_9 i.contract_type i.firm_type i.exp_type_1dig i.short_month i.quarter, absorb(mun_id) cluster(mun_id)

coefplot, keep(e_m9 e_m8 e_m7 e_m6 e_m5 e_m4 e_m3 e_m2 e_m0 e_1 e_2 e_3 e_4 e_5 e_6 e_7 e_8 e_9) vertical ///
    xline(9, lcolor(red)) title("Event-Study: `i'") ///
	ciopts(recast(rcap) lcolor(black))
	sleep 10000
}


* BASIC DID QUARTERLY - Controls with dynamic effects
* gen placebo and dynamic
cap drop event_time
cap drop e_*
gen event_time = quarter - tq(2022q2)

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

estimates clear
foreach i in $outcomes_sig {
areg `i' e_m4 e_m3 e_m2 e_m1 e_1 e_2 e_3 e_4 e_5 e_6 e_7 i.exp_type_1dig i.short_quarter i.year i.firm_type i.contract_type, absorb(mun_id) cluster(mun_id)

coefplot, keep(e_m9 e_m8 e_m7 e_m6 e_m5 e_m4 e_m3 e_m2 e_m0 e_1 e_2 e_3 e_4 e_5 e_6 e_7 e_8 e_9) vertical ///
    xline(4, lcolor(red)) title("Event-Study: `i'") ///
	ciopts(recast(rcap) lcolor(black))
	sleep 10000
}


** ROBUSTNESS CHECKS FOR PERC OF RESPONSE ***
* list of municipalities that incorporated last to SICOP
preserve
drop if inlist(municipality,"ACOSTA","MONTES DE ORO","LA CRUZ","DOTA","LEON CORTES","RIO CUARTO","POCOCI","BAGACES")
drop if inlist(municipality,"LIBERIA","NANDAYURE","SAN PABLO","GUATUSO","JIMENEZ","LA CRUZ","NICOYA")

areg perc_response treat time i.short_month ln_price i.contract_type i.firm_type i.year, absorb(mun_id) cluster(mun_id)
restore

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

reghdfe ln_price treat, absorb(mun_id short_quarter year contract_type) cluster(region)

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
line n test, xline(0.13, lcolor(red))
