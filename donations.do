use data/temp/elections2020, clear
replace win_party = trim(win_party)
gen party_clean = ustrupper( ustrregexra( ustrnormalize( party, "nfd" ) , "\p{Mark}", "" ))
keep party_clean municipality
duplicates drop party_clean, force
tempfile temp
save `temp', replace

use data/temp/donations, clear
rename dntn_pp party_clean
merge m:1 party_clean using `temp'
keep if _merge == 3

treatment

use data/temp/donations, clear
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