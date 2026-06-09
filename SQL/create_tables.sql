DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS patients;

CREATE TABLE patients (
    patient_id TEXT,
    first_name TEXT,
    last_name TEXT,
    birth_date DATE,
    gender TEXT,
    postcode TEXT,
    registration_date DATE
);

CREATE TABLE admissions (
    admission_id TEXT,
    patient_id TEXT,
    admission_date DATE,
    discharge_date DATE,
    department TEXT,
    diagnosis_code TEXT,
    total_cost NUMERIC
);

CREATE TABLE lab_results (
    lab_result_id TEXT,
    patient_id TEXT,
    test_name TEXT,
    test_date DATE,
    result_value NUMERIC,
    result_unit TEXT
);