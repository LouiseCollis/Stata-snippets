* Make some fake data for the excercise
* Make prices that increase at a rate of about 0.5% per month or 6% per year
clear

set obs 144
gen order=_n   // numbers the rows from 1 to N (in this case 144)
gen Month_of_invoice=""
gen int Year_of_invoice=.

local row=1
forvalue year = 2001/2012 {
	foreach mnth in `=c(Months)' {
		replace Year_of_invoice = `year' in `row'
		replace Month_of_invoice = "`mnth'" in `row'
		local row=`row'+1
		}
	}

* Make some fake data for the excercise
* Make prices that increase at a rate of about 0.5% per month or 6% per year

set seed 95 // I want the following random numbers to be the same each time we 
	        // run this, so I set a seed for the random number generator

gen long price_product_1=runiformint(20,99)
replace price_product_1=price_product_1[_n-1]*(1+(runiformint(-20,120)/10000)) if _n>1
replace price_product_1=round(price_product_1,0.01)

gen long price_product_2=runiformint(120,199)
replace price_product_2=price_product_1[_n-1]*(1+(runiformint(-20,120)/10000)) if _n>1
replace price_product_2=round(price_product_2,0.01)

* delete about 1 in 5 prices - pehaps there were no prices changes in these months
forvalue iteration = 2/144 {
	replace price_product_1=. if runiformint(1,5)==5 & _n==`iteration'
	replace price_product_2=. if runiformint(1,5)==5 & _n==`iteration'

	}
*
* count how many are missing
count if missing(price_product_1)
count if missing(price_product_2)

* add code here to fill in the missing prices with the price above it
* scroll down if you need help


















/*
you want to replace price_product_1 with the one above it if it's missing
to check if it's missing, use either of these:
		< add code that does something >  if missing(price_product_1)
		< add code that does something >  if price_product_1==.
and the action is replace  
		replace price_product_1 = price_product_1[_n-1]
put it together 

		replace price_product_1 = price_product_1[_n-1] if missing(price_product_1)
		replace price_product_1 = price_product_2[_n-1] if missing(price_product_2)
*/

