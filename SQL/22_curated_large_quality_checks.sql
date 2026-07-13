-- ============================================================
-- Script: 22_curated_large_quality_checks.sql
-- Purpose: Validate the curated analysis-ready views for the large healthcare dataset.
-- Layer: curated validation
--
-- This script checks:
-- 1. whether all curated views exist
-- 2. cleaned vs curated row counts
-- 3. rejected row counts
-- 4. whether curated views still contain own quality issues
-- 5. whether child records link to curated parent/reference records
-- 6. expected-vs-actual validation results
-- 7. sample rejected admissions with parent/join diagnostics
-- 8. sample rejected lab results with parent/join diagnostics
--
-- Design principle:
-- Curated views may contain fewer rows than cleaned views.
-- Rejected records are not deleted; they remain traceable in the cleaned layer.
-- ============================================================


-- ============================================================
-- 1. Verify that all curated views exist
-- ============================================================
-- Purpose:
-- Confirm that the curated layer has all expected analysis-ready views.
-- ============================================================

SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'curated_patients_large',
      'curated_departments_large',
      'curated_providers_large',
      'curated_admissions_large',
      'curated_lab_results_large'
  )
ORDER BY table_name;


-- ============================================================
-- 2. Cleaned vs curated row counts
-- ============================================================
-- Purpose:
-- Compare cleaned row counts with curated row counts.
--
-- Interpretation:
-- The rejected_row_count shows how many records were excluded from
-- the curated analysis-ready layer.
-- ============================================================

SELECT
    'patients' AS dataset,
    (SELECT COUNT(*) FROM cleaned_patients_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM curated_patients_large) AS curated_row_count,
    (SELECT COUNT(*) FROM cleaned_patients_large)
        -
    (SELECT COUNT(*) FROM curated_patients_large) AS rejected_row_count,
    ROUND(
        100.0
        * (
            (SELECT COUNT(*) FROM cleaned_patients_large)
                -
            (SELECT COUNT(*) FROM curated_patients_large)
        )
        / NULLIF((SELECT COUNT(*) FROM cleaned_patients_large), 0),
        2
    ) AS rejected_percentage

UNION ALL

SELECT
    'departments' AS dataset,
    (SELECT COUNT(*) FROM cleaned_departments_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM curated_departments_large) AS curated_row_count,
    (SELECT COUNT(*) FROM cleaned_departments_large)
        -
    (SELECT COUNT(*) FROM curated_departments_large) AS rejected_row_count,
    ROUND(
        100.0
        * (
            (SELECT COUNT(*) FROM cleaned_departments_large)
                -
            (SELECT COUNT(*) FROM curated_departments_large)
        )
        / NULLIF((SELECT COUNT(*) FROM cleaned_departments_large), 0),
        2
    ) AS rejected_percentage

UNION ALL

SELECT
    'providers' AS dataset,
    (SELECT COUNT(*) FROM cleaned_providers_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM curated_providers_large) AS curated_row_count,
    (SELECT COUNT(*) FROM cleaned_providers_large)
        -
    (SELECT COUNT(*) FROM curated_providers_large) AS rejected_row_count,
    ROUND(
        100.0
        * (
            (SELECT COUNT(*) FROM cleaned_providers_large)
                -
            (SELECT COUNT(*) FROM curated_providers_large)
        )
        / NULLIF((SELECT COUNT(*) FROM cleaned_providers_large), 0),
        2
    ) AS rejected_percentage

UNION ALL

SELECT
    'admissions' AS dataset,
    (SELECT COUNT(*) FROM cleaned_admissions_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM curated_admissions_large) AS curated_row_count,
    (SELECT COUNT(*) FROM cleaned_admissions_large)
        -
    (SELECT COUNT(*) FROM curated_admissions_large) AS rejected_row_count,
    ROUND(
        100.0
        * (
            (SELECT COUNT(*) FROM cleaned_admissions_large)
                -
            (SELECT COUNT(*) FROM curated_admissions_large)
        )
        / NULLIF((SELECT COUNT(*) FROM cleaned_admissions_large), 0),
        2
    ) AS rejected_percentage

UNION ALL

SELECT
    'lab_results' AS dataset,
    (SELECT COUNT(*) FROM cleaned_lab_results_large) AS cleaned_row_count,
    (SELECT COUNT(*) FROM curated_lab_results_large) AS curated_row_count,
    (SELECT COUNT(*) FROM cleaned_lab_results_large)
        -
    (SELECT COUNT(*) FROM curated_lab_results_large) AS rejected_row_count,
    ROUND(
        100.0
        * (
            (SELECT COUNT(*) FROM cleaned_lab_results_large)
                -
            (SELECT COUNT(*) FROM curated_lab_results_large)
        )
        / NULLIF((SELECT COUNT(*) FROM cleaned_lab_results_large), 0),
        2
    ) AS rejected_percentage

ORDER BY dataset;


-- ============================================================
-- 3. Rejected record summary
-- ============================================================
-- Purpose:
-- Show whether records were rejected because of their own quality issue
-- or because they no longer link to a curated parent/reference record.
--
-- Important:
-- For admissions and lab results, rejected_row_count can be higher than
-- the own quality issue count because curated views also require curated
-- parent/reference records.
-- ============================================================

SELECT
    'patients' AS dataset,
    COUNT(*) FILTER (WHERE cur.patient_row_id IS NULL) AS total_rejected_count,
    COUNT(*) FILTER (
        WHERE cur.patient_row_id IS NULL
          AND cln.has_patient_quality_issue IS TRUE
    ) AS rejected_with_own_quality_issue_count,
    COUNT(*) FILTER (
        WHERE cur.patient_row_id IS NULL
          AND cln.has_patient_quality_issue IS NOT TRUE
    ) AS rejected_due_to_parent_or_join_rule_count
FROM cleaned_patients_large cln
LEFT JOIN curated_patients_large cur
    ON cln.patient_row_id = cur.patient_row_id

UNION ALL

SELECT
    'departments' AS dataset,
    COUNT(*) FILTER (WHERE cur.department_row_id IS NULL) AS total_rejected_count,
    COUNT(*) FILTER (
        WHERE cur.department_row_id IS NULL
          AND cln.has_department_quality_issue IS TRUE
    ) AS rejected_with_own_quality_issue_count,
    COUNT(*) FILTER (
        WHERE cur.department_row_id IS NULL
          AND cln.has_department_quality_issue IS NOT TRUE
    ) AS rejected_due_to_parent_or_join_rule_count
FROM cleaned_departments_large cln
LEFT JOIN curated_departments_large cur
    ON cln.department_row_id = cur.department_row_id

UNION ALL

SELECT
    'providers' AS dataset,
    COUNT(*) FILTER (WHERE cur.provider_row_id IS NULL) AS total_rejected_count,
    COUNT(*) FILTER (
        WHERE cur.provider_row_id IS NULL
          AND cln.has_provider_quality_issue IS TRUE
    ) AS rejected_with_own_quality_issue_count,
    COUNT(*) FILTER (
        WHERE cur.provider_row_id IS NULL
          AND cln.has_provider_quality_issue IS NOT TRUE
    ) AS rejected_due_to_parent_or_join_rule_count
FROM cleaned_providers_large cln
LEFT JOIN curated_providers_large cur
    ON cln.provider_row_id = cur.provider_row_id

UNION ALL

SELECT
    'admissions' AS dataset,
    COUNT(*) FILTER (WHERE cur.admission_row_id IS NULL) AS total_rejected_count,
    COUNT(*) FILTER (
        WHERE cur.admission_row_id IS NULL
          AND cln.has_admission_quality_issue IS TRUE
    ) AS rejected_with_own_quality_issue_count,
    COUNT(*) FILTER (
        WHERE cur.admission_row_id IS NULL
          AND cln.has_admission_quality_issue IS NOT TRUE
    ) AS rejected_due_to_parent_or_join_rule_count
FROM cleaned_admissions_large cln
LEFT JOIN curated_admissions_large cur
    ON cln.admission_row_id = cur.admission_row_id

UNION ALL

SELECT
    'lab_results' AS dataset,
    COUNT(*) FILTER (WHERE cur.lab_result_row_id IS NULL) AS total_rejected_count,
    COUNT(*) FILTER (
        WHERE cur.lab_result_row_id IS NULL
          AND cln.has_lab_result_quality_issue IS TRUE
    ) AS rejected_with_own_quality_issue_count,
    COUNT(*) FILTER (
        WHERE cur.lab_result_row_id IS NULL
          AND cln.has_lab_result_quality_issue IS NOT TRUE
    ) AS rejected_due_to_parent_or_join_rule_count
FROM cleaned_lab_results_large cln
LEFT JOIN curated_lab_results_large cur
    ON cln.lab_result_row_id = cur.lab_result_row_id

ORDER BY dataset;


-- ============================================================
-- 4. Verify that curated records do not contain own quality issues
-- ============================================================
-- Purpose:
-- A curated record should not still have the quality issue flag that
-- belongs to its own entity/view.
--
-- Expected result:
-- All issue counts should be 0.
-- ============================================================

SELECT
    'patients' AS dataset,
    COUNT(*) AS curated_records_with_own_quality_issue_count
FROM curated_patients_large cur
JOIN cleaned_patients_large cln
    ON cur.patient_row_id = cln.patient_row_id
WHERE cln.has_patient_quality_issue IS TRUE

UNION ALL

SELECT
    'departments' AS dataset,
    COUNT(*) AS curated_records_with_own_quality_issue_count
FROM curated_departments_large cur
JOIN cleaned_departments_large cln
    ON cur.department_row_id = cln.department_row_id
WHERE cln.has_department_quality_issue IS TRUE

UNION ALL

SELECT
    'providers' AS dataset,
    COUNT(*) AS curated_records_with_own_quality_issue_count
FROM curated_providers_large cur
JOIN cleaned_providers_large cln
    ON cur.provider_row_id = cln.provider_row_id
WHERE cln.has_provider_quality_issue IS TRUE

UNION ALL

SELECT
    'admissions' AS dataset,
    COUNT(*) AS curated_records_with_own_quality_issue_count
FROM curated_admissions_large cur
JOIN cleaned_admissions_large cln
    ON cur.admission_row_id = cln.admission_row_id
WHERE cln.has_admission_quality_issue IS TRUE

UNION ALL

SELECT
    'lab_results' AS dataset,
    COUNT(*) AS curated_records_with_own_quality_issue_count
FROM curated_lab_results_large cur
JOIN cleaned_lab_results_large cln
    ON cur.lab_result_row_id = cln.lab_result_row_id
WHERE cln.has_lab_result_quality_issue IS TRUE

ORDER BY dataset;


-- ============================================================
-- 5. Verify curated child records link to curated parent records
-- ============================================================
-- Purpose:
-- Confirm that curated admissions and lab results do not point to
-- parent/reference records that were excluded from the curated layer.
--
-- Expected result:
-- All missing parent counts should be 0.
-- ============================================================

SELECT
    'curated_admissions_without_curated_patient' AS validation_check,
    COUNT(*) AS issue_count
FROM curated_admissions_large ca
LEFT JOIN curated_patients_large cp
    ON ca.patient_id = cp.patient_id
WHERE cp.patient_id IS NULL

UNION ALL

SELECT
    'curated_admissions_without_curated_department' AS validation_check,
    COUNT(*) AS issue_count
FROM curated_admissions_large ca
LEFT JOIN curated_departments_large cd
    ON ca.department_id = cd.department_id
WHERE cd.department_id IS NULL

UNION ALL

SELECT
    'curated_admissions_without_curated_provider' AS validation_check,
    COUNT(*) AS issue_count
FROM curated_admissions_large ca
LEFT JOIN curated_providers_large cpr
    ON ca.provider_id = cpr.provider_id
WHERE cpr.provider_id IS NULL

UNION ALL

SELECT
    'curated_lab_results_without_curated_admission' AS validation_check,
    COUNT(*) AS issue_count
FROM curated_lab_results_large clr
LEFT JOIN curated_admissions_large ca
    ON clr.admission_id = ca.admission_id
WHERE ca.admission_id IS NULL

UNION ALL

SELECT
    'curated_lab_results_without_curated_patient' AS validation_check,
    COUNT(*) AS issue_count
FROM curated_lab_results_large clr
LEFT JOIN curated_patients_large cp
    ON clr.patient_id = cp.patient_id
WHERE cp.patient_id IS NULL

ORDER BY validation_check;


-- ============================================================
-- 6. Expected-vs-actual validation summary
-- ============================================================
-- Purpose:
-- Turn the most important curated layer checks into PASS/FAIL output.
--
-- Why this matters:
-- This makes the data pipeline easier to review, rerun and trust.
-- ============================================================

WITH actual_row_counts AS (

    SELECT
        'patients' AS dataset,
        (SELECT COUNT(*) FROM cleaned_patients_large) AS actual_cleaned_row_count,
        (SELECT COUNT(*) FROM curated_patients_large) AS actual_curated_row_count,
        (SELECT COUNT(*) FROM cleaned_patients_large)
            -
        (SELECT COUNT(*) FROM curated_patients_large) AS actual_rejected_row_count

    UNION ALL

    SELECT
        'departments' AS dataset,
        (SELECT COUNT(*) FROM cleaned_departments_large) AS actual_cleaned_row_count,
        (SELECT COUNT(*) FROM curated_departments_large) AS actual_curated_row_count,
        (SELECT COUNT(*) FROM cleaned_departments_large)
            -
        (SELECT COUNT(*) FROM curated_departments_large) AS actual_rejected_row_count

    UNION ALL

    SELECT
        'providers' AS dataset,
        (SELECT COUNT(*) FROM cleaned_providers_large) AS actual_cleaned_row_count,
        (SELECT COUNT(*) FROM curated_providers_large) AS actual_curated_row_count,
        (SELECT COUNT(*) FROM cleaned_providers_large)
            -
        (SELECT COUNT(*) FROM curated_providers_large) AS actual_rejected_row_count

    UNION ALL

    SELECT
        'admissions' AS dataset,
        (SELECT COUNT(*) FROM cleaned_admissions_large) AS actual_cleaned_row_count,
        (SELECT COUNT(*) FROM curated_admissions_large) AS actual_curated_row_count,
        (SELECT COUNT(*) FROM cleaned_admissions_large)
            -
        (SELECT COUNT(*) FROM curated_admissions_large) AS actual_rejected_row_count

    UNION ALL

    SELECT
        'lab_results' AS dataset,
        (SELECT COUNT(*) FROM cleaned_lab_results_large) AS actual_cleaned_row_count,
        (SELECT COUNT(*) FROM curated_lab_results_large) AS actual_curated_row_count,
        (SELECT COUNT(*) FROM cleaned_lab_results_large)
            -
        (SELECT COUNT(*) FROM curated_lab_results_large) AS actual_rejected_row_count
),

expected_row_counts AS (

    SELECT
        *
    FROM (
        VALUES
            ('patients', 1000, 969, 31),
            ('departments', 8, 7, 1),
            ('providers', 50, 48, 2),
            ('admissions', 2000, 1635, 365),
            ('lab_results', 5000, 4079, 921)
    ) AS expected(
        dataset,
        expected_cleaned_row_count,
        expected_curated_row_count,
        expected_rejected_row_count
    )
),

row_count_validation AS (

    SELECT
        'row_count_' || expected.dataset AS validation_check,
        expected.expected_cleaned_row_count::TEXT
            || ' cleaned / '
            || expected.expected_curated_row_count::TEXT
            || ' curated / '
            || expected.expected_rejected_row_count::TEXT
            || ' rejected' AS expected_result,
        actual.actual_cleaned_row_count::TEXT
            || ' cleaned / '
            || actual.actual_curated_row_count::TEXT
            || ' curated / '
            || actual.actual_rejected_row_count::TEXT
            || ' rejected' AS actual_result,
        CASE
            WHEN actual.actual_cleaned_row_count = expected.expected_cleaned_row_count
             AND actual.actual_curated_row_count = expected.expected_curated_row_count
             AND actual.actual_rejected_row_count = expected.expected_rejected_row_count
            THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status
    FROM expected_row_counts expected
    JOIN actual_row_counts actual
        ON expected.dataset = actual.dataset
),

actual_zero_checks AS (

    SELECT
        'curated_patients_with_own_quality_issue' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_patients_large cur
    JOIN cleaned_patients_large cln
        ON cur.patient_row_id = cln.patient_row_id
    WHERE cln.has_patient_quality_issue IS TRUE

    UNION ALL

    SELECT
        'curated_departments_with_own_quality_issue' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_departments_large cur
    JOIN cleaned_departments_large cln
        ON cur.department_row_id = cln.department_row_id
    WHERE cln.has_department_quality_issue IS TRUE

    UNION ALL

    SELECT
        'curated_providers_with_own_quality_issue' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_providers_large cur
    JOIN cleaned_providers_large cln
        ON cur.provider_row_id = cln.provider_row_id
    WHERE cln.has_provider_quality_issue IS TRUE

    UNION ALL

    SELECT
        'curated_admissions_with_own_quality_issue' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_admissions_large cur
    JOIN cleaned_admissions_large cln
        ON cur.admission_row_id = cln.admission_row_id
    WHERE cln.has_admission_quality_issue IS TRUE

    UNION ALL

    SELECT
        'curated_lab_results_with_own_quality_issue' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_lab_results_large cur
    JOIN cleaned_lab_results_large cln
        ON cur.lab_result_row_id = cln.lab_result_row_id
    WHERE cln.has_lab_result_quality_issue IS TRUE

    UNION ALL

    SELECT
        'curated_admissions_without_curated_patient' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_admissions_large ca
    LEFT JOIN curated_patients_large cp
        ON ca.patient_id = cp.patient_id
    WHERE cp.patient_id IS NULL

    UNION ALL

    SELECT
        'curated_admissions_without_curated_department' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_admissions_large ca
    LEFT JOIN curated_departments_large cd
        ON ca.department_id = cd.department_id
    WHERE cd.department_id IS NULL

    UNION ALL

    SELECT
        'curated_admissions_without_curated_provider' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_admissions_large ca
    LEFT JOIN curated_providers_large cpr
        ON ca.provider_id = cpr.provider_id
    WHERE cpr.provider_id IS NULL

    UNION ALL

    SELECT
        'curated_lab_results_without_curated_admission' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_lab_results_large clr
    LEFT JOIN curated_admissions_large ca
        ON clr.admission_id = ca.admission_id
    WHERE ca.admission_id IS NULL

    UNION ALL

    SELECT
        'curated_lab_results_without_curated_patient' AS validation_check,
        COUNT(*) AS actual_issue_count
    FROM curated_lab_results_large clr
    LEFT JOIN curated_patients_large cp
        ON clr.patient_id = cp.patient_id
    WHERE cp.patient_id IS NULL
),

expected_zero_checks AS (

    SELECT
        *
    FROM (
        VALUES
            ('curated_patients_with_own_quality_issue', 0),
            ('curated_departments_with_own_quality_issue', 0),
            ('curated_providers_with_own_quality_issue', 0),
            ('curated_admissions_with_own_quality_issue', 0),
            ('curated_lab_results_with_own_quality_issue', 0),
            ('curated_admissions_without_curated_patient', 0),
            ('curated_admissions_without_curated_department', 0),
            ('curated_admissions_without_curated_provider', 0),
            ('curated_lab_results_without_curated_admission', 0),
            ('curated_lab_results_without_curated_patient', 0)
    ) AS expected(
        validation_check,
        expected_issue_count
    )
),

zero_check_validation AS (

    SELECT
        expected.validation_check,
        expected.expected_issue_count::TEXT AS expected_result,
        actual.actual_issue_count::TEXT AS actual_result,
        CASE
            WHEN actual.actual_issue_count = expected.expected_issue_count
            THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status
    FROM expected_zero_checks expected
    JOIN actual_zero_checks actual
        ON expected.validation_check = actual.validation_check
)

SELECT
    validation_check,
    expected_result,
    actual_result,
    validation_status
FROM row_count_validation

UNION ALL

SELECT
    validation_check,
    expected_result,
    actual_result,
    validation_status
FROM zero_check_validation

ORDER BY validation_check;


-- ============================================================
-- 7. Inspect rejected admission records
-- ============================================================
-- Purpose:
-- Review a sample of admissions that did not enter the curated layer.
--
-- This helps explain whether records were rejected because of their own
-- quality issue or because a patient, department or provider was not curated.
-- ============================================================

SELECT
    cln.admission_row_id,
    cln.admission_id_cleaned,
    cln.patient_id_cleaned,
    cln.department_id_cleaned,
    cln.provider_id_cleaned,

    -- Own admission-level quality issue
    cln.has_admission_quality_issue,

    -- Specific admission-level flags
    cln.has_unknown_patient_id,
    cln.has_unknown_department_id,
    cln.has_unknown_provider_id,
    cln.has_open_admission,
    cln.has_negative_total_cost,
    cln.has_extreme_total_cost,

    -- Parent/join rule diagnostics
    CASE
        WHEN cp.patient_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_curated_patient,

    CASE
        WHEN cd.department_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_curated_department,

    CASE
        WHEN cpr.provider_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_curated_provider

FROM cleaned_admissions_large cln

LEFT JOIN curated_admissions_large cur
    ON cln.admission_row_id = cur.admission_row_id

LEFT JOIN curated_patients_large cp
    ON cln.patient_id_cleaned = cp.patient_id

LEFT JOIN curated_departments_large cd
    ON cln.department_id_cleaned = cd.department_id

LEFT JOIN curated_providers_large cpr
    ON cln.provider_id_cleaned = cpr.provider_id

WHERE cur.admission_row_id IS NULL
ORDER BY cln.admission_row_id
LIMIT 25;

-- ============================================================
-- 8. Inspect rejected lab result records
-- ============================================================
-- Purpose:
-- Review a sample of lab results that did not enter the curated layer.
--
-- This helps explain whether records were rejected because of their own
-- quality issue or because their admission or patient was not curated.
-- ============================================================

SELECT
    cln.lab_result_row_id,
    cln.lab_result_id_cleaned,
    cln.admission_id_cleaned,
    cln.patient_id_cleaned,
    cln.test_name_standardized,
    cln.result_value,
    cln.result_unit_standardized,
    cln.test_date,

    -- Own lab-result-level quality issue
    cln.has_lab_result_quality_issue,

    -- Specific lab-result-level flags
    cln.has_unknown_admission_id,
    cln.has_unknown_patient_id,
    cln.has_negative_result_value,
    cln.has_extreme_result_value,
    cln.has_future_test_date,

    -- Parent/join rule diagnostics
    CASE
        WHEN ca.admission_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_curated_admission,

    CASE
        WHEN cp.patient_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_curated_patient

FROM cleaned_lab_results_large cln

LEFT JOIN curated_lab_results_large cur
    ON cln.lab_result_row_id = cur.lab_result_row_id

LEFT JOIN curated_admissions_large ca
    ON cln.admission_id_cleaned = ca.admission_id

LEFT JOIN curated_patients_large cp
    ON cln.patient_id_cleaned = cp.patient_id

WHERE cur.lab_result_row_id IS NULL
ORDER BY cln.lab_result_row_id
LIMIT 25;