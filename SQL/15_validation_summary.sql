-- Validation summary for feature_admission_v2
-- Purpose: central place for expected counts used to validate Python CSV output.

SELECT
    'feature_admission_v2_row_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2

UNION ALL

SELECT
    'is_analysis_ready_true_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2
WHERE is_analysis_ready = TRUE

UNION ALL

SELECT
    'is_analysis_ready_false_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2
WHERE is_analysis_ready = FALSE

UNION ALL

SELECT
    'has_missing_patient_features_true_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2
WHERE has_missing_patient_features = TRUE

UNION ALL

SELECT
    'has_length_of_stay_issue_true_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2
WHERE has_length_of_stay_issue = TRUE

UNION ALL

SELECT
    'has_cost_issue_true_count' AS check_name,
    COUNT(*) AS check_value
FROM feature_admission_v2
WHERE has_cost_issue = TRUE;