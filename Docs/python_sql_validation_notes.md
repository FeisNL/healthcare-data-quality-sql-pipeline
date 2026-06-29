# Python SQL Validation Notes

## What I validated

I exported the PostgreSQL view `feature_admission_v2` to CSV and loaded it in Python with pandas.

The CSV file used was:

`Data/Processed/feature_admission_v2.csv`

## Why this validation matters

The goal was to confirm that the CSV export still matches the SQL source view before using the data for further analysis.

## Checks performed

- Row count
- Column count
- `is_analysis_ready` distribution
- `has_missing_patient_features` distribution
- `has_length_of_stay_issue` distribution
- `has_cost_issue` distribution
- Missing values per column

## Result

The Python output matched the SQL validation contract.

The exported CSV is valid for the current Python profiling step.

## Risks

Possible risks are:

- wrong CSV exported
- old CSV used
- SQL view changed after export
- missing headers
- Python script reading the wrong file path
- column names changed

## Current limitation

This is not yet machine learning.

Python is currently used as a second validation layer to inspect and confirm SQL output.