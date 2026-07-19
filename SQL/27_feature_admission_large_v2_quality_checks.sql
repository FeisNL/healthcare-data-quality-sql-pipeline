-- ============================================================
-- Script: 27_feature_admission_large_v2_quality_checks.sql
-- Purpose: Validate feature_admission_large_v2 after adding
--          lab result aggregation features.
-- Layer: feature table v2 quality checks
--
-- Grain:
-- 1 row = 1 curated admission
--
-- Performance note:
-- feature_admission_large_v2 is built on stacked views and may be slow
-- when queried repeatedly. This script first creates temporary validation
-- snapshots so the expensive view logic is calculated once per session.
-- ============================================================


-- ============================================================
-- 1. Create temporary validation snapshots
-- ============================================================
-- Purpose:
-- Store the feature table and lab aggregations temporarily so repeated
-- validation checks run faster in the current database session.
--
-- Note:
-- TEMP tables only exist in the current database session.
-- They do not change the permanent pipeline.
-- ============================================================

DROP TABLE IF EXISTS tmp_feature_admission_large_v2_validation;
DROP TABLE IF EXISTS tmp_lab_aggregation_validation;

CREATE TEMP TABLE tmp_feature_admission_large_v2_validation AS
SELECT
    *
FROM feature_admission_large_v2;

CREATE TEMP TABLE tmp_lab_aggregation_validation AS
SELECT
    admission_id,
    COUNT(*) AS lab_result_count,
    COUNT(DISTINCT test_name) AS distinct_test_name_count,
    MIN(test_date) AS first_lab_result_date,
    MAX(test_date) AS latest_lab_result_date
FROM curated_lab_results_large
GROUP BY
    admission_id;


-- ============================================================
-- 2. Verify row count preservation
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
    'feature_admission_large_v2_snapshot' AS object_name,
    COUNT(*) AS row_count
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 3. Validate admission-level grain
-- ============================================================
-- Purpose:
-- Confirm that feature_admission_large_v2 still has one row per admission.
--
-- Expected:
-- duplicate_admission_count should be 0.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS distinct_admission_count,
    COUNT(*) - COUNT(DISTINCT admission_id) AS duplicate_admission_count
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 4. Validate required ID completeness
-- ============================================================
-- Purpose:
-- Confirm that required identifiers are not missing.
--
-- Expected:
-- All missing counts should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE admission_id IS NULL) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE patient_id IS NULL) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE department_id IS NULL) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE provider_id IS NULL) AS missing_provider_id_count
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 5. Validate lab aggregation totals
-- ============================================================
-- Purpose:
-- Confirm that all curated lab result rows are represented in the
-- admission-level feature table through lab_result_count.
--
-- Expected:
-- source_lab_result_count = total_lab_results_in_feature_v2.
-- difference_count should be 0.
-- ============================================================

WITH source_counts AS (

    SELECT
        COUNT(*) AS source_lab_result_count
    FROM curated_lab_results_large
),

feature_counts AS (

    SELECT
        SUM(lab_result_count) AS total_lab_results_in_feature_v2
    FROM tmp_feature_admission_large_v2_validation
)

SELECT
    source_counts.source_lab_result_count,
    feature_counts.total_lab_results_in_feature_v2,
    source_counts.source_lab_result_count
        - feature_counts.total_lab_results_in_feature_v2 AS difference_count
FROM source_counts
CROSS JOIN feature_counts;


-- ============================================================
-- 6. Validate lab aggregation join coverage
-- ============================================================
-- Purpose:
-- Compare the number of admissions with lab results in the source lab
-- aggregation against the feature table.
--
-- Expected:
-- source_admissions_with_lab_results should equal
-- feature_admissions_with_lab_results.
-- ============================================================

WITH source_lab_admissions AS (

    SELECT
        COUNT(*) AS source_admissions_with_lab_results
    FROM tmp_lab_aggregation_validation
),

feature_lab_admissions AS (

    SELECT
        COUNT(*) FILTER (WHERE has_lab_results IS TRUE) AS feature_admissions_with_lab_results
    FROM tmp_feature_admission_large_v2_validation
)

SELECT
    source_lab_admissions.source_admissions_with_lab_results,
    feature_lab_admissions.feature_admissions_with_lab_results,
    source_lab_admissions.source_admissions_with_lab_results
        - feature_lab_admissions.feature_admissions_with_lab_results AS difference_count
FROM source_lab_admissions
CROSS JOIN feature_lab_admissions;


-- ============================================================
-- 7. Validate has_lab_results distribution
-- ============================================================
-- Purpose:
-- Count admissions with and without lab results.
--
-- Note:
-- In this dataset, all curated admissions currently have at least one
-- curated lab result. Therefore, 0 admissions without lab results is valid.
-- ============================================================

SELECT
    has_lab_results,
    COUNT(*) AS admission_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage
FROM tmp_feature_admission_large_v2_validation
GROUP BY
    has_lab_results
ORDER BY
    has_lab_results;


-- ============================================================
-- 8. Validate lab count ranges
-- ============================================================
-- Purpose:
-- Inspect minimum and maximum lab result counts per admission.
--
-- Expected:
-- min_lab_result_count should not be negative.
-- max_lab_result_count should be plausible for the dataset.
-- ============================================================

SELECT
    MIN(lab_result_count) AS min_lab_result_count,
    MAX(lab_result_count) AS max_lab_result_count,
    MIN(distinct_test_name_count) AS min_distinct_test_name_count,
    MAX(distinct_test_name_count) AS max_distinct_test_name_count
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 9. Validate lab date order
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
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 10. Validate lab feature consistency
-- ============================================================
-- Purpose:
-- Confirm that lab count fields and has_lab_results tell the same story.
--
-- Expected:
-- All inconsistency counts should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE has_lab_results IS TRUE
          AND lab_result_count = 0
    ) AS has_labs_true_but_zero_lab_count,

    COUNT(*) FILTER (
        WHERE has_lab_results IS FALSE
          AND lab_result_count > 0
    ) AS has_labs_false_but_positive_lab_count,

    COUNT(*) FILTER (
        WHERE lab_result_count < distinct_test_name_count
    ) AS distinct_test_count_greater_than_lab_count,

    COUNT(*) FILTER (
        WHERE has_lab_results IS TRUE
          AND first_lab_result_date IS NULL
    ) AS has_labs_true_but_missing_first_lab_date,

    COUNT(*) FILTER (
        WHERE has_lab_results IS TRUE
          AND latest_lab_result_date IS NULL
    ) AS has_labs_true_but_missing_latest_lab_date
FROM tmp_feature_admission_large_v2_validation;


-- ============================================================
-- 11. PASS / FAIL validation summary
-- ============================================================
-- Purpose:
-- Provide a compact validation summary for feature_admission_large_v2.
-- ============================================================

WITH validation_metrics AS (

    SELECT
        (SELECT COUNT(*) FROM feature_admission_large_v1) AS v1_row_count,
        (SELECT COUNT(*) FROM tmp_feature_admission_large_v2_validation) AS v2_row_count,

        (
            SELECT COUNT(*) - COUNT(DISTINCT admission_id)
            FROM tmp_feature_admission_large_v2_validation
        ) AS duplicate_admission_count,

        (
            SELECT
                COUNT(*) FILTER (
                    WHERE admission_id IS NULL
                       OR patient_id IS NULL
                       OR department_id IS NULL
                       OR provider_id IS NULL
                )
            FROM tmp_feature_admission_large_v2_validation
        ) AS missing_required_id_count,

        (
            SELECT COUNT(*)
            FROM curated_lab_results_large
        ) AS source_lab_result_count,

        (
            SELECT SUM(lab_result_count)
            FROM tmp_feature_admission_large_v2_validation
        ) AS total_lab_results_in_feature_v2,

        (
            SELECT COUNT(*)
            FROM tmp_lab_aggregation_validation
        ) AS source_admissions_with_lab_results,

        (
            SELECT COUNT(*) FILTER (WHERE has_lab_results IS TRUE)
            FROM tmp_feature_admission_large_v2_validation
        ) AS feature_admissions_with_lab_results,

        (
            SELECT COUNT(*) FILTER (
                WHERE first_lab_result_date > latest_lab_result_date
            )
            FROM tmp_feature_admission_large_v2_validation
        ) AS invalid_lab_date_order_count,

        (
            SELECT COUNT(*) FILTER (
                WHERE has_lab_results IS TRUE
                  AND lab_result_count = 0
            )
            + COUNT(*) FILTER (
                WHERE has_lab_results IS FALSE
                  AND lab_result_count > 0
            )
            + COUNT(*) FILTER (
                WHERE lab_result_count < distinct_test_name_count
            )
            + COUNT(*) FILTER (
                WHERE has_lab_results IS TRUE
                  AND first_lab_result_date IS NULL
            )
            + COUNT(*) FILTER (
                WHERE has_lab_results IS TRUE
                  AND latest_lab_result_date IS NULL
            )
            FROM tmp_feature_admission_large_v2_validation
        ) AS lab_feature_inconsistency_count
)


SELECT
    'row_count_matches_feature_v1' AS check_name,
    v2_row_count AS actual_value,
    v1_row_count AS expected_value,
    CASE
        WHEN v2_row_count = v1_row_count THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'one_row_per_admission_id' AS check_name,
    duplicate_admission_count AS actual_value,
    0 AS expected_value,
    CASE
        WHEN duplicate_admission_count = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'required_ids_complete' AS check_name,
    missing_required_id_count AS actual_value,
    0 AS expected_value,
    CASE
        WHEN missing_required_id_count = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'lab_result_totals_preserved' AS check_name,
    total_lab_results_in_feature_v2 AS actual_value,
    source_lab_result_count AS expected_value,
    CASE
        WHEN total_lab_results_in_feature_v2 = source_lab_result_count THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'admissions_with_lab_results_match_source' AS check_name,
    feature_admissions_with_lab_results AS actual_value,
    source_admissions_with_lab_results AS expected_value,
    CASE
        WHEN feature_admissions_with_lab_results = source_admissions_with_lab_results THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'lab_date_order_valid' AS check_name,
    invalid_lab_date_order_count AS actual_value,
    0 AS expected_value,
    CASE
        WHEN invalid_lab_date_order_count = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

UNION ALL

SELECT
    'lab_feature_consistency_valid' AS check_name,
    lab_feature_inconsistency_count AS actual_value,
    0 AS expected_value,
    CASE
        WHEN lab_feature_inconsistency_count = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_metrics

ORDER BY
    check_name;