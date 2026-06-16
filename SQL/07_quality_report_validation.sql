/*
===============================================================================
Data Quality Report
Project: Healthcare Data Quality SQL Pipeline

Doel:
Dit script maakt een eerste samenvattend rapport van quality flags uit de
cleaned views.

Belangrijk:
De issue_count telt records waarbij een quality flag TRUE is.
Bij duplicate flags betekent dit dat alle betrokken duplicate records worden
geteld.

Severity:
- high: issue kan identificatie, koppelingen of tijdlogica ernstig verstoren.
- medium: issue is belangrijk, maar vraagt meestal aanvullende interpretatie
  of domeinvalidatie.
===============================================================================
*/


-- Report: Quality issue counts across cleaned views

SELECT
    'patients' AS entity,
    'has_missing_patient_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_missing_patient_id = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_duplicate_patient_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_duplicate_patient_id = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_future_birth_date' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_future_birth_date = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_unrealistic_age' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_unrealistic_age = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_invalid_gender_value' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_invalid_gender_value = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_duplicate_admission_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_duplicate_admission_id = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_unknown_patient_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_unknown_patient_id = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_invalid_admission_period' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_invalid_admission_period = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_missing_department' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_missing_department = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_negative_total_cost' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_negative_total_cost = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_duplicate_lab_result_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_duplicate_lab_result_id = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_unknown_patient_id' AS quality_check,
    'high' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_unknown_patient_id = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_missing_test_date' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_missing_test_date = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_future_test_date' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_future_test_date = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_invalid_result_value' AS quality_check,
    'medium' AS severity,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_invalid_result_value = TRUE

ORDER BY severity, entity, quality_check;


/*
===============================================================================
Quality Report Validation
Project: Healthcare Data Quality SQL Pipeline

Doel:
Deze query vergelijkt de huidige data quality report-resultaten met verwachte
uitkomsten voor de kleine synthetische dataset.

Dit voorkomt handmatig vergelijken van issue counts.
===============================================================================
*/


WITH expected_results AS (
    SELECT 'patients' AS entity, 'has_missing_patient_id' AS quality_check, 1 AS expected_issue_count
    UNION ALL
    SELECT 'patients', 'has_duplicate_patient_id', 2
    UNION ALL
    SELECT 'patients', 'has_future_birth_date', 1
    UNION ALL
    SELECT 'patients', 'has_unrealistic_age', 1
    UNION ALL
    SELECT 'patients', 'has_invalid_gender_value', 2

    UNION ALL
    SELECT 'admissions', 'has_duplicate_admission_id', 2
    UNION ALL
    SELECT 'admissions', 'has_unknown_patient_id', 3
    UNION ALL
    SELECT 'admissions', 'has_invalid_admission_period', 1
    UNION ALL
    SELECT 'admissions', 'has_missing_department', 1
    UNION ALL
    SELECT 'admissions', 'has_negative_total_cost', 1

    UNION ALL
    SELECT 'lab_results', 'has_duplicate_lab_result_id', 2
    UNION ALL
    SELECT 'lab_results', 'has_unknown_patient_id', 1
    UNION ALL
    SELECT 'lab_results', 'has_missing_test_date', 1
    UNION ALL
    SELECT 'lab_results', 'has_future_test_date', 0
    UNION ALL
    SELECT 'lab_results', 'has_invalid_result_value', 2
),

actual_results AS (
    SELECT
        'patients' AS entity,
        'has_missing_patient_id' AS quality_check,
        COUNT(*) AS actual_issue_count
    FROM cleaned_patients
    WHERE has_missing_patient_id = TRUE

    UNION ALL

    SELECT
        'patients',
        'has_duplicate_patient_id',
        COUNT(*)
    FROM cleaned_patients
    WHERE has_duplicate_patient_id = TRUE

    UNION ALL

    SELECT
        'patients',
        'has_future_birth_date',
        COUNT(*)
    FROM cleaned_patients
    WHERE has_future_birth_date = TRUE

    UNION ALL

    SELECT
        'patients',
        'has_unrealistic_age',
        COUNT(*)
    FROM cleaned_patients
    WHERE has_unrealistic_age = TRUE

    UNION ALL

    SELECT
        'patients',
        'has_invalid_gender_value',
        COUNT(*)
    FROM cleaned_patients
    WHERE has_invalid_gender_value = TRUE

    UNION ALL

    SELECT
        'admissions',
        'has_duplicate_admission_id',
        COUNT(*)
    FROM cleaned_admissions
    WHERE has_duplicate_admission_id = TRUE

    UNION ALL

    SELECT
        'admissions',
        'has_unknown_patient_id',
        COUNT(*)
    FROM cleaned_admissions
    WHERE has_unknown_patient_id = TRUE

    UNION ALL

    SELECT
        'admissions',
        'has_invalid_admission_period',
        COUNT(*)
    FROM cleaned_admissions
    WHERE has_invalid_admission_period = TRUE

    UNION ALL

    SELECT
        'admissions',
        'has_missing_department',
        COUNT(*)
    FROM cleaned_admissions
    WHERE has_missing_department = TRUE

    UNION ALL

    SELECT
        'admissions',
        'has_negative_total_cost',
        COUNT(*)
    FROM cleaned_admissions
    WHERE has_negative_total_cost = TRUE

    UNION ALL

    SELECT
        'lab_results',
        'has_duplicate_lab_result_id',
        COUNT(*)
    FROM cleaned_lab_results
    WHERE has_duplicate_lab_result_id = TRUE

    UNION ALL

    SELECT
        'lab_results',
        'has_unknown_patient_id',
        COUNT(*)
    FROM cleaned_lab_results
    WHERE has_unknown_patient_id = TRUE

    UNION ALL

    SELECT
        'lab_results',
        'has_missing_test_date',
        COUNT(*)
    FROM cleaned_lab_results
    WHERE has_missing_test_date = TRUE

    UNION ALL

    SELECT
        'lab_results',
        'has_future_test_date',
        COUNT(*)
    FROM cleaned_lab_results
    WHERE has_future_test_date = TRUE

    UNION ALL

    SELECT
        'lab_results',
        'has_invalid_result_value',
        COUNT(*)
    FROM cleaned_lab_results
    WHERE has_invalid_result_value = TRUE
)

SELECT
    e.entity,
    e.quality_check,
    e.expected_issue_count,
    a.actual_issue_count,
    CASE
        WHEN e.expected_issue_count = a.actual_issue_count THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM expected_results e
LEFT JOIN actual_results a
    ON e.entity = a.entity
   AND e.quality_check = a.quality_check
ORDER BY
    validation_status,
    e.entity,
    e.quality_check;