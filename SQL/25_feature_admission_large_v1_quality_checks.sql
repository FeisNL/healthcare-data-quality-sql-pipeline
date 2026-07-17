-- ============================================================
-- Script: 25_feature_admission_large_v1_quality_checks.sql
-- Purpose: Validate the large admission-level feature table v1.
-- Layer: feature table validation
--
-- This script validates whether feature_admission_large_v1 is reliable
-- enough to use as a foundation for analysis and later machine learning
-- experiments.
--
-- Grain:
-- 1 row = 1 curated admission
-- ============================================================


-- ============================================================
-- 1. Verify feature view exists
-- ============================================================
-- Purpose:
-- Confirm that the feature view is available before running quality checks.
-- ============================================================

SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'feature_admission_large_v1';


-- ============================================================
-- 2. Validate row count
-- ============================================================
-- Purpose:
-- Compare the row count of the feature view with curated_admissions_large.
--
-- Expected:
-- Both row counts should be 1,635.
-- If the feature view has fewer rows, a join may have removed records.
-- If the feature view has more rows, a join may have multiplied records.
-- ============================================================

SELECT
    'curated_admissions_large' AS object_name,
    COUNT(*) AS row_count
FROM curated_admissions_large

UNION ALL

SELECT
    'feature_admission_large_v1' AS object_name,
    COUNT(*) AS row_count
FROM feature_admission_large_v1;


-- ============================================================
-- 3. Validate admission-level grain
-- ============================================================
-- Purpose:
-- Confirm that each admission_id appears only once in the feature view.
--
-- Expected:
-- total_rows should equal distinct_admission_count.
-- duplicate_admission_count should be 0.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS distinct_admission_count,
    COUNT(*) - COUNT(DISTINCT admission_id) AS duplicate_admission_count
FROM feature_admission_large_v1;


-- ============================================================
-- 4. Validate required ID completeness
-- ============================================================
-- Purpose:
-- Confirm that required identifiers are not missing.
--
-- Expected:
-- All missing ID counts should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE admission_id IS NULL) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE patient_id IS NULL) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE department_id IS NULL) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE provider_id IS NULL) AS missing_provider_id_count
FROM feature_admission_large_v1;


-- ============================================================
-- 5. Validate key feature completeness
-- ============================================================
-- Purpose:
-- Check whether important feature columns are complete.
--
-- Expected:
-- Missing values should be reviewed before using this feature view
-- for analysis or machine learning.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE age_at_admission IS NULL) AS missing_age_at_admission_count,
    COUNT(*) FILTER (WHERE gender IS NULL) AS missing_gender_count,
    COUNT(*) FILTER (WHERE admission_type IS NULL) AS missing_admission_type_count,
    COUNT(*) FILTER (WHERE diagnosis_group IS NULL) AS missing_diagnosis_group_count,
    COUNT(*) FILTER (WHERE department_name IS NULL) AS missing_department_name_count,
    COUNT(*) FILTER (WHERE provider_department_id IS NULL) AS missing_provider_department_id_count
FROM feature_admission_large_v1;


-- ============================================================
-- 6. Validate provider-department warning distribution
-- ============================================================
-- Purpose:
-- Confirm that the known provider-to-department relationship warning
-- remains visible in the feature view.
--
-- Expected:
-- TRUE count should be 1,232.
-- FALSE count should be 403.
-- ============================================================

SELECT
    provider_department_mismatch_warning,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage
FROM feature_admission_large_v1
GROUP BY
    provider_department_mismatch_warning
ORDER BY
    provider_department_mismatch_warning;


-- ============================================================
-- 7. Validate age_at_admission range
-- ============================================================
-- Purpose:
-- Check whether age_at_admission contains unrealistic values.
--
-- Expected:
-- negative_age_count should be 0.
-- very_high_age_count should be reviewed if greater than 0.
-- ============================================================

SELECT
    MIN(age_at_admission) AS min_age_at_admission,
    MAX(age_at_admission) AS max_age_at_admission,
    COUNT(*) FILTER (WHERE age_at_admission < 0) AS negative_age_count,
    COUNT(*) FILTER (WHERE age_at_admission > 110) AS very_high_age_count
FROM feature_admission_large_v1;


-- ============================================================
-- 8. Inspect records with potential age issues
-- ============================================================
-- Purpose:
-- Show records with unrealistic age values for manual review.
-- ============================================================

SELECT
    admission_id,
    patient_id,
    age_at_admission,
    gender,
    admission_type,
    diagnosis_group,
    department_id,
    provider_id
FROM feature_admission_large_v1
WHERE age_at_admission < 0
   OR age_at_admission > 110
ORDER BY
    age_at_admission DESC,
    admission_id
LIMIT 25;


-- ============================================================
-- 9. PASS/WARNING validation summary
-- ============================================================
-- Purpose:
-- Summarize the main validation checks in a single reviewable output.
--
-- Interpretation:
-- PASS means the check matched the expected result.
-- WARNING means the feature table may still be usable, but the issue
-- should be reviewed or documented.
-- FAIL means the feature table should not be used until fixed.
-- ============================================================

WITH validation_metrics AS (

    SELECT
        (SELECT COUNT(*) FROM curated_admissions_large) AS curated_admission_count,
        (SELECT COUNT(*) FROM feature_admission_large_v1) AS feature_row_count,
        (SELECT COUNT(DISTINCT admission_id) FROM feature_admission_large_v1) AS distinct_admission_count,
        (SELECT COUNT(*) FILTER (WHERE admission_id IS NULL) FROM feature_admission_large_v1) AS missing_admission_id_count,
        (SELECT COUNT(*) FILTER (WHERE patient_id IS NULL) FROM feature_admission_large_v1) AS missing_patient_id_count,
        (SELECT COUNT(*) FILTER (WHERE department_id IS NULL) FROM feature_admission_large_v1) AS missing_department_id_count,
        (SELECT COUNT(*) FILTER (WHERE provider_id IS NULL) FROM feature_admission_large_v1) AS missing_provider_id_count,
        (SELECT COUNT(*) FILTER (WHERE age_at_admission < 0) FROM feature_admission_large_v1) AS negative_age_count,
        (SELECT COUNT(*) FILTER (WHERE age_at_admission > 110) FROM feature_admission_large_v1) AS very_high_age_count,
        (SELECT COUNT(*) FILTER (WHERE provider_department_mismatch_warning IS TRUE) FROM feature_admission_large_v1) AS provider_department_warning_true_count,
        (SELECT COUNT(*) FILTER (WHERE provider_department_mismatch_warning IS FALSE) FROM feature_admission_large_v1) AS provider_department_warning_false_count
)

SELECT
    'row_count_matches_curated_admissions' AS validation_check,
    curated_admission_count::TEXT AS expected_result,
    feature_row_count::TEXT AS actual_result,
    CASE
        WHEN curated_admission_count = feature_row_count
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM validation_metrics

UNION ALL

SELECT
    'one_row_per_admission_id' AS validation_check,
    feature_row_count::TEXT AS expected_result,
    distinct_admission_count::TEXT AS actual_result,
    CASE
        WHEN feature_row_count = distinct_admission_count
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM validation_metrics

UNION ALL

SELECT
    'required_ids_complete' AS validation_check,
    '0 missing required IDs' AS expected_result,
    (
        missing_admission_id_count
        + missing_patient_id_count
        + missing_department_id_count
        + missing_provider_id_count
    )::TEXT AS actual_result,
    CASE
        WHEN (
            missing_admission_id_count
            + missing_patient_id_count
            + missing_department_id_count
            + missing_provider_id_count
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM validation_metrics

UNION ALL

SELECT
    'age_at_admission_no_negative_values' AS validation_check,
    '0 negative ages' AS expected_result,
    negative_age_count::TEXT AS actual_result,
    CASE
        WHEN negative_age_count = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM validation_metrics

UNION ALL

SELECT
    'age_at_admission_very_high_values' AS validation_check,
    '0 ages above 110 preferred' AS expected_result,
    very_high_age_count::TEXT AS actual_result,
    CASE
        WHEN very_high_age_count = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END AS validation_status
FROM validation_metrics

UNION ALL

SELECT
    'provider_department_warning_distribution' AS validation_check,
    'TRUE = 1232, FALSE = 403' AS expected_result,
    'TRUE = '
        || provider_department_warning_true_count::TEXT
        || ', FALSE = '
        || provider_department_warning_false_count::TEXT AS actual_result,
    CASE
        WHEN provider_department_warning_true_count = 1232
         AND provider_department_warning_false_count = 403
        THEN 'PASS'
        ELSE 'WARNING'
    END AS validation_status
FROM validation_metrics;