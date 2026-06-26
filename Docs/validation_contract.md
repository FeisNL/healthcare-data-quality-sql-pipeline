# Validation Contract

## 1. Dataset Context

This document defines the expected validation results for the exported feature table.  
The goal is to compare the SQL source view with the exported CSV file that is later inspected in Python.

- Source view: `feature_admission_v2`
- Exported CSV: `Data/Processed/feature_admission_v2.csv`
- Export query:

```sql
SELECT *
FROM feature_admission_v2
ORDER BY admission_id;
```

## 2. Expected SQL Results

The following values come from the SQL validation summary.  
Python must confirm that the exported CSV matches these expected values.

| Check                               | Expected Value |
| ----------------------------------- | -------------: |
| feature_admission_v2 row count      |              6 |
| is_analysis_ready = TRUE            |              1 |
| is_analysis_ready = FALSE           |              5 |
| has_missing_patient_features = TRUE |              2 |
| has_length_of_stay_issue = TRUE     |              1 |
| has_cost_issue = TRUE               |              2 |

## 3. Python Validation Purpose

Python is used as a second validation layer.  
The Python script must confirm that the CSV export still matches the SQL source view.

If Python output differs from this contract, possible causes are:

- the wrong CSV file was exported
- an old CSV file is being used
- the SQL view changed after export
- the CSV was exported without headers
- the Python script reads the wrong file path
- a column name changed between SQL and Python

## 4. Current Validation Status

Current result:

- SQL row count matches Python row count: `PASS`
- SQL analysis-ready distribution matches Python output: `PASS`
- SQL issue flag counts match Python output: `PASS`

Conclusion:

The exported CSV file `feature_admission_v2.csv` is valid for the current Python profiling step.