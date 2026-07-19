# Large Feature Table V2 Lab Design

## Purpose

This document defines the design for the second large admission-level feature table.

The goal of feature table v2 is to extend `feature_admission_large_v1` with lab result aggregation features while preserving the admission-level grain.

## Grain

The grain remains:

`1 row = 1 curated admission`

This means each `admission_id` should appear only once in the feature table.

Lab results are not joined directly because `curated_lab_results_large` has a different grain:

`1 row = 1 lab result`

One admission can have multiple lab results. A direct join would multiply admission rows and break the feature table grain.

## Source Views

The feature table v2 will use the following views:

- `feature_admission_large_v1`
- `curated_lab_results_large`

The main source view is `feature_admission_large_v1`, because it already contains one row per curated admission.

Lab results will first be aggregated to admission level before they are joined to the feature table.

## Lab Source Columns

The relevant lab result columns are:

- `lab_result_id`
- `admission_id`
- `patient_id`
- `test_name`
- `result_value`
- `result_unit`
- `test_date`
- `is_analysis_ready`

The lab result source does not contain `test_code`. Therefore, v2 will use `test_name` for distinct test counting.

## Planned Lab Aggregation Features

The first lab aggregation version will include:

- `lab_result_count`
- `distinct_test_name_count`
- `first_lab_result_date`
- `latest_lab_result_date`
- `has_lab_results`

These features are aggregated by `admission_id`, so they preserve the admission-level grain.

## Deferred or Risky Lab Features

The following lab features are treated carefully:

- `avg_result_value`
- `min_result_value`
- `max_result_value`

These features are technically possible, but they may be difficult to interpret because different lab tests can have different meanings and units.

For example, averaging values across different lab tests may produce a number that is not clinically meaningful.

More specific lab features, such as test-specific averages or maximum values, can be considered in a later version.

## Leakage Risks

Lab result features may cause leakage in some machine learning scenarios.

For example, `latest_lab_result_date` may only be known after the prediction moment. If the goal is to predict an outcome at admission start, this feature should not be used as an input feature unless it is confirmed to be available at that time.

The main leakage question is:

Was this information available at the moment the prediction would be made?

For now, the lab aggregation features are treated as analysis features, not automatically as ML-safe features.

## Join Strategy

Feature table v2 will use a `LEFT JOIN` from `feature_admission_large_v1` to lab aggregations.

This is important because admissions without lab results should remain in the feature table.

For admissions without lab results:

- `lab_result_count` should be 0
- `distinct_test_name_count` should be 0
- `has_lab_results` should be FALSE
- lab date fields may remain NULL

## Validation Plan

The feature table v2 should be validated with the following checks:

- check row count against `feature_admission_large_v1`
- check one row per `admission_id`
- check no missing required IDs
- check lab aggregation fields are populated correctly
- check admissions without lab results remain present
- check `has_lab_results` distribution
- check `first_lab_result_date` and `latest_lab_result_date` ranges
- check joins do not multiply rows

## Next Steps

Next steps:

- create `SQL/26_feature_admission_large_v2.sql`
- aggregate lab results by `admission_id`
- join lab aggregations to `feature_admission_large_v1`
- validate row count and grain
- review SQL/26 before Git commit

## Performance Note

Queries against `feature_admission_large_v2` are currently slower than expected for this dataset size.

The likely reason is that `feature_admission_large_v2` is built on top of multiple stacked views:

- `feature_admission_large_v2`
- `feature_admission_large_v1`
- curated views
- cleaned views
- raw tables

Because regular PostgreSQL views do not store data physically, the underlying logic may be recalculated when the view is queried.

This is acceptable for the current correctness-focused phase, but performance should be reviewed before using this feature table for repeated analysis or machine learning workflows.

Possible future improvements include:

- using `EXPLAIN ANALYZE`
- adding indexes on join keys
- creating materialized views
- storing the feature table as a physical table for repeated analysis
- comparing query runtimes before and after optimization