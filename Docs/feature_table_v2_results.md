# Feature Table V2 Validation Results

## Purpose

This document summarizes the validation results for `feature_admission_large_v2`.

The goal of feature table v2 is to extend `feature_admission_large_v1` with admission-level lab result aggregation features while preserving the original admission-level grain.

## Feature View

Feature view:

`feature_admission_large_v2`

## Grain

The grain is:

`1 row = 1 curated admission`

This means each `admission_id` should appear only once in the feature table.

## Added Lab Aggregation Features

Feature table v2 adds the following lab aggregation features:

- `lab_result_count`
- `distinct_test_name_count`
- `first_lab_result_date`
- `latest_lab_result_date`
- `has_lab_results`

Lab results were aggregated by `admission_id` before joining them to `feature_admission_large_v1`.

## Validation Results

| Check | Result |
|---|---:|
| Feature table v1 row count | 1,635 |
| Feature table v2 row count | 1,635 |
| Duplicate admission count | 0 |
| Missing required IDs | 0 |
| Source curated lab result count | 4,079 |
| Total lab results represented in v2 | 4,079 |
| Lab result difference count | 0 |
| Source admissions with lab results | 1,635 |
| Feature admissions with lab results | 1,635 |
| Admissions without lab results | 0 |
| Invalid lab date order count | 0 |
| Lab feature inconsistency count | 0 |
| PASS checks | 7 |
| FAIL checks | 0 |

## Interpretation

The validation confirms that `feature_admission_large_v2` preserves the admission-level grain.

The row count of `feature_admission_large_v2` matches `feature_admission_large_v1`, and there are no duplicate `admission_id` values.

All 4,079 curated lab result rows are represented in the feature table through `lab_result_count`. This confirms that lab results were correctly aggregated to admission level before joining.

All 1,635 curated admissions currently have at least one curated lab result in this dataset. Therefore, `admissions_without_lab_results = 0` is valid for the current data.

## Data Quality Decision

`feature_admission_large_v2` is valid for initial descriptive analysis and further feature exploration.

The table is not automatically ML-ready for every prediction use case. Lab date features such as `latest_lab_result_date` may cause leakage if the prediction goal requires information to be available at admission start.

## Performance Observation

Queries against `feature_admission_large_v2` are slower than expected for the dataset size.

The likely reason is that the view is built on top of multiple stacked views. Creating a temporary validation snapshot improved the speed of repeated validation checks, but the initial creation of the temporary table still took several minutes.

This should be investigated before repeated analysis or machine learning workflows.

Potential next steps include:

- using `EXPLAIN ANALYZE`
- adding indexes on join keys
- creating materialized views
- storing the feature table as a physical table for repeated analysis
- comparing runtimes before and after optimization

## Limitations

Current limitations:

- lab result values are not yet aggregated by specific test name
- `avg_result_value`, `min_result_value`, and `max_result_value` are deferred because different lab tests can have different meanings and units
- lab date features require leakage review before ML use
- performance optimization is not yet implemented

## Next Steps

Next steps:

- review and commit `SQL/26_feature_admission_large_v2.sql`
- review and commit `SQL/27_feature_admission_large_v2_quality_checks.sql`
- review and commit this results document
- add performance diagnostics in a later script