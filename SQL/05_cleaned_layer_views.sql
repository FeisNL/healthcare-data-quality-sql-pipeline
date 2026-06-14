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

/*
===============================================================================
View 3: cleaned_lab_results

Doel:
Deze view maakt een gestandaardiseerde labresultatenlaag bovenop de raw
lab_results-tabel.

De view behoudt alle raw labresultaten en voegt quality flags toe voor:
- dubbele lab_result_id's;
- onbekende patient_id's;
- ontbrekende testdatums;
- toekomstige testdatums;
- negatieve of extreme result_value waarden.
===============================================================================
*/

CREATE OR REPLACE VIEW cleaned_lab_results AS
WITH duplicate_lab_results AS (
    SELECT
        lab_result_id
    FROM lab_results
    WHERE lab_result_id IS NOT NULL
      AND TRIM(lab_result_id) <> ''
    GROUP BY lab_result_id
    HAVING COUNT(*) > 1
)
SELECT
    l.lab_result_id,
    l.patient_id,

    CASE
        WHEN l.test_name IS NULL OR TRIM(l.test_name) = '' THEN NULL
        ELSE INITCAP(TRIM(l.test_name))
    END AS test_name_standardized,

    l.test_date,
    l.result_value,
    l.result_unit,

    CASE
        WHEN dl.lab_result_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_duplicate_lab_result_id,

    CASE
        WHEN p.patient_id IS NULL THEN TRUE
        ELSE FALSE
    END AS has_unknown_patient_id,

    CASE
        WHEN l.test_date IS NULL THEN TRUE
        ELSE FALSE
    END AS has_missing_test_date,

    CASE
        WHEN l.test_date > CURRENT_DATE THEN TRUE
        ELSE FALSE
    END AS has_future_test_date,

    CASE
        WHEN l.result_value < 0 OR l.result_value > 500 THEN TRUE
        ELSE FALSE
    END AS has_invalid_result_value

FROM lab_results l
LEFT JOIN patients p
    ON l.patient_id = p.patient_id
LEFT JOIN duplicate_lab_results dl
    ON l.lab_result_id = dl.lab_result_id;