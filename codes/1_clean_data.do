* Data from https://cgrweb.cgr.go.cr/apex/f?p=307:150::::::
cd "C:/Users/alove/Desktop/thesis"
include "C:\Users\alove\Documents\GitHub\Term_Limits_and_Corruption\programs.do"

* Prepare temp files from raw data
import excel "data/raw/bidders.xlsx", clear firstrow
rename (NúmerodeProcedimiento Cantidaddeparticipantesenel) (tender_id bidders)
keep tender_id bidders
duplicates drop tender_id, force
drop if bidders == .
recast str24 tender_id
save data/temp/bidders, replace
clear


* Invited to tenders
import excel "data/raw/invited.xlsx", clear firstrow
rename (NúmerodeProcedimiento Institución CantidaddeInvitados CantidaddeOfertaspresentadas CantidaddeProveedoresquepres) (tender_id municipality invitados ofertas ofertas_prov)
drop if invitados == .
recast str24 tender_id
save data/temp/invited, replace
clear


* Contracts with time 
import excel "data/raw/days1.xlsx", sheet("Export") firstrow clear
save data/temp/time, replace
import excel "data/raw/days2.xlsx", sheet("Export") firstrow clear
append using data/temp/time
rename NúmeroProcedimiento tender_id

drop if tender_id == ""
collapse (mean) DifAperturaDías DifNotificaciónDías DifAdjudicaciónDías (first) FechaPublicaciónBase , by(tender_id)
save "data/temp/time", replace
clear


* Donation data
import excel "data\raw\acumulado_donations.xlsx", sheet("BBDD") firstrow clear
keep if TIPOCONTRIBUCIÓN == "EFECTIVO"
keep if FECHA > td(01jan2020)
rename (CÉDULA MONTO PARTIDOPOLÍTICO FECHA) (rep_id dntn dntn_pp dntn_date)
sort rep_id dntn_date
collapse (first) dntn_date dntn_pp (sum) dntn, by(rep_id)

drop if rep_id == "0"
drop if strpos(rep_id,"NA")
drop if strpos(rep_id,"NI")
drop if strpos(rep_id,"NOINDICA")

destring rep_id, replace
save data/temp/donations, replace

* Municipalities date of SICOP inscription
import delimited "data\raw\fecha_ingreso_munis.csv", clear varnames(1)
drop v1
rename nombre_institucion municipality
replace municipality = strupper(municipality)
keep if strpos(municipality,"MUNICIPALIDAD")
drop if strpos(municipality,"FEDERACIóN")
clean_mun
replace fecha_ingreso = substr(fecha_ingreso,1,10)
gen fecha_ingreso1 = date(fecha_ingreso,"YMD")
format fecha_ingreso1 %td
keep municipality fecha_ingreso1
recast str20 municipality 
save data/temp/fecha_ingreso, replace
clear



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
clear


*** Income of municipalities
import delimited "data\raw\income2020.csv", clear
save data/temp/income, replace

forvalues i = 2021/2024 {
import delimited "data/raw/income`i'.csv", clear
append using data/temp/income
save data/temp/income, replace
}
rename inst municipality
clean_mun
drop if strpos(municipality,"COMITE")
drop if strpos(municipality,"FEDERACION")
drop if strpos(municipality,"JUNTA")
drop if strpos(municipality,"UNION")

* clean prices
split ejecutado, parse(",")
keep año cuenta descripc municipality ejecutado1
replace ejecutado1 = subinstr(ejecutado,".","",.)
destring ejecutado1, replace
rename ejecutado1 ejecutado

keep if inlist(descripcióncuenta,"INGRESOS DE CAPITAL","INGRESOS CORRIENTES","FINANCIAMIENTO")

cap drop id
egen id = group(municipality año)
replace cuenta = substr(cuenta,1,1)
drop descripc

reshape wide ejecutado año, i(id) j(cuenta) string
drop año2
rename (ejecutado1 año1 ejecutado2 ejecutado3) (corriente year capital financial)
drop id
treatment

* BCCR price index
gen price_index = 100 if year == 2020
replace price_index = 103.3 if year == 2021
replace price_index = 111.44 if year == 2022
replace price_index = 109.47 if year == 2023
replace price_index = 110.39 if year == 2024
/*

replace corriente = ln(100*(corriente/price_index))
replace capital = ln(100*(capital/price_index))
replace financial = ln(100*(financial/price_index))
*/

preserve
collapse corriente capital, by(term year)

twoway ///
    (line corriente year if term == 0, lcolor(blue) ) ///
    (line corriente year if term == 1, lcolor(blue*0.5)) ///
    (line capital year if term == 0, lcolor(red)) ///
    (line capital year if term == 1, lcolor(red*0.5)), ///
    graphregion(color(white)) ///
    legend(order(1 "Current income, first term" ///
                 2 "Current income, lame duck" ///
                 3 "Capital income, first term" ///
                 4 "Capital income, lame duck"))
graph export "figures/income_evolution.pdf", as(pdf) name(Graph) replace

restore
save data/temp/mun_income, replace
clear


*** Price index
import excel "data/raw/price_index_bccr", firstrow clear
keep month Nivel
cap drop month1
gen month1 = monthly(month,"YM")
drop month
rename month1 month
format month %tm
save data/temp/price_index, replace
clear

** Clean days to deliver the service
import excel "data/raw/delivery.xlsx", sheet("Export") firstrow clear
keep Númerodeprocedimiento Cantidaddedíasadelantoatras CédulayNombredelcontratista
rename (Númerodeprocedimiento Cantidaddedíasadelantoatras CédulayNombredelcontratista) (tender_id delay_days firm_id)
drop if delay_days == .
recast str24 tender_id
split firm_id, limit(1)
drop firm_id
rename firm_id1 firm_id

collapse delay_days, by(tender_id firm_id)

save data/temp/delivery, replace
clear

*** Readjustment prices from OCP Costa Rica
import excel "data/raw/reajusteprecios_ocpcr.xlsx", sheet("Export") firstrow clear
rename (Númerodeprocedimiento NúmerodeLíneadeContrato PrecioAdjudicado NúmerodeReajuste MontodelReajuste PrecioAnteriorÚltimoReajuste NuevoPrecio deIncrImentodelÚltimoReaju) (tender_id line p_adj numero_reajuste monto_reajuste precio_anterior new_price perc_change)
keep tender_id line p_adj numero_reajuste monto_reajuste precio_anterior new_price perc_change

collapse (max) numero_reajuste (sum) precio_anterior new_price, by(tender_id)

gen perc_change = (new_price - precio_anterior) / precio_anterior

save data/temp/reajusteprecios, replace
clear

* Prepare extra data
import delimited "data/raw/siac2020.csv", clear
drop descargarrespuestacgr
save siac, replace

foreach i in 2021 2022 2023 2024 {
	
	import delimited "data/raw/siac`i'.csv", clear
	drop descargarrespuestacgr
	append using siac
	save siac, replace
}

rename institucioncontratante municipality
keep if strpos(municipality, "MUNICIPALIDAD")
clean_mun
treatment 
rename (numero_procedimiento montoencolones nombredelcontratado ceduladelcontratado tipodeprocedimiento) (tender_id MontoAdjudicado Representante Cédularepresentante TipodeProcedimiento)

keep tender_id MontoAdjudicado Representante Cédularepresentante TipodeProcedimiento fecregistrodelcontrato municipality term

* tostring 
tostring Cédularepresentante, replace

* date
gen Fechasolicitudcontratación = date(fecregistrodelcontrato,"DMY")
drop fecregistrodelcontrato

* price
replace MontoAdjudicado = subinstr(MontoAdjudicado,".","",.)
destring MontoAdjudicado, replace

* sicop
gen sicop = 0

* replace
replace TipodeProcedimiento = "Contratación directa" if TipodeProcedimiento == "CONTRATACION DIRECTA"
replace TipodeProcedimiento = "Licitación abreviada" if TipodeProcedimiento == "LICITACION ABREVIADA"
replace TipodeProcedimiento = "Licitación mayor" if TipodeProcedimiento == "LICITACION MAYOR"
replace TipodeProcedimiento = "Licitación menor" if TipodeProcedimiento == "LICITACION MENOR"
replace TipodeProcedimiento = "Licitación pública nacional" if TipodeProcedimiento == "LICITACION PUBLICA NACIONAL"
replace TipodeProcedimiento = "Licitación reducida" if TipodeProcedimiento == "LICITACION REDUCIDA"
replace TipodeProcedimiento = "Procedimiento por excepción" if TipodeProcedimiento == "PROCEDIMIENTOS DE EXCEPCION - LGCP"

duplicates drop tender_id, force

save data/temp/siac, replace

