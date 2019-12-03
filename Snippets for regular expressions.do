
* simple regexm match 
keep if regexm(cust_name, "OXBOW") | regexm(cust_name, "TERROR")
* look for a "T" followed by optional period followed by "V" followed by optional period, or the string "TELE"
gen byte tv=cond(regexm(itemdescription, "T\.?V\.?") | strpos(itemdescription, "TELE"), 1, 0)

* pull the (first set of) letters out of an ID that is made up of letters and numbers
gen eqp = regexs(0) if(regexm(eqp_id, "[A-Z]+"))

* look for combination of numbers and possible decimal point before an optional space and then the letters "IN" or the inch symbol "
replace size=regexs(1) if regexm(item_desc_line_1, "([0-9\.]+)[\ ]?IN") & size==""
replace size=regexs(1) if regexm(item_desc_line_1, `"([0-9]+)""') & size=="", missing

* pull out the numbers at the end of the contact, ignoring numbers after hyphen or period
gen pauth_id_nbr = regexs(1) if regexm(Contract, "([0-9][0-9][0-9][0-9][0-9][0-9])[\-]*[0-9]*$")
replace pauth_id_nbr = regexs(1) if regexm(Contract, "([0-9][0-9][0-9][0-9][0-9])[\.]*[0-9]*$") & missing(pauth_id_nbr)

* check for ID starting with the letters "UP"
replace billed_by_up=1 if regexm(pauth_issue_id, "^UP")

* appending subsets of each type to make annual sets, some were monthly, some were quarterly
* using regexm to see if the table type or year was in the file name.

local list: dir "$path_project\03 Temp Data\raw" files "*.dta"

foreach dataset_type in armuv002 baduv002 baduv2_supp baduv004 fsc_provision_table ///
	rasvw014 rasvw036 rasvw038_qlfr rasvw055 rasvw326 rule11_indicator tdbvw123 {
    
	di "`dataset_type'"

	forval year = 2000/2008 {
		clear
		save "`interim_data'/`dataset_type'_`year'.dta", emptyok replace
		cd "$path_project\03 Temp Data\raw"
		pwd
		pause on

		foreach dataset of local list {
		    if regexm("`dataset'", "`dataset_type'") {
				if regexm("`dataset'", "`year'") {
					di "Append : `dataset'"
					use "$path_project\03 Temp Data\raw/`dataset'", clear
					append using "`interim_data'/`dataset_type'_`year'.dta"
					save "`interim_data'/`dataset_type'_`year'.dta", replace
				}
			}
		}
	}
}
*	











