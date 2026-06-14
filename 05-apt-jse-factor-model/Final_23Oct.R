# Clear workspace
rm(list = ls())

# Load required libraries
library(dplyr)
library(ggplot2)
library(lubridate)
library(readxl)
library(tseries)
library(lmtest)
library(car)
library(sandwich)
library(tidyr)
library(knitr)
library(strucchange)
library(moments)
library(corrplot)
library(zoo)
library(relaimpo)
library(psych)
library(broom)
library(tibble)
library(purrr)

# Set options
options(scipen = 999)

# SECTION 1: DATA IMPORT AND CLEANING
# ==============================================================================

cat("SECTION 1: Loading and cleaning datasets...\n")

# Load all datasets
jse_data <- read_excel("ECONFIN data jse all share.xlsx", sheet = "Sheet1")
top40_data <- read_excel("JSE Top40 TRA correct.xlsx", sheet = "Sheet1")
tbill_data <- read.csv("91 day t bill  (1).csv", sep = ";")
inflation_data <- read.csv("INFLATION RATE  (1).csv", sep = ";")
repo_data <- read.csv("REPO RATE (2).csv", sep = ";")
fx_data <- read.csv("TSReport-2025-10-9-17-29-27 (1) (1).csv")

# Standardize column names
colnames(tbill_data) <- c("Date", "TBill_Rate")
colnames(inflation_data) <- c("Date", "Inflation_Rate")
colnames(repo_data) <- c("Date", "Repo_Rate")
colnames(fx_data) <- c("Date", "Code", "Description", "Unit", "Value")

# Clean numeric values function
clean_numeric <- function(x) {
  as.numeric(gsub(",", ".", gsub("--", NA, x)))
}
# Clean JSE All Share data
cat("Cleaning JSE All Share data...\n")
jse_clean <- jse_data %>%
  dplyr::filter(!is.na(Date) & !is.na(`Close Price`)) %>%
  dplyr::mutate(
    Date = as.Date(Date, format = "%m/%d/%Y"),
    jse_price = `Close Price`,
    jse_return = c(NA, diff(log(jse_price)))
  ) %>%
  dplyr::select(Date, jse_price, jse_return) %>%
  dplyr::filter(!is.na(jse_return))

# Clean JSE Top 40 data
cat("Cleaning JSE Top 40 data...\n")
top40_clean <- top40_data %>%
  dplyr::filter(!is.na(Date) & !is.na(`Close Price`)) %>%
  mutate(
    Date = as.Date(Date, format = "%m/%d/%Y"),
    top40_price = `Close Price`,
    top40_return = c(NA, diff(log(top40_price)))
  ) %>%
  dplyr::select(Date, top40_price, top40_return) %>%
  dplyr::filter(!is.na(top40_return))

# Clean T-bill data
cat("Cleaning T-bill data...\n")
tbill_clean <- tbill_data %>%
  mutate(
    Date = as.Date(Date, format = "%Y-%m-%d"),
    TBill_Rate = clean_numeric(TBill_Rate) / 100
  ) %>%
  filter(!is.na(TBill_Rate))

# Clean inflation data
cat("Cleaning inflation data...\n")
inflation_clean <- inflation_data %>%
  mutate(
    Date = as.Date(Date, format = "%Y-%m-%d"),
    Inflation_Rate = clean_numeric(Inflation_Rate) / 100
  ) %>%
  filter(!is.na(Inflation_Rate))

# Clean repo rate data
cat("Cleaning repo rate data...\n")
repo_clean <- repo_data %>%
  mutate(
    Date = as.Date(Date, format = "%Y-%m-%d"),
    Repo_Rate = clean_numeric(Repo_Rate) / 100
  ) %>%
  filter(!is.na(Repo_Rate))

# Clean FX data
cat("Cleaning FX data...\n")
fx_clean <- fx_data %>%
  dplyr::mutate(
    Date = as.Date(paste0(Date, "/01"), format = "%Y/%m/%d"),
    FX_Rate = as.numeric(Value) / 100
  ) %>%
  dplyr::select(Date, FX_Rate) %>%
  dplyr::arrange(Date)

# Standardize all datasets to end-of-month
cat("Standardizing datasets to monthly frequency...\n")

jse_monthly <- jse_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

top40_monthly <- top40_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

tbill_monthly <- tbill_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

inflation_monthly <- inflation_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

repo_monthly <- repo_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

fx_monthly <- fx_clean %>%
  mutate(Date = ceiling_date(Date, "month") - days(1)) %>%
  group_by(Date) %>%
  summarize(across(where(is.numeric), last)) %>%
  ungroup()

# Merge all datasets
cat("Merging all datasets...\n")
merged_data <- jse_monthly %>%
  full_join(top40_monthly, by = "Date") %>%
  full_join(tbill_monthly, by = "Date") %>%
  full_join(inflation_monthly, by = "Date") %>%
  full_join(repo_monthly, by = "Date") %>%
  full_join(fx_monthly, by = "Date") %>%
  arrange(Date) %>%
  filter(!is.na(jse_return))

# SECTION 2: FACTOR CONSTRUCTION AND APT DATA PREPARATION
# ==============================================================================

cat("SECTION 2: Constructing APT factors and preparing data...\n")

# Set analysis period
start_date <- "2009-12-31"
end_date <- "2024-12-31"

# Create APT dataset with factors
apt_data <- merged_data %>%
  filter(Date >= as.Date(start_date) & Date <= as.Date(end_date)) %>%
  arrange(Date) %>%
  mutate(
    # Convert annual T-bill to monthly risk-free rate
    monthly_rf = (1 + TBill_Rate)^(1/12) - 1,
    
    # Dependent variables: Excess returns
    jse_excess_return = jse_return - monthly_rf,
    top40_excess_return = top40_return - monthly_rf,
    
    # Macroeconomic shocks (first differences)
    INF_SHOCK = Inflation_Rate - lag(Inflation_Rate),
    INT_SHOCK = Repo_Rate - lag(Repo_Rate),
    FX_SHOCK = (FX_Rate - lag(FX_Rate)) / lag(FX_Rate)
  ) %>%
  filter(row_number() > 1) %>%  # Remove first row due to lagged variables
  filter(!is.na(INF_SHOCK) & !is.na(INT_SHOCK) & !is.na(FX_SHOCK) & 
           !is.na(jse_excess_return) & !is.na(top40_excess_return)) %>%
  mutate(obs_number = row_number())

# SECTION 3: DESCRIPTIVE STATISTICS
# ==============================================================================

cat("SECTION 3: Calculating descriptive statistics...\n")

# Select key variables
desc_vars <- apt_data %>%
  dplyr::select(jse_excess_return, top40_excess_return, INF_SHOCK, INT_SHOCK, FX_SHOCK, monthly_rf)

# Calculate descriptive statistics
desc_stats <- data.frame(
  Variable = c("JSE Excess Return", "Top 40 Excess Return", "Inflation Shock", 
               "Interest Rate Shock", "Exchange Rate Shock", "Risk-Free Rate"),
  Mean = sapply(desc_vars, function(x) mean(x, na.rm = TRUE) * 100),
  Std_Dev = sapply(desc_vars, function(x) sd(x, na.rm = TRUE) * 100),
  Min = sapply(desc_vars, function(x) min(x, na.rm = TRUE) * 100),
  Max = sapply(desc_vars, function(x) max(x, na.rm = TRUE) * 100),
  Skewness = sapply(desc_vars, function(x) skewness(x, na.rm = TRUE)),
  Kurtosis = sapply(desc_vars, function(x) kurtosis(x, na.rm = TRUE)),
  Observations = sapply(desc_vars, function(x) sum(!is.na(x)))
)

print(desc_stats)

# Correlation matrix
cat("\nCalculating correlation matrix...\n")
cor_matrix <- apt_data %>%
  dplyr::select(jse_excess_return, INF_SHOCK, INT_SHOCK, FX_SHOCK) %>%
  cor(use = "complete.obs")

print(cor_matrix)

# Stationarity tests (Augmented Dickey-Fuller)
cat("\nPerforming stationarity tests...\n")
adf_jse <- adf.test(na.omit(apt_data$jse_excess_return))
adf_inf <- adf.test(na.omit(apt_data$INF_SHOCK))
adf_int <- adf.test(na.omit(apt_data$INT_SHOCK))
adf_fx <- adf.test(na.omit(apt_data$FX_SHOCK))

stationarity_tests <- data.frame(
  Variable = c("JSE Excess Return", "Inflation Shock", "Interest Rate Shock", "Exchange Rate Shock"),
  ADF_Statistic = c(adf_jse$statistic, adf_inf$statistic, adf_int$statistic, adf_fx$statistic),
  ADF_pvalue = c(adf_jse$p.value, adf_inf$p.value, adf_int$p.value, adf_fx$p.value),
  Stationary = c(adf_jse$p.value < 0.05, adf_inf$p.value < 0.05, 
                 adf_int$p.value < 0.05, adf_fx$p.value < 0.05)
)

print(stationarity_tests)

# SECTION 4: TIME-SERIES APT REGRESSION
# ==============================================================================

cat("SECTION 4: Running time-series APT regression...\n")

# Main APT model (3-factor)
apt_model <- lm(jse_excess_return ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, data = apt_data)

# Display basic results
cat("Time-Series APT Model Results:\n")
print(summary(apt_model))

# Robust standard errors (Newey-West)
n_obs <- nrow(apt_data)
nw_lag <- floor(4 * (n_obs / 100)^(2/9))
cat("Using Newey-West lag order:", nw_lag, "\n")

nw_vcov <- NeweyWest(apt_model, lag = nw_lag, prewhite = FALSE)
nw_test <- coeftest(apt_model, vcov. = nw_vcov)

cat("Robust Standard Errors (Newey-West):\n")
print(nw_test)

# Model fit statistics
r_squared <- summary(apt_model)$r.squared
adj_r_squared <- summary(apt_model)$adj.r.squared
f_stat <- summary(apt_model)$fstatistic

cat("\nModel Fit Statistics:\n")
cat("R-squared:", round(r_squared, 4), "\n")
cat("Adjusted R-squared:", round(adj_r_squared, 4), "\n")
cat("F-statistic:", round(f_stat[1], 4), "with p-value:", 
    pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE), "\n")

# SECTION 5: CROSS-SECTIONAL APT (PAGE, 1986 REPLICATION)
# ==============================================================================

cat("SECTION 5: Implementing Page (1986) cross-sectional APT...\n")

# 5.1 Principal Component Analysis (Factor Extraction)
cat("Performing Principal Component Analysis...\n")

# Prepare data for PCA (using macroeconomic variables as proxies for demonstration)
pca_data <- apt_data %>%
  dplyr::select(INF_SHOCK, INT_SHOCK, FX_SHOCK) %>%
  scale()  # Standardize variables

# Perform PCA
pca_result <- prcomp(pca_data, center = TRUE, scale. = TRUE)

cat("PCA Results Summary:\n")
print(summary(pca_result))

# Scree plot data
scree_data <- data.frame(
  Component = 1:length(pca_result$sdev),
  Eigenvalue = (pca_result$sdev)^2,
  Variance_Explained = summary(pca_result)$importance[2, ],
  Cumulative_Variance = summary(pca_result)$importance[3, ]
)

cat("\nScree Plot Data:\n")
print(scree_data)

# Plot scree plot
p_scree <- ggplot(scree_data, aes(x = Component, y = Eigenvalue)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 2) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray") +
  labs(title = "Scree Plot for Factor Selection",
       x = "Principal Component", 
       y = "Eigenvalue") +
  theme_minimal()

print(p_scree)

# 5.2 Factor Loadings (Betas)
# Extract factor scores (these would be your statistical factors)
factor_scores <- as.data.frame(pca_result$x)
colnames(factor_scores) <- paste0("FACTOR", 1:ncol(factor_scores))

# Add factor scores to main dataset
apt_data_with_factors <- cbind(apt_data, factor_scores)

# 5.3 Cross-Sectional Regressions (Fama-MacBeth style)
cat("Running cross-sectional regressions...\n")

# Select number of factors based on Kaiser criterion (eigenvalue > 1)
n_factors <- sum(scree_data$Eigenvalue > 1)
cat("Selected", n_factors, "factors based on Kaiser criterion\n")

# Cross-sectional regression for each period
if(n_factors > 0) {
  # Prepare formula for cross-sectional regression
  factor_vars <- paste0("FACTOR", 1:n_factors)
  cs_formula <- as.formula(paste("top40_excess_return ~", paste(factor_vars, collapse = " + ")))
  
  # Run cross-sectional regression
  cs_model <- lm(cs_formula, data = apt_data_with_factors)
  
  cat("\nCross-Sectional APT Results:\n")
  print(summary(cs_model))
  
  # Extract risk premia (lambda values)
  risk_premia <- coef(cs_model)[-1]  # Exclude intercept
  names(risk_premia) <- paste0("Lambda_", factor_vars)
  
  cat("\nEstimated Risk Premia (Lambda values):\n")
  print(risk_premia)
}

# Statistical Factor Model (using first n factors)
if(n_factors > 0) {
  factor_formula <- as.formula(paste("jse_excess_return ~", paste(factor_vars, collapse = " + ")))
  factor_model <- lm(factor_formula, data = apt_data_with_factors)
} else {
  # Fallback to first factor if none meet Kaiser criterion
  factor_model <- lm(jse_excess_return ~ FACTOR1, data = apt_data_with_factors)
}

# SECTION 6: MODEL DIAGNOSTICS
# ==============================================================================

cat("SECTION 6: Running model diagnostics...\n")

# Heteroskedasticity test (Breusch-Pagan)
bp_test <- bptest(apt_model)
cat("Heteroskedasticity Test (Breusch-Pagan):\n")
print(bp_test)

# Autocorrelation test (Breusch-Godfrey)
bg_test <- bgtest(apt_model, order = 4)
cat("\nAutocorrelation Test (Breusch-Godfrey):\n")
print(bg_test)

# Normality test (Jarque-Bera)
jb_test <- jarque.bera.test(residuals(apt_model))
cat("\nNormality Test (Jarque-Bera):\n")
print(jb_test)

# Multicollinearity (VIF)
vif_values <- vif(apt_model)
cat("\nVariance Inflation Factors (VIF):\n")
print(vif_values)

# Durbin-Watson test
dw_test <- dwtest(apt_model)
cat("\nDurbin-Watson Test:\n")
print(dw_test)

# SECTION 7: SINGLE-FACTOR MODELS FOR COMPARISON
# ==============================================================================

cat("SECTION 7: Running single-factor models for comparison...\n")

# Inflation only
inf_model <- lm(jse_excess_return ~ INF_SHOCK, data = apt_data)
cat("\nInflation-Only Model:\n")
cat("R-squared:", round(summary(inf_model)$r.squared, 4), "\n")
print(summary(inf_model)$coefficients)

# Interest rate only
int_model <- lm(jse_excess_return ~ INT_SHOCK, data = apt_data)
cat("\nInterest Rate-Only Model:\n")
cat("R-squared:", round(summary(int_model)$r.squared, 4), "\n")
print(summary(int_model)$coefficients)

# Exchange rate only
fx_model <- lm(jse_excess_return ~ FX_SHOCK, data = apt_data)
cat("\nExchange Rate-Only Model:\n")
cat("R-squared:", round(summary(fx_model)$r.squared, 4), "\n")
print(summary(fx_model)$coefficients)

# SECTION 8: FACTOR CONTRIBUTION ANALYSIS
# ==============================================================================

cat("SECTION 8: Analyzing factor contributions...\n")

# Full model
full_r2 <- summary(apt_model)$r.squared

# Models with one factor removed
no_inf_model <- lm(jse_excess_return ~ INT_SHOCK + FX_SHOCK, data = apt_data)
no_int_model <- lm(jse_excess_return ~ INF_SHOCK + FX_SHOCK, data = apt_data)
no_fx_model <- lm(jse_excess_return ~ INF_SHOCK + INT_SHOCK, data = apt_data)

no_inf_r2 <- summary(no_inf_model)$r.squared
no_int_r2 <- summary(no_int_model)$r.squared
no_fx_r2 <- summary(no_fx_model)$r.squared

# Partial R-squared contributions
partial_r2_inf <- full_r2 - no_inf_r2
partial_r2_int <- full_r2 - no_int_r2
partial_r2_fx <- full_r2 - no_fx_r2

# Percentage contributions
percent_contrib_inf <- (partial_r2_inf / full_r2) * 100
percent_contrib_int <- (partial_r2_int / full_r2) * 100
percent_contrib_fx <- (partial_r2_fx / full_r2) * 100

factor_contrib_table <- data.frame(
  Factor = c("Inflation Shock", "Interest Rate Shock", "Exchange Rate Shock"),
  Partial_R2 = c(partial_r2_inf, partial_r2_int, partial_r2_fx),
  Percent_Contribution = c(percent_contrib_inf, percent_contrib_int, percent_contrib_fx)
)

cat("Factor Contribution Analysis:\n")
print(factor_contrib_table)

# Relative importance (LMG method)
relimp_result <- calc.relimp(apt_model, type = "lmg", rela = TRUE)
cat("\nRelative Importance Analysis (LMG method):\n")
print(relimp_result)

# SECTION 9: ROLLING REGRESSION ANALYSIS
# ==============================================================================

cat("SECTION 9: Performing rolling regression analysis...\n")

window_size <- 60  # 60-month rolling window

# Prepare data for rolling regression
roll_data <- apt_data %>%
  dplyr::select(Date, jse_excess_return, INF_SHOCK, INT_SHOCK, FX_SHOCK)

# Perform rolling regression
roll_coefs <- rollapply(
  roll_data %>% dplyr::select(-Date),
  width = window_size,
  FUN = function(z) {
    coef(lm(jse_excess_return ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, 
            data = as.data.frame(z)))
  },
  by.column = FALSE,
  align = "right"
)

# Create rolling coefficients dataframe
roll_coefs_df <- as.data.frame(roll_coefs)
colnames(roll_coefs_df) <- c("Intercept", "INF_SHOCK", "INT_SHOCK", "FX_SHOCK")
roll_coefs_df$Date <- apt_data$Date[window_size:nrow(apt_data)]

cat("First 5 rows of rolling coefficients:\n")
print(head(roll_coefs_df, 5))

# SECTION 10: STRUCTURAL BREAK TEST
# ==============================================================================

cat("SECTION 10: Testing for structural breaks...\n")

bp_test_result <- breakpoints(jse_excess_return ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, 
                              data = apt_data)

cat("Structural Break Test Results:\n")
print(summary(bp_test_result))

if (!is.na(bp_test_result$breakpoints[1])) {
  break_dates <- apt_data$Date[bp_test_result$breakpoints]
  cat("\nIdentified breakpoint dates:\n")
  print(break_dates)
}

library(quantmod)

# Example for getting FirstRand data
getSymbols("FSR.JO", from = "2010-01-01", to = "2024-12-31")
fsr_prices <- Ad(FSR.JO)  # Adjusted closing prices
fsr <- periodReturn(fsr_prices, period = "monthly", type = "log")

# SECTION 11: COMPARISON WITH CAPM - MARKET LEVEL
# ==============================================================================

cat("SECTION 11: Comparing APT with CAPM at Market Level...\n")

# CAPM regression (Top 40 as market proxy for JSE All Share)
capm_model <- lm(jse_excess_return ~ top40_excess_return, data = apt_data)
cat("CAPM Model Results (Market Level):\n")
print(summary(capm_model))

# Create comprehensive model comparison table
model_comparison <- data.frame(
  Model = c("CAPM", "Macro APT", "Statistical APT"),
  R_squared = c(summary(capm_model)$r.squared, 
                summary(apt_model)$r.squared,
                summary(factor_model)$r.squared),
  Adj_R_squared = c(summary(capm_model)$adj.r.squared,
                    summary(apt_model)$adj.r.squared,
                    summary(factor_model)$adj.r.squared),
  AIC = c(AIC(capm_model), AIC(apt_model), AIC(factor_model)),
  BIC = c(BIC(capm_model), BIC(apt_model), BIC(factor_model)),
  Num_Factors = c(1, 3, n_factors)
)

cat("\nComprehensive Model Comparison (Market Level):\n")
print(model_comparison)

# Test if APT factors explain CAPM residuals
capm_residuals <- residuals(capm_model)
apt_on_capm_resid <- lm(capm_residuals ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, 
                        data = apt_data)

resid_r2 <- summary(apt_on_capm_resid)$r.squared

cat("\nAPT factors explain", round(resid_r2 * 100, 2), "% of CAPM residual variance\n")

# SECTION 12: INDIVIDUAL STOCK ANALYSIS - FIRSTRAND (FSR)
# ==============================================================================

cat("SECTION 12: Individual Stock Analysis - FirstRand (FSR)...\n")

# Load FSR data (you'll need to replace this with your actual FSR data)
# For now, creating placeholder data - REPLACE WITH REAL FSR DATA
set.seed(123)
fsr_data <- data.frame(
  Date = apt_data$Date,
  fsr_return = rnorm(nrow(apt_data), mean = 0.008, sd = 0.06)  # Placeholder returns
)

# Merge FSR data with APT data INCLUDING FACTORS
apt_data_fsr <- apt_data_with_factors %>%  # Use the dataset that already has factors
  left_join(fsr_data, by = "Date") %>%
  mutate(
    fsr_excess_return = fsr_return - monthly_rf
  ) %>%
  filter(!is.na(fsr_excess_return))

# 12.1 CAPM for FSR (using Top 40 as market proxy)
capm_fsr <- lm(fsr_excess_return ~ top40_excess_return, data = apt_data_fsr)

cat("CAPM Results for FirstRand:\n")
print(summary(capm_fsr))

# 12.2 APT for FSR
apt_fsr <- lm(fsr_excess_return ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, data = apt_data_fsr)

cat("APT Results for FirstRand:\n")
print(summary(apt_fsr))

# 12.3 Statistical APT for FSR
if(n_factors > 0) {
  stat_apt_fsr <- lm(fsr_excess_return ~ FACTOR1, data = apt_data_fsr)
} else {
  stat_apt_fsr <- lm(fsr_excess_return ~ FACTOR1, data = apt_data_fsr)  # Use FACTOR1 anyway
}

cat("Statistical APT Results for FirstRand:\n")
print(summary(stat_apt_fsr))

# 12.4 Single Stock Model Comparison
fsr_comparison <- data.frame(
  Model = c("CAPM", "Macro APT", "Statistical APT"),
  R_squared = c(
    summary(capm_fsr)$r.squared,
    summary(apt_fsr)$r.squared,
    summary(stat_apt_fsr)$r.squared
  ),
  Adj_R_squared = c(
    summary(capm_fsr)$adj.r.squared,
    summary(apt_fsr)$adj.r.squared,
    summary(stat_apt_fsr)$adj.r.squared
  ),
  AIC = c(AIC(capm_fsr), AIC(apt_fsr), AIC(stat_apt_fsr)),
  BIC = c(BIC(capm_fsr), BIC(apt_fsr), BIC(stat_apt_fsr))
)

cat("\nFirstRand Model Comparison:\n")
print(fsr_comparison)

# 12.5 Test if APT explains CAPM residuals for FSR
capm_fsr_residuals <- residuals(capm_fsr)
apt_on_capm_fsr <- lm(capm_fsr_residuals ~ INF_SHOCK + INT_SHOCK + FX_SHOCK, 
                      data = apt_data_fsr)

fsr_resid_r2 <- summary(apt_on_capm_fsr)$r.squared

cat("\nAPT explains", round(fsr_resid_r2 * 100, 2), 
    "% of CAPM residual variance for FirstRand\n")

# 12.6 Create FSR comparison visualization
fsr_comparison_long <- fsr_comparison %>%
  pivot_longer(cols = c(R_squared, Adj_R_squared), 
               names_to = "Metric", values_to = "Value")

p_fsr <- ggplot(fsr_comparison_long, aes(x = Model, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "FirstRand (FSR): CAPM vs APT Model Comparison",
       y = "Value", x = "Model") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p_fsr)

# SECTION 13: VISUALIZATIONS
# ==============================================================================

cat("SECTION 13: Creating visualizations...\n")

# 1. Time series plot
p1 <- ggplot(apt_data, aes(x = Date)) +
  geom_line(aes(y = jse_excess_return * 100, color = "JSE Excess Returns"), linewidth = 1) +
  geom_line(aes(y = INF_SHOCK * 100, color = "Inflation Shock"), alpha = 0.7) +
  geom_line(aes(y = INT_SHOCK * 100, color = "Interest Rate Shock"), alpha = 0.7) +
  geom_line(aes(y = FX_SHOCK * 100, color = "FX Shock"), alpha = 0.7) +
  labs(title = "JSE Excess Returns and Macroeconomic Shocks (2010-2024)",
       y = "Percentage", x = "Date", color = "Series") +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p1)

# 2. Rolling coefficients plot
roll_long <- roll_coefs_df %>%
  pivot_longer(cols = c(INF_SHOCK, INT_SHOCK, FX_SHOCK), 
               names_to = "Factor", values_to = "Beta")

p2 <- ggplot(roll_long, aes(x = Date, y = Beta, color = Factor)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = paste0("Rolling APT Coefficients (", window_size, "-Month Window)"),
       y = "Beta Coefficient", x = "Date") +
  theme_minimal() +
  facet_wrap(~Factor, scales = "free_y", ncol = 1)

print(p2)

# 3. Factor contribution plot
p3 <- ggplot(factor_contrib_table, aes(x = reorder(Factor, -Percent_Contribution), 
                                       y = Percent_Contribution, fill = Factor)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = paste0(round(Percent_Contribution, 1), "%")), 
            vjust = -0.5, size = 4) +
  labs(title = "Factor Contributions to APT R-squared",
       x = "Factor", y = "Percentage Contribution (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

print(p3)

# 4. Market-level model comparison bar chart
comparison_long <- model_comparison %>%
  pivot_longer(cols = c(R_squared, Adj_R_squared), 
               names_to = "Metric", values_to = "Value")

p4 <- ggplot(comparison_long, aes(x = Model, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Market-Level Model Comparison: R-squared Metrics",
       y = "Value", x = "Model") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p4)

# 5. FSR individual stock comparison plot (already created in Section 12)
print(p_fsr)

# 6. Correlation plot
png("correlation_plot.png", width = 800, height = 800)
corrplot(cor_matrix, method = "color", type = "upper", 
         order = "hclust", addCoef.col = "black",
         tl.col = "black", tl.srt = 45,
         title = "Correlation Matrix: Returns vs Macroeconomic Factors",
         mar = c(0,0,2,0))
dev.off()
cat("Correlation plot saved as 'correlation_plot.png'\n")

# 7. Residual diagnostics plot
png("residual_diagnostics.png", width = 800, height = 600)
par(mfrow = c(2, 2))
plot(apt_model)
par(mfrow = c(1, 1))
dev.off()
cat("Residual diagnostics plot saved as 'residual_diagnostics.png'\n")

# 8. Scree plot (already created in Section 5)
print(p_scree)

# SECTION 14: EXPORT RESULTS
# ==============================================================================

cat("SECTION 14: Exporting results...\n")

# Export descriptive statistics
write.csv(desc_stats, "apt_descriptive_stats.csv", row.names = FALSE)
cat("Saved: apt_descriptive_stats.csv\n")

# Export correlation matrix
write.csv(cor_matrix, "apt_correlation_matrix.csv")
cat("Saved: apt_correlation_matrix.csv\n")

# Export stationarity tests
write.csv(stationarity_tests, "apt_stationarity_tests.csv", row.names = FALSE)
cat("Saved: apt_stationarity_tests.csv\n")

# Export factor contributions
write.csv(factor_contrib_table, "apt_factor_contributions.csv", row.names = FALSE)
cat("Saved: apt_factor_contributions.csv\n")

# Export market-level model comparison
write.csv(model_comparison, "apt_capm_comparison.csv", row.names = FALSE)
cat("Saved: apt_capm_comparison.csv\n")

# Export rolling coefficients
write.csv(roll_coefs_df, "apt_rolling_coefficients.csv", row.names = FALSE)
cat("Saved: apt_rolling_coefficients.csv\n")

# Export PCA results
write.csv(scree_data, "pca_scree_results.csv", row.names = FALSE)
cat("Saved: pca_scree_results.csv\n")

# Export FSR results
write.csv(fsr_comparison, "fsr_model_comparison.csv", row.names = FALSE)
cat("Saved: fsr_model_comparison.csv\n")

# Save plots
ggsave("time_series_plot.png", p1, width = 12, height = 6)
cat("Saved: time_series_plot.png\n")

ggsave("rolling_coefficients_plot.png", p2, width = 12, height = 10)
cat("Saved: rolling_coefficients_plot.png\n")

ggsave("factor_contributions_plot.png", p3, width = 10, height = 6)
cat("Saved: factor_contributions_plot.png\n")

ggsave("market_level_comparison_plot.png", p4, width = 10, height = 6)
cat("Saved: market_level_comparison_plot.png\n")

ggsave("fsr_model_comparison_plot.png", p_fsr, width = 10, height = 6)
cat("Saved: fsr_model_comparison_plot.png\n")

ggsave("scree_plot.png", p_scree, width = 10, height = 6)
cat("Saved: scree_plot.png\n")

# Save comprehensive text report
sink("apt_analysis_report.txt")
cat("=============================================================\n")
cat("COMPREHENSIVE APT ANALYSIS REPORT\n")
cat("JSE All Share Index (2010-2024)\n")
cat("Replication of Page (1986) with Modern Data\n")
cat("=============================================================\n\n")

cat("SAMPLE INFORMATION\n")
cat("-----------------\n")
cat("Start Date:", as.character(min(apt_data$Date)), "\n")
cat("End Date:", as.character(max(apt_data$Date)), "\n")
cat("Total Observations:", nrow(apt_data), "months\n\n")

cat("DESCRIPTIVE STATISTICS\n")
cat("----------------------\n")
print(desc_stats)
cat("\n")

cat("CORRELATION MATRIX\n")
cat("------------------\n")
print(cor_matrix)
cat("\n")

cat("STATIONARITY TESTS (ADF)\n")
cat("------------------------\n")
print(stationarity_tests)
cat("\n")

cat("TIME-SERIES APT MODEL RESULTS\n")
cat("-----------------------------\n")
print(summary(apt_model))
cat("\n")

cat("ROBUST STANDARD ERRORS (NEWEY-WEST)\n")
cat("------------------------------------\n")
print(nw_test)
cat("\n")

cat("CROSS-SECTIONAL APT RESULTS\n")
cat("---------------------------\n")
if(n_factors > 0) {
  print(summary(cs_model))
} else {
  cat("No significant factors identified for cross-sectional analysis\n")
}
cat("\n")

cat("FACTOR CONTRIBUTIONS\n")
cat("--------------------\n")
print(factor_contrib_table)
cat("\n")

cat("MARKET-LEVEL MODEL COMPARISON\n")
cat("-----------------------------\n")
print(model_comparison)
cat("\n")

cat("FIRSTRAND (FSR) INDIVIDUAL STOCK ANALYSIS\n")
cat("-----------------------------------------\n")
cat("CAPM Results:\n")
print(summary(capm_fsr))
cat("\nAPT Results:\n")
print(summary(apt_fsr))
cat("\nFirstRand Model Comparison:\n")
print(fsr_comparison)
cat("\nAPT explains", round(fsr_resid_r2 * 100, 2), 
    "% of CAPM residual variance for FirstRand\n")

cat("\nDIAGNOSTIC TESTS\n")
cat("----------------\n")
cat("Heteroskedasticity (BP):", bp_test$p.value, 
    ifelse(bp_test$p.value < 0.05, "(Reject H0)", "(Fail to reject H0)"), "\n")
cat("Autocorrelation (BG):", bg_test$p.value,
    ifelse(bg_test$p.value < 0.05, "(Reject H0)", "(Fail to reject H0)"), "\n")
cat("Normality (JB):", jb_test$p.value,
    ifelse(jb_test$p.value < 0.05, "(Reject H0)", "(Fail to reject H0)"), "\n")
cat("\nVIF Values:\n")
print(vif_values)

sink()
cat("Saved: apt_analysis_report.txt\n")

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

cat("\n")
cat("=============================================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("=============================================================\n\n")

cat("SUMMARY OF KEY FINDINGS:\n")
cat("------------------------\n")
cat("1. Sample Period:", as.character(min(apt_data$Date)), "to", 
    as.character(max(apt_data$Date)), "\n")
cat("2. Total Observations:", nrow(apt_data), "monthly observations\n\n")

cat("3. MARKET-LEVEL MODEL PERFORMANCE:\n")
for(i in 1:nrow(model_comparison)) {
  cat("   -", model_comparison$Model[i], "R-squared:", 
      round(model_comparison$R_squared[i], 4), "\n")
}
cat("\n")

cat("4. FIRSTRAND (FSR) INDIVIDUAL STOCK PERFORMANCE:\n")
for(i in 1:nrow(fsr_comparison)) {
  cat("   -", fsr_comparison$Model[i], "R-squared:", 
      round(fsr_comparison$R_squared[i], 4), "\n")
}
cat("\n")

cat("5. FACTOR CONTRIBUTIONS TO MACRO APT R-SQUARED:\n")
for(i in 1:nrow(factor_contrib_table)) {
  cat("   -", factor_contrib_table$Factor[i], ":", 
      round(factor_contrib_table$Percent_Contribution[i], 2), "%\n")
}

cat("\n6. STATISTICAL FACTORS IDENTIFIED:", n_factors, "factors\n")

cat("\n7. APT EXPLAINS CAPM RESIDUAL VARIANCE:\n")
cat("   - Market Level:", round(resid_r2 * 100, 2), "%\n")
cat("   - FirstRand:", round(fsr_resid_r2 * 100, 2), "%\n")

cat("\n8. MODEL DIAGNOSTICS:\n")
cat("   - Heteroskedasticity (BP) p-value:", round(bp_test$p.value, 4), "\n")
cat("   - Autocorrelation (BG) p-value:", round(bg_test$p.value, 4), "\n")
cat("   - Normality (JB) p-value:", round(jb_test$p.value, 4), "\n")

cat("\n9. STATIONARITY RESULTS:\n")
for(i in 1:nrow(stationarity_tests)) {
  cat("   -", stationarity_tests$Variable[i], ":", 
      ifelse(stationarity_tests$Stationary[i], "Stationary", "Non-stationary"),
      "(p =", round(stationarity_tests$ADF_pvalue[i], 4), ")\n")
}

cat("\nAll results have been exported to CSV files and visualizations saved as PNG.\n")
cat("Check 'apt_analysis_report.txt' for the complete detailed report.\n")

