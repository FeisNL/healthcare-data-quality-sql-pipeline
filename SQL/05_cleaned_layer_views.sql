/*
===============================================================================
Cleaned Layer Views
Project: Healthcare Data Quality SQL Pipeline

Doel:
Deze views vormen de eerste cleaned layer bovenop de raw tabellen.
De raw data blijft behouden. In de cleaned layer worden waarden
gestandaardiseerd en worden quality flags toegevoegd.
===============================================================================
*/


-- View 1: cleaned_patients
-- Doel:
-- Deze view maakt een gestandaardiseerde patiëntlaag bovenop de raw patients-tabel.
-- De originele patients-tabel blijft ongewijzigd.
-- De view voegt gender_standardized en meerdere quality flags toe.

CREATE OR REPLACE VIEW cleaned_patients AS
WITH duplicate_patients AS (
    SELECT 
        patient_id
    FROM patients
    WHERE patient_id IS NOT NULL
      AND TRIM(patient_id) <> ''
    GROUP BY patient_id
    HAVING COUNT(*) > 1
)
SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    p.birth_date,

    CASE
        WHEN p.gender = 'male' THEN 'M'
        WHEN p.gender IN ('M', 'F') THEN p.gender
        ELSE NULL
    END AS gender_standardized,

    p.postcode,
    p.registration_date,

    CASE
        WHEN p.patient_id IS NULL OR TRIM(p.patient_id) = '' THEN TRUE
        ELSE FALSE
    END AS has_missing_patient_id,

    CASE
        WHEN dp.patient_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_duplicate_patient_id,

    CASE
        WHEN p.birth_date > CURRENT_DATE THEN TRUE
        ELSE FALSE
    END AS has_future_birth_date,

    CASE
        WHEN p.birth_date < CURRENT_DATE - INTERVAL '120 years' THEN TRUE
        ELSE FALSE
    END AS has_unrealistic_age,

    CASE
        WHEN p.gender NOT IN ('M', 'F', 'male') OR p.gender IS NULL THEN TRUE
        ELSE FALSE
    END AS has_invalid_gender_value

FROM patients p
LEFT JOIN duplicate_patients dp
    ON p.patient_id = dp.patient_id;


-- View 2: cleaned_admissions
-- Doel:
-- Deze view maakt een gestandaardiseerde opnamelaag bovenop de raw admissions-tabel.
-- De view voegt quality flags toe voor duplicaten, referentiële fouten,
-- ongeldige opnameperiodes, ontbrekende afdelingen en negatieve kosten.

CREATE OR REPLACE VIEW cleaned_admissions AS
WITH duplicate_admissions AS (
    SELECT 
        admission_id
    FROM admissions
    WHERE admission_id IS NOT NULL
      AND TRIM(admission_id) <> ''
    GROUP BY admission_id
    HAVING COUNT(*) > 1
)
SELECT
    a.admission_id,
    a.patient_id,
    a.admission_date,
    a.discharge_date,

    CASE
        WHEN a.department IS NULL OR TRIM(a.department) = '' THEN NULL
        ELSE INITCAP(TRIM(a.department))
    END AS department_standardized,

    a.diagnosis_code,
    a.total_cost,

    CASE
        WHEN da.admission_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_duplicate_admission_id,

    CASE
        WHEN p.patient_id IS NULL THEN TRUE
        ELSE FALSE
    END AS has_unknown_patient_id,

    CASE
        WHEN a.discharge_date < a.admission_date THEN TRUE
        ELSE FALSE
    END AS has_invalid_admission_period,

    CASE
        WHEN a.department IS NULL OR TRIM(a.department) = '' THEN TRUE
        ELSE FALSE
    END AS has_missing_department,

    CASE
        WHEN a.total_cost < 0 THEN TRUE
        ELSE FALSE
    END AS has_negative_total_cost

FROM admissions a
LEFT JOIN patients p
    ON a.patient_id = p.patient_id
LEFT JOIN duplicate_admissions da
    ON a.admission_id = da.admission_id;

select *
from cleaned_admissions 

select *
from cleaned_admissions
where has_duplicate_admission_id  = TRUE 
	or has_unknown_patient_id  = TRUE
	or has_invalid_admission_period  = TRUE
	or has_missing_department  = TRUE
	or has_negative_total_cost = true;

select
	department_standardized,
	count(*) as record_count
from cleaned_admissions
group by department_standardized
order by record_count desc;