* This code was not written by me; I don't know who to atribute it to
* I got it attached to a report written by Dr Janet Netz 2013
* If this is your code, let me know and I will attribute or remove
* I don't want to lose it, because I have found it very useful

* It is called from a program where regressions have been run, for example:

/*

tempfile dist_to_retail
tempfile to_cust

areg u_cost t_cost `addvars' if flag == 1 & qty>0 [fweight=qty], a(model) robust
estimates save `dist_to_retail'

areg u_price u_cost `addvars' if flag == 1 & t_cost < . & qty>0 [fweight=qty], a(model) robust
estimates save `to_cust'

product_of_coefficients `dist_to_retail' `to_cust', large test(1)

*/

* It stores coef(`=r(b)') var(`=r(V)') df(`=r(r_df)') for use in results file



capture log off

if _rc == 0 log on

capture program drop product_of_coefficients

program define product_of_coefficients, rclass
version 10.1
syntax anything , [independent LARGEvariance SMALLvariance test(numlist max=1)]

	if "`independent'`largevariance'`smallvariance'" == "" {
		display as error "You must specify one of: independent largevariance or smallvariance"
		exit(200)
	}

	if length("`independent'`largevariance'`smallvariance'") > 14 {
		display as error "You cannot specify more than one of independent largevariance or smallvariance"
		exit(200)
	}

	local sz : word count `anything'

	tempname X
	matrix define `X' = J(`sz', 2, .)

	tempname loop_counter
	scalar `loop_counter' = 0

	tempname RT
	scalar `RT' = 1

	tempname MIN_DF
	scalar `MIN_DF' = .

	preserve

	foreach fn of local anything {
		scalar `loop_counter' = `loop_counter' + 1
		capture confirm file "`fn'"
		if _rc != 0 {
			display as error `"File "`fn'" does not exist."'
			exit(201)
		}
		capture estimates use "`fn'"
		if _rc != 0 {
			display as error `"File "`fn'" is not a saved estimates file."'
			exit(202)
		}

		tempname B
		matrix `B' = e(b)
		tempname V
		matrix `V' = e(V)

		scalar `MIN_DF' = min(`MIN_DF', e(df_r))

		matrix `X'[`=`loop_counter'', 1] = `B'[1,1]
		matrix `X'[`=`loop_counter'', 2] = `V'[1,1]

		scalar `RT' = `RT' * `B'[1,1]
	}

	scalar `RT' = `RT' 

	tempname part1
	tempname part2
	scalar `part1' = 0	
	scalar `part2' = 0

	tempname coef
	scalar `coef' =  1

	forvalues i=1/`sz' {
		scalar `coef' = `coef' * `X'[`i', 1]

		scalar `part1' = `part1' + `X'[`i',2] * ( `RT' / `X'[`i',1] ) ^ 2

		if "`independent'" == "" {
			forvalues j = `=`i'+1'/`sz' {
				scalar `part2' = `part2' + 2 * sqrt(`X'[`i',2] * `X'[`j',2]) * (`RT' ^ (`loop_counter') / `X'[`i',1] / `X'[`j',1])
			}
		}
	}

	tempname variance
	if "`independent'" != "" {
		display as text "Assuming coefficient distributions are independent"
		scalar `variance' = `part1'
	}
	else if "`largevariance'" != "" {
		display as text "Assuming coefficient distributions correlated, upper bound on varaince"
		scalar `variance' = `part1' + `part2'
	}
	else if "`smallvariance'" != "" {
		display as text "Assuming coefficient distributons are correlated, lower bound on variance"
		scalar `variance' = `part1' - `part2'
	}

	display as text "Estimated Coefficient: " as result string(`coef')
	display as text "Variance: " as result string(`variance')
	display as text "Std. Error: " as result string(sqrt(`variance'))

	if "`test'" != "" {
		tempname tstat
		tempname pvalue
		scalar `tstat' = (`coef' - `test') / sqrt(`variance')
		scalar `pvalue' = ttail(`MIN_DF', `tstat')

		display
		display as text "Hypothesis tests and confidence intervals estimated using a t distribution with " as result `MIN_DF' as text " degrees of freedom."
		display

		if `tstat' > 0 {
			display as text "H0 : Pr( b = `test' ) two-sided: " as result ttail(`MIN_DF', `tstat') * 2
		}
		else {
			display as text "H0 : Pr( b = `test' ) two-sided: " as result ttail(`MIN_DF', -1 * `tstat')*2
		}
		display as text "H1 : Pr( b < `test' ) one-sided: " as result `pvalue'
		display as text "H1 : Pr( b > `test' ) one-sided: " as result 1-`pvalue'
		display
		display as text "Lower Bound 95% Confidence Interval: " as result `coef' + invttail(`MIN_DF', .975) * sqrt(`variance')
		display as text "Upper Bound 95% Confidence Interval: " as result `coef' - invttail(`MIN_DF', .975) * sqrt(`variance')
	}

	return scalar b = `coef'
	return scalar V = `variance'
	return scalar r_df = `MIN_DF'
end
