# Inflation Determinants: ARDL Cointegration Analysis
### South Africa, 2001–Present | Term Paper

## Overview
This project investigates the long-run and short-run determinants of inflation (CPI) 
in South Africa using an Autoregressive Distributed Lag (ARDL) bounds testing framework. 
Variables considered include real GDP, the deposit interest rate, money supply (M3), 
and the real effective exchange rate (REER).

## Pipeline

### 1. Stationarity Testing
- Phillips-Perron unit root tests (`ur.pp`) on all variables in levels
- Re-tested on first differences to confirm I(1) behaviour
- Mixed order of integration (RGDP stationary in levels; CPI, RR, M3, REER integrated 
  of order 1) confirmed ARDL as the appropriate framework

### 2. ARDL Model Selection
- Automatic lag selection via `auto_ardl` with AIC criterion
- Optimal specification: ARDL(1,1,1,1,1)
- VIF diagnostics revealed high multicollinearity between M3 and RR — M3 excluded 
  from final model

### 3. Bounds Test for Cointegration
- F-bounds test: rejected null of no cointegration (p < 0.05)
- t-bounds test: consistent result — strong evidence of a long-run relationship among 
  CPI, interest rate, REER, and RGDP

### 4. Error Correction Models
- **UECM** (Unrestricted ECM): short-run dynamics and speed of adjustment
- **RECM** (Restricted ECM): confirmed negative ECM coefficient — deviations from 
  long-run equilibrium are corrected over time

### 5. Diagnostics
- Breusch-Godfrey: no serial correlation at lag 1
- Breusch-Pagan: no heteroskedasticity
- Shapiro-Wilk: residuals normally distributed

### 6. Key Findings
- REER has a statistically significant negative long-run impact on CPI — exchange 
  rate appreciation is associated with lower inflation over the long run
- Repo rate is significant and positive in the short run
- No Granger causality from REER or RGDP to CPI

## Methods
Phillips-Perron unit root tests, ARDL bounds testing, UECM/RECM, Granger causality, 
short-run and long-run multipliers, VIF diagnostics

## Tools
R — `ARDL`, `urca`, `vars`, `dynlm`, `lmtest`, `car`

## Data
Annual South African macroeconomic data (2001 onwards): CPI, real GDP, deposit 
interest rate, money supply (M3), real effective exchange rate. Data not included 
