
clear all
set more off
set segmentsize 2g
set min_memory 16g

global data "/sciclone/home20/cbaehr/cambodia_gie/data"
global results "/sciclone/home20/cbaehr/cambodia_gie/results"

* global data "/Users/christianbaehr/Desktop"
* global results "/Users/christianbaehr/Desktop"

reghdfe, compile

import delimited "$data/panel.csv", clear

egen t = group(cell_id)
replace cell_id = t
drop t

replace ndvi = . if ndvi == -9999 | ndvi == -10000
replace ndvi = ndvi * 0.0001
replace year = year-1998

bysort cell_id (year): gen baseline_ndvi = ndvi[4]

replace plantation = "1" if plantation == "True"
replace plantation = "0" if plantation == "False"
destring plantation, replace

replace concession = "1" if concession == "True"
replace concession = "0" if concession == "False"
destring concession, replace

replace protected_area = "1" if protected_area == "True"
replace protected_area = "0" if protected_area == "False"
destring protected_area, replace

local var "temp precip ntl"

foreach i of local var {

	capture confirm string variable `i'
	if !_rc {
		replace `i' = "." if `i'=="NA"
		destring `i', replace
	}
	
}

bysort cell_id (year): gen ndvi_pretrend = ndvi[4] - ndvi[1]

replace precip = . if precip>1000 | precip==-1

compress

drop if missing(ndvi) | missing(trt) | missing(commune)

gen trt_dummy = (trt > 0)

outreg2 using "$results/ndvi_stats.doc", replace sum(log)
rm "$results/ndvi_stats.txt"

*** main models ***

capture quietly cgmreg ndvi trt_dummy, cluster(commune year)
outreg2 using "$results/main_models_dummytrt.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt_dummy, cluster(commune year) absorb(year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", N)
	
capture quietly reghdfe ndvi trt_dummy, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt_dummy temp precip, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt_dummy temp precip c.trt_dummy#c.baseline_ndvi, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt_dummy temp precip c.trt_dummy#c.(plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)
	
capture quietly reghdfe ndvi trt_dummy temp precip c.trt_dummy#c.(baseline_ndvi plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt_dummy temp precip c.trt_dummy#c.(baseline_ndvi road_distance plantation concession protected_area), cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt_dummy temp precip ndvi_pretrend, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

capture quietly reghdfe ndvi trt_dummy temp precip c.trt_dummy#c.(baseline_ndvi road_distance plantation concession protected_area) ndvi_pretrend, cluster(commune year) absorb(cell_id year)
outreg2 using "$results/main_models_dummytrt.doc", append noni nocons addtext("Year FEs", Y, "Grid cell FEs", Y)

