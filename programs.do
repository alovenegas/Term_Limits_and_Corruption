cap program drop _all

program clean_mun 
replace municipality = strupper(municipality)
replace municipality = subinstr(municipality,"MUNICIPALIDAD DE","",.)
replace municipality = subinstr(municipality,"MUNICIPALIDAD","",.)
replace municipality = subinstr(municipality,"GUANACASTE","",.)
replace municipality = subinstr(municipality,"DE HEREDIA","",.)
replace municipality = subinstr(municipality,"í","I",.)
replace municipality = subinstr(municipality,"ú","U",.)
replace municipality = subinstr(municipality,"á","A",.)
replace municipality = subinstr(municipality,"ó","O",.)
replace municipality = subinstr(municipality,"é","E",.)
replace municipality = subinstr(municipality,"ñ","N",.)
replace municipality = subinstr(municipality,"Á","A",.)
replace municipality = subinstr(municipality,"L CANTON DE","",.)
replace municipality = subinstr(municipality,".","",.)
replace municipality = subinstr(municipality,"ALVARADO DE PACAYAS","ALVARADO",.)
replace municipality = subinstr(municipality,"ALFARO RUIZ","ZARCERO",.)
replace municipality = subinstr(municipality,"CAÑAS","CANAS",.)
replace municipality = subinstr(municipality,"AGUIRRE","QUEPOS",.)
replace municipality = subinstr(municipality,"VALVERDE VEGA","SARCHI",.)
replace municipality = subinstr(municipality,"VAZQUEZ","VASQUEZ",.)
replace municipality = subinstr(municipality,"DE CARTAGO","",.)
replace municipality = subinstr(municipality,"LEON CORTES CASTRO","LEON CORTES",.)
replace municipality = strtrim(municipality)
end

program treatment
cap drop term
gen term = 1
replace term = 0 if inlist(municipality,"OROTINA","BELEN","FLORES","CARTAGO","SAN PABLO","CURRIDABAT","SANTO DOMINGO","PALMARES","BARVA")
replace term = 0 if inlist(municipality,"SAN CARLOS","GRECIA","GOICOECHEA","LA UNION","ALAJUELA","POAS","TIBAS","DESAMPARADOS","OREAMUNO")
replace term = 0 if inlist(municipality,"SARCHI","PARAISO","SANTA BARBARA","MORA","PURISCAL","SANTA CRUZ","POCOCI","LIBERIA","NICOYA")
replace term = 0 if inlist(municipality,"BAGACES","CAÑAS","RIO CUARTO","PUNTARENAS","SARAPIQUI","QUEPOS","ABANGARES","DOTA","COTO BRUS")
replace term = 0 if inlist(municipality,"MATINA","UPALA","GOLFITO","LA CRUZ","TALAMANCA","AGUIRRE")

* Went to congress
*replace term = 1 if inlist(municipality,"CAÑAS","DESAMPARADOS","SARAPIQUI","BELEN")

* Retired
replace term = 1 if inlist(municipality,"SAN CARLOS")

* Died
replace term = 0 if inlist(municipality,"DOTA","TIBAS")

*Label
cap label define tl 0 "First term" 1 "Lame duck"
label values term tl
end 


program reelec
cap drop reelec
gen reelec = 1
replace reelec = 0 if inlist(municipality,"HEREDIA","ABANGARES","LA UNION","PALMARES","PARAISO","PURISCAL","RIO CUARTO","SARAPIQUI","GOLFITO")
replace reelec = 0 if inlist(municipality,"MATINA","SAN PABLO","TALAMANCA","UPALA","LIBERIA","OREAMUNO","POCOCI","CARTAGO","SARCHI")
replace reelec = 0 if inlist(municipality,"MORA","SANTA CRUZ","NICOYA","ALAJUELA","LA CRUZ","BARVA","SANTO DOMINGO")
end


program region 
cap drop region
gen region = 0
/*
replace region = 0 if inlist(municipality,"CENTRAL","ESCAZU","DESAMPARADOS","PURISCAL","ASERRI","MORA","TARRAZU","GOICOECHEA","SANTA ANA")
replace region = 0 if inlist(municipality,"SANTA ANA","ALAJUELITA","VASQUEZ","ACOSTA","MORAVIA","TIBAS","MONTES DE OCA","DOTA","CURRIDABAT")
replace region = 1 if inlist(municipality,"LEON CORTES","TURRUBARES","ALAJUELA","SAN RAMON","GRECIA","ATENAS","NARANJO","PALMARES","POAS")
replace region = 1 if inlist(municipality,"ZARCERO","SARCHI","CARTAGO","PARAISO","LA UNION","JIMENEZ","TURRIALBA","ALVARADO","OREAMUNO")
replace region = 1 if inlist(municipality,"OREAMUNO","EL GUARCO","HEREDIA","BARVA","SANTO DOMINGO","SANTA BARBARA","SAN RAFAEL")
replace region = 1 if inlist(municipality,"SAN ISIDRIO","BELEN","FLORES","SAN PABLO")
*/
replace region = 1 if inlist(municipality,"LIBERIA","NICOYA","SANTA CRUZ","BAGACES","CARRILLO","CANAS","ABANGARES","TILARAN","NANDAYURE")
replace region = 1 if inlist(municipality,"LA CRUZ","HOJANCHA")
replace region = 2 if inlist(municipality,"PUNTARENAS","ESPARZA","QUEPOS","PARRITA","GARABITO","MONTEVERDE","MONTES DE ORO","SAN MATEO","OROTINA")
replace region = 3 if inlist(municipality,"PEREZ ZELEDON","BUENOS AIRES","GOLFITO","OSA","COTO BRUS","CORREDORES","PUERTO JIMENEZ")
replace region = 5 if inlist(municipality,"LIMON","POCOCI","SIQUIRRES","TALAMANCA","MATINA","GUACIMO")
replace region = 4 if inlist(municipality,"SAN CARLOS","LOS CHILES","RIO CUARTO","UPALA","GUATUSO","UPALA","SARAPIQUI")
cap label define region 0 "Central" 1 "Chorotega" 2 "Pacifico Central" 3 "Brunca" 4 "Huetar Atl" 5 "Huetar Norte"
cap label values region region
end


* Event study code
program define q_event_study 
	syntax, outcome(varlist) controls(varlist)
	
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

reghdfe `outcome' e_m4 e_m3 e_m2 e_m1 e_1 e_2 e_3 e_4 e_5 e_6 e_7, absorb(`controls') cluster(mun_id)

// Store coefficients and standard errors
matrix b = e(b)
matrix V = e(V)

// Insert omitted category (e_m0 = 0)
matrix b = (b[1, 1..4], 0, b[1, 5..11]) 

// Expand variance-covariance matrix to include e_m0
matrix V = (V[1..4,1..4], J(4,1,0), V[1..4,5..11] \ ///
            J(1,4,0), 0, J(1,7,0) \ ///
            V[5..11,1..4], J(7,1,0), V[5..11,5..11]) 

// Create a coefplot using stored coefficients
coefplot (matrix(b), v(V)), ///
         keep(e_m4 e_m3 e_m2 e_m1 e_m0 c5 e_1 e_2 e_3 e_4 e_5 e_6 e_7) ///
         vertical omitted ///
         coeflabels(e_m4 = "-4" e_m3 = "-3" e_m2 = "-2" e_m1 = "-1" ///
                    c5 = "0" e_1 = "1" e_2 = "2" e_3 = "3" e_4 = "4" ///
                    e_5 = "5" e_6 = "6" e_7 = "7") ///
         xline(5, lcolor(red))  ///
         ciopts(recast(rcap) lcolor(black)) ///
         graphregion(color(white)) ytitle(`outcome') xtitle("Quarters from treatment")
		
	sleep 5000	

end



