# Labour Market Microsimulation: COVID-19 Shock Analysis
### South Africa, 2019 Q4 → 2020 Q1 | Honours Research Project

## Overview
This project simulates the impact of the COVID-19 economic shock on South Africa's 
labour market using a structural microsimulation model applied to the Quarterly Labour 
Force Survey (QLFS). The baseline is 2019 Q4 (pre-shock) and the target is 2020 Q1 
(post-lockdown), covering approximately 30 million working-age individuals once survey 
weights are applied.

Findings were presented at the **Presidential Climate Commission (PCC) 2026 conference** 
in Cape Town and at the **10th International Conference on Applied Theory, Macro and Empirical Finance** in
Thessaloniki, Greece.

The Masters extension of this project will benchmark these traditional econometric methods 
against machine learning alternatives — comparing predictive accuracy, distributional fit, 
and policy interpretability across methods.

---

## Repository Contents

| File | Description |
|------|-------------|
| `DoFile_QLFS_2019Q4_2020Q1_No_Calibration.do` | Full microsimulation pipeline: weighting, shocks, job queuing, wage simulation, validation |
| `Graphs_QLFS_2019Q4_2020Q1_7May26.do` | Publication-quality visualisations: employment distributions, wage distributions, stochastic dominance, Gini coefficients |

---

## Pipeline

### 1. Data & Survey Weighting
- QLFS 2019 Q4 and 2020 Q1 microdata (Statistics South Africa)
- Survey-weighted estimation throughout (`svyset`, `svy:`)
- Post-stratification calibration of baseline weights by province using population 
  growth targets
- Calibration impact: chi-square improved from 438.05 (p<0.0001) to 28.80 (p=0.004)

### 2. Shock Estimation
- Employment share changes by sector (Agriculture, Mining, Manufacturing, Construction, 
  Services, Other Services) and skill level (skilled/unskilled)
- Wage shocks by skill group between 2019 Q4 and 2020 Q1

### 3. Occupational Reallocation — Job Queuing Algorithm
- **Multinomial logit** model of occupational choice as a function of demographics 
  and geography (urban/rural, province, age, education, marital status, children)
- **Job queuing**: individuals ranked by predicted sector probability; those least likely 
  to retain employment in contracting sectors displaced first; those most likely to enter 
  expanding sectors reallocated first
- Macro-constraint adjustment to ensure aggregate employment shares match 2020 Q1 targets
- Iterated separately by skill group

### 4. Wage Simulation
- **Heckman two-stage selection model** correcting for selection into employment
- Residuals drawn from N(0, σ²) for individuals with unobserved wages
- Aggregate wage adjustment factor applied to match observed macro wage changes

### 5. Visualisations (10 sections)
- Bar charts: employment shares by sector and skill (2019 Q4 vs 2020 Q1)
- Bar charts: employment shocks by sector and skill with percentage labels
- Bar chart: wage changes by skill level with 95% confidence intervals
- Bar charts: actual vs simulated 2020 Q1 employment distributions with CIs
- **KDE plots**: log wage distributions — simulated vs actual 2020 Q1 (skilled & unskilled)
- **Stochastic dominance CDFs** (`sdgr`) and dominance tests (`sdom`, bootstrapped, 100 reps)
- **Gini coefficients**: 2019 Q4 actual, 2020 Q1 simulated, 2020 Q1 actual — by skill group
- **S-rho**: bootstrapped distributional similarity statistic

### 6. Validation
| Metric | Description |
|--------|-------------|
| Employment MAE & RMSE | Simulated vs actual sector shares across 14 skill-sector cells |
| CI Coverage | Share of simulated proportions falling within actual 95% CIs |
| Chi-square (df=12) | 28.80, p=0.004 (with calibration) vs 438.05, p<0.0001 (without) |
| Wage MAE & RMSE | Simulated vs actual average wages by skill group |
| Gini coefficient | Inequality comparison across time points and simulation |
| S-rho | Bootstrapped distributional overlap statistic |

---

## Methods Summary
- Multinomial logit (occupational choice / labour supply)
- Job queuing with probabilistic ranking and macro-constraint enforcement
- Heckman two-stage selection model (wage prediction with selection correction)
- Survey-weighted estimation (`svyset`, `svy:`)
- Post-stratification calibration (`calibrate`)
- Stochastic dominance testing (`sdgr`, `sdom`)
- Inequality analysis (`ineqdeco`, Gini coefficients)
- Distributional similarity (bootstrapped S-rho)

## Tools
Stata — `mlogit`, `heckman`, `calibrate`, `ineqdeco`, `sdgr`, `sdom`, `srho`, 
`svyset`, `twoway`, matrix operations

## Data
QLFS microdata is proprietary (Statistics South Africa) and is not included in this 
repository. Both do-files are fully reproducible given access to the cleaned QLFS 
datasets at the paths specified in the global macros.

## Masters Extension (In Progress)
The next phase extends this framework using **Double/Debiased Machine Learning (DDML)** 
implemented in Stata via the `ddml` package (Ahrens, Hansen, Schaffer & Wiemann, 2024, 
*The Stata Journal*).

The structural multinomial logit and Heckman wage model from the Honours paper are 
replaced with Neyman-orthogonal, cross-fitted estimators that allow controls to enter 
nonparametrically — addressing potential misspecification bias in the traditional approach.

**Models being compared:**
- Partially linear model (`ddml, model(partial)`) vs multinomial logit for occupational 
  reallocation
- Interactive model (`ddml, model(interactive)`) for binary employment transitions
- Heckman 2-stage vs DML-based wage prediction

**Key methodological features:**
- Stacking estimation (`pystacked`) combining lasso, random forest, and gradient 
  boosting as base learners — data-driven learner selection
- K-fold cross-fitting to ensure independence between nuisance estimation and 
  second-stage causal estimates
- Neyman orthogonality ensuring local robustness to first-stage estimation error

**Validation:** same framework as Honours paper (MAE, RMSE, CI coverage, chi-square 
GOF, Gini, stochastic dominance) applied to both traditional and DML approaches for 
direct comparability.

**Reference:** Ahrens, A., Hansen, C.B., Schaffer, M.E., & Wiemann, T. (2024). 
ddml: Double/debiased machine learning in Stata. *The Stata Journal, 24*(1). 
https://doi.org/10.1177/1536867X241233641
