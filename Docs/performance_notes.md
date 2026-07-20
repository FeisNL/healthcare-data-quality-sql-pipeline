# Feature Table Performance Notes

## Purpose

This document summarizes the performance diagnostics for `feature_admission_large_v2`.

The goal is to understand why repeated queries and full materialization of the feature table are slower than expected for the current dataset size.

The focus of this step is diagnosis, not immediate optimization.

## Observed Problem

`feature_admission_large_v2` is valid from a data quality and grain perspective, but full materialization is slower than expected.

The feature table is built on top of multiple stacked views:

- `feature_admission_large_v2`
- `feature_admission_large_v1`
- curated views
- cleaned views
- raw tables

Because regular PostgreSQL views do not physically store result rows, querying the final feature view may require PostgreSQL to recalculate the underlying view logic.

## Baseline Timings

The following baseline timings were observed:

| Query | Runtime | Result |
|---|---:|---|
| `COUNT(*)` from `feature_admission_large_v1` | 6.796s | 1,635 rows |
| `COUNT(*)` from `feature_admission_large_v2` | 7.336s | 1,635 rows |
| Direct lab aggregation | 0.33s | 1,635 admission groups / 4,079 lab results |
| Create temp table from `feature_admission_large_v2` using `SELECT *` | 4m 42s - 4m 48s | 1,635 rows |
| `COUNT(*)` from temp feature table | 0.01s - 0.013s | 1,635 rows |

## Interpretation of Timings

The direct lab aggregation query is fast compared with the full feature table materialization.

This suggests that the lab aggregation itself is not the main bottleneck.

The slowest observed operation is full materialization of the `feature_admission_large_v2` view using `SELECT *`.

This is slower than `COUNT(*)` because `SELECT *` requires PostgreSQL to calculate and store all columns from the final feature view, including all underlying joins, filters, cleaned keys, and derived fields.

## EXPLAIN ANALYZE Findings

`EXPLAIN ANALYZE` confirmed that `COUNT(*)` on `feature_admission_large_v2` takes several seconds.

The execution plan contains signals that the query has to perform significant underlying work:

- multiple nested joins
- repeated scans
- many rows removed by join filters
- cleaned key expressions such as `TRIM` and `NULLIF`
- estimated row counts that differ from actual row counts

The direct lab aggregation query was much faster. It grouped 4,079 curated lab result rows into 1,635 admission-level groups.

This confirms that lab aggregation is not the main performance bottleneck.

## Likely Cause

The likely cause of the performance issue is the stacked view design.

The current pipeline is clear and traceable, but the final feature view depends on multiple earlier views. Those views contain data quality logic, joins, filters, and cleaned key expressions.

This means that when `feature_admission_large_v2` is queried, PostgreSQL may need to recalculate a large amount of underlying logic.

The main issue is not the number of rows in the dataset, but the amount of repeated view logic behind the final feature view.

## Why Temp Tables Helped

Temporary validation snapshots improved repeated validation speed.

Creating the temp table was slow because PostgreSQL still had to calculate `feature_admission_large_v2` once.

After that, repeated checks against the temp table were fast because the result was physically stored for the current session.

This shows that repeated validation checks are not the main problem. The expensive step is the initial calculation and materialization of the stacked feature view.

## Current Decision

No permanent performance optimization is applied yet.

The current decision is:

- keep the view-based pipeline for traceability during development
- document the performance issue clearly
- avoid blind index creation
- use temporary validation snapshots when repeated validation checks are needed
- investigate materialized views or physical feature tables before repeated analysis or machine learning workflows

## Possible Future Improvements

Possible future improvements include:

- using `EXPLAIN ANALYZE` more systematically
- adding indexes on raw table join keys where useful
- creating expression indexes for cleaned key expressions if needed
- storing cleaned or curated layers as physical tables
- creating materialized views for expensive intermediate layers
- storing the final feature table as a physical table for repeated analysis
- comparing runtimes before and after optimization

## Important Caution

Indexes should not be added blindly.

An index may help with joins and filters, but it also adds storage and maintenance cost. Also, some join conditions use expressions such as `TRIM` and `NULLIF`, so a normal index on the raw column may not fully solve the problem.

The professional approach is:

measure first, identify the bottleneck, then choose the optimization.

## Summary

The performance diagnostics show that `feature_admission_large_v2` is correct but expensive to fully materialize.

The direct lab aggregation is fast, so it is not the main bottleneck.

The main issue is likely the stacked view chain behind the final feature table.

For repeated analysis or machine learning workflows, a materialized view or physical feature table will likely be more appropriate than repeatedly querying the full stacked view.