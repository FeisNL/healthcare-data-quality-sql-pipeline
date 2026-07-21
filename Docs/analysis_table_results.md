# Analysis Table Results

## Purpose

This document summarizes the creation and validation results of the physical analysis table:

`analysis_feature_admission_large_v2`

The table was created from the validated feature view:

`feature_admission_large_v2`

The goal is to provide a stable and faster dataset for repeated analysis, Python/pandas profiling, and later machine learning workflows.

## Source View

Source view:

`feature_admission_large_v2`

The source view preserves the admission-level grain:

`1 row = 1 curated admission`

## Physical Analysis Table

Physical analysis table:

`analysis_feature_admission_large_v2`

This table is a validated snapshot of the source view.

The view remains the source definition, while the physical table is used for repeated analysis.

## Creation Result

The physical analysis table was created successfully.

Approximate creation runtime:

`about 5 minutes`

This runtime is expected because PostgreSQL must fully calculate the stacked view chain before storing the result physically.

## Validation Results

| Check | Result |
|---|---:|
| Source view row count | 1,635 |
| Physical table row count | 1,635 |
| Duplicate admission count | 0 |
| Missing required IDs | 0 |
| Source curated lab result count | 4,079 |
| Total lab results in analysis table | 4,079 |
| Lab result difference count | 0 |
| Lab feature inconsistency count | 0 |
| Invalid lab date order count | 0 |
| PASS checks | 6 |
| FAIL checks | 0 |

## Performance Comparison

| Query | Runtime |
|---|---:|
| `COUNT(*)` from `feature_admission_large_v2` | 7.496s |
| `COUNT(*)` from `analysis_feature_admission_large_v2` | near-instant / below visible DBeaver timing |

## Interpretation

The physical analysis table preserves the row count and grain of the source view.

The source view and the physical table both contain 1,635 rows.

There are no duplicate `admission_id` values, which confirms that the admission-level grain is preserved.

All 4,079 curated lab results are still represented through `lab_result_count`.

The validation confirms that no lab result counts were lost during materialization.

Repeated reads from the physical table are much faster than repeated reads from the stacked source view.

## Data Quality Decision

`analysis_feature_admission_large_v2` is valid for repeated analysis and Python/pandas profiling.

The table is not automatically ML-ready for every use case. Lab date features such as `latest_lab_result_date` may still require leakage review before being used in machine learning.

## Performance Decision

The physical table is useful for repeated analysis because it avoids recalculating the full stacked view chain every time the dataset is queried.

The initial creation step is still expensive, but repeated reads after creation are fast.

This makes the physical table a practical analysis snapshot.

## Risk: Stale Data

The main risk is stale data.

The physical table does not automatically update when raw data, cleaned logic, curated logic, or feature view logic changes.

If upstream data or logic changes, the table must be rebuilt and validated again.

## Next Steps

Next steps:

- use `analysis_feature_admission_large_v2` for Python/pandas profiling
- document any data quality findings during profiling
- review leakage risks before machine learning
- rebuild and revalidate the physical table if upstream logic changes
- update the README or pipeline overview to mention the physical analysis table