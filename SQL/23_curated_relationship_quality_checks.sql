-- ============================================================
-- Script: 23_curated_relationship_quality_checks.sql
-- Purpose: Validate relationship consistency in the curated healthcare layer.
-- Layer: curated relationship validation
--
-- This script checks whether curated admissions have a provider whose
-- assigned department matches the admission department.
--
-- Important:
-- This is treated as a WARNING check, not as a blocking exclusion rule.
-- A provider-to-department mismatch may be valid in real healthcare data,
-- for example when a provider performs a consultation outside their assigned
-- department.
-- ============================================================


-- ============================================================
-- 1. Verify required curated views exist
-- ============================================================
-- Purpose:
-- Confirm that the required curated views are available before running
-- relationship consistency checks.
-- ============================================================

SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'curated_admissions_large',
      'curated_providers_large'
  )
ORDER BY table_name;


-- ============================================================
-- 2. Provider-to-department mismatch count
-- ============================================================
-- Purpose:
-- Count curated admissions where the admission department does not match
-- the department assigned to the curated provider.
--
-- Interpretation:
-- A mismatch is treated as a relationship consistency warning.
-- It is not used to exclude records from the curated layer yet.
-- ============================================================

SELECT
    COUNT(*) AS total_curated_admissions,
    COUNT(*) FILTER (
        WHERE ca.department_id <> cp.department_id
    ) AS provider_department_mismatch_count,
    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE ca.department_id <> cp.department_id
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS provider_department_mismatch_percentage
FROM curated_admissions_large ca
JOIN curated_providers_large cp
    ON ca.provider_id = cp.provider_id;


-- ============================================================
-- 3. Provider-to-department mismatch breakdown
-- ============================================================
-- Purpose:
-- Show which admission department and provider department combinations
-- appear in the mismatch records.
--
-- This helps identify whether mismatches are isolated or concentrated in
-- specific department combinations.
-- ============================================================

SELECT
    ca.department_id AS admission_department_id,
    cp.department_id AS provider_department_id,
    COUNT(*) AS mismatch_count
FROM curated_admissions_large ca
JOIN curated_providers_large cp
    ON ca.provider_id = cp.provider_id
WHERE ca.department_id <> cp.department_id
GROUP BY
    ca.department_id,
    cp.department_id
ORDER BY
    mismatch_count DESC,
    admission_department_id,
    provider_department_id;


-- ============================================================
-- 4. Sample provider-to-department mismatch records
-- ============================================================
-- Purpose:
-- Inspect sample records where the admission department and provider
-- department do not match.
--
-- This makes the warning explainable and reviewable.
-- ============================================================

SELECT
    ca.admission_row_id,
    ca.admission_id,
    ca.patient_id,
    ca.department_id AS admission_department_id,
    ca.provider_id,
    cp.department_id AS provider_department_id,
    ca.admission_date,
    ca.discharge_date,
    ca.admission_type,
    ca.diagnosis_group,
    ca.total_cost,
    ca.length_of_stay_days
FROM curated_admissions_large ca
JOIN curated_providers_large cp
    ON ca.provider_id = cp.provider_id
WHERE ca.department_id <> cp.department_id
ORDER BY
    ca.admission_row_id
LIMIT 25;


-- ============================================================
-- 5. PASS/WARNING validation summary
-- ============================================================
-- Purpose:
-- Convert the provider-to-department relationship consistency check into
-- a clear validation status.
--
-- Interpretation:
-- PASS means no mismatches were found.
-- WARNING means mismatches were found, but they are not treated as blocking
-- until the business rule is confirmed.
-- ============================================================

WITH relationship_check AS (

    SELECT
        COUNT(*) AS total_curated_admissions,
        COUNT(*) FILTER (
            WHERE ca.department_id <> cp.department_id
        ) AS provider_department_mismatch_count,
        ROUND(
            100.0
            * COUNT(*) FILTER (
                WHERE ca.department_id <> cp.department_id
            )
            / NULLIF(COUNT(*), 0),
            2
        ) AS provider_department_mismatch_percentage
    FROM curated_admissions_large ca
    JOIN curated_providers_large cp
        ON ca.provider_id = cp.provider_id
)

SELECT
    'provider_department_consistency' AS validation_check,
    total_curated_admissions,
    provider_department_mismatch_count,
    provider_department_mismatch_percentage,
    CASE
        WHEN provider_department_mismatch_count = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END AS validation_status,
    CASE
        WHEN provider_department_mismatch_count = 0
        THEN 'All curated admissions have providers assigned to the same department.'
        ELSE 'Some curated admissions have providers assigned to a different department. This is treated as a warning until the business rule is confirmed.'
    END AS interpretation
FROM relationship_check;