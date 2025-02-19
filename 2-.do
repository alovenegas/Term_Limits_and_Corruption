cd "C:\Users\alove\Desktop\thesis\data"

import delimited "C:\Users\alove\Downloads\Egresos.csv", clear

sort institución
drop if _n <= 383

clean_mun

term_limit

reelec

merge m:1 municipality using pob_canton 
drop if _merge == 2
drop if _merge == 1

gen pob2020 = 5111238*share
gen pob2021 = 5163038*share
gen pob2022 = 5213374*share
gen pob2023 = 5262237*share

rename año year
replace ejecutado = subinstr(ejecutado,".","",.)
destring ejecutado, replace dpcomma

foreach i in 2020 2021 2022 2023 {
	replace ejecutado = ejecutado/pob`i' if year == `i'
}

replace ejecutado = log(ejecutado)

cap drop id
egen id = group(municipality cuenta)

xtset id year, yearly
bysort id (year): gen l_ejecutado = ejecutado - l.ejecutado

collapse (mean) l_ejecutado (sd) sd = l_ejecutado, by(year reelec descripcióncuenta cuenta)

gen upper = l_ejecutado + sd*1.96 
gen lower = l_ejecutado - sd*1.96

rename l_ejecutado ejecutado
preserve
keep if cuenta == "1.1.1.1"
tw line ejecutado year if reelec == 0 || line ejecutado year if reelec == 1 || rcap (upper lower year )
restore