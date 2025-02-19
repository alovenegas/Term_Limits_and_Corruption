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
gen term = 1
replace term = 0 if inlist(municipality,"HEREDIA","BELEN","FLORES","CARTAGO","SAN PABLO","CURRIDABAT","SANTO DOMINGO","PALMARES","BARVA")
replace term = 0 if inlist(municipality,"SAN CARLOS","GRECIA","GOICOECHEA","LA UNION","ALAJUELA","POAS","TIBAS","DESAMPARADOS","OREAMUNO")
replace term = 0 if inlist(municipality,"SARCHI","PARAISO","SANTA BARBARA","MORA","PURISCAL","SANTA CRUZ","POCOCI","LIBERIA","NICOYA")
replace term = 0 if inlist(municipality,"BAGACES","CAÑAS","RIO CUARTO","PUNTARENAS","SARAPIQUI","QUEPOS","ABANGARES","DOTA","COTO BRUS")
replace term = 0 if inlist(municipality,"MATINA","UPALA","GOLFITO","LA CRUZ","TALAMANCA")

* Went to congress
replace term = 1 if inlist(municipality,"CAÑAS","DESAMPARADOS","SARAPIQUI","BELEN")

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
gen reelec = 0
replace reelec = 1 if inlist(municipality,"HEREDIA","ABANGARES","LA UNION","PALMARES","PARAISO","PURISCAL","RIO CUARTO","SARAPIQUI","GOLFITO")
replace reelec = 1 if inlist(municipality,"MATINA","SAN PABLO","TALAMANCA","UPALA","LIBERIA","OREAMUNO","POCOCI","CARTAGO","SARCHI")
replace reelec = 1 if inlist(municipality,"MORA","SANTA CRUZ","NICOYA","ALAJUELA","LA CRUZ","BARVA","SANTO DOMINGO")
end


program region 
gen region = 0
replace region = 1 if inlist(municipality,"CENTRAL","ESCAZU","DESAMPARADOS","PURISCAL","ASERRI","MORA","TARRAZU","GOICOECHEA","SANTA ANA")
replace region = 1 if inlist(municipality,"SANTA ANA","ALAJUELITA","VASQUEZ","ACOSTA","MORAVIA","TIBAS","MONTES DE OCA","DOTA","CURRIDABAT")
replace region = 1 if inlist(municipality,"LEON CORTES","TURRUBARES","ALAJUELA","SAN RAMON","GRECIA","ATENAS","NARANJO","PALMARES","POAS")
replace region = 1 if inlist(municipality,"ZARCERO","SARCHI","CARTAGO","PARAISO","LA UNION","JIMENEZ","TURRIALBA","ALVARADO","OREAMUNO")
replace region = 1 if inlist(municipality,"OREAMUNO","EL GUARCO","HEREDIA","BARVA","SANTO DOMINGO","SANTA BARBARA","SAN RAFAEL")
replace region = 1 if inlist(municipality,"SAN ISIDRIO","BELEN","FLORES","SAN PABLO")
replace region = 2 if inlist(municipality,"LIBERIA","NICOYA","SANTA CRUZ","BAGACES","CARRILLO","CANAS","ABANGARES","TILARAN","NANDAYURE")
replace region = 2 if inlist(municipality,"LA CRUZ","HOJANCHA")
replace region = 3 if inlist(municipality,"PUNTARENAS","ESPARZA","QUEPOS","PARRITA","GARABITO","MONTEVERDE","MONTES DE ORO","SAN MATEO","OROTINA")
replace region = 4 if inlist(municipality,"PEREZ ZELEDON","BUENOS AIRES","GOLFITO","OSA","COTO BRUS","CORREDORES","PUERTO JIMENEZ")
replace region = 5 if inlist(municipality,"SAN CARLOS","LOS CHILES","RIO CUARTO","UPALA","GUATUSO","UPALA","SARAPIQUI")
label define region 0 "Central" 1 "Chorotega" 2 "Pacifico Central" 3 "Brunca" 4 "Huetar Atl" 5 "Huetar Norte"
label values region region
end


