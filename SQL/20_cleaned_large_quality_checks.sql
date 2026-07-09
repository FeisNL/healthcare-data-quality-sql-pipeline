-- ============================================================
-- Script: 20_cleaned_large_quality_checks.sql
-- Purpose: Validate the cleaned layer for the large healthcare dataset.
-- Layer: cleaned validation
--
-- This script validates that:
-- 1. all cleaned views exist
-- 2. raw and cleaned row counts match
-- 3. quality issue counts are visible per cleaned view
-- 4. individual quality flags can be inspected
-- 5. issue records can be reviewed manually
-- 6. expected-vs-actual checks return PASS
--
-- Important:
-- The cleaned layer should standardize and flag data.
-- It should not remove records.
-- ============================================================


-- ============================================================
-- 1. Verify that all cleaned views exist
-- ============================================================
-- Goal:
-- Confirm that all five cleaned views were created successfully.
-- Expected:
-- This query should return five rows.
-- ============================================================

SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'cleaned_patients_large',
      'cleaned_departments_large',
      'cleaned_providers_large',
      'cleaned_admissions_large',
      'cleaned_lab_results_large'
  )
ORDER BY table_name;


-- ============================================================
-- 2. Raw vs cleaned row count validation
-- ============================================================
-- Goal:
-- Confirm that cleaned views keep the same number of rows as the raw tables.
--
-- Why:
-- The cleaned layer should flag and standardize records.
-- It should not filter or remove records yet.
-- ============================================================

SELECT
    'patients' AS dataset,
    (SELECT COUNT(*) FROM patients_large) AS raw_row_count,
    (SELECT COUNT(*) FROM cleaned_patients_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM patients_large)
        =
    (SELECT COUNT(*) FROM cleaned_patients_large) AS row_count_matches

UNION ALL

SELECT
    'departments' AS dataset,
    (SELECT COUNT(*) FROM departments_large) AS raw_row_count,
    (SELECT COUNT(*) FROM cleaned_departments_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM departments_large)
        =
    (SELECT COUNT(*) FROM cleaned_departments_large) AS row_count_matches

UNION ALL

SELECT
    'providers' AS dataset,
    (SELECT COUNT(*) FROM providers_large) AS raw_row_count,
    (SELECT COUNT(*) FROM cleaned_providers_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM providers_large)
        =
    (SELECT COUNT(*) FROM cleaned_providers_large) AS row_count_matches

UNION ALL

SELECT
    'admissions' AS dataset,
    (SELECT COUNT(*) FROM admissions_large) AS raw_row_count,
    (SELECT COUNT(*) FROM cleaned_admissions_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM admissions_large)
        =
    (SELECT COUNT(*) FROM cleaned_admissions_large) AS row_count_matches

UNION ALL

SELECT
    'lab_results' AS dataset,
    (SELECT COUNT(*) FROM lab_results_large) AS raw_row_count,
    (SELECT COUNT(*) FROM cleaned_lab_results_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM lab_results_large)
        =
    (SELECT COUNT(*) FROM cleaned_lab_results_large) AS row_count_matches

ORDER BY dataset;


-- ============================================================
-- 3. Cleaned layer issue summary
-- ============================================================
-- Goal:
-- Count how many records in each cleaned view have at least one quality issue.
--
-- Important:
-- Use COUNT(*) FILTER (WHERE flag IS TRUE).
-- Do not use COUNT(flag), because COUNT(flag) counts both TRUE and FALSE.
-- ============================================================

SELECT
    'cleaned_patients_large' AS cleaned_view,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE has_patient_quality_issue IS TRUE) AS quality_issue_rows,
    ROUND(
        100.0 * 
        COUNT(*) FILTER (WHERE has_patient_quality_issue IS TRUE) / NULLIF(COUNT(*), 0),2) 
        AS quality_issue_percentage
FROM cleaned_patients_large

UNION ALL

SELECT
    'cleaned_departments_large' AS cleaned_view,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE has_department_quality_issue IS TRUE) AS quality_issue_rows,
    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE has_department_quality_issue IS TRUE) / NULLIF(COUNT(*), 0),2)
        AS quality_issue_percentage
FROM cleaned_departments_large

UNION ALL

SELECT
    'cleaned_providers_large' AS cleaned_view,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE has_provider_quality_issue IS TRUE) AS quality_issue_rows,
    ROUND(
        100.0 * 
        COUNT(*) FILTER (WHERE has_provider_quality_issue IS TRUE) / NULLIF(COUNT(*), 0),2) 
        AS quality_issue_percentage
FROM cleaned_providers_large

UNION ALL

SELECT
    'cleaned_admissions_large' AS cleaned_view,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE has_admission_quality_issue IS TRUE) AS quality_issue_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE has_admission_quality_issue IS TRUE) / NULLIF(COUNT(*), 0),2) 
        AS quality_issue_percentage
FROM cleaned_admissions_large

UNION ALL

SELECT
    'cleaned_lab_results_large' AS cleaned_view,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE has_lab_result_quality_issue IS TRUE) AS quality_issue_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE has_lab_result_quality_issue IS TRUE) / NULLIF(COUNT(*), 0),2) 
        AS quality_issue_percentage
FROM cleaned_lab_results_large

ORDER BY cleaned_view;


-- ============================================================
-- 4. Patient flag distribution
-- ============================================================
-- Goal:
-- Count each individual patient quality flag.
-- This shows which patient quality issues are present.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE has_missing_patient_id IS TRUE) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE has_duplicate_patient_id IS TRUE) AS duplicate_patient_id_rows,
    COUNT(*) FILTER (WHERE has_future_birth_date IS TRUE) AS future_birth_date_count,
    COUNT(*) FILTER (WHERE has_unrealistic_birth_date IS TRUE) AS unrealistic_birth_date_count,
    COUNT(*) FILTER (WHERE has_missing_gender IS TRUE) AS missing_gender_count,
    COUNT(*) FILTER (WHERE has_invalid_gender IS TRUE) AS invalid_gender_count,
    COUNT(*) FILTER (WHERE has_missing_postcode IS TRUE) AS missing_postcode_count,
    COUNT(*) FILTER (WHERE has_patient_quality_issue IS TRUE) AS patient_quality_issue_count
FROM cleaned_patients_large;


-- ============================================================
-- 5. Department flag distribution
-- ============================================================
-- Goal:
-- Count each individual department quality flag.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE has_missing_department_id IS TRUE) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE has_missing_department_name IS TRUE) AS missing_department_name_count,
    COUNT(*) FILTER (WHERE has_inactive_or_unknown_status IS TRUE) AS inactive_or_unknown_status_count,
    COUNT(*) FILTER (WHERE has_department_quality_issue IS TRUE) AS department_quality_issue_count
FROM cleaned_departments_large;


-- ============================================================
-- 6. Provider flag distribution
-- ============================================================
-- Goal:
-- Count each individual provider quality flag.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE has_missing_provider_id IS TRUE) AS missing_provider_id_count,
    COUNT(*) FILTER (WHERE has_missing_department_id IS TRUE) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE has_unknown_department_id IS TRUE) AS unknown_department_id_count,
    COUNT(*) FILTER (WHERE has_invalid_active_period IS TRUE) AS invalid_active_period_count,
    COUNT(*) FILTER (WHERE has_provider_quality_issue IS TRUE) AS provider_quality_issue_count
FROM cleaned_providers_large;


-- ============================================================
-- 7. Admission flag distribution
-- ============================================================
-- Goal:
-- Count each individual admission quality flag.
-- This checks referential integrity, date issues and cost issues.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE has_missing_admission_id IS TRUE) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE has_missing_patient_id IS TRUE) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE has_unknown_patient_id IS TRUE) AS unknown_patient_id_count,
    COUNT(*) FILTER (WHERE has_missing_department_id IS TRUE) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE has_unknown_department_id IS TRUE) AS unknown_department_id_count,
    COUNT(*) FILTER (WHERE has_missing_provider_id IS TRUE) AS missing_provider_id_count,
    COUNT(*) FILTER (WHERE has_unknown_provider_id IS TRUE) AS unknown_provider_id_count,
    COUNT(*) FILTER (WHERE has_discharge_before_admission IS TRUE) AS discharge_before_admission_count,
    COUNT(*) FILTER (WHERE has_open_admission IS TRUE) AS open_admission_count,
    COUNT(*) FILTER (WHERE has_negative_total_cost IS TRUE) AS negative_total_cost_count,
    COUNT(*) FILTER (WHERE has_extreme_total_cost IS TRUE) AS extreme_total_cost_count,
    COUNT(*) FILTER (WHERE has_admission_quality_issue IS TRUE) AS admission_quality_issue_count
FROM cleaned_admissions_large;


-- ============================================================
-- 8. Lab result flag distribution
-- ============================================================
-- Goal:
-- Count each individual lab result quality flag.
-- This checks referential integrity, lab values and future dates.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE has_missing_lab_result_id IS TRUE) AS missing_lab_result_id_count,
    COUNT(*) FILTER (WHERE has_missing_admission_id IS TRUE) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE has_unknown_admission_id IS TRUE) AS unknown_admission_id_count,
    COUNT(*) FILTER (WHERE has_missing_patient_id IS TRUE) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE has_unknown_patient_id IS TRUE) AS unknown_patient_id_count,
    COUNT(*) FILTER (WHERE has_missing_test_name IS TRUE) AS missing_test_name_count,
    COUNT(*) FILTER (WHERE has_missing_result_value IS TRUE) AS missing_result_value_count,
    COUNT(*) FILTER (WHERE has_negative_result_value IS TRUE) AS negative_result_value_count,
    COUNT(*) FILTER (WHERE has_extreme_result_value IS TRUE) AS extreme_result_value_count,
    COUNT(*) FILTER (WHERE has_future_test_date IS TRUE) AS future_test_date_count,
    COUNT(*) FILTER (WHERE has_lab_result_quality_issue IS TRUE) AS lab_result_quality_issue_count
FROM cleaned_lab_results_large;


-- ============================================================
-- 9. Inspect patient records with quality issues
-- ============================================================
-- Goal:
-- Review patient records where at least one patient quality flag is TRUE.
-- This helps confirm that the flags point to understandable bad records.
-- ============================================================

SELECT
    patient_row_id,
    patient_id,
    patient_id_cleaned,
    birth_date,
    gender,
    gender_standardized,
    postcode,
    postcode_standardized,
    has_missing_patient_id,
    has_duplicate_patient_id,
    has_future_birth_date,
    has_unrealistic_birth_date,
    has_missing_gender,
    has_invalid_gender,
    has_missing_postcode,
    has_patient_quality_issue
FROM cleaned_patients_large
WHERE has_patient_quality_issue IS TRUE
ORDER BY patient_row_id
LIMIT 25;


-- ============================================================
-- 10. Inspect department records with quality issues
-- ============================================================
-- Goal:
-- Review department records where at least one department quality flag is TRUE.
-- ============================================================

SELECT
    department_row_id,
    department_id,
    department_id_cleaned,
    department_name,
    department_name_standardized,
    department_category,
    department_category_standardized,
    is_active,
    has_missing_department_id,
    has_missing_department_name,
    has_inactive_or_unknown_status,
    has_department_quality_issue
FROM cleaned_departments_large
WHERE has_department_quality_issue IS TRUE
ORDER BY department_row_id;


-- ============================================================
-- 11. Inspect provider records with quality issues
-- ============================================================
-- Goal:
-- Review provider records where at least one provider quality flag is TRUE.
-- ============================================================

SELECT
    provider_row_id,
    provider_id,
    provider_id_cleaned,
    provider_name,
    provider_name_standardized,
    department_id,
    department_id_cleaned,
    has_missing_provider_id,
    has_missing_department_id,
    has_unknown_department_id,
    has_invalid_active_period,
    has_provider_quality_issue
FROM cleaned_providers_large
WHERE has_provider_quality_issue IS TRUE
ORDER BY provider_row_id;


-- ============================================================
-- 12. Inspect admission records with quality issues
-- ============================================================
-- Goal:
-- Review admission records where at least one admission quality flag is TRUE.
-- ============================================================

SELECT
    admission_row_id,
    admission_id,
    admission_id_cleaned,
    patient_id,
    patient_id_cleaned,
    department_id,
    department_id_cleaned,
    provider_id,
    provider_id_cleaned,
    admission_date,
    discharge_date,
    total_cost,
    has_missing_admission_id,
    has_missing_patient_id,
    has_unknown_patient_id,
    has_missing_department_id,
    has_unknown_department_id,
    has_missing_provider_id,
    has_unknown_provider_id,
    has_discharge_before_admission,
    has_open_admission,
    has_negative_total_cost,
    has_extreme_total_cost,
    has_admission_quality_issue
FROM cleaned_admissions_large
WHERE has_admission_quality_issue IS TRUE
ORDER BY admission_row_id
LIMIT 50;


-- ============================================================
-- 13. Inspect lab result records with quality issues
-- ============================================================
-- Goal:
-- Review lab result records where at least one lab result quality flag is TRUE.
-- ============================================================

SELECT
    lab_result_row_id,
    lab_result_id,
    lab_result_id_cleaned,
    admission_id,
    admission_id_cleaned,
    patient_id,
    patient_id_cleaned,
    test_name,
    test_name_standardized,
    result_value,
    result_unit,
    result_unit_standardized,
    test_date,
    has_missing_lab_result_id,
    has_missing_admission_id,
    has_unknown_admission_id,
    has_missing_patient_id,
    has_unknown_patient_id,
    has_missing_test_name,
    has_missing_result_value,
    has_negative_result_value,
    has_extreme_result_value,
    has_future_test_date,
    has_lab_result_quality_issue
FROM cleaned_lab_results_large
WHERE has_lab_result_quality_issue IS TRUE
ORDER BY lab_result_row_id
LIMIT 50;


-- ============================================================
-- 14. Expected-vs-actual validation summary
-- ============================================================
-- Goal:
-- Compare actual cleaned layer issue counts against expected values
-- observed during this synthetic dataset build.
--
-- Why:
-- If the script returns PASS, the cleaned layer is still producing
-- the expected validation results.
-- ============================================================

WITH actual_counts AS (
    SELECT
        'patients_quality_issue_rows' AS check_name,
        COUNT(*) FILTER (WHERE has_patient_quality_issue IS TRUE) AS actual_count
    FROM cleaned_patients_large

    UNION ALL

    SELECT
        'departments_quality_issue_rows' AS check_name,
        COUNT(*) FILTER (WHERE has_department_quality_issue IS TRUE) AS actual_count
    FROM cleaned_departments_large

    UNION ALL

    SELECT
        'providers_quality_issue_rows' AS check_name,
        COUNT(*) FILTER (WHERE has_provider_quality_issue IS TRUE) AS actual_count
    FROM cleaned_providers_large

    UNION ALL

    SELECT
        'admissions_quality_issue_rows' AS check_name,
        COUNT(*) FILTER (WHERE has_admission_quality_issue IS TRUE) AS actual_count
    FROM cleaned_admissions_large

    UNION ALL

    SELECT
        'lab_results_quality_issue_rows' AS check_name,
        COUNT(*) FILTER (WHERE has_lab_result_quality_issue IS TRUE) AS actual_count
    FROM cleaned_lab_results_large
),

expected_counts AS (
    SELECT
        'patients_quality_issue_rows' AS check_name,
        31 AS expected_count

    UNION ALL

    SELECT
        'departments_quality_issue_rows' AS check_name,
        1 AS expected_count

    UNION ALL

    SELECT
        'providers_quality_issue_rows' AS check_name,
        2 AS expected_count

    UNION ALL

    SELECT
        'admissions_quality_issue_rows' AS check_name,
        55 AS expected_count

    UNION ALL

    SELECT
        'lab_results_quality_issue_rows' AS check_name,
        65 AS expected_count
)

SELECT
    e.check_name,
    e.expected_count,
    a.actual_count,
    CASE
        WHEN e.expected_count = a.actual_count THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM expected_counts e
LEFT JOIN actual_counts a
    ON e.check_name = a.check_name
ORDER BY e.check_name;