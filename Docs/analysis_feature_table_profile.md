# Analysis Feature Table Profile

## Purpose

This document summarizes the Python/pandas profiling results for the exported physical analysis table:

`analysis_feature_admission_large_v2`

The goal of this profiling step is to confirm that the exported CSV matches the validated SQL table and to understand whether the dataset is suitable for further analysis.

The profiling was performed with:

`src/profile_analysis_feature_table.py`

## Source Data

Original PostgreSQL table:

`analysis_feature_admission_large_v2`

Exported CSV file:

`Data/Processed/analysis_feature_admission_large_v2.csv`

The table was created as a physical snapshot of:

`feature_admission_large_v2`

## Grain

The expected grain is:

`1 row = 1 admission`

This grain was preserved after export.

## Validation Summary

| Check | Actual Value | Expected Value | Status |
|---|---:|---:|---|
| Row count matches SQL table | 1,635 | 1,635 | PASS |
| One row per admission_id | 0 duplicates | 0 duplicates | PASS |
| Required IDs complete | 0 missing | 0 missing | PASS |
| Lab result total preserved | 4,079 | 4,079 | PASS |
| Lab result count not negative | 0 | 0 | PASS |
| Distinct test count not greater than lab count | 0 | 0 | PASS |
| Lab date order valid | 0 | 0 | PASS |

Overall result:

`7 PASS / 0 FAIL`

## Row Count and Grain Decision

The exported CSV contains 1,635 rows.

This matches the validated SQL table row count.

There are no duplicate `admission_id` values.

This confirms that the admission-level grain was preserved during export.

## Required ID Completeness

The required ID columns were checked:

- `admission_id`
- `patient_id`
- `department_id`
- `provider_id`

Missing required ID count:

`0`

This confirms that the exported dataset still contains the required identifiers needed for traceability and later analysis.

## Lab Result Total Check

The expected curated lab result total is:

`4,079`

The Python profiling script confirmed:

`SUM(lab_result_count) = 4,079`

This confirms that the lab aggregation total was preserved in the exported CSV.

## Numeric Range Profile

| Column | Missing/Invalid After Numeric Conversion | Min | Max | Mean | Median |
|---|---:|---:|---:|---:|---:|
| `age_at_admission` | 0 | 16 | 84 | 55.55 | 59.0 |
| `lab_result_count` | 0 | 1 | 3 | 2.49 | 2.0 |
| `distinct_test_name_count` | 0 | 1 | 1 | 1.0 | 1.0 |

## Numeric Range Interpretation

`age_at_admission` ranges from 16 to 84.

No impossible ages, such as negative values or extreme high ages, were found.

`lab_result_count` ranges from 1 to 3, with an average of 2.49 lab results per admission.

This is consistent with the SQL total of 4,079 lab results across 1,635 admissions.

`distinct_test_name_count` has no variation. The minimum, maximum, mean, and median are all 1.

This means every admission has exactly one distinct test name in the current dataset.

This column is technically valid, but it may have limited analytical or machine learning value because it does not help distinguish between records.

## Category Distributions

### Gender

| Gender | Count |
|---|---:|
| M | 943 |
| F | 692 |

Interpretation:

The dataset contains more male than female patients.

This distribution should be noted, but it is not automatically a blocker for descriptive analysis.

### Admission Type

| Admission Type | Count |
|---|---:|
| Transfer | 552 |
| Planned | 546 |
| Emergency | 537 |

Interpretation:

The three admission types are relatively balanced.

No missing or unexpected admission type categories were found in the profile output.

### Diagnosis Group

| Diagnosis Group | Count |
|---|---:|
| General | 473 |
| Respiratory | 470 |
| Neurological | 462 |
| Cardiac | 230 |

Interpretation:

The `Cardiac` diagnosis group is smaller than the other diagnosis groups.

This is not a blocker for descriptive analysis.

However, if `diagnosis_group` becomes a target or important modeling variable later, this distribution should be reviewed for class imbalance.

### Department Name

| Department Name | Count |
|---|---:|
| Cardiology | 471 |
| Neurology | 237 |
| Radiology | 235 |
| Laboratory | 231 |
| Emergency | 231 |
| Oncology | 230 |

Interpretation:

The department distribution shows that Cardiology has the highest number of admissions in this feature table.

The other departments are more evenly distributed.

This should be considered during analysis, especially if department-level comparisons are made.

## Warning Column Distributions

### Provider Department Mismatch Warning

| Value | Count |
|---|---:|
| True | 1,232 |
| False | 403 |

Interpretation:

A large number of admissions have a provider department mismatch warning.

This warning was already identified during SQL relationship consistency checks.

It is not treated as a blocking issue in the current pipeline, but it remains an important data quality and interpretation risk.

If department-provider consistency becomes important for a future analysis or model, this warning must be handled carefully.

### Has Lab Results

| Value | Count |
|---|---:|
| True | 1,635 |

Interpretation:

All admissions in the exported analysis table have lab results.

This is valid based on the current curated dataset.

However, `has_lab_results` has no variation in this dataset.

Because every row has the same value, this column is unlikely to be useful as a machine learning feature in the current dataset.

## Leakage-Risk Columns

The following columns were identified as potential leakage-risk columns:

- `lab_result_count`
- `distinct_test_name_count`
- `first_lab_result_date`
- `latest_lab_result_date`
- `has_lab_results`
- `diagnosis_group`

These columns are not automatically wrong.

Their safety depends on:

- the machine learning target
- the prediction moment
- what information would realistically be available at prediction time

For example, lab-related features may be leakage if the prediction is made at admission start and lab information becomes available later.

`diagnosis_group` may be leakage if it is used to predict diagnosis or if it is not known at prediction time.

## Data Quality Decision

`analysis_feature_admission_large_v2` is valid for Python/pandas profiling and descriptive analysis.

The dataset passed all validation checks:

`7 PASS / 0 FAIL`

The exported CSV preserved:

- row count
- admission-level grain
- required IDs
- lab result totals
- lab feature consistency
- lab date order

## ML Readiness Decision

The table is not automatically ML-ready.

Before machine learning, the following must still be defined and reviewed:

- target variable
- prediction moment
- leakage-risk columns
- class imbalance
- feature usefulness
- whether warning columns should be used, excluded, or documented separately

## Important Limitations

Important limitations:

- `provider_department_mismatch_warning` is present in 1,232 of 1,635 admissions.
- `has_lab_results` has no variation because all admissions have lab results.
- `distinct_test_name_count` has no variation because all values are 1.
- Lab-related features may become leakage depending on the prediction moment.
- `diagnosis_group` may be leakage depending on the target definition.

## Final Conclusion

The exported physical analysis table is valid for further Python-based profiling and descriptive analysis.

It is a reliable analysis snapshot of the validated SQL feature table.

However, it should not be used for machine learning until the target, prediction moment, leakage risks, class balance, and feature usefulness are reviewed.

## Next Steps

Next steps:

- commit the Python profiling script and profile document
- optionally export a small profiling summary CSV
- decide on a first analysis question
- define a possible ML target later
- perform leakage review before building any ML model