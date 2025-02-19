
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

*****
* SICOP CONTRACTS
*****

import excel "data/raw/contratos1.xlsx", sheet("Export") firstrow clear
save data/final/sicop, replace

import excel "data/raw/contratos2.xlsx", sheet("Export") firstrow clear
append using data/final/sicop
save data/final/sicop, replace

split NombreyCéduladelaInstitució, parse(" - ") gen(mun_id)
split NombreyCéduladelContratista, parse(" - ") gen(firm_id)
replace firm_id2 = firm_id2 + firm_id3
drop firm_id3
rename (firm_id1 firm_id2 mun_id1 mun_id2 Númerodeprocedimiento) (firm_id firm_name mun_id municipality tender_id)

replace municipality = strupper(municipality)

sort tender_id Línea
drop if municipality == ""

bysort tender_id firm_id: gen tag = _N
replace tag = -tag 
sort tender_id tag
drop tag

collapse (first) DescripcióndelProcedimiento firm_id firm_name municipality mun_id FechadeModificación Modificación, by(tender_id)

clean_mun
treatment

drop if _n == 44919
recast str24 tender_id
* Merge bidders
merge m:1 tender_id using data/temp/bidders
drop if _merge == 2
drop _merge

* Merge invited
merge 1:1 tender_id using data/temp/invited
drop if _merge ==2 
drop _merge

rename FechadeModificación date
gen year = year(date)
gen month = month(date)
gen quarter = quarter(date)

replace quarter = yq(year,quarter)
replace month = ym(year,month)
format quarter %tq
format month %tm 
drop if tender_id == ""

************ clean variables
rename Cédularepresentante rep_id 
cap drop _merge
merge m:1 rep_id using data/temp/donations, keep(1 3)
gen donate = (_merge == 3)
drop _merge

save data/final/sicop, replace

use data/final/sicop, clear

gen time = (quarter>tq(2022q1))

keep if inrange(date,td(1apr2020),td(30mar2024))


* Merge controls | Municipal level merge
cap drop _merge
merge m:1 municipality using "data/temp/elections2020"

***********************************************************
**************************************************************
*** CONTROL VARIABLES
***********************************************************
***********************************************************

* New firms ?
sort mun_id firm_id quarter
bysort mun_id firm_id : gen n = _n
replace n = 0 if n == 1
replace n = 1 if n >= 1

** Tender type and firm size
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

* gen montos


* Figure 1: Evolution of mean of bidders per quarter
preserve
drop if bidders == .
bysort municipality: egen m_bid = mean(bidders)
replace bidders = bidders/m_bid
collapse bidders, by(term quarter)
tw line bidders quarter if term == 0 || line bidders quarter if term == 1 , tline(2022q2) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if ofertas == .
bysort municipality: egen m_bid = mean(ofertas)
replace ofertas = ofertas/m_bid
collapse ofertas, by(term quarter)
tw line ofertas quarter if term == 0 || line ofertas quarter if term == 1 , tline(2022q2) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of invited per quarter
preserve
drop if invitados == .
bysort municipality: egen m_bid = mean(invitados)
replace invitados = invitados/m_bid
collapse invitados, by(term quarter)
tw line invitados quarter if term == 0 || line invitados quarter if term == 1 , tline(2022q2) legend(label(1 "First term") label(2 "Lame duck"))
restore

* Figure 2: Evolution of mean of first time 
preserve
drop if n == .
bysort municipality: egen m_bid = mean(n)
replace n = n/m_bid
collapse n, by(term quarter)
tw line n quarter if term == 0 || line n quarter if term == 1 , tline(2022q2) legend(label(1 "First term") label(2 "Lame duck"))
restore


preserve 
drop if year == 2024
collapse donate , by(term year)
tw line donate year if term_limit == 0 || line donate year if term_limit == 1 , tline(2022)
restore


***********************************************************
********************* DID ********************************
**********************************************************

* First regression
gen treat = term*time

areg bidders treat i.quarter, absorb(mun_id) cluster(mun_id)
areg n treat i.quarter, absorb(mun_id)
areg bidders treat i.quarter, absorb(mun_id) cluster(mun_id)
areg bidders treat i.quarter#term, absorb(mun_id) cluster(mun_id)

areg bidders treat##i.quarter  ln_price age i.firm_type i.contract_type, absorb(mun_id) cluster(mun_id)

areg invitados treat ln_price age i.firm_type i.quarter i.contract_type, absorb(mun_id) cluster(mun_id)
areg ofertas treat ln_price age i.firm_type i.quarter i.contract_type, absorb(mun_id) cluster(mun_id)
areg ofertas_prov treat ln_price age i.firm_type i.quarter i.contract_type, absorb(mun_id) cluster(mun_id)


replace treat = term_limit*time


collapse (mean) bidders term_limit (sd) sd_bidders = bidders , by(mun_id quarter)

drop time
replace time = (quarter>=tq(2022q1))

did_multiplegt_dyn bidders mun_id quarter treat, effects(6) placebo(3) controls(ln_price invitados)

did_multiplegt_dyn ofertas mun_id quarter treat, effects(6) placebo(3)

did_multiplegt_dyn invitados mun_id quarter treat, effects(6) placebo(3) 

tab firm_type, gen(firm)
tab contract_type, gen(t_type)

did_multiplegt_dyn bidders mun_id quarter treat, effects(6) placebo(3) controls(ln_price firm2 firm3 firm4 firm5 t_type2 t_type3 t_type4 t_type5 t_type6)

did_multiplegt_dyn bidders mun_id quarter treat, effects(6) placebo(3) controls(ln_price firm2 firm3 firm4 firm5 t_type2 t_type3 t_type4 t_type5 t_type6)


did_multiplegt_dyn donate mun_id quarter treat, effects(3) placebo(3) cluster(mun_id) controls(ln_price) 


did_multiplegt_dyn pyme mun_id quarter treat, effects(3) placebo(3) cluster(mun_id) 


