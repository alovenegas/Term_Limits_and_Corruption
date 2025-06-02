* Term limits and corruption 
* Alonso Venegas Cantillano
* Paris School of Economics
* APE - Master's Thesis
* Main program

cd "C:/Users/alove/Desktop/thesis"

* Include programs
include "codes\programs"

program main 

* Clean and prepare temp files
include "codes/1_clean_data.do"
* Build main database, merge temp files and descriptive stats
include "codes/2_balancetests.do"
* Build data
include "codes/3_build.do"
* Descriptive
include "codes/4_descriptive"
* Econometric analysis and main figures
include "codes/5_analysis.do"

end 

main 


