/*
===============================================================================
Feature Table Draft
Project: Healthcare Data Quality SQL Pipeline

Doel:
Eerste admission-level feature table op basis van curated patients en
curated admissions.

Belangrijk:
Dit is nog geen definitieve ML-dataset. De view is bedoeld als technische
voorbereiding op latere analyse en feature engineering.
===============================================================================
*/


CREATE OR REPLACE VIEW feature_admission_base AS
SELECT
    a.admission_id,
    a.patient_id,
    a.department_standardized,
    a.admission_date,
    a.discharge_date,

    (a.discharge_date - a.admission_date) AS length_of_stay_days,

    a.total_cost,

    p.gender_standardized,
    p.birth_date,

    DATE_PART('year', AGE(a.admission_date, p.birth_date)) AS age_at_admission,

    a.has_missing_department,
    a.has_negative_total_cost,
    p.has_unrealistic_age,
    p.has_invalid_gender_value

FROM curated_admissions a
LEFT JOIN curated_patients p
    ON a.patient_id = p.patient_id;