# Analysis Table Decision

## Purpose

This document explains the decision to create a physical analysis table from `feature_admission_large_v2`.

The goal is to prepare a stable and faster dataset for repeated analysis, Python profiling, and later machine learning workflows.

## Current Situation

`feature_admission_large_v2` is a validated feature view.

It preserves the admission-level grain:

`1 row = 1 curated admission`

The view also includes lab aggregation features, such as:

- `lab_result_count`
- `distinct_test_name_count`
- `first_lab_result_date`
- `latest_lab_result_date`
- `has_lab_results`

Quality checks confirmed that the view is correct from a data quality and grain perspective.

## Current Problem

Performance diagnostics showed that full materialization of `feature_admission_large_v2` is slower than expected.

The view is built on top of multiple stacked views:

- `feature_admission_large_v2`
- `feature_admission_large_v1`
- curated views
- cleaned views
- raw tables

Because regular PostgreSQL views do not physically store result rows, PostgreSQL may need to recalculate the underlying view logic when the final view is queried.

This is especially expensive when using `SELECT *`, because all columns and derived fields must be calculated.

## Decision

A physical analysis table will be created:

`analysis_feature_admission_large_v2`

The view `feature_admission_large_v2` remains the source definition.

The physical analysis table is used as a validated snapshot for repeated analysis and later Python/ML workflows.

## Why Not Only Use the View?

The view is useful because it keeps the transformation logic transparent and reproducible.

However, repeatedly querying the full view is inefficient for analysis workflows.

Using only the view would mean that PostgreSQL may need to recalculate the full stacked view chain every time the data is queried.

This is not ideal for repeated profiling, exports, notebooks, or model development.

## Why a Physical Analysis Table?

A physical analysis table stores the result rows.

This makes repeated reads much faster after the table has been created.

This is useful for:

- Python/pandas profiling
- repeated analysis queries
- exploratory data analysis
- later ML feature inspection
- reproducible analysis snapshots

The physical table acts as a stable analysis-ready dataset.

## Risk: Stale Data

The main risk of a physical table is stale data.

A physical table does not automatically update when the source view, raw data, cleaned logic, or curated logic changes.

If upstream data or transformation logic changes, the analysis table must be rebuilt and validated again.

Therefore, the analysis table should always be treated as a snapshot, not as a live view.

## Validation Requirements

After creating the physical analysis table, the following checks are required:

- source view row count equals physical table row count
- `duplicate_admission_id_count = 0`
- required IDs are complete
- `SUM(lab_result_count)` matches the expected curated lab result count
- lab date order is valid
- `has_lab_results` is consistent with `lab_result_count`
- the table creation time is documented
- the validation result is documented

## Why Not Blind Indexing Yet?

Indexes are not added blindly at this stage.

Performance diagnostics suggested that the main issue is the stacked view chain and full materialization cost, not the direct lab aggregation itself.

Indexes may help later, especially on join keys or cleaned key expressions, but they should only be added after targeted measurement.

The current step focuses on creating a validated physical snapshot for repeated analysis.

## Expected Outcome

The expected outcome is:

- `analysis_feature_admission_large_v2` is created successfully
- the physical table has 1,635 rows
- each `admission_id` appears once
- all 4,079 curated lab results are represented through `lab_result_count`
- repeated reads from the physical table are faster than repeated reads from the stacked view
- the physical table is ready for Python/pandas profiling

## Next Steps

Next steps:

- create `SQL/29_create_feature_admission_large_v2_analysis_table.sql`
- create the physical analysis table from `feature_admission_large_v2`
- validate row count and grain
- validate lab aggregation totals
- compare read performance between the view and physical table
- document the results