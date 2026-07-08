-- Script: 16_create_large_synthetic_tables.sql
-- Purpose: Create raw/sandbox-style large synthetic healthcare tables.
-- Layer: raw/sandbox
-- Notes:
-- These tables use technical row IDs as primary keys.
-- Logical business keys such as patient_id and admission_id are intentionally not enforced as primary keys in the raw layer.
-- This allows intentional data quality issues such as duplicate IDs and unknown references to be loaded and analyzed.

-- Departments reference-style table
CREATE TABLE IF NOT EXISTS departments_large (
    department_row_id BIGSERIAL PRIMARY KEY,
    department_id TEXT,
    department_name TEXT,
    department_category TEXT,
    is_active_boolean BOOLEAN,
    source_system TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT TIMESTAMP,
);

-- Providers reference-style table
CREATE TABLE IF NOT EXISTS providers_large (
    provider_row_id BIGSERIAL PRIMARY KEY,
    provider_id TEXT,
    provider_name TEXT,
    specialty TEXT,
    department_id TEXT,
    active_from DATE,
    active_to DATE,
    source_system TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT TIMESTAMP
);

-- Patients master-style table
CREATE TABLE IF NOT EXISTS patients_large(
    patient_row_id BIGSERIAL PRIMARY KEY,
    patient_id TEXT,
    first_name TEXT,
    last_name TEXT,
    birth_date DATE,
    gender TEXT,
    post_code TEXT,
    registration_date DATE,
    source_system TEXT,
    loaded_at DEFAULT CURRENT TIMESTAMP
);

-- Admissions transactional table
CREATE TABLE IF NOT EXISTS admisssions_large(
    admission_row_id BIGSERIAL PRIMARY KEY,
    admission_id TEXT,
    patient_id TEXT,
    department_id TEXT,
    provider_id TEXT,
    admission_date DATE,
    discharge_date DATE,
    admission_type TEXT,
    diagnosis_group TEXT,
    total_cost NUMERIC(12, 2),
    source_system TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_results_large (
    lab_result_row_id BIGSERIAL PRIMARY KEY,
    lab_result_id TEXT,
    admission_id TEXT,
    patient_id TEXT,
    test_name TEXT,
    result_value NUMERIC(10, 2),
    result_unit TEXT,
    test_date DATE,
    source_system TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);