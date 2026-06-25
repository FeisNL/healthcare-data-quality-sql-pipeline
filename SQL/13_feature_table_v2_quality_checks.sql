/*
===============================================================================
Feature Table V2 Quality Checks
Project: Healthcare Data Quality SQL Pipeline

Doel:
Controleren of feature_admission_v2 de verwachte grain, row count en
feature-level quality flags bevat.

Deze checks controleren:
- row count
- admission-level grain
- missing patient features
- length_of_stay issues
- cost issues
- analysis readiness distribution
===============================================================================
*/

-- Check 1: row count
SELECT
    COUNT(*) AS row_count
FROM feature_admission_v2;

-- Check 2: duplicate admission_id check
SELECT
    admission_id,
    COUNT(*) AS record_count
FROM feature_admission_v2
GROUP BY admission_id
HAVING COUNT(*) > 1;

-- Check 3: records with missing patient features
SELECT
    admission_id,
    patient_id,
    gender_standardized,
    birth_date,
    age_at_admission,
    has_missing_patient_features
FROM feature_admission_v2
WHERE has_missing_patient_features = TRUE;

-- Check 4: records with length_of_stay issues
SELECT
    admission_id,
    admission_date,
    discharge_date,
    length_of_stay_days,
    has_length_of_stay_issue
FROM feature_admission_v2
WHERE has_length_of_stay_issue = TRUE;

-- Check 5: records with cost issues
SELECT
    admission_id,
    patient_id,
    total_cost,
    has_negative_total_cost,
    has_cost_issue
FROM feature_admission_v2
WHERE has_cost_issue = TRUE;

-- Check 6: analysis readiness distribution
SELECT
    is_analysis_ready,
    COUNT(*) AS record_count
FROM feature_admission_v2
GROUP BY is_analysis_ready
ORDER BY is_analysis_ready;

-- Check 7: compact feature table quality profile
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN has_missing_patient_features = TRUE THEN 1 ELSE 0 END) AS missing_patient_feature_count,
    SUM(CASE WHEN has_length_of_stay_issue = TRUE THEN 1 ELSE 0 END) AS length_of_stay_issue_count,
    SUM(CASE WHEN has_cost_issue = TRUE THEN 1 ELSE 0 END) AS cost_issue_count,
    SUM(CASE WHEN is_analysis_ready = TRUE THEN 1 ELSE 0 END) AS analysis_ready_count
FROM feature_admission_v2;