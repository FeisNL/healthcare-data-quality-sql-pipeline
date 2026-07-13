-- ============================================================
-- Script: 21_curated_large_layer_views.sql
-- Purpose: Create curated analysis-ready views for the large healthcare dataset.
-- Layer: curated
--
-- Design principle:
-- The cleaned layer keeps all records and makes data quality issues visible.
-- The curated layer applies documented inclusion and exclusion rules.
--
-- Expected behavior:
-- Curated views may have fewer rows than cleaned views.
-- Rejected records are not deleted; they remain traceable in the cleaned layer.
-- ============================================================


-- ============================================================
-- 1. Curated patients view
-- ============================================================
-- Goal:
-- Create an analysis-ready patient view.
--
-- Source:
-- cleaned_patients_large
--
-- Inclusion rule:
-- A patient record is included only when it has no patient-level quality issue.
--
-- Exclusion logic:
-- Records are excluded when has_patient_quality_issue IS TRUE.
-- ============================================================

CREATE OR REPLACE VIEW curated_patients_large AS

SELECT
    -- 1a. Technical row ID for traceability back to the raw patient row
    patient_row_id,

    -- 1b. Cleaned business key used for joins and analysis
    patient_id_cleaned AS patient_id,

    -- 1c. Original demographic fields
    first_name,
    last_name,
    birth_date,

    -- 1d. Standardized demographic fields
    gender_standardized AS gender,
    postcode_standardized AS postcode,

    -- 1e. Other useful source metadata
    registration_date,
    source_system,
    loaded_at,

    -- 1f. Curated-layer status flag
    -- All records in this view should be analysis-ready based on the current rules.
    TRUE AS is_analysis_ready

FROM cleaned_patients_large

-- 1g. Curated filter
-- Keep only patient records without patient-level quality issues.
WHERE has_patient_quality_issue IS NOT TRUE;


-- ============================================================
-- 2. Curated departments view
-- ============================================================
-- Goal:
-- Create an analysis-ready department reference view.
--
-- Source:
-- cleaned_departments_large
--
-- Inclusion rule:
-- A department record is included only when it has no department-level quality issue.
-- ============================================================

CREATE OR REPLACE VIEW curated_departments_large AS

SELECT
    -- 2a. Technical row ID for traceability
    department_row_id,

    -- 2b. Cleaned business key used for joins and analysis
    department_id_cleaned AS department_id,

    -- 2c. Standardized department attributes
    department_name_standardized AS department_name,
    department_category_standardized AS department_category,

    -- 2d. Active status and metadata
    is_active,
    source_system,
    loaded_at,

    -- 2e. Curated-layer status flag
    TRUE AS is_analysis_ready

FROM cleaned_departments_large

-- 2f. Curated filter
-- Keep only department records without department-level quality issues.
WHERE has_department_quality_issue IS NOT TRUE;


-- ============================================================
-- 3. Curated providers view
-- ============================================================
-- Goal:
-- Create an analysis-ready provider reference view.
--
-- Source:
-- cleaned_providers_large
--
-- Inclusion rule:
-- A provider record is included only when it has no provider-level quality issue.
--
-- Important:
-- Providers with missing or unknown department references are excluded here.
-- They remain visible in cleaned_providers_large with quality flags.
-- ============================================================

CREATE OR REPLACE VIEW curated_providers_large AS

SELECT
    -- 3a. Technical row ID for traceability
    provider_row_id,

    -- 3b. Cleaned business key used for joins and analysis
    provider_id_cleaned AS provider_id,

    -- 3c. Standardized provider attributes
    provider_name_standardized AS provider_name,
    specialty_standardized AS specialty,

    -- 3d. Cleaned department reference
    department_id_cleaned AS department_id,

    -- 3e. Active period fields
    active_from,
    active_to,

    -- 3f. Source metadata
    source_system,
    loaded_at,

    -- 3g. Curated-layer status flag
    TRUE AS is_analysis_ready

FROM cleaned_providers_large

-- 3h. Curated filter
-- Keep only provider records without provider-level quality issues.
WHERE has_provider_quality_issue IS NOT TRUE;

-- ============================================================
-- 4. Curated admissions view
-- ============================================================
-- Goal:
-- Create an analysis-ready admissions view.
--
-- Source:
-- cleaned_admissions_large
--
-- Additional curated rule:
-- An admission is only analysis-ready when:
-- 1. the admission itself has no admission-level quality issue
-- 2. the patient reference exists in curated_patients_large
-- 3. the department reference exists in curated_departments_large
-- 4. the provider reference exists in curated_providers_large
--
-- Why:
-- A record can have valid-looking IDs in the cleaned layer, but still link to
-- a patient, department or provider that was excluded from the curated layer.
-- ============================================================

CREATE OR REPLACE VIEW curated_admissions_large AS

SELECT
    -- 4a. Technical row ID for traceability back to the raw admission row
    ca.admission_row_id,

    -- 4b. Cleaned business key
    ca.admission_id_cleaned AS admission_id,

    -- 4c. Curated foreign keys
    ca.patient_id_cleaned AS patient_id,
    ca.department_id_cleaned AS department_id,
    ca.provider_id_cleaned AS provider_id,

    -- 4d. Extra traceability to curated reference records
    cp.patient_row_id AS curated_patient_row_id,
    cd.department_row_id AS curated_department_row_id,
    cpr.provider_row_id AS curated_provider_row_id,

    -- 4e. Admission attributes
    ca.admission_date,
    ca.discharge_date,
    ca.admission_type_standardized AS admission_type,
    ca.diagnosis_group_standardized AS diagnosis_group,
    ca.total_cost,

    -- 4f. Derived analysis field
    -- Because open admissions and invalid date records are excluded,
    -- this length of stay calculation is safe for completed-admission analysis.
    ca.discharge_date - ca.admission_date AS length_of_stay_days,

    -- 4g. Source metadata
    ca.source_system,
    ca.loaded_at,

    -- 4h. Curated-layer status flag
    TRUE AS is_analysis_ready

FROM cleaned_admissions_large ca

-- 4i. Require the patient to exist in the curated patient view
JOIN curated_patients_large cp
    ON ca.patient_id_cleaned = cp.patient_id

-- 4j. Require the department to exist in the curated department view
JOIN curated_departments_large cd
    ON ca.department_id_cleaned = cd.department_id

-- 4k. Require the provider to exist in the curated provider view
JOIN curated_providers_large cpr
    ON ca.provider_id_cleaned = cpr.provider_id

-- 4l. Curated filter
-- Keep only admissions without admission-level quality issues.
WHERE ca.has_admission_quality_issue IS NOT TRUE;


-- ============================================================
-- 5. Curated lab results view
-- ============================================================
-- Goal:
-- Create an analysis-ready lab results view.
--
-- Source:
-- cleaned_lab_results_large
--
-- Additional curated rule:
-- A lab result is only analysis-ready when:
-- 1. the lab result itself has no lab-level quality issue
-- 2. the admission reference exists in curated_admissions_large
-- 3. the patient reference exists in curated_patients_large
--
-- Why:
-- A lab result can have a known admission_id in the cleaned layer,
-- but that admission may still be excluded from the curated admissions view.
-- ============================================================

CREATE OR REPLACE VIEW curated_lab_results_large AS

SELECT
    -- 5a. Technical row ID for traceability back to the raw lab result row
    clr.lab_result_row_id,

    -- 5b. Cleaned business key
    clr.lab_result_id_cleaned AS lab_result_id,

    -- 5c. Curated foreign keys
    clr.admission_id_cleaned AS admission_id,
    clr.patient_id_cleaned AS patient_id,

    -- 5d. Extra traceability to curated parent records
    ca.admission_row_id AS curated_admission_row_id,
    cp.patient_row_id AS curated_patient_row_id,

    -- 5e. Standardized lab attributes
    clr.test_name_standardized AS test_name,
    clr.result_value,
    clr.result_unit_standardized AS result_unit,
    clr.test_date,

    -- 5f. Source metadata
    clr.source_system,
    clr.loaded_at,

    -- 5g. Curated-layer status flag
    TRUE AS is_analysis_ready

FROM cleaned_lab_results_large clr

-- 5h. Require the admission to exist in the curated admissions view
JOIN curated_admissions_large ca
    ON clr.admission_id_cleaned = ca.admission_id

-- 5i. Require the patient to exist in the curated patient view
JOIN curated_patients_large cp
    ON clr.patient_id_cleaned = cp.patient_id

-- 5j. Curated filter
-- Keep only lab results without lab-level quality issues.
WHERE clr.has_lab_result_quality_issue IS NOT TRUE;