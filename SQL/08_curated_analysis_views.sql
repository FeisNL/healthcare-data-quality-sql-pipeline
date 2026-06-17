/*
===============================================================================
Curated Analysis Views
Project: Healthcare Data Quality SQL Pipeline

Doel:
Deze views maken analysegerichte subsets op basis van de cleaned views.
Records met blocking high-risk quality issues worden uitgesloten.

Belangrijk:
De raw data en cleaned views blijven behouden. De curated views verwijderen geen
brondata, maar maken analysegerichte selecties.
===============================================================================
*/


-- View 1: curated_patients
CREATE OR REPLACE VIEW curated_patients AS
SELECT *
FROM cleaned_patients
WHERE has_missing_patient_id = FALSE
  AND has_duplicate_patient_id = FALSE
  AND has_future_birth_date = FALSE;


-- View 2: curated_admissions
CREATE OR REPLACE VIEW curated_admissions AS
SELECT *
FROM cleaned_admissions
WHERE has_duplicate_admission_id = FALSE
  AND has_unknown_patient_id = FALSE
  AND has_invalid_admission_period = FALSE;


-- View 3: curated_lab_results
CREATE OR REPLACE VIEW curated_lab_results AS
SELECT *
FROM cleaned_lab_results
WHERE has_duplicate_lab_result_id = FALSE
  AND has_unknown_patient_id = FALSE;

-- row counts test
SELECT 'curated_patients' AS view_name, COUNT(*) AS row_count
FROM curated_patients
UNION ALL
SELECT 'curated_admissions' AS view_name, COUNT(*) AS row_count
FROM curated_admissions
UNION ALL
SELECT 'curated_lab_results' AS view_name, COUNT(*) AS row_count
FROM curated_lab_results;

-- check for excluded records
SELECT *
FROM cleaned_patients
WHERE has_missing_patient_id = TRUE
   OR has_duplicate_patient_id = TRUE
   OR has_future_birth_date = TRUE;

SELECT *
FROM cleaned_admissions
WHERE has_duplicate_admission_id = TRUE
   OR has_unknown_patient_id = TRUE
   OR has_invalid_admission_period = TRUE;

SELECT *
FROM cleaned_lab_results
WHERE has_duplicate_lab_result_id = TRUE
   OR has_unknown_patient_id = TRUE;