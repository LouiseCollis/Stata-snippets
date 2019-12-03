
clear
set obs 250      // make a dataset with 250 observations, no variable yet
set seed 3       // set a seed for the random function to make it return the same values each time
gen int ym=runiformint(ym(2014,7),ym(2019,6))   // generate a new variable called ym with type integer
format ym %tm                                   // format ym as a date variable year-month. See Drill 15
gen model=strofreal(runiformint(1,5))           // generate a new variable called brand, populate with random numbers 1-5 as string
duplicates drop									// I don't want the same product in the same month twice
replace model="Alpha" if model=="1"             // Give them some names
replace model="Beta" if model=="2"
replace model="Gamma" if model=="3"
replace model="Delta" if model=="4"
replace model="Epsilon" if model=="5"

gen quantity=runiformint(1,25)*5		// make some random quantities

gen year=yofd(dofm(ym))			// see Drill 15 for manipulating dates

count if model=="Alpha"
count if model=="Delta"

* create a new byte variable called conspiracy that =1 if the brand is Alpha or Delta; =0 otherwise
* scroll down if you need help


















/*
to create a new variable, use generate, or gen for short
You don't have to specify type, but depending on the defaults set up in Stata, 
	it will probably default to float or double which is less efficient (uses more memory)
You can either set the number to zero and then replace it later:
		gen byte conspiracy =0
		replace conspiracy=1 if <add condition>
where the conditions are model=="Alpha" or model=="Delta"
put it together 
		gen byte conspiracy =0
		replace conspiracy=1 if model=="Alpha" | model=="Delta"

Or you can do it all in one:
		gen byte conspiracy = (model=="Alpha" | model=="Delta")

*/

