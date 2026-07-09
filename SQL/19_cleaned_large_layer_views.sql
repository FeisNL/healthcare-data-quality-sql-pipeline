-- ============================================================
-- Script: 19_cleaned_large_layer_views.sql
-- Purpose: Create cleaned views for the large synthetic healthcare dataset.
-- Layer: cleaned
--
-- Design principle:
-- The cleaned layer does not remove bad records.
-- It keeps raw values, adds standardized values, and creates data quality flags.
--
-- Expected behavior:
-- Row counts in cleaned views should stay equal to the raw source tables.
-- ============================================================


-- ============================================================
-- 1. Cleaned patients view
-- ============================================================
-- Goal:
-- Create a cleaned patient view that:
-- 1. keeps the technical row ID for traceability
-- 2. keeps original source values
-- 3. creates standardized fields
-- 4. adds patient-level data quality flags
-- 5. adds one combined quality issue flag
-- ============================================================

CREATE OR REPLACE VIEW cleaned_patients_large AS

-- 1a. Find duplicate patient IDs
-- This CTE creates a small lookup table containing patient IDs
-- that appear more than once in the raw patients table.
WITH duplicate_patient_ids AS (
    SELECT
        NULLIF(TRIM(patient_id), '') AS patient_id_cleaned
    FROM patients_large
    WHERE NULLIF(TRIM(patient_id), '') IS NOT NULL
    GROUP BY NULLIF(TRIM(patient_id), '')
    HAVING COUNT(*) > 1
),

-- 1b. Create cleaned fields and individual patient quality flags
-- This CTE keeps the original raw columns and adds standardized columns.
-- It also creates separate TRUE/FALSE flags for each patient data issue.
patient_flags AS (
    SELECT
        -- 1b-1. Technical row ID
        -- This identifies the exact raw row, even if patient_id is missing or duplicated.
        p.patient_row_id,

        -- 1b-2. Original patient ID from the source system
        p.patient_id,

        -- 1b-3. Cleaned patient ID
        -- TRIM removes leading/trailing spaces.
        -- NULLIF(..., '') converts empty strings into NULL.
        NULLIF(TRIM(patient_id, '') AS patient_id_cleaned,

        -- 1b-4. Original demographic fields
        p.first_name,
        p.last_name,
        p.birth_date,
        p.gender,

        -- 1b-5. Standardized gender
        -- If gender is missing or empty, keep it as NULL.
        -- Otherwise, remove spaces and convert to uppercase.
        CASE
            WHEN NULLIF(TRIM(p.gender), '') IS NULL THEN NULL
            ELSE UPPER(TRIM(p.gender))
        END AS gender_standardized,

        -- 1b-6. Original postcode
        p.postcode,

        -- 1b-7. Standardized postcode
        -- If postcode is missing or empty, keep it as NULL.
        -- Otherwise, remove spaces and convert to uppercase.
        CASE
            WHEN NULLIF(TRIM(p.postcode), '') IS NULL THEN NULL
            ELSE UPPER(TRIM(p.postcode))
        END AS postcode_standardized,

        -- 1b-8. Other original metadata fields
        p.registration_date,
        p.source_system,
        p.loaded_at,

        -- 1b-9. Flag: missing patient ID
        -- TRUE when patient_id is NULL or empty after trimming.
        NULLIF(TRIM(p.patient_id), '') IS NULL AS has_missing_patient_id,

        -- 1b-10. Flag: duplicate patient ID
        -- TRUE when this cleaned patient_id appears in the duplicate lookup CTE.
        d.patient_id_cleaned IS NOT NULL AS has_duplicate_patient_id,

        -- 1b-11. Flag: birth date in the future
        -- A patient cannot be born after the current date.
        p.birth_date > CURRENT_DATE AS has_future_birth_date,

        -- 1b-12. Flag: unrealistic birth date
        -- Here we flag patients older than 120 years.
        p.birth_date < CURRENT_DATE - INTERVAL '120 years' AS has_unrealistic_birth_date,

        -- 1b-13. Flag: missing gender
        -- TRUE when gender is NULL or empty after trimming.
        NULLIF(TRIM(p.gender), '') IS NULL AS has_missing_gender,

        -- 1b-14. Flag: invalid gender
        -- TRUE when gender is present but not one of the accepted values.
        NULLIF(TRIM(p.gender), '') IS NOT NULL
            AND UPPER(TRIM(p.gender)) NOT IN ('M', 'F') AS has_invalid_gender,

        -- 1b-15. Flag: missing postcode
        -- TRUE when postcode is NULL or empty after trimming.
        NULLIF(TRIM(p.postcode), '') IS NULL AS has_missing_postcode

    FROM patients_large p

    -- 1b-16. Join raw patients to duplicate patient ID lookup
    -- This lets us mark every raw row whose patient_id is duplicated.
    LEFT JOIN duplicate_patient_ids d
        ON NULLIF(TRIM(p.patient_id), '') = d.patient_id_cleaned
)

-- 1c. Final patient view output
-- This outer SELECT adds the combined patient quality flag.
-- We use an outer SELECT because SQL usually cannot reuse aliases
-- from the same SELECT list for another calculation.
SELECT
    *,
    (
        has_missing_patient_id
        OR has_duplicate_patient_id
        OR has_future_birth_date
        OR has_unrealistic_birth_date
        OR has_missing_gender
        OR has_invalid_gender
        OR has_missing_postcode
    ) AS has_patient_quality_issue
FROM patient_flags;


-- ============================================================
-- 2. Cleaned departments view
-- ============================================================
-- Goal:
-- Create a cleaned department view that:
-- 1. keeps the technical row ID
-- 2. keeps original department values
-- 3. creates standardized department name/category fields
-- 4. adds department-level quality flags
-- 5. adds one combined department quality issue flag
-- ============================================================

CREATE OR REPLACE VIEW cleaned_departments_large AS

-- 2a. Create cleaned fields and individual department quality flags
WITH department_flags AS (
    SELECT
        -- 2a-1. Technical row ID
        department_row_id,

        -- 2a-2. Original department ID
        department_id,

        -- 2a-3. Cleaned department ID
        NULLIF(TRIM(department_id), '') AS department_id_cleaned,

        -- 2a-4. Original department name
        department_name,

        -- 2a-5. Standardized department name
        -- INITCAP converts text to title case.
        -- Example: 'cardiology' becomes 'Cardiology'.
        CASE
            WHEN NULLIF(TRIM(department_name), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(department_name))
        END AS department_name_standardized,

        -- 2a-6. Original department category
        department_category,

        -- 2a-7. Standardized department category
        CASE
            WHEN NULLIF(TRIM(department_category), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(department_category))
        END AS department_category_standardized,

        -- 2a-8. Original active status and metadata
        is_active,
        source_system,
        loaded_at,

        -- 2a-9. Flag: missing department ID
        NULLIF(TRIM(department_id), '') IS NULL AS has_missing_department_id,

        -- 2a-10. Flag: missing department name
        NULLIF(TRIM(department_name), '') IS NULL AS has_missing_department_name,

        -- 2a-11. Flag: inactive or unknown department status
        -- IS DISTINCT FROM TRUE treats both FALSE and NULL as problematic.
        is_active IS DISTINCT FROM TRUE AS has_inactive_or_unknown_status

    FROM departments_large
)

-- 2b. Final department view output
-- Add one combined department quality flag.
SELECT
    *,
    (
        has_missing_department_id
        OR has_missing_department_name
        OR has_inactive_or_unknown_status
    ) AS has_department_quality_issue
FROM department_flags;


-- ============================================================
-- 3. Cleaned providers view
-- ============================================================
-- Goal:
-- Create a cleaned provider view that:
-- 1. keeps the technical row ID
-- 2. keeps original provider values
-- 3. creates standardized text fields
-- 4. checks whether the provider references a valid department
-- 5. adds provider-level quality flags
-- 6. adds one combined provider quality issue flag
-- ============================================================

CREATE OR REPLACE VIEW cleaned_providers_large AS

-- 3a. Create a lookup of valid department IDs
-- This CTE contains all non-missing department IDs from the raw department table.
-- We use DISTINCT to avoid row multiplication if a department_id ever appears more than once.
WITH valid_department_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(department_id), '') AS department_id_cleaned
    FROM departments_large
    WHERE NULLIF(TRIM(department_id), '') IS NOT NULL
),

-- 3b. Create cleaned fields and individual provider quality flags
provider_flags AS (
    SELECT
        -- 3b-1. Technical row ID
        pr.provider_row_id,

        -- 3b-2. Original provider ID
        pr.provider_id,

        -- 3b-3. Cleaned provider ID
        NULLIF(TRIM(pr.provider_id), '') AS provider_id_cleaned,

        -- 3b-4. Original provider name
        pr.provider_name,

        -- 3b-5. Standardized provider name
        CASE
            WHEN NULLIF(TRIM(pr.provider_name), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(pr.provider_name))
        END AS provider_name_standardized,

        -- 3b-6. Original specialty
        pr.specialty,

        -- 3b-7. Standardized specialty
        CASE
            WHEN NULLIF(TRIM(pr.specialty), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(pr.specialty))
        END AS specialty_standardized,

        -- 3b-8. Original department ID reference
        pr.department_id,

        -- 3b-9. Cleaned department ID reference
        NULLIF(TRIM(pr.department_id), '') AS department_id_cleaned,

        -- 3b-10. Active period fields
        pr.active_from,
        pr.active_to,

        -- 3b-11. Metadata fields
        pr.source_system,
        pr.loaded_at,

        -- 3b-12. Flag: missing provider ID
        NULLIF(TRIM(pr.provider_id), '') IS NULL AS has_missing_provider_id,

        -- 3b-13. Flag: missing department ID
        -- A provider should normally belong to a department.
        NULLIF(TRIM(pr.department_id), '') IS NULL AS has_missing_department_id,

        -- 3b-14. Flag: unknown department ID
        -- TRUE when provider has a department_id, but that department_id
        -- does not exist in departments_large.
        NULLIF(TRIM(pr.department_id), '') IS NOT NULL
            AND vd.department_id_cleaned IS NULL AS has_unknown_department_id,

        -- 3b-15. Flag: invalid active period
        -- active_to should not be before active_from.
        pr.active_to IS NOT NULL
            AND pr.active_from IS NOT NULL
            AND pr.active_to < pr.active_from AS has_invalid_active_period

    FROM providers_large pr

    -- 3b-16. Join providers to valid department IDs
    -- This supports the has_unknown_department_id flag.
    LEFT JOIN valid_department_ids vd
        ON NULLIF(TRIM(pr.department_id), '') = vd.department_id_cleaned
)

-- 3c. Final provider view output
-- Add one combined provider quality flag.
SELECT
    *,
    (
        has_missing_provider_id
        OR has_missing_department_id
        OR has_unknown_department_id
        OR has_invalid_active_period
    ) AS has_provider_quality_issue
FROM provider_flags;


-- ============================================================
-- 4. Cleaned admissions view
-- ============================================================
-- Goal:
-- Create a cleaned admissions view that:
-- 1. keeps the technical row ID for traceability
-- 2. keeps original admission source values
-- 3. creates cleaned ID fields for joins and validation
-- 4. checks whether patient, department and provider references are valid
-- 5. adds date and cost quality flags
-- 6. adds one combined admission quality issue flag
-- ============================================================

CREATE OR REPLACE VIEW cleaned_admissions_large AS

-- 4a. Create a lookup of valid patient IDs
-- This CTE contains all non-missing patient IDs from the raw patients table.
-- DISTINCT prevents row multiplication if the same patient_id appears more than once.
WITH valid_patient_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(patient_id), '') AS patient_id_cleaned
    FROM patients_large
    WHERE NULLIF(TRIM(patient_id), '') IS NOT NULL
),

-- 4b. Create a lookup of valid department IDs
-- This CTE is used to check whether an admission references an existing department.
valid_department_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(department_id), '') AS department_id_cleaned
    FROM departments_large
    WHERE NULLIF(TRIM(department_id), '') IS NOT NULL
),

-- 4c. Create a lookup of valid provider IDs
-- This CTE is used to check whether an admission references an existing provider.
valid_provider_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(provider_id), '') AS provider_id_cleaned
    FROM providers_large
    WHERE NULLIF(TRIM(provider_id), '') IS NOT NULL
),

-- 4d. Create cleaned fields and individual admission quality flags
admission_flags AS (
    SELECT
        -- 4d-1. Technical row ID
        -- This identifies the exact raw admission row.
        a.admission_row_id,

        -- 4d-2. Original admission ID
        a.admission_id,

        -- 4d-3. Cleaned admission ID
        NULLIF(TRIM(a.admission_id), '') AS admission_id_cleaned,

        -- 4d-4. Original patient ID reference
        a.patient_id,

        -- 4d-5. Cleaned patient ID reference
        NULLIF(TRIM(a.patient_id), '') AS patient_id_cleaned,

        -- 4d-6. Original department ID reference
        a.department_id,

        -- 4d-7. Cleaned department ID reference
        NULLIF(TRIM(a.department_id), '') AS department_id_cleaned,

        -- 4d-8. Original provider ID reference
        a.provider_id,

        -- 4d-9. Cleaned provider ID reference
        NULLIF(TRIM(a.provider_id), '') AS provider_id_cleaned,

        -- 4d-10. Admission date fields
        a.admission_date,
        a.discharge_date,

        -- 4d-11. Original admission type
        a.admission_type,

        -- 4d-12. Standardized admission type
        CASE
            WHEN NULLIF(TRIM(a.admission_type), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(a.admission_type))
        END AS admission_type_standardized,

        -- 4d-13. Original diagnosis group
        a.diagnosis_group,

        -- 4d-14. Standardized diagnosis group
        CASE
            WHEN NULLIF(TRIM(a.diagnosis_group), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(a.diagnosis_group))
        END AS diagnosis_group_standardized,

        -- 4d-15. Cost and metadata fields
        a.total_cost,
        a.source_system,
        a.loaded_at,

        -- 4d-16. Flag: missing admission ID
        NULLIF(TRIM(a.admission_id), '') IS NULL AS has_missing_admission_id,

        -- 4d-17. Flag: missing patient ID
        NULLIF(TRIM(a.patient_id), '') IS NULL AS has_missing_patient_id,

        -- 4d-18. Flag: unknown patient ID
        -- TRUE when the admission has a patient_id,
        -- but that patient_id does not exist in patients_large.
        NULLIF(TRIM(a.patient_id), '') IS NOT NULL
            AND vp.patient_id_cleaned IS NULL AS has_unknown_patient_id,

        -- 4d-19. Flag: missing department ID
        NULLIF(TRIM(a.department_id), '') IS NULL AS has_missing_department_id,

        -- 4d-20. Flag: unknown department ID
        -- TRUE when the admission has a department_id,
        -- but that department_id does not exist in departments_large.
        NULLIF(TRIM(a.department_id), '') IS NOT NULL
            AND vd.department_id_cleaned IS NULL AS has_unknown_department_id,

        -- 4d-21. Flag: missing provider ID
        NULLIF(TRIM(a.provider_id), '') IS NULL AS has_missing_provider_id,

        -- 4d-22. Flag: unknown provider ID
        -- TRUE when the admission has a provider_id,
        -- but that provider_id does not exist in providers_large.
        NULLIF(TRIM(a.provider_id), '') IS NOT NULL
            AND vpr.provider_id_cleaned IS NULL AS has_unknown_provider_id,

        -- 4d-23. Flag: discharge date before admission date
        -- This is invalid because a patient cannot be discharged before being admitted.
        a.discharge_date IS NOT NULL
            AND a.admission_date IS NOT NULL
            AND a.discharge_date < a.admission_date AS has_discharge_before_admission,

        -- 4d-24. Flag: open admission
        -- NULL discharge_date can mean the admission is still open.
        -- This is not always wrong, but it is important for analysis.
        a.discharge_date IS NULL AS has_open_admission,

        -- 4d-25. Flag: negative total cost
        -- Costs should not be negative.
        a.total_cost < 0 AS has_negative_total_cost,

        -- 4d-26. Flag: extreme total cost
        -- This threshold is a training rule for detecting large outliers.
        a.total_cost >= 100000 AS has_extreme_total_cost

    FROM admissions_large a

    -- 4d-27. Join to valid patient IDs
    -- Supports the has_unknown_patient_id flag.
    LEFT JOIN valid_patient_ids vp
        ON NULLIF(TRIM(a.patient_id), '') = vp.patient_id_cleaned

    -- 4d-28. Join to valid department IDs
    -- Supports the has_unknown_department_id flag.
    LEFT JOIN valid_department_ids vd
        ON NULLIF(TRIM(a.department_id), '') = vd.department_id_cleaned

    -- 4d-29. Join to valid provider IDs
    -- Supports the has_unknown_provider_id flag.
    LEFT JOIN valid_provider_ids vpr
        ON NULLIF(TRIM(a.provider_id), '') = vpr.provider_id_cleaned
)

-- 4e. Final admissions view output
-- This outer SELECT adds one combined admission quality issue flag.
SELECT
    *,
    (
        has_missing_admission_id
        OR has_missing_patient_id
        OR has_unknown_patient_id
        OR has_missing_department_id
        OR has_unknown_department_id
        OR has_missing_provider_id
        OR has_unknown_provider_id
        OR has_discharge_before_admission
        OR has_open_admission
        OR has_negative_total_cost
        OR has_extreme_total_cost
    ) AS has_admission_quality_issue
FROM admission_flags;


-- ============================================================
-- 5. Cleaned lab results view
-- ============================================================
-- Goal:
-- Create a cleaned lab results view that:
-- 1. keeps the technical row ID for traceability
-- 2. keeps original lab result source values
-- 3. creates cleaned ID fields for validation
-- 4. standardizes selected text fields
-- 5. checks whether admission and patient references are valid
-- 6. adds lab value and date quality flags
-- 7. adds one combined lab result quality issue flag
-- ============================================================

CREATE OR REPLACE VIEW cleaned_lab_results_large AS

-- 5a. Create a lookup of valid admission IDs
-- This CTE contains all non-missing admission IDs from admissions_large.
-- DISTINCT prevents row multiplication if admission_id appears more than once.
WITH valid_admission_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(admission_id), '') AS admission_id_cleaned
    FROM admissions_large
    WHERE NULLIF(TRIM(admission_id), '') IS NOT NULL
),

-- 5b. Create a lookup of valid patient IDs
-- This CTE contains all non-missing patient IDs from patients_large.
-- DISTINCT prevents row multiplication if patient_id appears more than once.
valid_patient_ids AS (
    SELECT DISTINCT
        NULLIF(TRIM(patient_id), '') AS patient_id_cleaned
    FROM patients_large
    WHERE NULLIF(TRIM(patient_id), '') IS NOT NULL
),

-- 5c. Create cleaned fields and individual lab result quality flags
lab_result_flags AS (
    SELECT
        -- 5c-1. Technical row ID
        -- This identifies the exact raw lab result row.
        l.lab_result_row_id,

        -- 5c-2. Original lab result ID
        l.lab_result_id,

        -- 5c-3. Cleaned lab result ID
        NULLIF(TRIM(l.lab_result_id), '') AS lab_result_id_cleaned,

        -- 5c-4. Original admission ID reference
        l.admission_id,

        -- 5c-5. Cleaned admission ID reference
        NULLIF(TRIM(l.admission_id), '') AS admission_id_cleaned,

        -- 5c-6. Original patient ID reference
        l.patient_id,

        -- 5c-7. Cleaned patient ID reference
        NULLIF(TRIM(l.patient_id), '') AS patient_id_cleaned,

        -- 5c-8. Original test name
        l.test_name,

        -- 5c-9. Standardized test name
        -- INITCAP makes test names more consistent for analysis.
        CASE
            WHEN NULLIF(TRIM(l.test_name), '') IS NULL THEN NULL
            ELSE INITCAP(TRIM(l.test_name))
        END AS test_name_standardized,

        -- 5c-10. Original result value
        l.result_value,

        -- 5c-11. Original result unit
        l.result_unit,

        -- 5c-12. Standardized result unit
        -- We keep unit text mostly uppercase for consistency.
        CASE
            WHEN NULLIF(TRIM(l.result_unit), '') IS NULL THEN NULL
            ELSE UPPER(TRIM(l.result_unit))
        END AS result_unit_standardized,

        -- 5c-13. Test date and metadata
        l.test_date,
        l.source_system,
        l.loaded_at,

        -- 5c-14. Flag: missing lab result ID
        NULLIF(TRIM(l.lab_result_id), '') IS NULL AS has_missing_lab_result_id,

        -- 5c-15. Flag: missing admission ID
        NULLIF(TRIM(l.admission_id), '') IS NULL AS has_missing_admission_id,

        -- 5c-16. Flag: unknown admission ID
        -- TRUE when lab result has an admission_id,
        -- but that admission_id does not exist in admissions_large.
        NULLIF(TRIM(l.admission_id), '') IS NOT NULL
            AND va.admission_id_cleaned IS NULL AS has_unknown_admission_id,

        -- 5c-17. Flag: missing patient ID
        NULLIF(TRIM(l.patient_id), '') IS NULL AS has_missing_patient_id,

        -- 5c-18. Flag: unknown patient ID
        -- TRUE when lab result has a patient_id,
        -- but that patient_id does not exist in patients_large.
        NULLIF(TRIM(l.patient_id), '') IS NOT NULL
            AND vp.patient_id_cleaned IS NULL AS has_unknown_patient_id,

        -- 5c-19. Flag: missing test name
        NULLIF(TRIM(l.test_name), '') IS NULL AS has_missing_test_name,

        -- 5c-20. Flag: missing result value
        l.result_value IS NULL AS has_missing_result_value,

        -- 5c-21. Flag: negative result value
        -- Lab values should normally not be negative.
        l.result_value < 0 AS has_negative_result_value,

        -- 5c-22. Flag: extreme result value
        -- This is a broad training threshold for obvious outliers.
        l.result_value >= 1000 AS has_extreme_result_value,

        -- 5c-23. Flag: future test date
        -- A lab test should not have a date after the current date.
        l.test_date > CURRENT_DATE AS has_future_test_date

    FROM lab_results_large l

    -- 5c-24. Join lab results to valid admission IDs
    -- Supports the has_unknown_admission_id flag.
    LEFT JOIN valid_admission_ids va
        ON NULLIF(TRIM(l.admission_id), '') = va.admission_id_cleaned

    -- 5c-25. Join lab results to valid patient IDs
    -- Supports the has_unknown_patient_id flag.
    LEFT JOIN valid_patient_ids vp
        ON NULLIF(TRIM(l.patient_id), '') = vp.patient_id_cleaned
)

-- 5d. Final lab results view output
-- This outer SELECT adds one combined lab result quality issue flag.
SELECT
    *,
    (
        has_missing_lab_result_id
        OR has_missing_admission_id
        OR has_unknown_admission_id
        OR has_missing_patient_id
        OR has_unknown_patient_id
        OR has_missing_test_name
        OR has_missing_result_value
        OR has_negative_result_value
        OR has_extreme_result_value
        OR has_future_test_date
    ) AS has_lab_result_quality_issue
FROM lab_result_flags;