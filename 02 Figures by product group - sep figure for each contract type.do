capture log close
local working "P:\Cases\/* redacted*/\Team\LCollis\20190812 Automate figures"
local Vendor_Shortcuts "P:\cases\/* redacted*/\Working Data"

use "`Vendor_Shortcuts'\Vendor Shortcuts.dta", clear
set obs 16
replace vendorname = "LANNETT CO INC b" in 16
replace vendor_abbrev = "lcib" in 16
replace vendor_color = 16 in 16
replace vendor_short = "Lannett" in 16
replace vendor_ndx = 16 in 16
gen brand=inlist(vendor_abbrev,"aul", "apl", "lcib", "pu")
gsort brand vendorname
gen order=_n
tostring order, replace
replace order = "0" + order if strlen(order)==1
replace vendor_abbrev=order+vendor_abbrev
rename vendorname VendorName
drop brand order

			tempfile shortcuts
			save `shortcuts.dta', replace

use "`working'\working data\data for figures.dta", clear
replace VendorName="LANNETT CO INC b" if VendorName=="LANNETT CO INC" & generic==0


merge m:1 VendorName using `shortcuts'
	assert _merge == 3
	drop _merge

*	Vendor Info
*	Read in the vendor-specific info and assign values to local macro variables
preserve
	use `shortcuts', clear
	sort vendor_ndx
	local num_vendors = c(N)	
	forvalue vendor_ndx = 1/`num_vendors' {
		local abbrev = vendor_abbrev[`vendor_ndx']
		local color_`abbrev' = vendor_color[`vendor_ndx']
		local short_`abbrev' = vendor_short[`vendor_ndx']		
	}
restore


*   Make list of figures for automated bookmarks in pdf file
*	Format xx yy zz graph_title_1 graph_title_2 drug product Vendor brand_name/generic
gen list_xx="01" if GenericName=="/* redacted*/"
gen drug = GenericName
replace drug = GenericName + " ER" if ER==1
replace list_xx="02" if GenericName=="/* redacted*/" & ER==0
replace list_xx="03" if GenericName=="/* redacted*/" & ER==1
tostring rank_for_drug, gen(list_yy)
replace list_yy = "0" + list_yy if strlen(list_yy)==1
gen prod_short = Form + " " + Strength + " " + strofreal(Size)

preserve
	keep list_xx list_yy g_product_desc drug prod_short
	duplicates drop
	sort g_product_desc
	expand (4)
	bysort g_product_desc: gen list_zz=_n
	tostring list_zz, replace
	replace list_zz = "0" + list_zz if strlen(list_zz)==1
	rename g_product_desc graph_title_1
	rename prod_short product
	gen graph_title_2=""
	gen graph_name_4 = ""
	replace graph_title_2="Vendor Acquisition Costs" if list_zz=="01"
	replace graph_name_4 = "- Acquisition Cost by Vendor" if list_zz=="01"
	replace graph_title_2="Non-Contract Price" if list_zz=="02"
	replace graph_name_4 = "- Non-Contract Sales Price by Vendor" if list_zz=="02"
	replace graph_title_2="Other Contract Price" if list_zz=="03"
	replace graph_name_4 = "- Other Contract Sales Price by Vendor" if list_zz=="03"
	replace graph_title_2="Govt. Contract Price" if list_zz=="04"
	replace graph_name_4 = "- Gov't Contract Sales Price by Vendor" if list_zz=="04"
*	`graph_name_1' `rank' `graph_name_3' `graph_name_4'
	gen filename = list_xx + " " + list_yy + " " + list_zz + " " + graph_name_4 + ".pdf"
	keep list_xx list_yy list_zz graph_title_1 graph_title_2 drug product filename
	order list_xx list_yy list_zz graph_title_1 graph_title_2 drug product filename
	sort list_xx list_yy list_zz
	save "`working'\output\list for by price type figures.dta", replace
restore


*	Graphs for each drug

levelsof g_product_desc, local(Products)
foreach l_Product of local Products {
	preserve
	keep if g_product_desc=="`l_Product'"
*/
	* make some locals for the figure save name
	local graph_name_1=list_xx[1]
	local rank = list_yy[1]
	
	* make macro for brand name for legend label
	tempfile manual_restore
	save `manual_restore.dta', replace
		keep vendor_abbrev product_name
		duplicates drop
		sort vendor_abbrev
		local num_vendors = c(N)		
		forvalue vendor_ndx = 1/`num_vendors' {
			local abbrev = vendor_abbrev[`vendor_ndx']
			display "`abbrev'"
			local product_name_`abbrev' = product_name[`vendor_ndx']
		display "`product_name_`abbrev''"
		}
	use `manual_restore.dta', clear
	if GenericName[1]=="/* redacted*/" {
		local week_range = "2014w9(4)2014w22"
		local tick_range = "2014w9(1)2014w22"
		local note_for_chart = "Source: /* redacted*/, /* redacted*/"
		}
	else {
		local week_range = "2013w40(4)2014w22"
		local tick_range = "2013w40(1)2014w22"
		local on_angle = "angle(45)"
		local note_for_chart="Source: /* redacted*/, /* redacted*/"
		}


	*->	Reshape so the data are wide
	keep sales_week price_* acq_cost vendor_abbrev product_name
	rename price_* price_*_
	rename acq_cost acq_cost_

	reshape wide price_*_ acq_cost_, i(sales_week product_name) j(vendor_abbrev) string


	*->	Aggregate plot, legend, and colors. 
	*	NEED: implement shapes and sizes.
	*local price_type = 1  
	forvalue price_type = 1/4 {	

		*->	Get a list of the vendors in this graph and store in `vendors'
		ds price_2_*
		local vendors = subinstr("`r(varlist)'", "price_2_", "", .)
		disp "`vendors'"

		*->	Initialize some collection variables
		local label = ""   // loop below incrementally adds: 1 /* redacted*/ 2 /* redacted*/ ...
		local plot = ""    // loop below  incrementally adds acq_cost_lci acq_cost_pf ...
		local color = ""   // adds appropriate color from shortcuts
		local order = ""   // adds 1 2 3 4 ... for legend
		local labnum = 1   // needed this in legend when we had multiple price types 
		local msymbol = ""
		local shape = ""
		local V_num = 1
		local size = ""
		if `price_type' == 1 {
				local price_type_name = "Vendor Acquisition Costs"
				local price_to_plot = "acq_cost_"
				local graph_name_3 = "01"
				local graph_name_4 = "- Acquisition Cost by Vendor"
				local add_note = ""
				}
		if `price_type' == 2 {
				local price_type_name = "Non-Contract Price"
				local price_to_plot = "price_2_"
				local graph_name_3 = "02"
				local graph_name_4 = "- Non-Contract Sales Price by Vendor"
				local add_note = `"     The term "Non-Contract" represents transactions with a contract group name of "N/A"."'
				}
		if `price_type' == 3 {
				local price_type_name = "Govt. Contract Price"
				local price_to_plot = "price_3_"
				local graph_name_3 = "04"
				local graph_name_4 = "- Gov't Contract Sales Price by Vendor"
				local add_note = `"     "Government Contract" represents transactions that appear to be made under a Public Health Service or Department of Defense arrangement."'
				}
		if `price_type' == 4 {
				local price_type_name = "Other Contract Price"
				local price_to_plot = "price_4_"
				local graph_name_3 = "03"
				local graph_name_4 = "- Other Contract Sales Price by Vendor"
				local add_note = `"     "Other Contract" represents sales made under a non-government contract."'
				}	
	*/			
		foreach vendor in `vendors' {
				display "`product_name_`vendor''"
				if "`product_name_`vendor''" == "Generic" {
						local add_shape = "triangle_hollow"
						}
				else {
						local add_shape = "circle_hollow"
						}
				
				disp "`vendor'"
				disp "`price_type_name'"
				disp "`color_`vendor''"
				disp "`short_`vendor''"
				local label = `"`label' label(`labnum' "`short_`vendor''" "`product_name_`vendor''") "'
				local order = "`order' `labnum'"
				local labnum = `labnum' + 1
				local plot = "`plot' `price_to_plot'`vendor'"
				local color = "`color' ce`color_`vendor''"
				local shape = "`shape' `add_shape'"
				
				if `V_num' == 1 {
					local size = "`size' large"
					}
				if `V_num' == 2 {
					local size = "`size' medlarge"
					}
				if `V_num' == 3 {
					local size = "`size' medium"
					}			
				if `V_num' == 4 {
					local size = "`size' medsmall"
					}			
				if `V_num' == 5 {
					local size = "`size' small"
					}			
				if `V_num' == 6 {
					local size = "`size' small"
					}	
				if `V_num' == 7 {
					local size = "`size' small"
					}
				
				*local size = "`size' large"
				local ++V_num
				
			}
			disp `"`label'"'
			disp `"`plot'"'
			disp "`order'"
			disp "`color'"
			disp "`shape'"
			
		*	Plot
		twoway connected `plot' sales_week, ///
			scheme(ce1) ///
			title("Privileged and Confidential – Prepared at the Request of Counsel", size(vsmall)) ///
			subtitle("`l_Product'" "`price_type_name'", size(small)) ///
			tlabel(`week_range', labsize(vsmall) `on_angle') ///
			tmtick(`tick_range') ///
			ttitle("Week Beginning", size(vsmall)) ///
			mcolor(`color') ///
			lcolor(`color') ///
			msymbol(`shape') ///
			msize(`size') ///
			ylabel(#6, labsize(small) angle(0)) ///
			yscale(range(0 100)) ///
			legend(size(vsmall) cols(4) span on ///
				`label' ///
				order(`order')) ///
			ytitle("Average Weekly Acquisition Cost and Price ($)", size(vsmall)) ///
			caption(`"`note_for_chart' `add_note'"' ///
			`"Note: Excludes returns, apparent internal transfers and sales by Vendors who were exclusively resellers to Puerto Rico and Virgin Islands."', size(tiny) span)		

			graph display, xsize(11) ysize(8.5) 
			graph export "`working'\output\Figures - joint/`graph_name_1' `rank' `graph_name_3' `graph_name_4'.pdf",  replace	
			graph export "`working'\output\Figures - joint/`graph_name_1' `rank' `graph_name_3' `graph_name_4'.png", width(2186) height(1000) replace
	
		}

	restore
}
* 
















