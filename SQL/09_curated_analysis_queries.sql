/*
===============================================================================
Curated Analysis Queries
Project: Healthcare Data Quality SQL Pipeline

Doel:
Eerste eenvoudige analyses uitvoeren op de curated views.

Belangrijk:
Deze queries zijn bedoeld als technische analyse-oefeningen. De dataset is klein
en synthetisch, dus de resultaten mogen niet als medische conclusies worden
geïnterpreteerd.
===============================================================================
*/


-- Analyse 1: aantal veilige admissions per afdeling
SELECT
    department_standardized,
    COUNT(*) AS admission_count
FROM curated_admissions
GROUP BY department_standardized
ORDER BY admission_count DESC;


-- Analyse 2: gemiddelde total_cost op veilige admissions
-- Negative total_cost records worden uitgesloten omdat ze kostenanalyse kunnen vertekenen.
-- Analyse 2: gemiddelde total_cost op veilige admissions
-- Negative en extreme total_cost records worden uitgesloten omdat ze kostenanalyse kunnen vertekenen.
SELECT
    ROUND(AVG(total_cost), 2) AS avg_total_cost
FROM curated_admissions
WHERE has_negative_total_cost = FALSE
  AND total_cost < 100000;


-- Analyse 3: aantal veilige lab results per test type
SELECT
    test_name_standardized,
    COUNT(*) AS lab_result_count
FROM curated_lab_results
GROUP BY test_name_standardized
ORDER BY lab_result_count DESC;


-- Analyse 4: gemiddelde labwaarde per test type, exclusief ongeldige waarden
SELECT
    test_name_standardized,
    ROUND(AVG(result_value), 2) AS avg_result_value,
    count(*) as number_records
FROM curated_lab_results
WHERE has_invalid_result_value = FALSE
GROUP BY test_name_standardized
ORDER BY test_name_standardized;

-- Audit: patients
SELECT
    'patients' AS entity,
    patient_id AS record_id,
    has_missing_patient_id,
    has_duplicate_patient_id,
    has_future_birth_date
FROM cleaned_patients
WHERE has_missing_patient_id = TRUE
   OR has_duplicate_patient_id = TRUE
   OR has_future_birth_date = TRUE;

-- Audit: admissions
SELECT
    'admissions' AS entity,
    admission_id AS record_id,
    has_duplicate_admission_id,
    has_unknown_patient_id,
    has_invalid_admission_period
FROM cleaned_admissions
WHERE has_duplicate_admission_id = TRUE
   OR has_unknown_patient_id = TRUE
   OR has_invalid_admission_period = TRUE;

-- Audit: lab_results
SELECT
    'lab_results' AS entity,
    lab_result_id AS record_id,
    has_duplicate_lab_result_id,
    has_unknown_patient_id
FROM cleaned_lab_results
WHERE has_duplicate_lab_result_id = TRUE
   OR has_unknown_patient_id = TRUE;
