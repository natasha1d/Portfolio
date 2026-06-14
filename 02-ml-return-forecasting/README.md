# Machine Learning Return Forecasting

## Overview
This project applies supervised machine learning to forecast future 3-month style returns using historical risk and return features calculated over rolling windows. Two regression models are benchmarked against each other with full train/test/validation evaluation.

## Methods
- **Feature engineering** — MinMax scaling fitted on training data only, applied separately to test and validation sets (no data leakage)
- **Train/test/validation split** — 70/30 train-test partition with a fully held-out validation set
- **Linear Regression** — baseline model; evaluated on MSE, RMSE, and MAE across all three sets
- **Ridge Regression** — regularised model with hyperparameter tuning via `GridSearchCV` (5-fold cross-validation across alpha, fit_intercept, and solver combinations); regularisation path plotted to visualise bias-variance tradeoff
- **Model comparison** — Ridge outperformed Linear Regression on the test set; Linear Regression generalised better on the validation set, flagging potential overfitting in the Ridge tuning process

## Key Findings
- Best Ridge parameters: identified via 5-fold CV with MSE scoring
- Ridge achieved lower test MSE than Linear Regression
- Linear Regression showed stronger validation performance, suggesting Ridge's CV gains did not fully generalise — noted as a limitation and area for further work (e.g. expanding the feature set or using time-series cross-validation)

## Tools
Python — `pandas`, `numpy`, `scikit-learn`, `matplotlib`
