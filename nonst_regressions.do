
capture log close		
capture clear all	

** set initial parameters	
local file "$data/results/pass_through_results_$date"
local spec "prod fe"     // products as fixed effects
local addvars ""         // size, flatscreen

** run code to create program to store results
** program define record_results
** syntax using/, NAME(string) TYPE(string) CHANNEL(string) SPEC(string) ///
**		[tube_manufacturer tube_distributor product_manufacturer product_distributor online_retailer bm_retailer no_count std_reg]
** program define record_results_explicit
** syntax using/, NAME(string) TYPE(string) CHANNEL(string) SPEC(string) ///
** 		COEFficient(real) VARiance(real) DF(integer) ///
**		[tube_manufacturer tube_distributor product_manufacturer product_distributor online_retailer bm_retailer OBServations(integer 0)]
do "$path\common_programs\record_results_modified.do"

** run code to create program to create correct estimates in two-step product chain
** program define product_of_coefficients, rclass
** syntax anything , [independent LARGEvariance SMALLvariance test(numlist max=1)]
do "$path\common_programs\product_of_coefficients.do"


cd "$data"
********************************************************************************

use "panasonic_bestbuy_com_TAB_clean.dta", clear

areg unit_price tube_unit_price `addvars' [fweight = quantity] if quantity>0, a(model2) robust
record_results using "`file'.dta", name("Panasonic - Best Buy.com") type("Televisions") channel("Top-and-Bottom") spec("`spec'") tube_manufacturer online_retailer
test tube_unit_price = 1

********************************************************************************

use "samsung_bestbuy_tab_clean.dta", clear

areg bestbuy_unit_price samsung_unit_price `addvars' [fweight = bestbuy_quantity] if tv == 1 & bestbuy_quantity>0, a(model) robust
record_results using "`file'.dta", name("Samsung - Best Buy") type("Televisions") channel("Top-and-Bottom") spec("`spec'") tube_manufacturer bm_retailer
test samsung_unit_price = 1

********************************************************************************

use "samsung_bestbuy_tab_clean.dta", clear

areg bestbuy_unit_price samsung_unit_price `addvars' [fweight = bestbuy_quantity] if monitor == 1 & bestbuy_quantity>0, a(model) robust
record_results using "`file'.dta", name("Samsung - Best Buy") type("Monitors") channel("Top-and-Bottom") spec("`spec'") tube_manufacturer bm_retailer
test samsung_unit_price = 1

********************************************************************************

use "sanyo_data_combine.dta", clear

areg unit_price tube_cost `addvars' if tv == 1 & qty>0 [fweight=qty] , a(model) robust
record_results using "`file'.dta", name("Sanyo - Walmart") type("Televisions") channel("Top-and-Bottom") spec("`spec'") tube_manufacturer bm_retailer
test tube_cost = 1

********************************************************************************

use "sanyo_data_combine.dta", clear

tempfile smc_to_wm
tempfile wm

areg unit_cost tube_cost `addvars' if tv == 1 & qty>0 [fweight=qty], a(model) robust
estimates save `smc_to_wm'
test tube_cost = 1

areg unit_price unit_cost `addvars' if tv == 1 & tube_cost < . & qty>0 [fweight=qty], a(model) robust
estimates save `wm'
test unit_cost = 1

product_of_coefficients `smc_to_wm' `wm', large test(1)

record_results_explicit using "`file'.dta", name("Sanyo - Walmart") type("Televisions") channel("Top-to-Bottom") spec("`spec'") ///
	coef(`=r(b)') var(`=r(V)') df(`=r(r_df)')	///
	tube_manufacturer product_manufacturer bm_retailer


********************************************************************************

use "sanyo_data_combine.dta", clear

areg unit_cost tube_cost `addvars' if tv == 1 & qty>0 [fweight=qty], a(model) robust

record_results using "`file'.dta", name("sanyo_data_combine.dta") type("Televisions") channel("test") spec("`spec'") product_manufacturer
test tube_cost = 1

********************************************************************************

/*Toshiba*/

tempfile costco

use "..\TAEC\taec_data_load.dta", clear

keep if tube_type=="CPT"

rename unit_price tube_price
rename unit_cost tube_cost

tempfile toshiba_to_taec

gen byte tacp_flag=cond(strpos(ship_to_cust_name, "TOSHIBA AMERICA CONSUMER PROD"), 1, 0)
gen date=month
format date %tm

areg tube_price tube_cost `addvars' [fweight=qty_sold] if tacp_flag==1 & qty_sold>0, a(model) robust
estimates save `toshiba_to_taec'
test tube_cost=1

tempfile taec
save `taec', replace

tempfile taec_to_tacp

use `taec', clear

keep if tacp_flag==1
gen byte flatscreen=cond(strpos(description, "FLAT") | strpos(description, "PF"), 1, 0)
label var flatscreen "Indicator variable for flat screen CRT displays"

collapse (mean) tube_price [fweight=qty_sold], by(month size flatscreen)

tempfile taecmonth
save `taecmonth', replace

use "..\TACP\tacp_sales_clean.dta", clear

rename flat_screen flatscreen
merge m:1 month size flatscreen using `taecmonth'
drop if _merge==2
drop _merge

foreach s in "AG" "AN" "BA" "BZ" "CH" "CN" "EL" "EN" "GU" "HD" "JM" "JP" "MX" "PG" "PH" "PN" "PR" "TW" "VZ" {
	display as result "Dropping sales shipped to state `s'"
	drop if ship_to_state=="`s'"
}

encode model_number, generate(model_no)
rename unit_price fg_price
gen byte costco_flag=cond(strpos(bill_to_name, "COST"), 1, 0)

	tempfile tacp
	save `tacp', replace

use `tacp', clear
keep if costco_flag==1

collapse (mean) fg_price [fweight=sales_qty], by(month model_number)

rename fg_price tacp_price

	tempfile tacpcostco
	save `tacpcostco', replace

clear

!copy "..\Costco\costco.dta" `costco'
use `costco', clear

areg fg_price tube_price `addvars' [fweight = sales_qty] if costco_flag == 1 & sales_qty>0, a(model) robust
estimates save `taec_to_tacp'
test tube_price=1

use `costco', clear

gen int month=mofd(mbdate)
format month %tm

merge m:1 month model_number using `tacpcostco'
keep if _merge==3
drop _merge

encode model_number, generate(model)
gen date=month
format date %tm

	tempfile costco_to_endusers

areg unit_price tacp_price `addvars' [fweight=quantity] if tv==1 & quantity>0, a(model) robust
estimates save `costco_to_endusers'
test tacp_price=1

product_of_coefficients `toshiba_to_taec' `taec_to_tacp' `costco_to_endusers', large test(1)

record_results_explicit using "`file'.dta", name("Toshiba") type("Televisions") channel("Top-to-Bottom") spec("`spec'") ///
	coef(`=r(b)') var(`=r(V)') df(`=r(r_df)') ///
	tube_distributor product_manufacturer bm_retailer
	
	









