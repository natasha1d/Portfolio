rm(list =ls())
# Load necessary libraries

library(tidyverse)
library(tseries)
library(urca)
library(dynlm)
library(lmtest)
library(car)
library(ARDL)
library(readxl)
library(vars)


data <- read_excel("dataTP.xlsx")

#Rename
data <- data |>
  rename(RGDP = GDP,
         CPI = CPI,
         RR = deposit_interest,
         M3 = moneysupply,
         REER = exchange)

# Convert data to time series format
RGDP_ts <- ts(data$RGDP, start = c(2001,1), frequency = 1)
CPI_ts <- ts(data$CPI, start = c(2001,1), frequency = 1)
RR_ts <- ts(data$RR, start = c(2001,1), frequency = 1)
M3_ts <- ts(data$M3, start = c(2001,1), frequency = 1)
REER_ts <- ts(data$REER, start = c(2001,1), frequency = 1)



#Stationarity tests for level variables

pp_test_CPI <- ur.pp(CPI_ts, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_CPI) 
# Test-statistic is less than CV @ 5 %
#fail to reject null. CPI is no stationary

pp_test_RGDP <- ur.pp(RGDP_ts, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_RGDP)
#test-statistic > CV @5%
#RGDP is stationary

pp_test_RR <- ur.pp(RR_ts, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_RR)
#t-stat is , CV @ 5%
#RR is non stationary

pp_test_M3 <- ur.pp(M3_ts, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_M3)
#t-stat is < CV @5%
#M3 is non stationary


pp_test_REER <- ur.pp(REER_ts, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_REER)
#t-stat is < CV @5%
#REER is non stationary

#Combine level variables
combo_ts <- cbind(CPI_ts, RGDP_ts, RR_ts, M3_ts, REER_ts)

# Select lag length based on AIC
lag_selection <- VARselect(combo_ts, lag.max=10, type='const')
print(lag_selection$selection)
#choose up to lag 3
#Might complexity due to small sample

# Estimate ARDL model for levels using lowest lags
ardl_model_levels <- auto_ardl(CPI_ts ~ RGDP_ts + RR_ts + M3_ts + REER_ts , data = combo_ts, max_order = 1, selection = "AIC")
print(ardl_model_levels)
#ARDL(1,1,1,1,1) is best

ardl_best <- ardl(CPI_ts ~ RGDP_ts + RR_ts + M3_ts + REER_ts, data = combo_ts, order = c(1,1,1,1,1))
print(ardl_best)

#unrestricted ECM
uecm_best <- uecm(ardl_best)
summary(uecm_best)
#no bounds test because of multicollinearity


#check for multicollinearity
library(car)
vif(ardl_model_levels$best_model)

#M3 & RR and their lags are highly correlated, that's why the bounds test failed.
#the rest of the variables must be differenced 

#Differencing
diff_cpi <- diff(CPI_ts)
diff_REER <- diff(REER_ts)
diff_RGDP <- diff(RGDP_ts)
diff_M3 <- diff(M3_ts)
diff_RR <- diff(RR_ts)

#Differrencing to achieve stationarity to avoid spurious regression
#STATIONARITY TESTS with differenced variables

pp_test_CPI <- ur.pp(diff_cpi, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_CPI)
#test sta > than cv @10%
#Became stationary

pp_test_RGDP <- ur.pp(diff_RGDP, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_RGDP)
#Became stationary

pp_test_RR <- ur.pp(diff_RR, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_RR)
#became stationary @ 10%

pp_test_M3 <- ur.pp(diff_M3, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_M3)

pp_test_REER <- ur.pp(diff_REER, type = "Z-tau", model = "trend", lags = "short")
summary(pp_test_REER)
#became stationary

#after considering the correlated variables, M3 was entirely left out & diff_RGDP too
combo_df <- cbind(diff_cpi, diff_RR, diff_REER, RGDP_ts)

#Differenced ARDL
ardl_model_diff <- auto_ardl(diff_cpi ~  diff_RR + diff_REER + RGDP_ts,
                              data = combo_df, max_order = 1, selection = "AIC")

print(ardl_model_diff)

#check for multicollinearity
vif_values <- vif(ardl_model_diff$best_model)
print(vif_values)
#No more multicollinearity IN THE VARIABLES

summary(ardl_model_diff$best_model)

bounds_test2 <- bounds_f_test(ardl_model_diff$best_model, case = "3")
print(bounds_test2)
# Since the p-value is very small (< 0.05), you reject the null hypothesis of no cointegration.
#This provides strong evidence that a cointegrating (long-run) relationship exists among your variables.
tbounds <- bounds_t_test(ardl_model_diff$best_model, case = 3)
print(tbounds)
#p-value is lower than 0.05 so there's consistency. Evidence for cointegration

#UECM
uecm_best <- uecm(ardl_model_diff$best_model)
summary(uecm_best)

#RECM
recm_best <- recm(uecm_best, case = 3)
summary(recm_best)
#ECM has a negative sign meaning deviations from the long run equilibrium are corrected over time



# Diagnostic checks for the model
diagnostic_tests <- list(
  serial_correlation = bgtest(uecm_best),
  heteroskedasticity = bptest(uecm_best),
  normality = shapiro.test(residuals(uecm_best))
)
print(diagnostic_tests)

#BG test
#no evidence for serial correlation @ lag 1
#Reject null at 0.05 - pvalue is 0.02318


#BP test
#Fail ro reject null for BP test,
#significant at  0.05
#no evidence of heteroskedasticity

#Shapiro
#FAIL to reject null at 0.05 for normality
#No statistical evidence to suggest that residuals deviate from normality


#multipliers
multipliers(uecm_best, type = "sr")
#repo rate is significant and positive in the short run, the rest aren't
multipliers(uecm_best)
#The real effective exchange rate (REER) has a statistically significant negative long-run impact on CPI, indicating that increases(appreciation in nominal exchange rate) in REER are associated with decreases in CPI over the long run.


# Perform Granger causality tests
grangertest(diff_cpi ~ diff_REER, order = 1, data = combo_df)
#fail to reject null, no granger causality
grangertest(diff_cpi ~ RGDP_ts, order = 1, data = combo_df)
#NO GRANGER CAUSALITY




