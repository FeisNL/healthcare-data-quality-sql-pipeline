/*
===============================================================================
Feature Table V2
Project: Healthcare Data Quality SQL Pipeline

Doel:
Feature table v2 voegt feature-level quality flags toe aan
feature_admission_base. Hiermee worden ontbrekende patient features,
ligduurproblemen en kostenproblemen expliciet zichtbaar gemaakt.

Belangrijk:
Deze view is nog geen definitieve ML-dataset. De view is bedoeld als
analysevoorbereiding en als oefening in betrouwbare feature engineering.
===============================================================================
*/

ALTER VIEW feature_admission_v2
RENAME COLUMN has_length__of_stay_issue to has_length_of_stay_issue

CREATE OR REPLACE VIEW feature_admission_v2 AS
WITH feature_flags AS (
    SELECT
        admission_id,
        patient_id,
        department_standardized,
        admission_date,
        discharge_date,
        length_of_stay_days,
        total_cost,
        gender_standardized,
        birth_date,
        age_at_admission,
        has_missing_department,
        has_negative_total_cost,
        has_unrealistic_age,
        has_invalid_gender_value,

        CASE
            WHEN gender_standardized IS NULL
              OR birth_date IS NULL
              OR age_at_admission IS NULL
            THEN TRUE
            ELSE FALSE
        END AS has_missing_patient_features,

        CASE
            WHEN length_of_stay_days IS NULL
              OR length_of_stay_days < 0
            THEN TRUE
            ELSE FALSE
        END AS has_length_of_stay_issue,

        CASE
            WHEN has_negative_total_cost = TRUE
              OR total_cost >= 100000
            THEN TRUE
            ELSE FALSE
        END AS has_cost_issue

    FROM feature_admission_base
)
SELECT
    *,
    CASE
        WHEN has_missing_patient_features = FALSE
          AND has_length_of_stay_issue = FALSE
          AND has_cost_issue = FALSE
        THEN TRUE
        ELSE FALSE
    END AS is_analysis_ready
FROM feature_flags;

-- meta data query: checking if column names are correct
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'feature_admission_v2'
ORDER BY ordinal_position;

SELECT COUNT(*)
FROM feature_admission_v2;

SELECT
    is_analysis_ready,
    COUNT(*) AS record_count
FROM feature_admission_v2
GROUP BY is_analysis_ready
ORDER BY is_analysis_ready;

SELECT
    admission_id,
    has_missing_patient_features,
    has_length_of_stay_issue,
    has_cost_issue,
    is_analysis_ready
FROM feature_admission_v2
ORDER BY admission_id;

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN has_missing_patient_features = TRUE THEN 1 ELSE 0 END) AS missing_patient_feature_count,
    SUM(CASE WHEN has_length_of_stay_issue = TRUE THEN 1 ELSE 0 END) AS length_of_stay_issue_count,
    SUM(CASE WHEN has_cost_issue = TRUE THEN 1 ELSE 0 END) AS cost_issue_count,
    SUM(CASE WHEN is_analysis_ready = TRUE THEN 1 ELSE 0 END) AS analysis_ready_count
FROM feature_admission_v2;