# NYC Payroll Analysis: SQL + Machine Learning

## Overview

This project explores payroll data from New York City employees (downloaded from https://www.kaggle.com/datasets/new-york-city/nyc-citywide-payroll-data/data), combining **SQL-based data engineering** with **Python-based exploratory analysis and machine learning**.

The goal is to:

* clean and structure a large real-world dataset (~2 M entries),
* explore key drivers of employee income,
* and build a predictive model for total salary.

The focus is on a **clear, reproducible workflow**, rather than complex modelling.

---

## Dataset

The dataset contains payroll records with information such as:

* fiscal year
* agency and job title
* work location (borough)
* employment duration (tenure)
* hours worked and overtime
* salary components

The final cleaned dataset includes ~800 k rows and 15 columns.

---

## Workflow

### 1. Data Preparation (SQL)

Raw CSV data was imported into PostgreSQL and cleaned using SQL.

Key steps:

* **Schema definition** with appropriate data types
* Removal of formatting issues (e.g. `$` symbols in salary columns)
* Creation of derived features:

  * `job_antiquity_years` (tenure relative to fiscal year)
  * `total_hours = regular_hours + ot_hours`
  * `ot_ratio = ot_hours / regular_hours`
  * `total_income = regular + overtime + other pay`
* Filtering:

  * only active employees
  * removal of extreme or inconsistent entries

Categorical cleaning included:

* normalization of `agency_name`
* consolidation of similar categories (e.g. "DEPT" → "DEPARTMENT")
* handling of missing values (e.g. borough → `"UNKNOWN"`)

The result is a structured table exported to CSV for analysis in Python.

---

### 2. Exploratory Data Analysis (Python)

EDA was performed using `pandas`, `matplotlib`, and `seaborn`. 

All salaries were initially converted to k$ to deal with smaller numbers.

#### Salary distributions

* Compared across fiscal years using smoothed density plots 
* Heavy-tailed behaviour observed → strong skew in income
* Salaries tend to increase sligthly over time (e.g. consistent with inflation)

#### Job title analysis

* Violin plots for most common job titles
* Significant differences between job titles that have relatively narrow salary distributions, but some job titles have a large spread that makes them less informative

#### Borough analysis

* Salary distributions compared across work locations
* Small differences observed, meaning that the borough is not expected to play a driving role in the salaries

#### Hours vs income

* Hexbin plots used to handle large dataset
* Clear relationship between:

  * total hours worked
  * total income
* Overtime ratio (`ot_ratio`) provides additional structure, although not too different from simply correlating with total hours for >2000 hours. In some cases it introduces a significant increase in the salary.

#### Tenure vs income

* Income increases for early career (~0–10 years)
* Plateau or decline at higher tenure
* Likely explained by workforce composition and overtime patterns

---

### 3. Machine Learning

A regression model was trained to predict total income.

#### Features used

* `fiscal_year`
* `agency_name`
* `work_borough`
* `title_description`
* `job_antiquity_years`
* `total_hours`
* `ot_ratio`

Target:

* `total_income`

#### Preprocessing

* Numerical features scaled (`StandardScaler`)
* Categorical features encoded (`OneHotEncoder`)
* Combined using `ColumnTransformer`

#### Model

* `RandomForestRegressor` (baseline model)

#### Training

* Train/test split: 80% / 20%
* Additional filtering to avoid extreme category imbalance

---

### 4. Evaluation

Model performance evaluated using:

* Mean Squared Error (MSE)
* Mean Absolute Error (MAE)
* R² score

Additional analysis:

* feature importance ranking
* residual analysis
* identification of best and worst predictions

---

## Key Observations

* **Income is mostly driven by hours worked**
* **Job title is a major source of variation**, but highly heterogeneous
* **Tenure has a nonlinear effect**:

  * early growth
  * later plateau (or apparent decline due to composition)
* **Borough has little influence**

---

## Tools Used

### SQL

* PostgreSQL
* Data cleaning, transformation, and feature engineering

### Python

* pandas
* numpy
* matplotlib
* seaborn
* scikit-learn

---

## Project Structure (suggested)

```
.
├── data/
│   └── cleaned_payroll.csv
├── sql/
│   └── data_cleaning.sql
├── notebooks/
│   └── data_visualization_and_ML.ipynb
├── README.md
```

---

## Notes

This project prioritises:

* clarity of workflow
* reproducibility
* handling of real-world messy data

The modelling is intentionally kept simple to highlight:

* feature engineering
* data understanding
* end-to-end pipeline construction

---

## Possible Improvements

* Further cleaning of data and possible grouping of categories (job titles)
* Test if last names have an impact (e.g., latino vs non-latino)
* Compare multiple models (e.g. Gradient Boosting)
* Add cross-validation
* Deploy as a small API or dashboard

---
