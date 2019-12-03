


* concatenate strings
gen unique_ATM_identifier = ATM_ID + " " + ATM_address + " " + ATM_state

* real(number as string) -> number; string(number) -> string {strofreal(number) does the same thing}
gen ym_source = ym(real(substr(str_period, 1, 4)), real(substr(str_period, -2, 2)))
gen yq = yq(year, int((real(substr(period, 2, 2)) - 1)/3) + 1)
gen address = string(street_number) + " " + street_name


* remove leading and trailing blanks
replace name=trim(name)
* replace internal multiple spaces with a single space
replace name=itrim(name)
gen id_equip = upper(trim(eqmt_init)) + " " + string(eqmt_nbr)

* identify a substring by starting point and length
keep if substr(stcc,1,3)=="112" | substr(stcc,1,5)=="29913"
* using a starting point by counting frm the right
replace b_sprb =1 if substr(orig_ship, -2,2) == "WY"

* check for a substring wihtin a string and return the starting position
* most often used to check if a substring exists within a string, returns zero if not
gen byte desktop = (strpos(description, "DESKTOP")>0)
replace pauth_regulated = 1 if substr(pauth_id_nbr,1,6) == "000009" & strpos(pauth_issue_id , "BN")
keep if strpos(stcc,"112")==1 | strpos(stcc,"29913")==1

