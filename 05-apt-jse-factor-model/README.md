# Arbitrage Pricing Theory: JSE Factor Model
### South Africa, 2009–2024 | Empirical Finance Project

## Overview
This project replicates and extends the Page (1986) Arbitrage Pricing Theory (APT) 
framework applied to the Johannesburg Stock Exchange (JSE). It estimates the risk 
premia associated with macroeconomic factors — inflation shocks, interest rate shocks, 
and exchange rate shocks — and benchmarks APT against CAPM at both market and 
individual stock level.

Data sources: JSE All Share Index, JSE Top 40, 91-day T-bill, CPI, repo rate, 
ZAR/USD exchange rate (monthly, 2009–2024).

## Pipeline

### 1. Data Cleaning & Integration
- Six separate data sources cleaned, standardised to monthly end-of-date frequency, 
  and merged
- Log returns computed for JSE All Share and Top 40
- Excess returns constructed using monthly-converted T-bill as risk-free rate

### 2. Factor Construction
- **Inflation shock**: first difference of monthly CPI rate
- **Interest rate shock**: first difference of repo rate
- **Exchange rate shock**: percentage change in ZAR/USD

### 3. Descriptive Statistics & Stationarity
- Descriptive stats table (mean, std dev, min, max, skewness, kurtosis)
- Correlation matrix across factors and returns
- Augmented Dickey-Fuller stationarity tests on all variables

### 4. Time-Series APT Regression
- OLS regression of JSE excess return on three macro factor shocks
- **Newey-West robust standard errors** (lag order selected by rule of thumb)
- R², adjusted R², F-statistic reported

### 5. Cross-Sectional APT (Page 1986 Replication)
- **Principal Component Analysis (PCA)** for statistical factor extraction
- Kaiser criterion (eigenvalue > 1) for factor selection
- Cross-sectional regression of Top 40 excess returns on extracted factors
- Risk premia (lambda values) estimated

### 6. Model Diagnostics
- Breusch-Pagan heteroskedasticity test
- Breusch-Godfrey autocorrelation test (up to lag 4)
- Jarque-Bera normality test on residuals
- VIF multicollinearity check
- Durbin-Watson test

### 7. Single-Factor & Factor Contribution Analysis
- Individual factor models estimated (inflation only, interest rate only, FX only)
- Partial R² decomposition: marginal contribution of each factor
- Relative importance analysis using LMG method (`relaimpo`)

### 8. Rolling Regression Analysis
- 60-month rolling window regressions to assess parameter stability over time
- Time-varying factor sensitivities plotted across the 2009–2024 period

### 9. Structural Break Testing
- Bai-Perron structural break detection (`strucchange`)
- Break dates identified and reported

### 10. CAPM vs APT Comparison
- CAPM estimated using Top 40 as market proxy
- Comprehensive model comparison: CAPM vs Macro APT vs Statistical APT
- R², adjusted R², AIC, BIC across all three models
- APT factors tested on CAPM residuals to assess incremental explanatory power

## Key Findings
- Macro APT outperforms CAPM on adjusted R² — macroeconomic factors capture 
  systematic risk not explained by the market factor alone
- Exchange rate shock is the most influential factor by partial R²
- Rolling regressions reveal time-variation in factor sensitivities, particularly 
  around the 2015–2016 rand depreciation and COVID-19 period

## Methods
APT time-series regression, PCA factor extraction, Fama-MacBeth cross-sectional 
regression, Newey-West robust SEs, rolling window regression, Bai-Perron structural 
breaks, relative importance analysis (LMG), CAPM benchmark comparison

## Tools
R — `lmtest`, `sandwich`, `relaimpo`, `strucchange`, `zoo`, `corrplot`, `psych`, 
`ggplot2`, `tidyverse`, `quantmod`

## Data
JSE All Share and Top 40 price data, 91-day T-bill rate, CPI, repo rate, ZAR/USD 
exchange rate (2009–2024). Raw data files not included due to licensing restrictions.

> **Note:** Section 12 (FirstRand individual stock analysis) uses synthetic placeholder 
> return data. This section is intended as a structural template and should be 
> re-run with actual FSR price data from a licensed source (e.g. Bloomberg, Refinitiv).
