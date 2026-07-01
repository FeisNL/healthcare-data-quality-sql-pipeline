# Python Profiling Notes

## Purpose

This document summarizes the first Python profiling checks on the exported feature table.

Python is used to inspect the exported CSV after SQL validation.

## Dataset

- Source SQL view: `feature_admission_v2`
- Source CSV: `Data/Processed/feature_admission_v2.csv`
- Python script: `src/profile_feature_table.py`

## Profiling Questions

1. How many records and columns are in the dataset?
2. Which columns contain missing values?
3. What are the distributions of the quality flags?
4. What are the distributions of key categorical columns?
5. What are the ranges of key numeric columns?
6. Which records are not analysis-ready and why?

## Planned Checks

| Question | Pandas action | Why it matters |
|---|---|---|
| How many rows and columns? | `df.shape` | Confirms dataset size |
| Which values are missing? | `df.isna().sum()` | Identifies incomplete fields |
| How are quality flags distributed? | `value_counts(dropna=False)` | Shows remaining data quality risks |
| What categories exist? | `value_counts(dropna=False)` | Checks categorical consistency |
| What are numeric ranges? | `describe()` | Finds extreme or invalid values |
| Which records are rejected? | filter on `is_analysis_ready == False` | Explains why records are not analysis-ready |

## Key Findings

### Numeric Profiling

#### `length_of_stay_days`

- Non-missing values: 5 out of 6 records.
- Minimum value: 1.
- Maximum value: 19.
- Finding: 1 record has a missing `length_of_stay_days` value.

Interpretation:

The missing value is likely caused by a missing `discharge_date`. This makes length-of-stay analysis incomplete for that admission.

#### `total_cost`

- Non-missing values: 6 out of 6 records.
- Minimum value: -300.
- Maximum value: 999999.99.
- Finding: the column contains both a negative value and an extreme high value.

Interpretation:

The negative cost value is invalid. The extreme maximum value should be treated as a potential outlier or synthetic test value.

#### `age_at_admission`

- Non-missing values: 4 out of 6 records.
- Minimum value: 34.
- Maximum value: 132.
- Finding: 2 records have missing age values, and the maximum age is unrealistic or suspicious.

Interpretation:

Age-based analysis is currently unreliable unless missing and unrealistic age values are handled.

### Categorical Profiling

#### `department_standardized`

Observed distribution:

* `Cardiology`: 3 records
* `Emergency`: 2 records
* missing value: 1 record

Interpretation:

One admission record has a missing department value. This should not be filled automatically. The record should first be traced back to the source admission data to determine whether the department is missing, unknown or incorrectly recorded.

Data quality risk:

A missing department value can affect department-level reporting and analysis.

#### `gender_standardized`

Observed distribution:

* `M`: 2 records
* `F`: 2 records
* missing value: 2 records

Interpretation:

Two records have missing gender values. These missing values are likely linked to records with missing patient-derived features.

Data quality risk:

Demographic analysis is incomplete if records with missing gender values are included without explanation or handling.

### Rejected Records Inspection

Rejected records:

- Total rejected records: 5
- Rejected admission IDs: `A003`, `A005`, `A006`, `A007`, `A008`

Rejection reasons:

- Missing patient features: 2 records
- Length-of-stay issue: 1 record
- Cost issue: 2 records

Interpretation:

Five out of six records are currently not analysis-ready. The rejected records are excluded because they contain missing patient-derived features, a length-of-stay issue or cost-related issues.

Data quality risk:

The current analysis-ready subset is very small. This means the dataset is not yet suitable for reliable machine learning or broad statistical analysis. The rejected records should be reviewed before deciding whether to exclude, correct or keep them with warning flags.


## Data Quality Interpretation

The Python profiling checks confirm that the exported feature table still contains important data quality risks.

Main risks:

- Missing patient-derived features affect age and gender fields.
- Missing `length_of_stay_days` affects length-of-stay analysis.
- Negative and extreme `total_cost` values make cost analysis unreliable without additional handling.
- The analysis-ready subset contains only 1 out of 6 records.

These findings show that feature engineering does not automatically make the data analysis-ready. Feature tables also need their own validation and profiling checks.

## Current Limitations

This is still a small synthetic dataset.

The current Python profiling step is not machine learning. It is used to inspect and validate the exported SQL feature table before deeper analysis.

Before using this data for machine learning, the project still needs:

- target definition
- leakage checks
- train/test split
- metric selection
- baseline model
- error analysis
- a clearer decision about how rejected records should be handled 

## Python Validation Summary

A validation summary was added to `src/profile_feature_table.py`.

The script now compares expected SQL validation results with the actual values found in the exported CSV.

Validation checks:

- Row count
- Analysis-ready records
- Rejected records
- Missing patient feature issues
- Length-of-stay issues
- Cost issues

Current result:

- PASS: 6 checks
- FAIL: 0 checks

Interpretation:

The Python validation confirms that the exported CSV matches the expected SQL validation counts. This means the export is technically consistent with the SQL feature table.

This does not mean the data is fully analysis-ready. The profiling results still show missing values, invalid values and rejected records.