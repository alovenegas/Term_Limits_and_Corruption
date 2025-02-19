

cap drop event_time
gen event_time = quarter - tq(2022q1)
replace event_time = event_time
gen e_m4 = (event_time == -4) * term
gen e_m3 = (event_time == -3) * term
gen e_m2 = (event_time == -2) * term
gen e_m1 = (event_time == -1)  // Omitted category
gen e_0 = (event_time == 0) * term
gen e_1 = (event_time == 1) * term
gen e_2 = (event_time == 2) * term
gen e_3 = (event_time == 3) * term
gen e_4 = (event_time == 4) * term


areg perc_response e_m4 e_m3 e_m2 e_0 e_1 e_2 e_3 e_4 ln_price i.contract_type i.firm_type i.quarter, absorb(mun_id) cluster(mun_id)

coefplot, keep(e_m4 e_m3 me_m2 e_0 e_1 e_2 e_3 e_4) vertical ///
    xline(4, lcolor(red)) title("Event-Study: Term Limits and Corruption") ///
	xlabel(1 "-4" 2 "-3" 3 "-2" 4 "-1" 5 "0" 6 "1" 7 "2" 8 "3" 9 "4")  ///
	ciopts(recast(rcap) lcolor(black))

gen placebo_reform = year_of_reform - 3  // Artificially shift reform date

gen placebo_post = (year >= placebo_reform)

gen placebo_did = treatment * placebo_post

xtreg Y placebo_did X1 X2 X3 i.year, fe cluster(municipality_id)
