# Equity Style Factor Analysis

## Overview
This project evaluates the historical performance of MSCI global style indices which includes Growth, Value, Quality, Momentum, Low Volatility, and Small Cap relative to the MSCI benchmark. The analysis applies classical statistical and econometric techniques to determine which styles have delivered statistically significant excess returns.

## Methods
- **Paired sample t-tests** — tested whether each style achieved a positive average excess return relative to the benchmark; identified Quality and Small Cap as significant outperformers
- **One-way ANOVA** — tested whether styles achieved significantly different returns across the panel; failed to reject equality, indicating high within-style variance relative to between-style differences
- **Time-series OLS regression** — estimated alpha (intercept), beta (market sensitivity), and R² for each style; Low Volatility and Quality showed statistically significant positive alphas
- **VAR & Impulse Response Functions** — modelled inter-style dynamics and estimated response to market shocks using Statsmodels

## Key Findings
- Low Volatility delivered the strongest risk-adjusted performance, with a statistically significant alpha and defensive beta below 1
- Quality showed significant positive alpha and high R², indicating consistent benchmark-relative outperformance
- Momentum exhibited the highest raw alpha but with elevated variance, reducing statistical significance
- ANOVA results suggest style differentiation is limited when controlling for within-style volatility

## Tools
Python — `pandas`, `scipy`, `statsmodels`, `matplotlib`, `seaborn`
