-- ============================================================
-- Script: 24_feature_admission_large_v1.sql
-- Purpose: Create the first large admission-level feature view.
-- Layer: feature table v1
--
-- Grain:
-- 1 row = 1 curated admission
--
-- Design notes:
-- - curated_admissions_large is the main source because the feature table
--   is admission-level.
-- - Patient, department and provider context are added through curated views.
-- - Lab results are not directly joined in v1 because they have a different
--   grain and could multiply admission rows.
-- - provider_department_mismatch_warning is included as a warning feature,
--   not as a blocking filter.
-- ============================================================


-- ============================================================
-- 1. Create admission-level feature view
-- ============================================================
-- Purpose:
-- Create one feature row per curated admission.
--
-- Important:
-- This view should preserve the row count of curated_admissions_large.
-- ============================================================

CREATE OR REPLACE VIEW feature_admission_large_v1 AS

SELECT
    -- --------------------------------------------------------
    -- Admission identifiers
    -- --------------------------------------------------------
    ca.admission_id,
    ca.patient_id,

    -- --------------------------------------------------------
    -- Patient features
    -- --------------------------------------------------------
    EXTRACT(YEAR FROM AGE(ca.admission_date, p.birth_date))::INTEGER AS age_at_admission,
    p.gender,

    -- --------------------------------------------------------
    -- Admission features
    -- --------------------------------------------------------
    ca.admission_type,
    ca.diagnosis_group,

    -- --------------------------------------------------------
    -- Admission department context
    -- --------------------------------------------------------
    ca.department_id,
    d.department_name,

    -- --------------------------------------------------------
    -- Provider context
    -- --------------------------------------------------------
    ca.provider_id,
    pr.department_id AS provider_department_id,

    -- --------------------------------------------------------
    -- Relationship consistency warning
    -- --------------------------------------------------------
    CASE
        WHEN ca.department_id <> pr.department_id
        THEN TRUE
        ELSE FALSE
    END AS provider_department_mismatch_warning

FROM curated_admissions_large ca

JOIN curated_patients_large p
    ON ca.patient_id = p.patient_id

JOIN curated_departments_large d
    ON ca.department_id = d.department_id

JOIN curated_providers_large pr
    ON ca.provider_id = pr.provider_id;

-- ============================================================
-- 2. Validate row count
-- ============================================================
-- Purpose:
-- Confirm that the feature view preserves the admission-level grain.
-- Expected:
-- feature_admission_large_v1 row count should equal curated_admissions_large row count.
-- ============================================================

SELECT
    'curated_admissions_large' AS object_name,
    COUNT(*) AS row_count
FROM curated_admissions_large

UNION ALL

SELECT
    'feature_admission_large_v1' AS object_name,
    COUNT(*) AS row_count
FROM feature_admission_large_v1;


-- ============================================================
-- 3. Validate one row per admission_id
-- ============================================================
-- Purpose:
-- Confirm that each admission appears only once in the feature view.
-- Expected:
-- total_rows should equal distinct_admission_count.
-- duplicate_admission_count should be 0.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS distinct_admission_count,
    COUNT(*) - COUNT(DISTINCT admission_id) AS duplicate_admission_count
FROM feature_admission_large_v1;


-- ============================================================
-- 4. Validate required IDs are present
-- ============================================================
-- Purpose:
-- Confirm that required identifiers are not missing in the feature view.
-- Expected:
-- all missing counts should be 0.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE admission_id IS NULL) AS missing_admission_id_count,
    COUNT(*) FILTER (WHERE patient_id IS NULL) AS missing_patient_id_count,
    COUNT(*) FILTER (WHERE department_id IS NULL) AS missing_department_id_count,
    COUNT(*) FILTER (WHERE provider_id IS NULL) AS missing_provider_id_count
FROM feature_admission_large_v1;


-- ============================================================
-- 5. Validate provider-department warning distribution
-- ============================================================
-- Purpose:
-- Check how many feature rows have a provider-to-department mismatch warning.
-- Expected:
-- This should match the relationship consistency result from SQL/23.
-- ============================================================

SELECT
    provider_department_mismatch_warning,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage
FROM feature_admission_large_v1
GROUP BY
    provider_department_mismatch_warning
ORDER BY
    provider_department_mismatch_warning;


-- ============================================================
-- 6. Validate key feature completeness
-- ============================================================
-- Purpose:
-- Check whether important feature columns are complete.
-- Expected:
-- missing values should be reviewed before using this feature view
-- for analysis or machine learning.
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE age_at_admission IS NULL) AS missing_age_at_admission_count,
    COUNT(*) FILTER (WHERE gender IS NULL) AS missing_gender_count,
    COUNT(*) FILTER (WHERE admission_type IS NULL) AS missing_admission_type_count,
    COUNT(*) FILTER (WHERE diagnosis_group IS NULL) AS missing_diagnosis_group_count,
    COUNT(*) FILTER (WHERE department_name IS NULL) AS missing_department_name_count,
    COUNT(*) FILTER (WHERE provider_department_id IS NULL) AS missing_provider_department_id_count
FROM feature_admission_large_v1;


-- ============================================================
-- 7. Inspect sample feature rows
-- ============================================================
-- Purpose:
-- Review a small sample of the feature view to confirm that the output
-- is readable and aligned with the design document.
-- ============================================================

SELECT
    admission_id,
    patient_id,
    age_at_admission,
    gender,
    admission_type,
    diagnosis_group,
    department_id,
    department_name,
    provider_id,
    provider_department_id,
    provider_department_mismatch_warning
FROM feature_admission_large_v1
ORDER BY
    admission_id
LIMIT 25;