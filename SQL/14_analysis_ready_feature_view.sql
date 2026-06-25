/*
===============================================================================
Analysis Ready Feature View
Project: Healthcare Data Quality SQL Pipeline

Doel:
Een eerste analysegerichte subset maken op basis van feature_admission_v2.

Deze view bevat alleen records die volgens de huidige feature-level regels
analysis-ready zijn.

Belangrijk:
Analysis-ready betekent niet dat de data perfect of ML-ready is. Het betekent
alleen dat het record voldoet aan de gekozen regels voor eerste technische
analyse.
===============================================================================
*/

CREATE OR REPLACE VIEW feature_admission_analysis_ready AS
SELECT
    admission_id,
    patient_id,
    department_standardized,
    admission_date,
    discharge_date,
    length_of_stay_days,
    total_cost,
    gender_standardized,
    age_at_admission,
    is_analysis_ready
FROM feature_admission_v2
WHERE is_analysis_ready = TRUE;

-- Check 1: row count of the analysis-ready view
SELECT
    COUNT(*) AS row_count
FROM feature_admission_analysis_ready;

-- Check 2: verify that all records in the view are analysis-ready
SELECT
    is_analysis_ready,
    COUNT(*) AS record_count
FROM feature_admission_analysis_ready
GROUP BY is_analysis_ready
ORDER BY is_analysis_ready DESC;

-- Check 3: verify that admission_id remains unique
SELECT
    admission_id,
    COUNT(*) AS record_count
FROM feature_admission_analysis_ready
GROUP BY admission_id
HAVING COUNT(*) > 1;

-- Check 4: show records rejected from the analysis-ready view and their flags
SELECT
    admission_id,
    patient_id,
    has_missing_patient_features,
    has_length_of_stay_issue,
    has_cost_issue,
    is_analysis_ready
FROM feature_admission_v2
WHERE is_analysis_ready = FALSE
ORDER BY admission_id;

-- Check 5: compact rejected-reason audit
-- Note: if a record has multiple issues, this CASE returns the first matching issue.
SELECT
    admission_id,
    patient_id,
    CASE
        WHEN has_missing_patient_features = TRUE THEN 'missing_patient_features'
        WHEN has_length_of_stay_issue = TRUE THEN 'length_of_stay_issue'
        WHEN has_cost_issue = TRUE THEN 'cost_issue'
        ELSE 'unknown'
    END AS rejection_reason
FROM feature_admission_v2
WHERE is_analysis_ready = FALSE
ORDER BY admission_id;

-- Check 6: severity of the main rejection reason per admission_id
-- Note: this severity is based on the first matching issue in the CASE order.
SELECT
    admission_id,
    patient_id,
    CASE
        WHEN has_missing_patient_features = TRUE THEN 'missing_patient_features'
        WHEN has_length_of_stay_issue = TRUE THEN 'length_of_stay_issue'
        WHEN has_cost_issue = TRUE THEN 'cost_issue'
        ELSE 'unknown'
    END AS rejection_reason,
    CASE
        WHEN has_missing_patient_features = TRUE THEN 'high'
        WHEN has_length_of_stay_issue = TRUE THEN 'medium'
        WHEN has_cost_issue = TRUE THEN 'medium'
        ELSE 'unknown'
    END AS rejection_severity
FROM feature_admission_v2
WHERE is_analysis_ready = FALSE
ORDER BY admission_id;

-- Check 7: issue count per rejection reason
WITH rejected_records AS (
    SELECT
        admission_id,
        CASE
            WHEN has_missing_patient_features = TRUE THEN 'missing_patient_features'
            WHEN has_length_of_stay_issue = TRUE THEN 'length_of_stay_issue'
            WHEN has_cost_issue = TRUE THEN 'cost_issue'
            ELSE 'unknown'
        END AS rejection_reason
    FROM feature_admission_v2
    WHERE is_analysis_ready = FALSE
)
SELECT
    rejection_reason,
    COUNT(*) AS record_count
FROM rejected_records
GROUP BY rejection_reason
ORDER BY record_count DESC, rejection_reason;