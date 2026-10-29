# Natashya Dikola — Portfolio

**Master of Economic Science candidate | University of the Witwatersrand**  
Student member, Institute and Faculty of Actuaries  
natashya1d@icloud.com | Johannesburg, South Africa (on exchange at UCLouvain, Belgium, until January 2027)  

---

## About

I am a quantitative analyst with a strong foundation in econometrics, statistical modelling, causal inference, machine learning, and financial analytics. My work spans labour market microsimulation, asset pricing, time series econometrics, and applied machine learning — implemented across Python, R, Stata, SAS, and SQL.

My research follows a deliberate arc: applying and validating traditional structural econometric methods, then extending them using modern ML and causal inference frameworks to assess where each approach excels and where it breaks down

---

## Projects

| # | Project | Methods | Tools |
|---|---------|---------|-------|
| [01](#01) | Equity Style Factor Analysis | Paired t-tests, ANOVA, OLS, VAR & IRF | Python |
| [02](#02) | ML Return Forecasting | Linear Regression, Ridge, GridSearchCV | Python |
| [03](#03) | Labour Market Microsimulation | Multinomial logit, Heckman, Job queuing, DML (in progress) | Stata |
| [04](#04) | Inflation Determinants | ARDL bounds testing, UECM/RECM, Granger causality | R |
| [05](#05) | APT JSE Factor Model | APT, PCA, Fama-MacBeth, Rolling regression, CAPM comparison | R |
| [06](#06) | Motor Insurance Pricing Analysis | Data quality checks, one-way analysis, large-loss capping, credibility, out-of-sample lift & Gini | SQL |

---

## Research Arc

**Honours → Masters continuity:**

My Honours research built a structural labour market microsimulation model for
South Africa, validated against observed 2020 Q1 QLFS outcomes using MAE, RMSE,
CI coverage, chi-square goodness-of-fit, Gini coefficients, and stochastic dominance
tests. The model used a multinomial logit for occupational reallocation and a
Heckman two-stage model for wage prediction.

My Masters research extends this by replacing the parametric structural models with
**Double/Debiased Machine Learning** (`ddml`, Ahrens et al., 2024, *The Stata Journal*)
— using Neyman-orthogonal, cross-fitted estimators with stacked learners (lasso,
random forest, gradient boosting). The same validation framework is applied to both
approaches, enabling a rigorous comparison of causal identification, predictive
accuracy, and distributional fit between traditional econometrics and modern ML.

---

<a name="01"></a>
## 01 — Equity Style Factor Analysis
📁 [View project](./01-equity-style-factor-analysis/)

Evaluates MSCI global style indices (Growth, Value, Quality, Momentum, Low Volatility,
Small Cap) relative to the MSCI benchmark using classical statistical and time series
methods.

**Methods:** Paired sample t-tests · One-way ANOVA · Time-series OLS (alpha, beta, R²)
· VAR with Impulse Response Functions

**Key findings:** Low Volatility delivered the strongest risk-adjusted performance with
a statistically significant alpha and defensive beta below 1. ANOVA results suggest
limited style differentiation when controlling for within-style volatility.

**Tools:** Python — `pandas`, `scipy`, `statsmodels`, `matplotlib`, `seaborn`

---

<a name="02"></a>
## 02 — Machine Learning Return Forecasting
📁 [View project](./02-ml-return-forecasting/)

Applies supervised ML to forecast 3-month forward style returns using historical
risk and return features. Demonstrates correct ML pipeline discipline — no data
leakage, proper train/test/validation separation, and critical commentary on
out-of-sample generalisation.

**Methods:** MinMax scaling (fit on train only) · 70/30 train-test split · Linear
Regression · Ridge Regression with GridSearchCV (5-fold CV) · Regularisation path
analysis · Train/test/validation MSE comparison

**Key findings:** Ridge outperformed Linear Regression on the test set but Linear
Regression generalised better on the validation set — flagged as evidence of
overfitting in the Ridge tuning process and discussed as a limitation motivating
further feature engineering.

**Tools:** Python — `scikit-learn`, `pandas`, `numpy`, `matplotlib`

---

<a name="03"></a>
## 03 — Labour Market Microsimulation: COVID-19 Shock Analysis
📁 [View project](./03-labour-market-microsimulation/)

*Honours research project. Presented as keynote at the Energy Modelling Platform for Africa (EMP-A) Joint High-Level Community Meeting, Cape Town, March 2026, co-hosted by African Energy Futures, the Presidential Climate Commission and Climate Compatible Growth; and at the 10th International Conference on Applied Theory, Macro and Empirical Finance, University of Macedonia, Thessaloniki, April 2026.*

Full structural microsimulation of South Africa's labour market response to the
COVID-19 shock (2019 Q4 → 2020 Q1), applied to QLFS microdata covering approximately
30 million working-age individuals after survey weighting.

**Methods:** Post-stratification calibration by province · Employment and wage shock
estimation · Multinomial logit (occupational choice) · Job queuing algorithm with
macro-constraint enforcement · Heckman two-stage wage model · Weighted KDE wage
distributions · Stochastic dominance testing (`sdgr`, `sdom`) · Gini coefficients
(`ineqdeco`) · Bootstrapped S-rho · MAE, RMSE, CI coverage, chi-square GOF

**Validation result:** Post-stratification calibration improved the chi-square goodness-of-fit statistic from 438.05 (p<0.0001) to 28.80 (p=0.004). The calibrated model fits the observed distribution far better, though the test still detects some remaining differences, which the Masters extension aims to address.

**Masters extension (in progress):** Replacing the multinomial logit and Heckman
model with Double/Debiased Machine Learning (`ddml`, Ahrens et al., 2024) using
stacked learners, with identical validation applied to both approaches for direct
comparison.

**Tools:** Stata — `mlogit`, `heckman`, `calibrate`, `ineqdeco`, `sdgr`, `sdom`,
`srho`, `svyset`, `twoway`

---

<a name="04"></a>
## 04 — Inflation Determinants: ARDL Cointegration Analysis
📁 [View project](./04-inflation-determinants-ardl/)

Investigates the long-run and short-run determinants of South African CPI using
an ARDL bounds testing framework. Addresses mixed order of integration and
multicollinearity through careful model selection and variable treatment.

**Methods:** Phillips-Perron unit root tests · Automatic ARDL lag selection (AIC)
· VIF multicollinearity diagnostics · F-bounds and t-bounds cointegration tests
· UECM and RECM · Short-run and long-run multipliers · Granger causality tests
· Breusch-Godfrey, Breusch-Pagan, Shapiro-Wilk diagnostics

**Key findings:** Strong evidence of cointegration among CPI, interest rate, REER,
and RGDP. REER has a statistically significant negative long-run impact on CPI.
Repo rate is significant and positive in the short run.

**Tools:** R — `ARDL`, `urca`, `vars`, `dynlm`, `lmtest`, `car`

---

<a name="05"></a>
## 05 — Arbitrage Pricing Theory: JSE Factor Model
📁 [View project](./05-apt-jse-factor-model/)

Replicates and extends the Page (1986) APT framework applied to the JSE All Share
Index (2009–2024), benchmarking macro APT against CAPM at both market and individual
stock level. Integrates six data sources across a full reproducible pipeline.

**Methods:** Data cleaning and monthly standardisation across 6 sources · APT
time-series OLS with Newey-West robust SEs · PCA for statistical factor extraction
· Fama-MacBeth cross-sectional regression · Risk premia (lambda) estimation ·
Partial R² and LMG relative importance decomposition · 60-month rolling regressions
· Bai-Perron structural break testing · CAPM vs Macro APT vs Statistical APT
model comparison (R², AIC, BIC)

**Key findings:** Macro APT outperforms CAPM on adjusted R² — macro factors capture
systematic risk not explained by the market factor alone. Rolling regressions reveal
time-varying factor sensitivities, particularly around the 2015–2016 rand depreciation
and the COVID-19 period.

**Tools:** R — `lmtest`, `sandwich`, `relaimpo`, `strucchange`, `zoo`, `corrplot`,
`ggplot2`, `tidyverse`, `quantmod`

---

<a name="06"></a>
## 06 — Motor Insurance Pricing Analysis in SQL
📁 [View project](./06-motor-insurance-pricing-sql/)

End-to-end pricing analysis of 677,991 real motor insurance policies and 26,444
claims (freMTPL2, CASdatasets), written in SQL: from raw data to rating
relativities tested on unseen policies.

**Methods:** Data quality and reconciliation checks · Exposure-weighted claim
frequency, severity and pure premium by rating factor · Large-loss capping at the
99.5th percentile with a portfolio load · Limited-fluctuation credibility ·
80/20 train/test split · Exposure-weighted deciles, lift and Gini

**SQL techniques:** CTEs · Window functions (`SUM() OVER`, `RANK`, `LAG`, running
totals) · `UNPIVOT` · `QUALIFY` · Correlated subqueries · `EXISTS` / `NOT EXISTS`

**Key findings:** Claims above €20,000 are 0.8% of claims but 37% of cost. Drivers
aged 18–20 claim 3.2 times as often as average. On held-out policies, the riskiest
tenth claims 5.6 times as much as the safest (Gini 0.26). The score over-predicts
the riskiest tenth because the one-way relativities are multiplied as if the
factors were independent, which motivates a Poisson/Gamma GLM as the next step.

**Tools:** SQL (DuckDB) · Python for the runner and charts

---

## Technical Skills

**Languages:** Python · R · Stata · SQL · SAS · Advanced Excel

**Econometrics & Statistics:** Time series analysis · Cointegration · Panel data ·
Microsimulation · Survey-weighted estimation · Causal inference · Double/Debiased ML

**Machine Learning:** Supervised regression · Ridge/Lasso · Cross-validation ·
Feature engineering · Stacking · Pipeline design

**Finance:** Factor models · Asset pricing · Performance attribution · Risk modelling ·
Financial analytics

---

## Education

**University of the Witwatersrand** — Master of Economic Science *(2026 – present)*  
Coursework: Time-Series Econometrics · Quantitative Research
Techniques · Advanced Mathematical Economics 

**Université catholique de Louvain (UCLouvain)** — Exchange semester *(September 2026 – January 2027)*. 
Coursework: Applied Econometrics · Time-Series Econometrics · Dynamical Methods in Economics · Advanced Microeconomics I · Growth, Population and Environment

**University of the Witwatersrand** — Bachelor of Economic Science with Honours *(Graduated March 2026)*  
Aggregate 71%; Advanced Mathematical Economics 87%; Research Paper in Economics 80%. 
Coursework: Advanced Econometrics · Financial Economics: Capital Markets, Investments and International Finance 
· Advanced Macroeconomics · Advanced Microeconomics  

**University of Pretoria** — Bachelor of Science *(Graduated May 2024)*  
Final-year modules in statistics, data analytics, economics and mathematics

