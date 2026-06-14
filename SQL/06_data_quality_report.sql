-- Report: Quality issue counts across cleaned views

SELECT
    'patients' AS entity,
    'has_missing_patient_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_missing_patient_id = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_duplicate_patient_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_duplicate_patient_id = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_future_birth_date' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_future_birth_date = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_unrealistic_age' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_unrealistic_age = TRUE

UNION ALL

SELECT
    'patients' AS entity,
    'has_invalid_gender_value' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_patients
WHERE has_invalid_gender_value = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_duplicate_admission_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_duplicate_admission_id = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_unknown_patient_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_unknown_patient_id = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_invalid_admission_period' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_invalid_admission_period = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_missing_department' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_missing_department = TRUE

UNION ALL

SELECT
    'admissions' AS entity,
    'has_negative_total_cost' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_admissions
WHERE has_negative_total_cost = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_duplicate_lab_result_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_duplicate_lab_result_id = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_unknown_patient_id' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_unknown_patient_id = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_missing_test_date' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_missing_test_date = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_future_test_date' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_future_test_date = TRUE

UNION ALL

SELECT
    'lab_results' AS entity,
    'has_invalid_result_value' AS quality_check,
    COUNT(*) AS issue_count
FROM cleaned_lab_results
WHERE has_invalid_result_value = TRUE

ORDER BY entity, quality_check;