-- ============================================================
-- Script: 28_feature_table_performance_diagnostics.sql
-- Purpose: Diagnose performance issues around feature_admission_large_v2.
-- Layer: performance diagnostics
--
-- Context:
-- feature_admission_large_v2 preserves the admission-level grain and
-- correctly represents lab aggregations, but full materialization is
-- slower than expected for the dataset size.
--
-- Diagnostic principle:
-- Measure first. Do not add indexes, materialized views, or physical
-- tables before identifying the likely bottleneck.
-- ============================================================


-- ============================================================
-- 1. Verify relevant feature views exist
-- ============================================================

SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'feature_admission_large_v1',
      'feature_admission_large_v2',
      'curated_lab_results_large'
  )
ORDER BY
    table_name;


-- ============================================================
-- 2. Inspect existing indexes on relevant raw tables
-- ============================================================
-- Purpose:
-- Check whether PostgreSQL currently has indexes available on common
-- join keys used by the pipeline.
--
-- Note:
-- Views do not have indexes directly. Indexes are created on tables
-- or materialized views.
-- ============================================================

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
      'patients_large',
      'departments_large',
      'providers_large',
      'admissions_large',
      'lab_results_large'
  )
ORDER BY
    tablename,
    indexname;


-- ============================================================
-- 3. Baseline row count timings
-- ============================================================
-- Purpose:
-- Run these queries manually and record runtimes in Docs/performance_notes.md.
-- ============================================================

SELECT
    COUNT(*) AS feature_v1_row_count
FROM feature_admission_large_v1;


SELECT
    COUNT(*) AS feature_v2_row_count
FROM feature_admission_large_v2;


-- ============================================================
-- 4. Baseline direct lab aggregation timing
-- ============================================================
-- Purpose:
-- Check whether lab aggregation itself is slow.
--
-- Observed:
-- This query was fast compared with full feature table materialization.
-- ============================================================

WITH lab_aggregations AS (

    SELECT
        admission_id,
        COUNT(*) AS lab_result_count
    FROM curated_lab_results_large
    GROUP BY
        admission_id
)

SELECT
    COUNT(*) AS admissions_with_labs,
    SUM(lab_result_count) AS total_lab_results,
    MIN(lab_result_count) AS min_lab_results_per_admission,
    MAX(lab_result_count) AS max_lab_results_per_admission
FROM lab_aggregations;


-- ============================================================
-- 5. EXPLAIN ANALYZE: count feature table v2
-- ============================================================
-- Purpose:
-- Inspect how PostgreSQL executes a COUNT query against v2.
--
-- Note:
-- This query executes the statement and returns the actual plan.
-- Look for:
-- - Execution Time
-- - expensive joins
-- - expensive scans
-- - expensive aggregates
-- - large difference between estimated and actual rows
-- ============================================================

EXPLAIN ANALYZE
SELECT
    COUNT(*) AS row_count
FROM feature_admission_large_v2;


-- ============================================================
-- 6. EXPLAIN ANALYZE: direct lab aggregation
-- ============================================================
-- Purpose:
-- Compare the plan for direct lab aggregation with the feature view.
-- ============================================================

EXPLAIN ANALYZE
WITH lab_aggregations AS (

    SELECT
        admission_id,
        COUNT(*) AS lab_result_count
    FROM curated_lab_results_large
    GROUP BY
        admission_id
)

SELECT
    COUNT(*) AS admissions_with_labs,
    SUM(lab_result_count) AS total_lab_results
FROM lab_aggregations;


-- ============================================================
-- 7. Optional heavy diagnostic: materialize feature table v2
-- ============================================================
-- Purpose:
-- Measure the expensive operation explicitly.
--
-- Warning:
-- This may take several minutes because it fully calculates and stores
-- all columns from feature_admission_large_v2.
-- ============================================================

DROP TABLE IF EXISTS tmp_feature_admission_large_v2_perf_diagnostic;

CREATE TEMP TABLE tmp_feature_admission_large_v2_perf_diagnostic AS
SELECT
    *
FROM feature_admission_large_v2;


-- ============================================================
-- 8. Confirm temp table read speed
-- ============================================================
-- Purpose:
-- Confirm that repeated reads are fast after materialization.
-- ============================================================

SELECT
    COUNT(*) AS temp_feature_v2_row_count
FROM tmp_feature_admission_large_v2_perf_diagnostic;


-- ============================================================
-- 9. Diagnostic interpretation template
-- ============================================================
-- Purpose:
-- This SELECT stores the current interpretation in query output form.
-- Copy the relevant conclusions into Docs/performance_notes.md.
-- ============================================================

SELECT
    'direct_lab_aggregation' AS diagnostic_area,
    'Fast in baseline test; unlikely to be the main bottleneck.' AS interpretation

UNION ALL

SELECT
    'feature_v2_count',
    'Moderately slow for the dataset size, but much faster than full SELECT * materialization.'

UNION ALL

SELECT
    'feature_v2_materialization',
    'Slowest observed operation. Full SELECT * from stacked views is the likely bottleneck.'

UNION ALL

SELECT
    'temp_table_reads',
    'Very fast after materialization, which suggests repeated validation checks are not the main issue.'

UNION ALL

SELECT
    'next_step',
    'Review EXPLAIN ANALYZE output before deciding between indexes, materialized views, or physical feature tables.';