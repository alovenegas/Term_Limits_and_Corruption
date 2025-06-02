*********************************************************************
*********************************************************************
*********************************************************************
*      				DESCRIPTIVE STATS
*********************************************************************
*********************************************************************
*********************************************************************
cap use data/final/final_dta, clear

tabstat ln_price bidders perc_response delay_days, by(year) s(mean sd median max min n)

**** Most important figure 
clear all 
use data/final/final_dta, clear

* Step 1: Initialize an empty matrix
tempname results
matrix `results' = J(1,4,.)

* Step 2: Get unique quarters
levelsof quarter, local(quarters)

* Step 3: Loop over each quarter
foreach q of local quarters {
    preserve
    keep if quarter == `q'

    qui reg ln_price term exp_type_2dig firm_type short_quarter

    scalar beta = _b[term]
    scalar sttd = _se[term]
    scalar lb = beta - (1.96*sttd)
    scalar ub = beta + (1.96*sttd)

    matrix `results' = `results' \ (`q', beta, lb, ub)
    scalar drop _all
    restore
}

* Step 4: Convert matrix to dataset
clear
svmat `results', names(col)

rename c1 quarter
rename c2 beta
rename c3 lb
rename c4 ub
drop if _n == 1

* Optional: format if quarter is time variable
format quarter %tq
drop if quarter < tq(2020q2)

* Step 5: Plot coefficient with confidence interval
twoway (rarea ub lb quarter, color(gs12) ) ///
    (line beta quarter, lcolor(blue) lwidth(medthick)) ///
    ,  ytitle("Diff-in-mean") ///
      xtitle("Quarter") graphregion(color(white)) xline(249) legend(off)

graph export "figures/coefplot_lnprice.pdf" , name("Graph") as(pdf) replace



cap use data/final/final_dta, clear
cap treatment

* Figure 1: Evolution of mean of bidders per month
preserve
drop if bidders == .
bysort municipality: egen m_bid = mean(bidders)
replace bidders = bidders - m_bid
collapse bidders, by(term month)
tw line bidders month if term == 0 || line bidders month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck")) graphregion(color(white))
graph export "figures/lineplot_bidders.pdf", as(pdf) name(Graph)
replace
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if ofertas == .
bysort municipality: egen m_bid = mean(ofertas)
replace ofertas = ofertas - m_bid
collapse ofertas, by(term month)
tw line ofertas month if term == 0 || line ofertas month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck")) graphregion(color(white))
graph export "figures/lineplot_ofertas.pdf", as(pdf) name(Graph) replace

restore

* Figure 3: Evolution of mean of perc of response per quarter
preserve
drop if perc_response == .
bysort municipality: egen m_bid = mean(perc_response)
replace perc_response = perc_response - m_bid
collapse perc_response, by(term month)
tw line perc_response month if term == 0 || line perc_response month if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck")) graphregion(color(white))
graph export "figures/lineplot_perc_response.pdf", as(pdf) name(Graph) replace

restore


* Figure 4: Evolution of new contracts 
preserve 
cap gen one = 1
collapse (sum) one, by(term month)
tw line one month if term == 0 || line one month if term == 1, tline(2022m3)
restore

* Figure 8: Evolution of the price of contracts
preserve 
bysort mun_id: egen mean = mean(ln_price)
replace ln_price = ln_price/mean
collapse ln_price, by(term month)
xtset term month, monthly
*gen d_ln_price = ln_price /l12.ln_price
tw line ln_price month if term == 0 || line ln_price month if term == 1, tline(2022m4) graphregion(color(white)) legend(label(1 "First term") label(2 "Lame duck"))
graph export "figures/lineplot_lnprice.pdf", as(pdf) name(Graph) replace
restore

* Figure 8: Evolution of the price of contracts
preserve 
cap gen one = 1
bysort mun_id: egen mean_lnprice = mean(ln_price)
replace ln_price = ln_price/mean_lnprice
collapse ln_price, by(term quarter)
xtset term quarter, quarterly
gen  d_ln_price = ln_price/l4.ln_price
drop if quarter < tq(2021q2)
tw line d_ln_price quarter if term == 0 || line d_ln_price quarter if term == 1, tline(2022q2) graphregion(color(white)) legend(label(1 "First term") label(2 "Lame duck"))
graph export "figures/lineplot_d_price.pdf", as(pdf) name(Graph) replace
restore

* Figure 9: Evolution of direct deals
preserve 
cap gen one = 1
cap gen dd = (contract_type == 1)
collapse one dd, by(term month)
gen corruption = 100*(dd/one)
tw line corruption month if term == 0 || line corruption month if term == 1, tline(2022m3) graphregion(color(white)) legend(label(1 "First term") label(2 "Lame duck"))
restore

** Figure 9: Evolution of mean firm size
preserve
drop if pyme == .
bysort mun_id: egen m_pyme = mean(pyme)
replace pyme = pyme - m_pyme
collapse pyme, by(term quarter)
tw line pyme quarter if term == 0 || line pyme quarter if term == 1 , tline(2022m3) legend(label(1 "First term") label(2 "Lame duck"))
restore



*** Density plots of ln_prices

twoway ///
(kdensity ln_price if term == 0, lcolor(%c1) lwidth(medthick) lpattern(solid) ///
 legend(order(1 "No Term Limit" 2 "Term Limited") ///
        region(lcolor(white)) size(medsmall)) ///
 graphregion(color(white)) ///
 xlabel(, labsize(small)) ///
 ylabel(, labsize(small)) ///
 xtitle("Log Price", size(medsmall)) ///
 ytitle("Density", size(medsmall))) ///
(kdensity ln_price if term == 1, lcolor(%c2) lwidth(medthick) lpattern(dash))

graph export "figures/prices_density.pdf", as(pdf) name(Graph) replace












