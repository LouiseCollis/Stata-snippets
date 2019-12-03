
* examples of use

use "G:\CE Training\2019 Training Modules\04. Stata-specific drills\Raw Data and Documents\2019-05-07 Myauto\MyAuto 1978.dta", clear

* after setting a path for working_data
use "`working_data'\MyAuto 1978.dta", clear

* after creating tempfile results
use `results', clear

* in a do file that is called from other code where the call has the format:
*     do "`results_code'\CS.do" "`results'" "`name'" "`X'" "CS" "`results_code'"
use "`1'\Disaggregated\\`2'_`3'", replace

* read in subset of data - quicker than reading in all and dropping unwanted
use issuer acquirer transaction_count using `bank' if ATM_location=="USA"



* examples of save 

save "`working_data'\MyAuto 1978.dta", replace

* in a do file that is called from other code where the call has the format:
*     do "`results_code'\CS.do" "`results'" "`name'" "`X'" "CS" "`results_code'"
save "`1'\Disaggregated\results_`4'", replace

* after creating tempfile results, before adding any data to results
save `results', replace emptyok



