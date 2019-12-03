
local working_data "G:\CE Training\2019 Training Modules\04. Stata-specific drills\Raw Data and Documents"

import excel "`working_data'\2019-07-22 output from Drill 11\COH0000006123 cost data Q1.xls", sheet("Jan_2001") clear firstrow






* code to read in arbitrary number of sheets and merge them

local working_data "G:\CE Training\2019 Training Modules\04. Stata-specific drills\Raw Data and Documents"
clear
import excel using "`working_data'\2019-07-22 output from Drill 11\COH0000006123 cost data Q1.xls", describe
forvalues sheet=1/`=r(N_worksheet)' {
		local sheetname=r(worksheet_`sheet')
		di "Sheetname: `sheetname'"
		import excel using "`working_data'\2019-07-22 output from Drill 11\COH0000006123 cost data Q1.xls", sheet("`sheetname'") clear firstrow
		rename cost cost_`sheetname'
		tempfile file_`sheet'
		save `file_`sheet'', replace
		}
use `file_1', clear
		forv j=2/3 {
		merge 1:1 model_number using `file_`j'', nogen
		}

*













