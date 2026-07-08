-- Script: 18_large_data_quality_checks.sql
-- Purpose: Run data quality checks on the large synthetic healthcare dataset.
-- Layer: raw/sandbox
-- Notes:
-- These checks validate row counts, duplicates, missing values, unknown references,
-- invalid dates, outliers and invalid numeric values.

-- ============================================================
-- 1. Row counts
-- ============================================================

SELECT 'departments_large' AS table_name, count(*) AS row_count FROM departments_large
UNION ALL 
SELECT 'providers_large' AS table_name, count(*) AS row_count FROM providers_large
UNION ALL
SELECT 'patients_large' AS table_name, count(*) AS row_count FROM patients_large
UNION ALL 
SELECT 'admissions_large' AS table_name, count(*) AS row_count FROM admissions_large
UNION ALL 
SELECT 'lab_results_large' AS table_name, count(*) AS row_count FROM lab_results_large
ORDER BY table_name;