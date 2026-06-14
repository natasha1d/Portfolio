clear all
set more off

* Set path
global IN  "/Users/natashyadikola/Documents/Stata"
global OUT "/Users/natashyadikola/Documents/Stata"

* Generate calibrated weights using population growth 2019 Q4 to 2020 Q1

* Load 2019 Q4 data and calculate total population
use "$IN/qlfs_2019_q4_clean.dta", clear
svyset [pw=Weight]
svy: total Weight
scalar pop_2019 = e(N_pop)
di "2019 Q4 Population: " pop_2019

* Load 2020 Q1 data and calculate total population
use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]
svy: total Weight
scalar pop_2020 = e(N_pop)
di "2020 Q1 Population: " pop_2020

* Calculate population growth rate
scalar pop_growth_rate = (pop_2020 - pop_2019) / pop_2019
di "Population Growth Rate 2019 Q4 to 2020 Q1: " pop_growth_rate

global pop_growth_2020 = pop_growth_rate

* Load 2019 Q4 baseline and initialise weights
use "$IN/qlfs_2019_q4_clean.dta", clear

* Initialise sim1 weight as missing — to be filled by calibrate
gen wgt19_sim1 = .

* Matrix of target population by province for 2020 Q1
matrix M1_2020 = J(1,9,.)
matrix colnames M1_2020 = "wCape" "eCape" "nCape" "Fstate" "Kwznatal" "nWest" "Gauteng" "Mpml" "Lim"
matrix rownames M1_2020 = "population"

local prov = 1
foreach name in "wCape" "eCape" "nCape" "Fstate" "Kwznatal" "nWest" "Gauteng" "Mpml" "Lim" {
    tabulate Province [iw=wgt19_sim0] if `name' == 1
    matrix M1_2020[1,`prov'] = `r(N)' * (1 + pop_growth_rate)
    local prov = `prov' + 1
}

matrix list M1_2020

* I tested dropping the calibration step. Not only does it not matter for the Gini results, it actually substantially worsens the employment validation — chi-square goes from 28.80 (p=0.004) to 438.05 (p<0.0001), and MAE/RMSE roughly triple

calibrate , marginals(wCape eCape nCape Fstate Kwznatal nWest Gauteng Mpml Lim) ///
    poptot(M1_2020) entrywt(wgt19_sim0) exitwt(wgt19_sim1)

save "$OUT/qlfs_2019_q4_clean_weighted.dta", replace

* TEST: bypass calibration — set wgt19_sim1 = wgt19_sim0
* Comment this line out to restore the calibrated weights
* replace wgt19_sim1 = wgt19_sim0
* save "$OUT/qlfs_2019_q4_clean_weighted.dta", replace

* Compute shocks from 2019 Q4 (baseline) to 2020 Q1 (post-shock)
* changes in employment and wage
* Load 2019 Q4  baseline again for shock calculations

use "$IN/qlfs_2019_q4_clean.dta", clear
svyset [pw=Weight]

* Employment shares and wage by skill

forvalues s = 0/1 {
    svy: tab worker_sim0 if skilled_sim0 == `s', percent
    matrix empl_shares_2019_`s' = e(b)
    matrix list empl_shares_2019_`s'

    svy: mean wages if skilled_sim0 == `s' & worker_sim0 <= 6 & wages > 0
    scalar avg_wage_2019_`s' = _b[wages]
    di "Avg wage 2019 Q4 skill `s': " avg_wage_2019_`s'
}

tempfile baseline_2019Q4
save `baseline_2019Q4'

* Load 2020 Q1 comparison

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

forvalues s = 0/1 {
    svy: tab worker_sim0 if skilled_sim0 == `s', percent
    matrix empl_shares_2020_`s' = e(b)
    matrix list empl_shares_2020_`s'

    svy: mean wages if skilled_sim0 == `s' & worker_sim0 <= 6 & wages > 0
    scalar avg_wage_2020_`s' = _b[wages]
    di "Avg wage 2020 Q1 skill `s': " avg_wage_2020_`s'
}

* Compute Employment and Wage Shocks
* Employment shocks

forvalues s = 0/1 {
    matrix employment_shocks_`s' = J(1,7,.)
    forvalues e = 1/7 {
        local share_2019 = empl_shares_2019_`s'[1,`e']
        local share_2020 = empl_shares_2020_`s'[1,`e']
        if `share_2019' > 0 {
            local pct_change = ((`share_2020' - `share_2019') / `share_2019')
        }
        else {
            local pct_change = .
        }
        matrix employment_shocks_`s'[1,`e'] = `pct_change'
    }
    matrix colnames employment_shocks_`s' = "Agric" "Mining" "Manuf" "Construction" "Services" "Other Services" "Unemployed"
	
	* Display employment shocks
    matrix list employment_shocks_`s'
}

* Wage shocks
forvalues s = 0/1 {
    scalar wage_change_pct_`s' = (avg_wage_2020_`s' - avg_wage_2019_`s') / avg_wage_2019_`s'
    di "Wage change for skill `s': " wage_change_pct_`s' "%"
}

* Save the shock matrices for later use

forvalues s = 0/1 {
    matrix empl_sh_`s'_sim1 = employment_shocks_`s'
}

* Create wage change matrix

matrix chng_wage_sim1 = (wage_change_pct_1, wage_change_pct_0)
matrix colnames chng_wage_sim1 = "skilled" "unskilled"

* "calibrate-ocup.do"
* Random draw program (occupational reallocation)

capture program drop draw

program define draw
  capture drop u1-u7
  capture drop v1-v7
  capture drop pr

  tempvar i

  local y `1'
  local i 1
  local k 1

  gen v1 = uniform()
  gen v2 = uniform()
  gen v3 = uniform()
  gen v4 = uniform()
  gen v5 = uniform()
  gen v6 = uniform()
  gen v7 = uniform()
  
*!!
* note: given what is done below, no need to generate u1-u4 as random numbers
 
  gen u1 = uniform()
  gen u2 = uniform()
  gen u3 = uniform()
  gen u4 = uniform()
  gen u5 = uniform()
  gen u6 = uniform()
  gen u7 = uniform()

  gen u1_ = u1
  gen u2_ = u2
  gen u3_ = u3
  gen u4_ = u4
  gen u5_ = u5
  gen u6_ = u6
  gen u7_ = u7

  gen ur = 0
  gen pr = 0

  while `i' < 8 {
    replace u`i' = -ln(-pr_`i'*ln(v`i')) if `i' == `y'
    replace ur = u`i' if `i' == `y'
    replace pr = pr_`i' if `i' == `y'
    local i = `i' + 1
  }

  while `k' < 8  {
    replace u`k' = -ln(exp(-ur)*(pr_`k'/pr) - ln(v`k')) if `k' ~= `y'
    local k = `k' + 1
  }

end

* sim-ocup.doi
* Employment transitions

use "$OUT/qlfs_2019_q4_clean_weighted.dta", clear

* initialize ocuppational categories and skills for t=i using t=i-1=k
* in this case, k=0 is hard-coded

clonevar worker_sim1  = worker_sim0
clonevar skilled_sim1 = skilled_sim0

* Compute population growth adjustment by sector and skill
* iterate over skills (0=unskilled; 1=skilled)

forvalues s = 0(1)1 {
	
	* iterate over occupational categories 
	
    forvalues e = 1(1)6 {
		
		 * start: compute population growth
		 
        tabulate worker_sim0 [iw=wgt19_sim0] if worker_sim0==`e' & skilled_sim0==`s'
        local abs_0 = r(N)
        tabulate worker_sim1 [iw=wgt19_sim1] if worker_sim1==`e' & skilled_sim1==`s'
        local abs_1 = r(N)
        local diff_`e' = (`abs_1'/`abs_0')-1
		
		* end: compute population growth
		
        di `diff_`e''
		
		* substract population growth 
		 
        scalar chng_`s'`e' = empl_sh_`s'_sim1[1, `e'] - `diff_`e''
    }
}

* Multinomial logit and job queuing
* iterate over skills (0=unskilled; 1=skilled)

forvalues s = 0(1)1 {
	
	* keep required variables

    keep hhid pid age_sim0 skilled_* worker_* male Province yrschool ///
         married n_children wgt19* urban ln_wage_0 age2_sim0 Qtr
		 
	* estimate multinomial logit model for occupational category (labor supply)

    xi: mlogit worker_sim0 urban i.Province male age_sim0 yrschool ///
        n_children married [pw=wgt19_sim0] if skilled_sim0==`s', base(7)
		
	* predict individual probabilities for each occupational category

    predict pr_1 if worker_sim1!=., outcome(1)
    predict pr_2 if worker_sim1!=., outcome(2)
    predict pr_3 if worker_sim1!=., outcome(3)
    predict pr_4 if worker_sim1!=., outcome(4)
    predict pr_5 if worker_sim1!=., outcome(5)
    predict pr_6 if worker_sim1!=., outcome(6)
    predict pr_7 if worker_sim1!=., outcome(7)

    draw worker_sim0
	
	* generate linear predictions based on observables

    predict xb1 if worker_sim1!=., outcome(1) xb
    predict xb2 if worker_sim1!=., outcome(2) xb
    predict xb3 if worker_sim1!=., outcome(3) xb
    predict xb4 if worker_sim1!=., outcome(4) xb
    predict xb5 if worker_sim1!=., outcome(5) xb
    predict xb6 if worker_sim1!=., outcome(6) xb
    predict xb7 if worker_sim1!=., outcome(7) xb
	
	* generate actual utility for each occupational choice based on observables + unobservables

    gen ut1 = xb1 + u1
    gen ut2 = xb2 + u2
    gen ut3 = xb3 + u3
    gen ut4 = xb4 + u4
    gen ut5 = xb5 + u5
    gen ut6 = xb6 + u6
    gen ut7 = xb7 + u7

    * Check: predicted vs observed, should be the same
	
    gen worker_sim_ = .
    replace worker_sim_ = 1 if ut1 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 2 if ut2 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 3 if ut3 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 4 if ut4 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 5 if ut5 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 6 if ut6 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)
    replace worker_sim_ = 7 if ut7 == max(ut1,ut2,ut3,ut4,ut5,ut6,ut7)

    tabulate worker_sim0 worker_sim_ if worker_sim1!=. & e(sample)
    drop worker_sim_

    * estimate the probabilities associated to each category
	
    gen pr1 = exp(ut1)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr2 = exp(ut2)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr3 = exp(ut3)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr4 = exp(ut4)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr5 = exp(ut5)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr6 = exp(ut6)/(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
    gen pr7 = exp(u7) /(exp(ut1)+exp(ut2)+exp(ut3)+exp(ut4)+exp(ut5)+exp(ut6)+exp(u7))
	
	* define the highest probability according to the individual's utility

    gen pmax = max(pr1,pr2,pr3,pr4,pr5,pr6)

    gen pmax1 = pmax==pr1 & pr1!=.
    gen pmax2 = pmax==pr2 & pr2!=.
    gen pmax3 = pmax==pr3 & pr3!=.
    gen pmax4 = pmax==pr4 & pr4!=.
    gen pmax5 = pmax==pr5 & pr5!=.
    gen pmax6 = pmax==pr6 & pr6!=.

    * Job queuing
	* for each occupational category, sort individuals according to their estimated probability  
	* iterate over occupational categories   
	
    forvalues e = 1(1)6 {

		* Case 1: if there is a decrease in the occupational category `e'
		
        if chng_`s'`e' <= 0 {
            display as text "change for s=`s' and e=`e' is <=0"
            tabulate worker_sim0 [iw=wgt19_sim0] if worker_sim0==`e' & skilled_sim0==`s'
            local perc = abs(chng_`s'`e')/100
            centile pr`e' if worker_sim0==`e' & skilled_sim1==`s', centile(`perc')
            replace worker_sim1 = 7 if ((pr`e'<=r(c_1) & pr`e'!=.) & (worker_sim0==`e')) & skilled_sim1==`s'
        }
        gen migr_`e'7_sim1 = (worker_sim0==`e' & worker_sim1==7)

        * Case 2: if there is an increase in the occupational category 'e'
		
        if chng_`s'`e' > 0 {
            display as text "change for s=`s' and e=`e' is >0"
            tabulate worker_sim0 [iw=wgt19_sim0] if worker_sim0==`e' & skilled_sim0==`s'
            local absolute_change = r(N)*abs(chng_`s'`e')
            tabulate worker_sim0 [iw=wgt19_sim0] if worker_sim1!=`e' & worker_sim1!=. & skilled_sim1==`s'
            local perc = (r(N) - `absolute_change') / r(N) * 100
            centile pr`e' if worker_sim0!=`e' & worker_sim0!=. & skilled_sim1==`s', centile(`perc')
            replace worker_sim1=`e' if pr`e'>=r(c_1) & worker_sim0!=`e' & worker_sim0!=. & pr`e'!=. & skilled_sim1==`s'
        }
        gen migr_7`e'_sim1    = (worker_sim0==7 & worker_sim1==`e')
        gen migr_not`e'`e'_sim1 = (worker_sim0!=`e' & worker_sim1==`e')
    }

    * Final adjustment to satisfy macro constraints 
	* iterate over occupational categories  
	  
    forvalues e = 1(1)6 {
		
		    * estimate the absolute number of changes based on the new occupational 
			* status and then the difference needed to satisfy the macro results
	
        tabulate worker_sim0 [iw=wgt19_sim0] if skilled_sim0==`s' & worker_sim0==`e'
        local tot_force_sim0_`e' = r(N)
        tabulate worker_sim1 [iw=wgt19_sim0] if skilled_sim1==`s' & worker_sim1==`e'
        local tot_force_sim1_`e' = r(N)
        scalar chng_`s'`e'_abs = `tot_force_sim0_`e''*(1+chng_`s'`e') - `tot_force_sim1_`e''
    }

    forvalues e = 1(1)6 {

        * case 1 - exceeding workers in sector `e'
		
        if (chng_`s'`e'_abs < 0) {
            tab worker_sim1 [iw=wgt19_sim0] if worker_sim1==`e' & skilled_sim1==`s'
            local perc = 100 - ((r(N)+chng_`s'`e'_abs)*100/r(N))
            centile pr`e' if worker_sim1==`e' & skilled_sim1==`s', centile(`perc')
            replace worker_sim1=7 if pr`e'<r(c_1) & pr`e'!=. & skilled_sim1==`s' & worker_sim1==`e'
        }

        * case 2 - missing workers in sector `e'
		
        if chng_`s'`e'_abs > 0 {
            tabulate worker_sim1 [iw=wgt19_sim0] if worker_sim1==7 & pmax`e'==1 & skilled_sim1==`s'
            local perc = (r(N)-chng_`s'`e'_abs)*100/r(N)
            centile pr`e' if worker_sim1==7 & pmax`e'==1 & skilled_sim1==`s', centile(`perc')
            replace worker_sim1=`e' if pr`e'>=r(c_1) & worker_sim1==7 & pr`e'!=. & pmax`e'==1 & skilled_sim1==`s'
        }
    }

    preserve
    keep if skilled_sim1==`s'
    keep hhid pid worker_sim1 skilled_sim1 Qtr migr_*
    save "$OUT/skilled`s'_sim1.dta", replace
    restore
}

* Combine skilled and unskilled, merge back to weighted baseline

use "$OUT/skilled0_sim1.dta", clear
append using "$OUT/skilled1_sim1.dta"
merge 1:1 hhid pid Qtr using "$OUT/qlfs_2019_q4_clean_weighted.dta"
drop _merge

save "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", replace

* Distribution comparisons

* Before shocks: 2019 Q4 

use "$IN/qlfs_2019_q4_clean.dta", clear
svyset [pw=Weight]

forvalues s = 0/1 {
    svy: tab worker_sim0 if skilled_sim0 == `s', percent ci
}

* After shocks: simulated 

use "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    svy: tab worker_sim1 if skilled_sim1 == `s', percent ci
}

* Actual 2020 Q1 distribution

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

* Recode to employment_status to match worker_sim0 structure

gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
replace employment_status = 7 if inlist(Status, 2, 3, 4)

forvalues s = 0/1 {
    svy: tab employment_status if skilled_sim0 == `s', percent ci
}

* Wage simulation - Heckman 2 stage 

use "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", clear

* iterate over skills (0=unskilled; 1=skilled)

forvalues s = 0(1)1 {

    preserve

    keep if skilled_sim1==`s'
    gen employed_sim0 = (worker_sim0!=7 & worker_sim0!=.)
    gen employed_sim1 = (worker_sim1!=7 & worker_sim1!=.)
	
	* Heckman selection model

    xi: heckman ln_wage_`s' male i.Province age_sim0 age2_sim0 yrschool, ///
        select(employed_sim0=married age_sim0 male i.Province n_children)
		
	* save standard errors of residuals

    global sigw_`s' = e(sigma)
	
	* predict log wage
	* option ycond = E(y | y observed)

    predict lnwage_fitted_`s'_sim1, ycond
	
	* generate residuals for individuals with observed wage 

    gen res_`s' = ln_wage_`s' - lnwage_fitted_`s'_sim1 if e(sample)
	
	  * generate residuals for individuals without (unobserved) wage -- draw randomly from a normal distribution with the relevant (skilled or unskilled) observed variance
	  
    replace res_`s' = invnorm(runiform())*$sigw_`s' if ln_wage_`s'==.
	
	* convert ln wages to level values

    gen wage_`s'_fitted_sim1 = exp(lnwage_fitted_`s'_sim1 + res_`s')
    gen wage_`s' = exp(ln_wage_`s')
	
	* wage changes
	* chng_wage_1 = change in wage for skilled workers
	* chng_wage_0 = change in wage for unskilled workers

    if `s'==0 {
        scalar chng_wage_`s' = chng_wage_sim1[1, 2]
    }
    if `s'==1 {
        scalar chng_wage_`s' = chng_wage_sim1[1, 1]
    }
	
	* assign fitted wages for individuals with missing wage

    replace wage_`s' = wage_`s'_fitted_sim1 if (employed_sim0==1) & wage_`s'==.
    gen wage_`s'_hat = 0 if (employed_sim0==1) & (employed_sim1!=1)
	
	* initialize the simulated wage

    replace wage_`s'_hat = wage_`s'_fitted_sim1 if (employed_sim0==1)  & (employed_sim1==1)
    replace wage_`s'_hat = wage_`s'_fitted_sim1 if (employed_sim0!=1)  & (employed_sim1==1)
    replace wage_`s'     = 0 if wage_`s'==. | wage_`s'==1
    replace wage_`s'_hat = 0 if wage_`s'_hat==. | wage_`s'_hat==1

    gen wage_`s'_sim1 = wage_`s' if (employed_sim0==1) & (employed_sim1==1)
    replace wage_`s'_sim1 = wage_`s'_hat if (employed_sim0!=1) & (employed_sim1==1)

	* compute the average wages in sim`k' and in sim`i' and save them
	
    sum wage_`s' [aw=wgt19_sim0] if (employed_sim0==1) & wage_`s'>1
    scalar imean = r(mean)

    sum wage_`s'_sim1 [aw=wgt19_sim1] if (employed_sim1==1) & wage_`s'_sim1>1
    scalar ffmean = r(mean)

    global agwage = (1+chng_wage_`s')*(imean/ffmean)
    replace wage_`s'_sim1 = wage_`s'_sim1*$agwage
    sum wage_`s'_sim1 [aw=wgt19_sim1] if (employed_sim1==1) & wage_`s'_sim1>1
	
	* compute the absolute change in wage

    gen delta_`s' = wage_`s'_sim1 - wage_`s'
    replace delta_`s' = 0 if delta_`s'==.
	
	* replace delta_`s' = -wage_`s' if (worker_sim0==1 |worker_sim0==2) & (worker_sim1!=1 |worker_sim1!=2)
	
    replace delta_`s' = -wage_`s' if (employed_sim0==1 & employed_sim1!=1)
	
	* sum wage changes of all household members and collapse to one observation per household 

    gen worker_sim0_ = worker_sim0
    gen worker_sim1_ = worker_sim1

    keep hhid pid delta_`s' wage_`s'_sim1 wage_`s' ln_wage_`s' wage_`s'_hat ///
         wages Qtr wage_`s'_fitted_sim1 worker_sim0_ worker_sim1_ employed_sim* age_sim0

    save "$OUT/wage_after`s'.dta", replace
    di $agwage
    restore
}

use "$OUT/wage_after0.dta", clear
append using "$OUT/wage_after1.dta"
merge 1:1 hhid pid Qtr using "$OUT/qlfs_2019_q4_clean_weighted_skill.dta"
drop _merge

label define skill 0 "unskilled" 1 "skilled"
label define work_status 1 "agric" 2 "mining" 3 "manufacturing" 4 "construction" 5 "services" 6 "other services" 7 "unemployed"
label values skilled_sim0 skill
label values skilled_sim1 skill
label values worker_sim0 work_status
label values worker_sim1 work_status

svyset [pw=wgt19_sim0]
svy, subpop(if skilled_sim0==1): tab worker_sim0
matrix before = e(b)

*svy, subpop (if skilled_sim0==1): prop i.worker_sim0

svyset [pw=wgt19_sim1]
svy, subpop(if skilled_sim1==1): tab worker_sim1
matrix after = e(b)

matrix difference = (after-before)
matrix change = J(1,6,0)

forvalues j = 1/6 {
    matrix change[1,`j'] = difference[1,`j']/before[1,`j']
}
matrix list change

svyset [pw=wgt19_sim0]
svy, subpop(if skilled_sim0==0): tab worker_sim0
svyset [pw=wgt19_sim1]
svy, subpop(if skilled_sim1==0): tab worker_sim1

* Distribution of wages after the shocks were applied 

save "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", replace

* Wage validation statistics 

* Simulated wages by skill
use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    forvalues e = 1/6 {
        capture svy: mean wages if skilled_sim1==`s' & worker_sim1==`e' & wages > 0
        if _rc == 0 {
            scalar sim_wage_`s'_`e'    = _b[wages]
            scalar sim_wage_se_`s'_`e' = _se[wages]
        }
    }
    svy: mean wages if skilled_sim1==`s' & inlist(worker_sim1,1,2,3,4,5,6) & wages > 0
    scalar sim_wage_`s'_all    = _b[wages]
    scalar sim_wage_se_`s'_all = _se[wages]
}

* Actual 2020 Q1 wages

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
replace employment_status = 7 if inlist(Status, 2, 3, 4)

forvalues s = 0/1 {
    forvalues e = 1/6 {
        capture svy: mean wages if skilled_sim0==`s' & employment_status==`e' & wages > 0
        if _rc == 0 {
            scalar act_wage_`s'_`e'    = _b[wages]
            scalar act_wage_se_`s'_`e' = _se[wages]
        }
    }
    svy: mean wages if skilled_sim0==`s' & inlist(employment_status,1,2,3,4,5,6) & wages > 0
    scalar act_wage_`s'_all    = _b[wages]
    scalar act_wage_se_`s'_all = _se[wages]
}

* Wage MAE and RMSE

scalar wage_MAE  = (abs(sim_wage_0_all - act_wage_0_all) + abs(sim_wage_1_all - act_wage_1_all)) / 2
scalar wage_RMSE = sqrt(((sim_wage_0_all - act_wage_0_all)^2 + (sim_wage_1_all - act_wage_1_all)^2) / 2)
di "Wage MAE  = R" wage_MAE
di "Wage RMSE = R" wage_RMSE

* Employment validation metrics (MAE, RMSE, CI Coverage, Chi squared)

* Simulated 2020 employment shares

use "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    svy, subpop(if skilled_sim1==`s'): proportion worker_sim1
    matrix sim_empl_`s' = e(b)
}

* Actual 2020 Q1 employment shares

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
replace employment_status = 7 if inlist(Status, 2, 3, 4)

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0==`s'): proportion employment_status
    matrix act_empl_`s' = e(b)
}

* MAE and RMSE

local sum_ae  = 0
local sum_se  = 0
local n_cells = 0

forvalues s = 0/1 {
    forvalues e = 1/7 {
        local sim_p = sim_empl_`s'[1,`e']
        local act_p = act_empl_`s'[1,`e']
        local err   = abs(`sim_p' - `act_p')
        local sum_ae = `sum_ae' + `err'
        local sum_se = `sum_se' + (`err'^2)
        local n_cells = `n_cells' + 1
    }
}

scalar empl_MAE  = `sum_ae' / `n_cells'
scalar empl_RMSE = sqrt(`sum_se' / `n_cells')
di "Employment MAE  = " empl_MAE
di "Employment RMSE = " empl_RMSE

* CI Coverage

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
replace employment_status = 7 if inlist(Status, 2, 3, 4)

local covered = 0
local total   = 0

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0==`s'): proportion employment_status
    matrix act_b = e(b)
    matrix act_V = e(V)

    forvalues e = 1/7 {
        local act_p  = act_b[1,`e']
        local act_se = sqrt(act_V[`e',`e'])
        local ci_lo  = `act_p' - 1.96*`act_se'
        local ci_hi  = `act_p' + 1.96*`act_se'
        local sim_p  = sim_empl_`s'[1,`e']

        if `sim_p' >= `ci_lo' & `sim_p' <= `ci_hi' {
            local covered = `covered' + 1
        }
        local total = `total' + 1
    }
}

scalar empl_CI_coverage = `covered' / `total'
di "Employment CI coverage = " `covered' "/" `total' " = " empl_CI_coverage

* Chi-square goodness of fit

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
replace employment_status = 7 if inlist(Status, 2, 3, 4)

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0==`s'): proportion employment_status
    matrix act_prop_`s' = e(b)
    scalar act_N_`s'    = e(N_subpop)
}

clear
set obs 14
gen skill    = .
gen sector   = .
gen observed = .
gen expected = .

local row = 1
forvalues s = 0/1 {
    forvalues e = 1/7 {
        replace skill    = `s'                                  in `row'
        replace sector   = `e'                                  in `row'
        replace observed = act_prop_`s'[1,`e'] * act_N_`s'     in `row'
        replace expected = sim_empl_`s'[1,`e'] * act_N_`s'     in `row'
        local row = `row' + 1
    }
}

gen chi2_cell = (observed - expected)^2 / expected
egen chi2_stat = sum(chi2_cell)
scalar chi2_total = chi2_stat[1]
scalar chi2_df    = 12
scalar chi2_pval  = chi2tail(chi2_df, chi2_total)

di ""
di "════════════════════════════════════"
di "  CHI-SQUARE GOODNESS OF FIT TEST"
di "  Simulated vs Actual 2020 Q1"
di "════════════════════════════════════"
di "  Chi2 statistic = " %8.2f chi2_total
di "  Degrees of freedom = " chi2_df
di "  p-value = " %6.4f chi2_pval
di "════════════════════════════════════"

list skill sector observed expected chi2_cell, sep(7)

* Transition matrix

use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear
tabulate worker_sim0 worker_sim1 [iw=wgt19_sim0], matcell(freq)
matrix trans = freq
forvalues i = 1/7 {
    local rowsum = 0
    forvalues j = 1/7 {
        local rowsum = `rowsum' + trans[`i',`j']
    }
    forvalues j = 1/7 {
        matrix trans[`i',`j'] = trans[`i',`j'] / `rowsum'
    }
}
matrix list trans

