-- Script: 17_insert_large_synthetic_data.sql
-- Purpose: Insert synthetic data into the large raw/sandbox healthcare tables.
-- Layer: raw/sandbox
-- Notes:
-- This script intentionally inserts data quality issues for training and validation.
-- It should only be used on sandbox tables.

truncate table
	admissions_large,
	departments_large,
	lab_results_large,
	patients_large,
	providers_large
restart identity;

-- filling departments_large
insert into departments_large (
	department_id,
	department_name,
	department_category,
	is_active,
	source_system 
)

values 
    ('D001', 'Cardiology', 'Clinical', TRUE, 'synthetic_generator'),
    ('D002', 'Emergency', 'Clinical', TRUE, 'synthetic_generator'),
    ('D003', 'Neurology', 'Clinical', TRUE, 'synthetic_generator'),
    ('D004', 'Oncology', 'Clinical', TRUE, 'synthetic_generator'),
    ('D005', 'Radiology', 'Diagnostics', TRUE, 'synthetic_generator'),
    ('D006', 'Laboratory', 'Diagnostics', TRUE, 'synthetic_generator'),
    ('D007', 'cardiology', 'Clinical', TRUE, 'synthetic_generator'),
    ('D008', 'Unknown Dept', 'Unknown', NULL, 'synthetic_generator');

select
	*
from
	departments_large

-- filling providers_large
INSERT
	INTO
	providers_large(
	provider_id,
    provider_name,
    specialty,
    department_id,
    active_from,
    active_to,
    source_system
)
SELECT
	'PR' || LPAD(n::TEXT, 4, '0') AS provider_id,
	'Provider ' || n AS provider_name,
	CASE
		WHEN n % 5 = 0 THEN 'Cardiology'
		WHEN n % 5 = 1 THEN 'Emergency Medicine'
		WHEN n % 5 = 2 THEN 'Neurology'
		WHEN n % 5 = 3 THEN 'Oncology'
		ELSE 'Internal Medicine'
	END AS specialty,
	CASE
		WHEN n = 49 THEN 'D999'
		WHEN n = 50 THEN NULL
		ELSE 'D' || LPAD(((n - 1) % 8 + 1)::TEXT, 3, '0')
	END AS department_id,
	DATE '2020-01-01' + ((n * 7) % 1000) AS active_from,
	CASE
		WHEN n % 10 = 0 THEN DATE '2023-12-31'
		ELSE NULL
	END AS active_to,
	'synthetic_generator' AS source_system
FROM
	generate_series(1, 50) AS n;

SELECT *
FROM departments_large 

-- filling patients_large
INSERT INTO patients_large (
    patient_id,
    first_name,
    last_name,
    birth_date,
    gender,
    postcode,
    registration_date,
    source_system
)
SELECT
    CASE
        WHEN n = 10 THEN NULL
        WHEN n = 20 THEN 'P0002'
        ELSE 'P' || LPAD(n::TEXT, 4, '0')
    END AS patient_id,
    'FirstName' || n AS first_name,
    'LastName' || n AS last_name,
    CASE
        WHEN n = 30 THEN CURRENT_DATE + 30
        WHEN n = 40 THEN DATE '1880-01-01'
        ELSE DATE '1940-01-01' + ((n * 37) % 25000)
    END AS birth_date,
    CASE
        WHEN n % 100 = 0 THEN NULL
        WHEN n % 125 = 0 THEN 'X'
        WHEN n % 2 = 0 THEN 'F'
        ELSE 'M'
    END AS gender,
    CASE
        WHEN n % 90 = 0 THEN NULL
        ELSE LPAD((1000 + (n % 8999))::TEXT, 4, '0') || ' AB'
    END AS postcode,
    DATE '2020-01-01' + ((n * 11) % 1500) AS registration_date,
    'synthetic_generator' AS source_system
FROM generate_series(1, 1000) AS n;

SELECT *
FROM patients_large;

-- filling admissions_large
WITH generated_admissions AS (
    SELECT
        n,
        DATE '2024-01-01' + (n % 365) AS generated_admission_date
    FROM generate_series(1, 2000) AS n
)
INSERT INTO admissions_large (
    admission_id,
    patient_id,
    department_id,
    provider_id,
    admission_date,
    discharge_date,
    admission_type,
    diagnosis_group,
    total_cost,
    source_system
)
SELECT
    CASE
        WHEN n = 100 THEN 'A00001'
        ELSE 'A' || LPAD(n::TEXT, 5, '0')
    END AS admission_id,
    CASE
        WHEN n % 250 = 0 THEN 'P9999'
        WHEN n % 300 = 0 THEN NULL
        ELSE 'P' || LPAD((((n - 1) % 1000) + 1)::TEXT, 4, '0')
    END AS patient_id,
    CASE
        WHEN n % 333 = 0 THEN 'D999'
        WHEN n % 400 = 0 THEN NULL
        ELSE 'D' || LPAD((((n - 1) % 8) + 1)::TEXT, 3, '0')
    END AS department_id,
    CASE
        WHEN n % 275 = 0 THEN 'PR9999'
        ELSE 'PR' || LPAD((((n - 1) % 50) + 1)::TEXT, 4, '0')
    END AS provider_id,
    generated_admission_date AS admission_date,
    CASE
        WHEN n % 200 = 0 THEN generated_admission_date - 1
        WHEN n % 150 = 0 THEN NULL
        ELSE generated_admission_date + ((n % 10) + 1)
    END AS discharge_date,
    CASE
        WHEN n % 3 = 0 THEN 'Emergency'
        WHEN n % 3 = 1 THEN 'Planned'
        ELSE 'Transfer'
    END AS admission_type,
    CASE
        WHEN n % 4 = 0 THEN 'Cardiac'
        WHEN n % 4 = 1 THEN 'Respiratory'
        WHEN n % 4 = 2 THEN 'Neurological'
        ELSE 'General'
    END AS diagnosis_group,
    CASE
        WHEN n % 175 = 0 THEN -500.00
        WHEN n % 220 = 0 THEN 999999.99
        ELSE (1000 + ((n * 17) % 9000))::NUMERIC(12, 2)
    END AS total_cost,
    'synthetic_generator' AS source_system
FROM generated_admissions;

SELECT * 
FROM admissions_large;

-- filling lab_results_large
INSERT INTO lab_results_large (
    lab_result_id,
    admission_id,
    patient_id,
    test_name,
    result_value,
    result_unit,
    test_date,
    source_system
)
SELECT
    CASE
        WHEN n = 1000 THEN 'L00001'
        ELSE 'L' || LPAD(n::TEXT, 5, '0')
    END AS lab_result_id,
    CASE
        WHEN n % 400 = 0 THEN 'A99999'
        ELSE 'A' || LPAD((((n - 1) % 2000) + 1)::TEXT, 5, '0')
    END AS admission_id,
    CASE
        WHEN n % 333 = 0 THEN 'P9999'
        ELSE 'P' || LPAD((((n - 1) % 1000) + 1)::TEXT, 4, '0')
    END AS patient_id,
    CASE
        WHEN n % 4 = 0 THEN 'CRP'
        WHEN n % 4 = 1 THEN 'HbA1c'
        WHEN n % 4 = 2 THEN 'Hemoglobin'
        ELSE 'Glucose'
    END AS test_name,
    CASE
        WHEN n % 250 = 0 THEN -5.00
        WHEN n % 375 = 0 THEN 9999.00
        WHEN n % 4 = 0 THEN (5 + (n % 80))::NUMERIC(10, 2)
        WHEN n % 4 = 1 THEN (4 + (n % 8))::NUMERIC(10, 2)
        WHEN n % 4 = 2 THEN (8 + (n % 10))::NUMERIC(10, 2)
        ELSE (3 + (n % 15))::NUMERIC(10, 2)
    END AS result_value,
    CASE
        WHEN n % 4 = 0 THEN 'mg/L'
        WHEN n % 4 = 1 THEN '%'
        WHEN n % 4 = 2 THEN 'g/dL'
        ELSE 'mmol/L'
    END AS result_unit,
    CASE
        WHEN n % 500 = 0 THEN CURRENT_DATE + 30
        ELSE DATE '2024-01-01' + (n % 365)
    END AS test_date,
    'synthetic_generator' AS source_system
FROM generate_series(1, 5000) AS n;

SELECT * 
FROM lab_results_large 