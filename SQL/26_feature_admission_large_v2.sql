-- ============================================================
-- Script: 26_feature_admission_large_v2.sql
-- Purpose: Create the second large admission-level feature view
--          with lab result aggregation features.
-- Layer: feature table v2
--
-- Grain:
-- 1 row = 1 curated admission
--
-- Design notes:
-- - feature_admission_large_v1 is the main source because it already
--   preserves the admission-level grain.
-- - Lab results are aggregated by admission_id before joining.
-- - A LEFT JOIN is used so admissions without lab results remain present.
-- - Lab aggregation features are analysis features, not automatically
--   ML-safe features for every prediction use case.
-- ============================================================


-- ============================================================
-- 1. Create admission-level feature view v2 with lab aggregations
-- ============================================================
-- Purpose:
-- Add lab result aggregation features to feature_admission_large_v1
-- while preserving one row per admission.
-- ============================================================

CREATE OR REPLACE VIEW feature_admission_large_v2 AS

WITH lab_aggregations AS (

    SELECT
        admission_id,
        COUNT(*) AS lab_result_count,
        COUNT(DISTINCT test_name) AS distinct_test_name_count,
        MIN(test_date) AS first_lab_result_date,
        MAX(test_date) AS latest_lab_result_date
    FROM curated_lab_results_large
    GROUP BY
        admission_id
)

SELECT
    -- --------------------------------------------------------
    -- Existing v1 admission-level features
    -- --------------------------------------------------------
    f.admission_id,
    f.patient_id,
    f.age_at_admission,
    f.gender,
    f.admission_type,
    f.diagnosis_group,
    f.department_id,
    f.department_name,
    f.provider_id,
    f.provider_department_id,
    f.provider_department_mismatch_warning,

    -- --------------------------------------------------------
    -- Lab aggregation features
    -- --------------------------------------------------------
    COALESCE(l.lab_result_count, 0)::INTEGER AS lab_result_count,
    COALESCE(l.distinct_test_name_count, 0)::INTEGER AS distinct_test_name_count,
    l.first_lab_result_date,
    l.latest_lab_result_date,
    CASE
        WHEN l.admission_id IS NULL
        THEN FALSE
        ELSE TRUE
    END AS has_lab_results

FROM feature_admission_large_v1 f

LEFT JOIN lab_aggregations l
    ON f.admission_id = l.admission_id;


-- ============================================================
-- 2. Validate row count
-- ============================================================
-- Purpose:
-- Confirm that feature_admission_large_v2 preserves the same row count
-- as feature_admission_large_v1.
--
-- Expected:
-- Both row counts should be 1,635.
-- ============================================================

SELECT
    'feature_admission_large_v1' AS object_name,
    COUNT(*) AS row_count
FROM feature_admission_large_v1

UNION ALL

SELECT
    'feature_admission_large_v2' AS object_name,
    COUNT(*) AS row_count
FROM feature_admission_large_v2;


-- ============================================================
-- 3. Validate one row per admission_id
-- ============================================================
-- Purpose:
-- Confirm that the v2 feature table still has one row per admission.
--
-- Expected:
-- duplicate_admission_count should be 0.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS distinct_admission_count,
    COUNT(*) - COUNT(DISTINCT admission_id) AS duplicate_admission_count
FROM feature_admission_large_v2;


-- ============================================================
-- 4. Validate lab aggregation totals
-- ============================================================
-- Purpose:
-- Confirm that the sum of lab_result_count in the feature table equals
-- the number of rows in curated_lab_results_large.
--
-- Expected:
-- source_lab_result_count should equal aggregated_lab_result_count.
-- difference_count should be 0.
-- ============================================================

WITH source_counts AS (

    SELECT
        COUNT(*) AS source_lab_result_count
    FROM curated_lab_results_large
),

aggregated_counts AS (

    SELECT
        SUM(lab_result_count) AS aggregated_lab_result_count
    FROM feature_admission_large_v2
)

SELECT
    source_counts.source_lab_result_count,
    aggregated_counts.aggregated_lab_result_count,
    source_counts.source_lab_result_count
        - aggregated_counts.aggregated_lab_result_count AS difference_count
FROM source_counts
CROSS JOIN aggregated_counts;


-- ============================================================
-- 5. Validate has_lab_results distribution
-- ============================================================
-- Purpose:
-- Count admissions with and without lab results.
-- ============================================================

SELECT
    has_lab_results,
    COUNT(*) AS admission_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage
FROM feature_admission_large_v2
GROUP BY
    has_lab_results
ORDER BY
    has_lab_results;


-- ============================================================
-- 6. Validate lab feature ranges
-- ============================================================
-- Purpose:
-- Inspect basic ranges for lab aggregation features.
-- ============================================================

SELECT
    MIN(lab_result_count) AS min_lab_result_count,
    MAX(lab_result_count) AS max_lab_result_count,
    MIN(distinct_test_name_count) AS min_distinct_test_name_count,
    MAX(distinct_test_name_count) AS max_distinct_test_name_count,
    MIN(first_lab_result_date) AS earliest_first_lab_result_date,
    MAX(latest_lab_result_date) AS latest_lab_result_date
FROM feature_admission_large_v2;


-- ============================================================
-- 7. Validate lab date order
-- ============================================================
-- Purpose:
-- Confirm that first_lab_result_date is not after latest_lab_result_date.
--
-- Expected:
-- invalid_lab_date_order_count should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE first_lab_result_date > latest_lab_result_date
    ) AS invalid_lab_date_order_count
FROM feature_admission_large_v2;


-- ============================================================
-- 8. Inspect admissions without lab results
-- ============================================================
-- Purpose:
-- Confirm that admissions without lab results remain present in v2.
-- ============================================================

SELECT
    admission_id,
    patient_id,
    admission_type,
    diagnosis_group,
    department_id,
    provider_id,
    lab_result_count,
    distinct_test_name_count,
    has_lab_results
FROM feature_admission_large_v2
WHERE has_lab_results IS FALSE
ORDER BY
    admission_id
LIMIT 25;


-- ============================================================
-- 9. Inspect admissions with the highest lab result counts
-- ============================================================
-- Purpose:
-- Review admissions with many lab results for plausibility.
-- ============================================================

SELECT
    admission_id,
    patient_id,
    admission_type,
    diagnosis_group,
    department_id,
    provider_id,
    lab_result_count,
    distinct_test_name_count,
    first_lab_result_date,
    latest_lab_result_date,
    has_lab_results
FROM feature_admission_large_v2
ORDER BY
    lab_result_count DESC,
    admission_id
LIMIT 25;


-- ============================================================
-- 10. Counting number of records in curated_lab_results_large
-- ============================================================
-- Purpose:
-- Review number of records in curated_lab_results_large
-- ============================================================

SELECT
    COUNT(*) AS curated_lab_results_large_count
FROM curated_lab_results_large;

-- ============================================================
-- 11. Counting number of records in curated_lab_results_large linked with an admission_id, total count of lab results after aggregation,
--     min and max lab results per admission
-- ============================================================
-- Purpose:
-- Review curated lab result with count, sum(adds per admission_id) the counts and returns the sum, and min/max values.
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
    COUNT(*) AS admissions_with_lab_results,
    SUM(lab_result_count) AS total_lab_results_after_aggregation,
    MIN(lab_result_count) AS min_lab_results_per_admission,
    MAX(lab_result_count) AS max_lab_results_per_admission
FROM lab_aggregations;



-- ============================================================
-- 11. Creating an overview off calculations to compare to earlier calculations done based on the source tabel
-- ============================================================
-- Purpose:
-- Review if the data from the source tabel has landed correctly in the target table
-- ============================================================
SELECT
    COUNT(*) AS feature_v2_rows,
    COUNT(*) FILTER (WHERE has_lab_results IS TRUE) AS admissions_with_lab_results,
    COUNT(*) FILTER (WHERE has_lab_results IS FALSE) AS admissions_without_lab_results,
    SUM(lab_result_count) AS total_lab_results_in_feature_v2,
    MIN(lab_result_count) AS min_lab_result_count,
    MAX(lab_result_count) AS max_lab_result_count
FROM feature_admission_large_v2;