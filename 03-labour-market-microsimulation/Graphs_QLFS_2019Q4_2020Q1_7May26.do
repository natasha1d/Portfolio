* Simple bar grapghs - employment shares and shocks 
* Create matrices for graph data

matrix ss  = (2019\2019\2019\2019\2019\2019\2019\2020\2020\2020\2020\2020\2020\2020)
matrix ss1 = (1\2\3\4\5\6\7\1\2\3\4\5\6\7)
matrix s   = ss, ss1

* Employment shares

matrix unskilled_shares_2019_0 = empl_shares_2019_0'
matrix unskilled_shares_2020_0 = empl_shares_2020_0'
matrix skilled_shares_2019_0   = empl_shares_2019_1'
matrix skilled_shares_2020_0   = empl_shares_2020_1'

matrix unskilled_shares = unskilled_shares_2019_0 \ unskilled_shares_2020_0
matrix skilled_shares   = skilled_shares_2019_0   \ skilled_shares_2020_0

matrix unskilled_shares = unskilled_shares, s
matrix skilled_shares   = skilled_shares,   s

* Clean up 
capture drop unskilled_prop skilled_prop
capture drop unskilled_shares1 unskilled_shares2 unskilled_shares3
capture drop skilled_shares1 skilled_shares2 skilled_shares3
capture drop sector year
capture drop employ_shocks_11 employ_shocks_01 sector_shocks
capture drop skilled_shocks unskilled_shocks
capture drop chng_wage1 chng_wage2 skill_cat wage_pct_change skill
capture drop sector year worker_sim0 worker_sim1 skilled_sim0 skilled_sim1 wages ln_wage_0 ln_wage_1 wgt19_sim0 wgt19_sim1

* Convert to variables
preserve // Keep the matricies in memory while whipping dataset so there's no conflicting variables 
clear
svmat unskilled_shares
svmat skilled_shares

ren unskilled_shares1 unskilled_prop
ren unskilled_shares2 year
ren unskilled_shares3 sector
ren skilled_shares1 skilled_prop
capture drop skilled_shares2 skilled_shares3

label define sector_lbl 1 "Agriculture" 2 "Mining" 3 "Manufacturing" ///
    4 "Construction" 5 "Services" 6 "Other Services" 7 "Unemployed", modify // add modify to update existing label definition rather than trying to create a new one from scratch
	
label values sector sector_lbl

label define year_lbl 2019 "2019 Q4" 2020 "2020 Q1"
label values year year_lbl

* Employment shocks
matrix employ_shocks_1 = 100*employment_shocks_1
matrix employ_shocks_1 = employ_shocks_1'
matrix employ_shocks_0 = 100*employment_shocks_0
matrix employ_shocks_0 = employ_shocks_0'

svmat employ_shocks_1
svmat employ_shocks_0

gen sector_shocks = _n if !missing(employ_shocks_11)
label values sector_shocks sector_lbl

ren employ_shocks_11 skilled_shocks
ren employ_shocks_01 unskilled_shocks

* Wage changes
matrix chng_wage = 100*chng_wage_sim1
matrix chng_wage = chng_wage'
matrix xx = (1\0)
matrix chng_wage = chng_wage, xx

svmat chng_wage
gen skill_cat = _n if !missing(chng_wage1)
ren chng_wage1 wage_pct_change
ren chng_wage2 skill

label define skill_lbl 0 "Unskilled" 1 "Skilled"
label values skill skill_lbl

* GRAPH 1: Unskilled Employment by Sector
graph bar unskilled_prop, over(year, gap(2)) over(sector, lab(labsize(small))) ///
    asyvars ///
    bar(1, fcolor(brown) lw(none)) bar(2, fcolor(brown*0.5) lw(none)) ///
    ytitle("Proportion employed (unskilled)", size(small)) ///
    title("Proportion of unskilled employment by quarter") ///
    name(unskill, replace)
graph export "$OUT/graph_prop_unskilled_empl.png", replace width(2400) height(1600)

* GRAPH 2: Skilled Employment by Sector
graph bar skilled_prop, over(year, gap(2)) over(sector, lab(labsize(small))) ///
    asyvars ///
    bar(1, fcolor(brown) lw(none)) bar(2, fcolor(brown*0.5) lw(none)) ///
    ytitle("Proportion employed (skilled)", size(small)) ///
    title("Proportion of skilled employment by quarter") ///
    name(skill, replace)
graph export "$OUT/graph_prop_skilled_empl.png", replace width(2400) height(1600)

* GRAPH 3: Skilled Employment Shocks
graph bar skilled_shocks, over(sector_shocks, lab(labsize(small))) ///
    bar(1, fcolor(brown) lw(none)) ///
    blabel(bar, format(%9.2f) size(small)) ///
    ytitle("Skilled shocks (% change)", size(small)) ///
    title("Percentage change in skilled employment") ///
    name(skill_shocks, replace)
graph export "$OUT/graph_employment_shocks_skilled.png", replace width(2400) height(1600)

* GRAPH 4: Unskilled Employment Shocks
graph bar unskilled_shocks, over(sector_shocks, lab(labsize(small))) ///
    bar(1, fcolor(brown*0.5) lw(none)) ///
    blabel(bar, format(%9.2f) size(small)) ///
    ytitle("Unskilled shocks (% change)", size(small)) ///
    title("Percentage change in unskilled employment") ///
    name(unskill_shocks, replace)
graph export "$OUT/graph_employment_shocks_unskilled.png", replace width(2400) height(1600)

* GRAPH 5: Combined Employment Shocks
graph bar skilled_shocks unskilled_shocks, ///
    over(sector_shocks, label(angle(45) labsize(small))) ///
    bar(1, fcolor(forest_green*0.8) lcolor(forest_green) lwidth(thin)) ///
    bar(2, fcolor(orange*0.8) lcolor(orange) lwidth(thin)) ///
    legend(order(1 "Skilled" 2 "Unskilled") rows(1) size(small) position(6)) ///
    ytitle("Employment Shock (% Change)", size(small)) ///
    title("Employment Shocks by Sector and Skill", size(medium)) ///
    subtitle("Percentage Change from 2019 Q4 to 2020 Q1", size(small)) ///
    ylabel(, format(%9.1f) labsize(small)) ///
    yline(0, lcolor(black) lwidth(thin)) ///
    blabel(bar, format(%9.1f) size(small) position(outside)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(employment_shocks, replace)
graph export "$OUT/graph_employment_shocks.png", replace width(2400) height(1600)

* GRAPH 6: Wage Changes by Skill
graph bar wage_pct_change, ///
    over(skill, label(labsize(small))) ///
    bar(1, fcolor(midblue*0.8) lcolor(midblue) lwidth(thin)) ///
    ytitle("Wage Change (% Change)", size(small)) ///
    title("Wage Changes by Skill Level", size(medium)) ///
    subtitle("Percentage Change from 2019 Q4 to 2020 Q1", size(small)) ///
    ylabel(, format(%9.1f) labsize(small)) ///
    yline(0, lcolor(black) lwidth(thin)) ///
    blabel(bar, format(%9.2f) size(medium)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(wage_changes, replace)
graph export "$OUT/graph_wage_changes.png", replace width(2000) height(1400)

* SECTION 2: SIMULATED vs ACTUAL 2019 Q4 — PUBLICATION GRAPHS

use "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    svy, subpop(if skilled_sim1 == `s'): proportion worker_sim1
    matrix sim_props_`s' = e(b)
    matrix sim_V_`s'     = e(V)
}

use "$IN/qlfs_2019_q4_clean.dta", clear
svyset [pw=Weight]

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0 == `s'): proportion worker_sim0
    matrix act_props_`s' = e(b)
    matrix act_V_`s'     = e(V)
}

clear
set obs 14
gen obs      = _n
gen skill    = .
gen sector   = .
gen sim_prop = .
gen sim_se   = .
gen act_prop = .
gen act_se   = .

local row = 1
forvalues s = 0/1 {
    forvalues sec = 1/7 {
        replace skill    = `s'                         in `row'
        replace sector   = `sec'                       in `row'
        replace sim_prop = sim_props_`s'[1,`sec']      in `row'
        replace sim_se   = sqrt(sim_V_`s'[`sec',`sec']) in `row'
        replace act_prop = act_props_`s'[1,`sec']      in `row'
        replace act_se   = sqrt(act_V_`s'[`sec',`sec']) in `row'
        local ++row
    }
}

gen sim_ci_lower = sim_prop - 1.96 * sim_se
gen sim_ci_upper = sim_prop + 1.96 * sim_se
gen act_ci_lower = act_prop - 1.96 * act_se
gen act_ci_upper = act_prop + 1.96 * act_se

label define sector_lbl 1 "Agriculture" 2 "Mining" 3 "Manufacturing" ///
    4 "Construction" 5 "Services" 6 "Other" 7 "Unemployed"
label define skill_lbl 0 "Unskilled" 1 "Skilled"
label values sector sector_lbl
label values skill  skill_lbl

gen id = _n
reshape long @_prop @_se @_ci_lower @_ci_upper, i(id) j(data_type) string
replace data_type = "Simulated"    if data_type == "sim"
replace data_type = "Actual 2019 Q4" if data_type == "act"

rename _prop    prop
rename _se      se
rename _ci_lower ci_lower
rename _ci_upper ci_upper

gen graph_pos = .
replace graph_pos = 1  if sector == 1 & data_type == "Simulated"
replace graph_pos = 2  if sector == 1 & data_type == "Actual 2019 Q4"
replace graph_pos = 4  if sector == 2 & data_type == "Simulated"
replace graph_pos = 5  if sector == 2 & data_type == "Actual 2019 Q4"
replace graph_pos = 7  if sector == 3 & data_type == "Simulated"
replace graph_pos = 8  if sector == 3 & data_type == "Actual 2019 Q4"
replace graph_pos = 10 if sector == 4 & data_type == "Simulated"
replace graph_pos = 11 if sector == 4 & data_type == "Actual 2019 Q4"
replace graph_pos = 13 if sector == 5 & data_type == "Simulated"
replace graph_pos = 14 if sector == 5 & data_type == "Actual 2019 Q4"
replace graph_pos = 16 if sector == 6 & data_type == "Simulated"
replace graph_pos = 17 if sector == 6 & data_type == "Actual 2019 Q4"
replace graph_pos = 19 if sector == 7 & data_type == "Simulated"
replace graph_pos = 20 if sector == 7 & data_type == "Actual 2019 Q4"

* UNSKILLED: Simulated vs Actual 2019 Q4
* SKILLED: Simulated vs Actual 2019 Q4
* SECTION 3: WAGE BAR GRAPH WITH CONFIDENCE INTERVALS

use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    svy: mean wages if skilled_sim1==`s' & inlist(worker_sim1,1,2,3,4,5,6) & wages > 0
    matrix sim_wage_`s'    = e(b)
    matrix sim_wage_se_`s' = e(V)
}

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
    svy: mean wages if skilled_sim0==`s' & inlist(employment_status,1,2,3,4,5,6) & wages > 0
    matrix act_wage_`s'    = e(b)
    matrix act_wage_se_`s' = e(V)
}

clear
set obs 4
gen skill_level = .
gen data_type   = ""
gen wage_mean   = .
gen ci_lower    = .
gen ci_upper    = .

local row = 1
forvalues s = 0/1 {
    replace skill_level = `s'                                             in `row'
    replace data_type   = "Simulated"                                     in `row'
    replace wage_mean   = sim_wage_`s'[1,1]                               in `row'
    replace ci_lower    = sim_wage_`s'[1,1] - 1.96*sqrt(sim_wage_se_`s'[1,1]) in `row'
    replace ci_upper    = sim_wage_`s'[1,1] + 1.96*sqrt(sim_wage_se_`s'[1,1]) in `row'
    local row = `row' + 1
    replace skill_level = `s'                                             in `row'
    replace data_type   = "Actual 2020 Q1"                                in `row'
    replace wage_mean   = act_wage_`s'[1,1]                               in `row'
    replace ci_lower    = act_wage_`s'[1,1] - 1.96*sqrt(act_wage_se_`s'[1,1]) in `row'
    replace ci_upper    = act_wage_`s'[1,1] + 1.96*sqrt(act_wage_se_`s'[1,1]) in `row'
    local row = `row' + 1
}

gen group = .
replace group = 1 if skill_level == 0 & data_type == "Simulated"
replace group = 2 if skill_level == 0 & data_type == "Actual 2020 Q1"
replace group = 3 if skill_level == 1 & data_type == "Simulated"
replace group = 4 if skill_level == 1 & data_type == "Actual 2020 Q1"

gen ci_string = string(wage_mean, "%9.0f") + " [" + ///
                string(ci_lower, "%9.0f") + ", " + ///
                string(ci_upper, "%9.0f") + "]"

twoway ///
    (bar wage_mean group, barwidth(0.6) fcolor(blue%50) lcolor(blue) lwidth(thin)) ///
    (rcap ci_upper ci_lower group, lcolor(black) lwidth(0.5)) ///
    (scatter ci_upper group, msize(0) msymbol(none) ///
        mlabel(ci_string) mlabsize(small) mlabcolor(black) mlabposition(12) mlabgap(1)), ///
    xlabel(1 "Unskilled Simulated" 2 "Unskilled Actual" ///
           3 "Skilled Simulated" 4 "Skilled Actual", labsize(small) angle(45)) ///
    xtitle("") ///
    ytitle("Average Wage", size(small)) ///
    title("Average Wages by Skill Level", size(medium)) ///
    subtitle("With 95% Confidence Intervals", size(small)) ///
    legend(off) ///
    xscale(range(0.5 4.5)) ///
    ylabel(0(5000)25000, format(%9.0f) labsize(small) angle(horizontal)) ///
    yscale(range(0 27000)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(wage_skill_bar_ci, replace)
graph export "$OUT/graph_wage_skill_ci.png", replace width(2000) height(1400)

* SECTION 4: 2019 Q4 vs 2020 Q1 ACTUAL — EMPLOYMENT WITH CI

use "$IN/qlfs_2019_q4_clean.dta", clear
svyset [pw=Weight]

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0 == `s'): proportion worker_sim0
    matrix empl_shares_2019_`s' = e(b)
    matrix V = e(V)
    local k = colsof(V)
    matrix empl_se_2019_`s' = J(1,`k',.)
    forvalues i = 1/`k' {
        matrix empl_se_2019_`s'[1,`i'] = sqrt(V[`i',`i'])
    }
    svy: mean wages if skilled_sim0==`s' & worker_sim0<=6 & wages > 0
    scalar avg_wage_2019_`s' = _b[wages]
}

use "$IN/qlfs_2020_q1_clean.dta", clear
svyset [pw=Weight]

gen worker_2020 = .
replace worker_2020 = 1 if Status == 1 & sector == 1
replace worker_2020 = 2 if Status == 1 & sector == 2
replace worker_2020 = 3 if Status == 1 & sector == 3
replace worker_2020 = 4 if Status == 1 & sector == 4
replace worker_2020 = 5 if Status == 1 & sector == 5
replace worker_2020 = 6 if Status == 1 & sector == 6
replace worker_2020 = 7 if inlist(Status, 2, 3, 4)

forvalues s = 0/1 {
    svy, subpop(if skilled_sim0 == `s'): proportion worker_2020
    matrix empl_shares_2020_`s' = e(b)
    matrix V = e(V)
    local k = colsof(V)
    matrix empl_se_2020_`s' = J(1,`k',.)
    forvalues i = 1/`k' {
        matrix empl_se_2020_`s'[1,`i'] = sqrt(V[`i',`i'])
    }
    svy: mean wages if skilled_sim0==`s' & worker_2020<=6 & wages > 0
    scalar avg_wage_2020_`s' = _b[wages]
}

matrix ss  = (2019\2019\2019\2019\2019\2019\2019\2020\2020\2020\2020\2020\2020\2020)
matrix ss1 = (1\2\3\4\5\6\7\1\2\3\4\5\6\7)
matrix s   = ss, ss1

matrix unskilled_props = empl_shares_2019_0' \ empl_shares_2020_0'
matrix unskilled_se    = empl_se_2019_0'     \ empl_se_2020_0'
matrix skilled_props   = empl_shares_2019_1' \ empl_shares_2020_1'
matrix skilled_se      = empl_se_2019_1'     \ empl_se_2020_1'

matrix unskilled_final = unskilled_props, unskilled_se, s
matrix skilled_final   = skilled_props,   skilled_se,   s

drop _all
svmat unskilled_final
svmat skilled_final

ren unskilled_final1 unskilled_prop
ren unskilled_final2 unskilled_se
ren unskilled_final3 year
ren unskilled_final4 sector_new
ren skilled_final1   skilled_prop
ren skilled_final2   skilled_se
drop skilled_final3 skilled_final4

drop if missing(unskilled_prop)

gen unskilled_ci_lower = max(0, unskilled_prop - 1.96*unskilled_se)
gen unskilled_ci_upper = min(1, unskilled_prop + 1.96*unskilled_se)
gen skilled_ci_lower   = max(0, skilled_prop   - 1.96*skilled_se)
gen skilled_ci_upper   = min(1, skilled_prop   + 1.96*skilled_se)

label define sector_lbl 1 "Agriculture" 2 "Mining" 3 "Manufacturing" ///
    4 "Construction" 5 "Services" 6 "Other Services" 7 "Unemployed", modify
label values sector_new sector_lbl
label define year_lbl 2019 "2019 Q4" 2020 "2020 Q1"
label values year year_lbl

gen graph_pos = .
replace graph_pos = 1  if sector_new==1 & year==2019
replace graph_pos = 2  if sector_new==1 & year==2020
replace graph_pos = 4  if sector_new==2 & year==2019
replace graph_pos = 5  if sector_new==2 & year==2020
replace graph_pos = 7  if sector_new==3 & year==2019
replace graph_pos = 8  if sector_new==3 & year==2020
replace graph_pos = 10 if sector_new==4 & year==2019
replace graph_pos = 11 if sector_new==4 & year==2020
replace graph_pos = 13 if sector_new==5 & year==2019
replace graph_pos = 14 if sector_new==5 & year==2020
replace graph_pos = 16 if sector_new==6 & year==2019
replace graph_pos = 17 if sector_new==6 & year==2020
replace graph_pos = 19 if sector_new==7 & year==2019
replace graph_pos = 20 if sector_new==7 & year==2020

gen unskilled_pct          = unskilled_prop * 100
gen skilled_pct            = skilled_prop   * 100
gen unskilled_ci_lower_pct = unskilled_ci_lower * 100
gen unskilled_ci_upper_pct = unskilled_ci_upper * 100
gen skilled_ci_lower_pct   = skilled_ci_lower   * 100
gen skilled_ci_upper_pct   = skilled_ci_upper   * 100

gen unskilled_label    = string(unskilled_pct, "%4.1f") + "%"
gen skilled_label      = string(skilled_pct,   "%4.1f") + "%"
gen unskilled_ci_label = "[" + string(unskilled_ci_lower_pct, "%4.1f") + "-" + string(unskilled_ci_upper_pct, "%4.1f") + "]"
gen skilled_ci_label   = "[" + string(skilled_ci_lower_pct,   "%4.1f") + "-" + string(skilled_ci_upper_pct,   "%4.1f") + "]"

gen label_pos_unskilled    = unskilled_ci_upper + 0.06
gen label_pos_unskilled_ci = unskilled_ci_upper + 0.03
gen label_pos_skilled      = skilled_ci_upper   + 0.06
gen label_pos_skilled_ci   = skilled_ci_upper   + 0.03

* Unskilled: 2019 Q4 vs 2020 Q1
twoway ///
    (bar unskilled_prop graph_pos if year==2019, barwidth(0.8) fcolor(brown) lcolor(brown) lwidth(thin)) ///
    (bar unskilled_prop graph_pos if year==2020, barwidth(0.8) fcolor(sand) lcolor(sand) lwidth(thin)) ///
    (rcap unskilled_ci_upper unskilled_ci_lower graph_pos, lcolor(black) lwidth(thin) msize(2)) ///
    (scatter label_pos_unskilled graph_pos, msize(0) msymbol(none) mlabel(unskilled_label) ///
        mlabsize(2.0) mlabcolor(black) mlabposition(12) mlabgap(0)) ///
    (scatter label_pos_unskilled_ci graph_pos, msize(0) msymbol(none) mlabel(unskilled_ci_label) ///
        mlabsize(1.8) mlabcolor(gs6) mlabposition(12) mlabgap(0)), ///
    xlabel(1.5 "Agriculture" 4.5 "Mining" 7.5 "Manufacturing" ///
           10.5 "Construction" 13.5 "Services" 16.5 "Other Services" 19.5 "Unemployed", ///
           labsize(2.5) angle(45)) ///
    xtitle("Sector", size(3)) ytitle("Proportion Employed (Unskilled)", size(3)) ///
    title("Unskilled Employment by Sector: 2019 Q4 vs 2020 Q1", size(4) color(black)) ///
    subtitle("With 95% Confidence Intervals", size(2.5) color(gs6)) ///
    legend(order(1 "2019 Q4" 2 "2020 Q1") rows(1) size(2.5) position(6)) ///
    ylabel(0(0.1)0.7, format(%4.2f) labsize(2.5) angle(0)) ///
    yscale(range(0 0.80)) xscale(range(0 21)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(unskilled_ci, replace)
graph export "$OUT/unskilled_employment_with_CI.png", replace width(3800) height(2200)

* Skilled: 2019 Q4 vs 2020 Q1
twoway ///
    (bar skilled_prop graph_pos if year==2019, barwidth(0.8) fcolor(navy) lcolor(navy) lwidth(thin)) ///
    (bar skilled_prop graph_pos if year==2020, barwidth(0.8) fcolor(ltblue) lcolor(ltblue) lwidth(thin)) ///
    (rcap skilled_ci_upper skilled_ci_lower graph_pos, lcolor(black) lwidth(thin) msize(2)) ///
    (scatter label_pos_skilled graph_pos, msize(0) msymbol(none) mlabel(skilled_label) ///
        mlabsize(2.0) mlabcolor(black) mlabposition(12) mlabgap(0)) ///
    (scatter label_pos_skilled_ci graph_pos, msize(0) msymbol(none) mlabel(skilled_ci_label) ///
        mlabsize(1.8) mlabcolor(gs6) mlabposition(12) mlabgap(0)), ///
    xlabel(1.5 "Agriculture" 4.5 "Mining" 7.5 "Manufacturing" ///
           10.5 "Construction" 13.5 "Services" 16.5 "Other Services" 19.5 "Unemployed", ///
           labsize(2.5) angle(45)) ///
    xtitle("Sector", size(3)) ytitle("Proportion Employed (Skilled)", size(3)) ///
    title("Skilled Employment by Sector: 2019 Q4 vs 2020 Q1", size(4) color(black)) ///
    subtitle("With 95% Confidence Intervals", size(2.5) color(gs6)) ///
    legend(order(1 "2019 Q4" 2 "2020 Q1") rows(1) size(2.5) position(6)) ///
    ylabel(0(0.1)0.7, format(%4.2f) labsize(2.5) angle(0)) ///
    yscale(range(0 0.80)) xscale(range(0 21)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(skilled_ci, replace)
graph export "$OUT/skilled_employment_with_CI.png", replace width(3800) height(2200)

* SECTION 5: ACTUAL 2020 Q1 vs SIMULATED 2020 Q1

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
    matrix empl_shares_actual2020_`s' = e(b)
    matrix V = e(V)
    local k = colsof(V)
    matrix empl_se_actual2020_`s' = J(1,`k',.)
    forvalues i = 1/`k' {
        matrix empl_se_actual2020_`s'[1,`i'] = sqrt(V[`i',`i'])
    }
}

use "$OUT/qlfs_2019_q4_clean_weighted_skill.dta", clear
svyset [pw=wgt19_sim1]

forvalues s = 0/1 {
    svy, subpop(if skilled_sim1==`s'): proportion worker_sim1
    matrix empl_shares_sim2020_`s' = e(b)
    matrix V = e(V)
    local k = colsof(V)
    matrix empl_se_sim2020_`s' = J(1,`k',.)
    forvalues i = 1/`k' {
        matrix empl_se_sim2020_`s'[1,`i'] = sqrt(V[`i',`i'])
    }
}

matrix ss  = (1\1\1\1\1\1\1\2\2\2\2\2\2\2)
matrix ss1 = (1\2\3\4\5\6\7\1\2\3\4\5\6\7)
matrix s   = ss, ss1

matrix unskilled_props = empl_shares_actual2020_0' \ empl_shares_sim2020_0'
matrix unskilled_se    = empl_se_actual2020_0'     \ empl_se_sim2020_0'
matrix skilled_props   = empl_shares_actual2020_1' \ empl_shares_sim2020_1'
matrix skilled_se      = empl_se_actual2020_1'     \ empl_se_sim2020_1'

matrix unskilled_final = unskilled_props, unskilled_se, s
matrix skilled_final   = skilled_props,   skilled_se,   s

drop _all
svmat unskilled_final
svmat skilled_final

ren unskilled_final1 unskilled_prop
ren unskilled_final2 unskilled_se
ren unskilled_final3 type
ren unskilled_final4 sector_new
ren skilled_final1   skilled_prop
ren skilled_final2   skilled_se
drop skilled_final3 skilled_final4

drop if missing(unskilled_prop)

gen unskilled_ci_lower = max(0, unskilled_prop - 1.96*unskilled_se)
gen unskilled_ci_upper = min(1, unskilled_prop + 1.96*unskilled_se)
gen skilled_ci_lower   = max(0, skilled_prop   - 1.96*skilled_se)
gen skilled_ci_upper   = min(1, skilled_prop   + 1.96*skilled_se)

label define sector_lbl 1 "Agriculture" 2 "Mining" 3 "Manufacturing" ///
    4 "Construction" 5 "Services" 6 "Other Services" 7 "Unemployed", modify
label values sector_new sector_lbl
label define type_lbl 1 "Actual 2020 Q1" 2 "Simulated 2020 Q1"
label values type type_lbl

gen graph_pos = .
replace graph_pos = 1  if sector_new==1 & type==1
replace graph_pos = 2  if sector_new==1 & type==2
replace graph_pos = 4  if sector_new==2 & type==1
replace graph_pos = 5  if sector_new==2 & type==2
replace graph_pos = 7  if sector_new==3 & type==1
replace graph_pos = 8  if sector_new==3 & type==2
replace graph_pos = 10 if sector_new==4 & type==1
replace graph_pos = 11 if sector_new==4 & type==2
replace graph_pos = 13 if sector_new==5 & type==1
replace graph_pos = 14 if sector_new==5 & type==2
replace graph_pos = 16 if sector_new==6 & type==1
replace graph_pos = 17 if sector_new==6 & type==2
replace graph_pos = 19 if sector_new==7 & type==1
replace graph_pos = 20 if sector_new==7 & type==2

gen unskilled_pct          = unskilled_prop * 100
gen skilled_pct            = skilled_prop   * 100
gen unskilled_ci_lower_pct = unskilled_ci_lower * 100
gen unskilled_ci_upper_pct = unskilled_ci_upper * 100
gen skilled_ci_lower_pct   = skilled_ci_lower   * 100
gen skilled_ci_upper_pct   = skilled_ci_upper   * 100

gen unskilled_label    = string(unskilled_pct, "%4.1f") + "%"
gen skilled_label      = string(skilled_pct,   "%4.1f") + "%"
gen unskilled_ci_label = "[" + string(unskilled_ci_lower_pct, "%4.1f") + "-" + string(unskilled_ci_upper_pct, "%4.1f") + "]"
gen skilled_ci_label   = "[" + string(skilled_ci_lower_pct,   "%4.1f") + "-" + string(skilled_ci_upper_pct,   "%4.1f") + "]"

gen label_pos_unskilled    = unskilled_ci_upper + 0.06
gen label_pos_unskilled_ci = unskilled_ci_upper + 0.03
gen label_pos_skilled      = skilled_ci_upper   + 0.06
gen label_pos_skilled_ci   = skilled_ci_upper   + 0.03

* Unskilled: Actual vs Simulated 2020 Q1
twoway ///
    (bar unskilled_prop graph_pos if type==1, barwidth(0.8) fcolor(brown) lcolor(brown) lwidth(thin)) ///
    (bar unskilled_prop graph_pos if type==2, barwidth(0.8) fcolor(sand) lcolor(sand) lwidth(thin)) ///
    (rcap unskilled_ci_upper unskilled_ci_lower graph_pos, lcolor(black) lwidth(thin) msize(2)) ///
    (scatter label_pos_unskilled graph_pos, msize(0) msymbol(none) mlabel(unskilled_label) ///
        mlabsize(2.3) mlabcolor(black) mlabposition(12) mlabgap(0)) ///
    (scatter label_pos_unskilled_ci graph_pos, msize(0) msymbol(none) mlabel(unskilled_ci_label) ///
        mlabsize(1.8) mlabcolor(gs6) mlabposition(12) mlabgap(0)), ///
    xlabel(1.5 "Agriculture" 4.5 "Mining" 7.5 "Manufacturing" ///
           10.5 "Construction" 13.5 "Services" 16.5 "Other Services" 19.5 "Unemployed", ///
           labsize(2.5) angle(45)) ///
    xtitle("Sector", size(3)) ytitle("Proportion Employed (Unskilled)", size(3)) ///
    title("Unskilled Employment: Actual vs Simulated 2020 Q1", size(4) color(black)) ///
    subtitle("With 95% Confidence Intervals", size(2.5) color(gs6)) ///
    legend(order(1 "Actual 2020 Q1" 2 "Simulated 2020 Q1") rows(1) size(2.5) position(6)) ///
    ylabel(0(0.1)0.7, format(%4.2f) labsize(2.5) angle(0)) ///
    yscale(range(0 0.80)) xscale(range(0 21)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(unskilled_actvssim, replace)
graph export "$OUT/unskilled_actual_vs_simulated_2020.png", replace width(3800) height(2200)

* Skilled: Actual vs Simulated 2020 Q1
twoway ///
    (bar skilled_prop graph_pos if type==1, barwidth(0.8) fcolor(navy) lcolor(navy) lwidth(thin)) ///
    (bar skilled_prop graph_pos if type==2, barwidth(0.8) fcolor(ltblue) lcolor(ltblue) lwidth(thin)) ///
    (rcap skilled_ci_upper skilled_ci_lower graph_pos, lcolor(black) lwidth(thin) msize(2)) ///
    (scatter label_pos_skilled graph_pos, msize(0) msymbol(none) mlabel(skilled_label) ///
        mlabsize(2.3) mlabcolor(black) mlabposition(12) mlabgap(0)) ///
    (scatter label_pos_skilled_ci graph_pos, msize(0) msymbol(none) mlabel(skilled_ci_label) ///
        mlabsize(1.8) mlabcolor(gs6) mlabposition(12) mlabgap(0)), ///
    xlabel(1.5 "Agriculture" 4.5 "Mining" 7.5 "Manufacturing" ///
           10.5 "Construction" 13.5 "Services" 16.5 "Other Services" 19.5 "Unemployed", ///
           labsize(2.5) angle(45)) ///
    xtitle("Sector", size(3)) ytitle("Proportion Employed (Skilled)", size(3)) ///
    title("Skilled Employment: Actual vs Simulated 2020 Q1", size(4) color(black)) ///
    subtitle("With 95% Confidence Intervals", size(2.5) color(gs6)) ///
    legend(order(1 "Actual 2020 Q1" 2 "Simulated 2020 Q1") rows(1) size(2.5) position(6)) ///
    ylabel(0(0.1)0.7, format(%4.2f) labsize(2.5) angle(0)) ///
    yscale(range(0 0.80)) xscale(range(0 21)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(skilled_actvssim, replace)
graph export "$OUT/skilled_actual_vs_simulated_2020.png", replace width(3800) height(2200)

* SECTION 6: KDE WAGE DISTRIBUTIONS (WEIGHTED)

use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear
gen data_source = 1
gen ln_wage = ln(wages) if wages > 0 & !missing(wages)
gen skill   = skilled_sim1
keep if inlist(worker_sim1, 1, 2, 3, 4, 5, 6)
keep data_source ln_wage skill wgt19_sim1
rename wgt19_sim1 weight
save "$OUT/sim_lnwages.dta", replace

use "$IN/qlfs_2020_q1_clean.dta", clear
gen data_source = 0
gen ln_wage = ln(wages) if wages > 0 & !missing(wages)
gen skill   = skilled_sim0
gen employment_status = .
replace employment_status = 1 if Status == 1 & sector == 1
replace employment_status = 2 if Status == 1 & sector == 2
replace employment_status = 3 if Status == 1 & sector == 3
replace employment_status = 4 if Status == 1 & sector == 4
replace employment_status = 5 if Status == 1 & sector == 5
replace employment_status = 6 if Status == 1 & sector == 6
keep if inlist(employment_status, 1, 2, 3, 4, 5, 6)
keep data_source ln_wage skill Weight
rename Weight weight
save "$OUT/act_lnwages.dta", replace

use "$OUT/act_lnwages.dta", clear
append using "$OUT/sim_lnwages.dta"
save "$OUT/combined_lnwages.dta", replace

* Unskilled KDE
use "$OUT/combined_lnwages.dta", clear
keep if skill == 0 & !missing(ln_wage)
twoway ///
    (kdensity ln_wage [aw=weight] if data_source==0, lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
    (kdensity ln_wage [aw=weight] if data_source==1, lcolor(navy)      lwidth(medium) lpattern(solid)), ///
    xtitle("Log Wage", size(small)) ytitle("Density", size(small)) ///
    title("Unskilled Workers: Wage Distribution", size(medium) color(black)) ///
    subtitle("Actual 2020 Q1 vs Simulated 2020 Q1", size(small) color(gs6)) ///
    legend(order(1 "Actual 2020 Q1" 2 "Simulated 2020 Q1") rows(1) size(small) position(6)) ///
    xlabel(0(2)18, format(%9.1f) labsize(small)) ylabel(, format(%9.2f) labsize(small)) ///
    note("Note: Survey weighted. Employed workers only.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(kde_unskilled, replace)
graph export "$OUT/kde_unskilled.png", replace width(2400) height(1600)

* Skilled KDE
use "$OUT/combined_lnwages.dta", clear
keep if skill == 1 & !missing(ln_wage)
twoway ///
    (kdensity ln_wage [aw=weight] if data_source==0, lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
    (kdensity ln_wage [aw=weight] if data_source==1, lcolor(navy)      lwidth(medium) lpattern(solid)), ///
    xtitle("Log Wage", size(small)) ytitle("Density", size(small)) ///
    title("Skilled Workers: Wage Distribution", size(medium) color(black)) ///
    subtitle("Actual 2020 Q1 vs Simulated 2020 Q1", size(small) color(gs6)) ///
    legend(order(1 "Actual 2020 Q1" 2 "Simulated 2020 Q1") rows(1) size(small) position(6)) ///
    xlabel(0(2)18, format(%9.1f) labsize(small)) ylabel(, format(%9.2f) labsize(small)) ///
    note("Note: Survey weighted. Employed workers only.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(kde_skilled, replace)
graph export "$OUT/kde_skilled.png", replace width(2400) height(1600)

* SECTION 7: STOCHASTIC DOMINANCE (sdgr and sdom)

* Unskilled CDF
use "$OUT/combined_lnwages.dta", clear
keep if skill==0 & !missing(ln_wage)
sdgr ln_wage [aw=weight], group(data_source) group1(0) group2(1) ng(2) np(500) ///
    xaxis("Log Wages") label1("Actual 2020 Q1") label2("Simulated 2020 Q1") ///
    ms(i i) int(0) sav("$OUT/sd_cdf_unskilled") replace
graph use "$OUT/sd_cdf_unskilled.gph"
graph export "$OUT/sd_cdf_unskilled.png", replace width(2400) height(1600)

use "$OUT/combined_lnwages.dta", clear
keep if skill==0 & !missing(ln_wage)
sdom ln_wage [aw=weight], g(data_source) group1(0) group2(1) ///
    order(3) np(200) trim(0.01) bs reps(100) ///
    saving("$OUT/sdom_unskilled") replace

* Skilled CDF
use "$OUT/combined_lnwages.dta", clear
keep if skill==1 & !missing(ln_wage)
sdgr ln_wage [aw=weight], group(data_source) group1(0) group2(1) ng(2) np(500) ///
    xaxis("Log Wages") label1("Actual 2020 Q1") label2("Simulated 2020 Q1") ///
    ms(i i) int(0) sav("$OUT/sd_cdf_skilled") replace
graph use "$OUT/sd_cdf_skilled.gph"
graph export "$OUT/sd_cdf_skilled.png", replace width(2400) height(1600)

use "$OUT/combined_lnwages.dta", clear
keep if skill==1 & !missing(ln_wage)
sdom ln_wage [aw=weight], g(data_source) group1(0) group2(1) ///
    order(3) np(200) trim(0.01) bs reps(100) ///
    saving("$OUT/sdom_skilled") replace
	
* View results
use "$OUT/sdom_unskilled.dta", clear
sum

use "$OUT/sdom_skilled.dta", clear
sum

graph use "$OUT/sd_cdf_unskilled.gph"
graph use "$OUT/sd_cdf_skilled.gph"


* Unskilled CDF
use "$OUT/combined_lnwages.dta", clear
keep if skill==0 & !missing(ln_wage)
sdgr ln_wage [aw=weight], group(data_source) group1(0) group2(1) ng(2) np(500) ///
    xaxis("Log Wages") label1("Actual 2020 Q1") label2("Simulated 2020 Q1") ///
    ms(i i) int(0) sav("$OUT/sd_cdf_unskilled") replace
graph use "$OUT/sd_cdf_unskilled.gph"
graph export "$OUT/sd_cdf_unskilled.png", replace width(2400) height(1600)

use "$OUT/combined_lnwages.dta", clear
keep if skill==0 & !missing(ln_wage)
sdom ln_wage [aw=weight], g(data_source) group1(0) group2(1) ///
    order(3) np(200) trim(0.01) bs reps(100) ///
    saving("$OUT/sdom_unskilled") replace

* Skilled CDF
use "$OUT/combined_lnwages.dta", clear
keep if skill==1 & !missing(ln_wage)
sdgr ln_wage [aw=weight], group(data_source) group1(0) group2(1) ng(2) np(500) ///
    xaxis("Log Wages") label1("Actual 2020 Q1") label2("Simulated 2020 Q1") ///
    ms(i i) int(0) sav("$OUT/sd_cdf_skilled") replace
graph use "$OUT/sd_cdf_skilled.gph"
graph export "$OUT/sd_cdf_skilled.png", replace width(2400) height(1600)

use "$OUT/combined_lnwages.dta", clear
keep if skill==1 & !missing(ln_wage)
sdom ln_wage [aw=weight], g(data_source) group1(0) group2(1) ///
    order(3) np(200) trim(0.01) bs reps(100) ///
    saving("$OUT/sdom_skilled") replace

* View sdom results
use "$OUT/sdom_unskilled.dta", clear
sum

use "$OUT/sdom_skilled.dta", clear
sum

* SECTION 8: VALIDATION METRICS (Wage MAE/RMSE, Employment MAE/RMSE,
* CI Coverage, Chi-square, Transition matrix)

*  WAGE VALIDATION 

* Simulated wages by skill (2020 Q1)
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

* EMPLOYMENT VALIDATION 

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

* CI COVERAGE 

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

* CHI-SQUARE GOODNESS OF FIT 

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

* ── TRANSITION MATRIX ────────────────────────────────────────────────

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

* SECTION 9: GINI COEFFICIENTS
use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear

* Simulated Gini — post-shock wages
ineqdeco wage_0_sim1 [aw=wgt19_sim1] if skilled_sim1==0 & inlist(worker_sim1,1,2,3,4,5,6) & wage_0_sim1 > 0 & wage_0_sim1 != .
scalar gini_sim_unskilled = r(gini)

ineqdeco wage_1_sim1 [aw=wgt19_sim1] if skilled_sim1==1 & inlist(worker_sim1,1,2,3,4,5,6) & wage_1_sim1 > 0 & wage_1_sim1 != .
scalar gini_sim_skilled = r(gini)

ineqdeco wage_0_sim1 [aw=wgt19_sim1] if inlist(worker_sim1,1,2,3,4,5,6) & wage_0_sim1 > 0 & wage_0_sim1 != .
scalar gini_sim_combined = r(gini)
di "Simulated Combined Gini = " %6.4f gini_sim_combined

* Actual 2020 Q1 Gini
use "$IN/qlfs_2020_q1_clean.dta", clear

gen employment_status = .
replace employment_status = 1 if Status==1 & sector==1
replace employment_status = 2 if Status==1 & sector==2
replace employment_status = 3 if Status==1 & sector==3
replace employment_status = 4 if Status==1 & sector==4
replace employment_status = 5 if Status==1 & sector==5
replace employment_status = 6 if Status==1 & sector==6
replace employment_status = 7 if inlist(Status,2,3,4)

ineqdeco wages [aw=Weight] if skilled_sim0==0 & inlist(employment_status,1,2,3,4,5,6) & wages > 0
scalar gini_act_unskilled = r(gini)

ineqdeco wages [aw=Weight] if skilled_sim0==1 & inlist(employment_status,1,2,3,4,5,6) & wages > 0
scalar gini_act_skilled = r(gini)

ineqdeco wages [aw=Weight] if inlist(employment_status,1,2,3,4,5,6) & wages > 0
scalar gini_act_combined = r(gini)
di "Actual 2020 Q1 Combined Gini = " %6.4f gini_act_combined

* Actual 2019 Q4 Gini
use "$IN/qlfs_2019_q4_clean.dta", clear

ineqdeco wages [aw=Weight] if skilled_sim0==0 & inlist(worker_sim0,1,2,3,4,5,6) & wages > 0
scalar gini_act2019_unskilled = r(gini)

ineqdeco wages [aw=Weight] if skilled_sim0==1 & inlist(worker_sim0,1,2,3,4,5,6) & wages > 0
scalar gini_act2019_skilled = r(gini)

* Display all Gini results

di "Unskilled 2019 Q4 Actual:    " %6.4f gini_act2019_unskilled
di "Unskilled Simulated 2020 Q1: " %6.4f gini_sim_unskilled
di "Unskilled Actual 2020 Q1:    " %6.4f gini_act_unskilled
di "------------------------------------"
di "Skilled 2019 Q4 Actual:      " %6.4f gini_act2019_skilled
di "Skilled Simulated 2020 Q1:   " %6.4f gini_sim_skilled
di "Skilled Actual 2020 Q1:      " %6.4f gini_act_skilled

di "Combined  — Simulated 2020 Q1: " %6.4f gini_sim_combined
di "Combined  — Actual    2020 Q1: " %6.4f gini_act_combined

* SECTION 10: S-RHO (BOOTSTRAP)

use "$OUT/combined_lnwages.dta", clear

label define skill_lbl 0 "Unskilled" 1 "Skilled", modify
label values skill skill_lbl

capture drop tag
gen tag = data_source   // 1 = Simulated, 0 = Actual 2020 Q1

* Unskilled S-rho
bootstrap t=r(Srho), saving("$OUT/bstat_u", replace) rep(100): ///
    srho ln_wage if skill==0 & !missing(ln_wage), by(tag) npts(200) kernel(gaussian)
scalar srho_unskilled = _b[t]
di "Unskilled S-rho = " %6.4f srho_unskilled

* Skilled S-rho
bootstrap t=r(Srho), saving("$OUT/bstat_s", replace) rep(100): ///
    srho ln_wage if skill==1 & !missing(ln_wage), by(tag) npts(200) kernel(gaussian)
scalar srho_skilled = _b[t]
di "Skilled S-rho = " %6.4f srho_skilled

* why is the gap so big on the gini coefficient?

* Check top wage percentiles — simulated vs actual 2020 Q1
use "$OUT/qlfs_2019_q4_clean_weighted_skill_income.dta", clear
xtile wage_pctile = wage_0_sim1 [aw=wgt19_sim1] if inlist(worker_sim1,1,2,3,4,5,6) & wage_0_sim1 > 0, nq(10)
tabstat wage_0_sim1 [aw=wgt19_sim1] if inlist(worker_sim1,1,2,3,4,5,6), by(wage_pctile) stat(mean)

use "$IN/qlfs_2020_q1_clean.dta", clear
gen employment_status = .
replace employment_status = 1 if Status==1 & sector==1
replace employment_status = 2 if Status==1 & sector==2
replace employment_status = 3 if Status==1 & sector==3
replace employment_status = 4 if Status==1 & sector==4
replace employment_status = 5 if Status==1 & sector==5
replace employment_status = 6 if Status==1 & sector==6
xtile wage_pctile = wages [aw=Weight] if inlist(employment_status,1,2,3,4,5,6) & wages > 0, nq(10)
tabstat wages [aw=Weight] if inlist(employment_status,1,2,3,4,5,6), by(wage_pctile) stat(mean)
