-- ============================================================
-- Script: 29_create_feature_admission_large_v2_analysis_table.sql
-- Purpose: Create a physical analysis table from the validated
--          feature_admission_large_v2 view.
-- Layer: analysis table
--
-- Source view:
-- feature_admission_large_v2
--
-- Target table:
-- analysis_feature_admission_large_v2
--
-- Design notes:
-- - The view remains the source definition.
-- - The physical table is a validated snapshot for repeated analysis.
-- - This table is useful for Python/pandas profiling and later ML workflows.
-- - The table must be rebuilt and revalidated if upstream data or logic changes.
-- ============================================================


-- ============================================================
-- 1. Drop existing analysis table if it exists
-- ============================================================
-- Purpose:
-- Recreate the analysis table from the current validated source view.
--
-- Note:
-- This is acceptable in this project phase because the table is a
-- reproducible snapshot, not manually edited business data.
-- ============================================================

DROP TABLE IF EXISTS analysis_feature_admission_large_v2;


-- ============================================================
-- 2. Create physical analysis table from feature view
-- ============================================================
-- Purpose:
-- Materialize feature_admission_large_v2 into a physical table so repeated
-- reads are faster for analysis, profiling, exports, and later ML workflows.
--
-- Expected:
-- This step may take several minutes because the source view is built on
-- stacked views.
-- ============================================================

CREATE TABLE analysis_feature_admission_large_v2 AS
SELECT
    f.*,

    -- Metadata fields for traceability
    CURRENT_TIMESTAMP AS analysis_table_created_at,
    'feature_admission_large_v2'::TEXT AS source_view_name

FROM feature_admission_large_v2 f;


-- ============================================================
-- 3. Validate source view and physical table row counts
-- ============================================================
-- Purpose:
-- Confirm that the physical table has the same number of rows as the
-- source feature view.
--
-- Expected:
-- Both row counts should be 1,635.
-- ============================================================

SELECT
    'feature_admission_large_v2' AS object_name,
    COUNT(*) AS row_count
FROM feature_admission_large_v2

UNION ALL

SELECT
    'analysis_feature_admission_large_v2' AS object_name,
    COUNT(*) AS row_count
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 4. Validate admission-level grain
-- ============================================================
-- Purpose:
-- Confirm that the physical analysis table still has one row per admission.
--
-- Expected:
-- duplicate_admission_count should be 0.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS distinct_admission_count,
    COUNT(*) - COUNT(DISTINCT admission_id) AS duplicate_admission_count
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 5. Validate required ID completeness
-- ============================================================
-- Purpose:
-- Confirm that required identifiers are not missing after materialization.
--
-- Expected:
-- All missing counts should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE admission_id IS NULL) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE patient_id IS NULL) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE department_id IS NULL) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE provider_id IS NULL) AS missing_provider_id_count
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 6. Validate lab result totals
-- ============================================================
-- Purpose:
-- Confirm that all curated lab results are still represented through
-- lab_result_count in the physical analysis table.
--
-- Expected:
-- source_lab_result_count = total_lab_results_in_analysis_table.
-- difference_count should be 0.
-- ============================================================

WITH source_counts AS (

    SELECT
        COUNT(*) AS source_lab_result_count
    FROM curated_lab_results_large
),

analysis_counts AS (

    SELECT
        SUM(lab_result_count) AS total_lab_results_in_analysis_table
    FROM analysis_feature_admission_large_v2
)

SELECT
    source_counts.source_lab_result_count,
    analysis_counts.total_lab_results_in_analysis_table,
    source_counts.source_lab_result_count
        - analysis_counts.total_lab_results_in_analysis_table AS difference_count
FROM source_counts
CROSS JOIN analysis_counts;


-- ============================================================
-- 7. Validate lab feature consistency
-- ============================================================
-- Purpose:
-- Confirm that lab count fields and has_lab_results remain consistent
-- after materialization.
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
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 8. Validate lab date order
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
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 9. Compare read speed from view vs physical table
-- ============================================================
-- Purpose:
-- Run these queries manually and compare runtimes in DBeaver.
--
-- Expected:
-- COUNT from the physical table should be much faster than repeated
-- COUNT or SELECT operations from the stacked view.
-- ============================================================

SELECT
    COUNT(*) AS source_view_row_count
FROM feature_admission_large_v2;


SELECT
    COUNT(*) AS analysis_table_row_count
FROM analysis_feature_admission_large_v2;


-- ============================================================
-- 10. Inspect metadata columns
-- ============================================================
-- Purpose:
-- Confirm that snapshot metadata was added to the physical table.
-- ============================================================

SELECT
    source_view_name,
    MIN(analysis_table_created_at) AS snapshot_created_at_min,
    MAX(analysis_table_created_at) AS snapshot_created_at_max,
    COUNT(*) AS row_count
FROM analysis_feature_admission_large_v2
GROUP BY
    source_view_name;


-- ============================================================
-- 11. PASS / FAIL validation summary
-- ============================================================
-- Purpose:
-- Provide a compact validation summary for the physical analysis table.
-- ============================================================

WITH validation_metrics AS (

    SELECT
        (SELECT COUNT(*) FROM feature_admission_large_v2) AS source_view_row_count,
        (SELECT COUNT(*) FROM analysis_feature_admission_large_v2) AS analysis_table_row_count,

        (
            SELECT COUNT(*) - COUNT(DISTINCT admission_id)
            FROM analysis_feature_admission_large_v2
        ) AS duplicate_admission_count,

        (
            SELECT
                COUNT(*) FILTER (
                    WHERE admission_id IS NULL
                       OR patient_id IS NULL
                       OR department_id IS NULL
                       OR provider_id IS NULL
                )
            FROM analysis_feature_admission_large_v2
        ) AS missing_required_id_count,

        (
            SELECT COUNT(*)
            FROM curated_lab_results_large
        ) AS source_lab_result_count,

        (
            SELECT SUM(lab_result_count)
            FROM analysis_feature_admission_large_v2
        ) AS total_lab_results_in_analysis_table,

        (
            SELECT COUNT(*) FILTER (
                WHERE first_lab_result_date > latest_lab_result_date
            )
            FROM analysis_feature_admission_large_v2
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
            FROM analysis_feature_admission_large_v2
        ) AS lab_feature_inconsistency_count
)

SELECT
    'row_count_matches_source_view' AS check_name,
    analysis_table_row_count AS actual_value,
    source_view_row_count AS expected_value,
    CASE
        WHEN analysis_table_row_count = source_view_row_count THEN 'PASS'
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
    total_lab_results_in_analysis_table AS actual_value,
    source_lab_result_count AS expected_value,
    CASE
        WHEN total_lab_results_in_analysis_table = source_lab_result_count THEN 'PASS'
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