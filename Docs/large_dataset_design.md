# Large Synthetic Healthcare Dataset Design

## Purpose

This dataset is used to scale the healthcare data quality pipeline from a small controlled dataset to a larger relational healthcare dataset. The goal is to practice PostgreSQL, data quality checks, SQL validation, Python/pandas validation and agent-ready workflow design.

## Tables

The first version contains five large tables:

1. `patients_large`
2. `departments_large`
3. `providers_large`
4. `admissions_large`
5. `lab_results_large`

Future extensions may include:

1. `diagnoses_large`
2. `medications_large`
3. `procedures_large`
4. `claims_large`
5. `appointments_large`

## Relationships

- `patients_large.patient_id` links to `admissions_large.patient_id`
- `departments_large.department_id` links to `admissions_large.department_id`
- `providers_large.provider_id` links to `admissions_large.provider_id`
- `admissions_large.admission_id` links to `lab_results_large.admission_id`
- `patients_large.patient_id` links to `lab_results_large.patient_id`

## Constraints Strategy

The `*_large` tables are designed as synthetic raw/sandbox tables. They contain logical keys such as `patient_id`, `admission_id`, `department_id` and `provider_id`, but not every relationship is enforced with hard foreign key constraints at the raw layer.

This is intentional. The purpose of the raw layer is to load both valid and invalid records so data quality issues can be detected, counted and documented. For example, an admission can contain an unknown `patient_id`. If a hard foreign key constraint were enforced immediately, this invalid record would be rejected during loading and could not be analyzed as a data quality issue.

Referential integrity is therefore validated with SQL checks in the raw layer. Invalid records are flagged in the cleaned layer and excluded or handled explicitly in the curated layer.

## Cardinality

The first version of the large synthetic healthcare dataset uses mostly one-to-many relationships.

- One patient can have zero or many admissions.
- One department can have zero or many admissions.
- One provider can handle zero or many admissions.
- One admission can have zero or many lab results.
- One patient can have zero or many lab results.

This means that joins must be handled carefully. For example, joining `admissions_large` to `lab_results_large` can multiply rows because one admission can have multiple lab results. This is expected behavior, but it must be considered when calculating counts, averages or costs.

### Join Grain Risk

The expected relationship between `patients_large` and `admissions_large` is one patient to many admissions. However, because the raw layer allows duplicate `patient_id` values, joining admissions to patients on `patient_id` can multiply admission rows.

For example, if one admission references `patient_id = P0002` and `patients_large` contains two raw rows with `patient_id = P0002`, the join will return two rows for the same admission. This can distort admission counts, cost totals and patient-level features.

The technical `patient_row_id` helps identify the exact raw patient rows that caused the duplicate match. Duplicate business keys must therefore be detected before using joined data for analysis or machine learning.

## Business Logic

The dataset includes business rules that should be checked before the data is used for analysis or machine learning.

Important business rules:

- Every admission should refer to a valid patient.
- Every admission should refer to a valid department.
- Every admission should refer to a valid provider.
- A discharge date should not be earlier than the admission date.
- A total cost should not be negative.
- Extremely high total cost values should be flagged as possible outliers.
- Every lab result should refer to a valid admission.
- Every lab result should refer to a valid patient.
- Lab result values should be within realistic ranges for the test type.
- Lab result dates should not be in the future.

These rules are not all enforced as hard constraints in the raw/sandbox tables. Instead, they are first validated with SQL data quality checks. Invalid records are later flagged in the cleaned layer and excluded or handled explicitly in the curated layer.

## Entity Relationship Diagram

```mermaid
erDiagram
    patients_large ||--o{ admissions_large : has
    departments_large ||--o{ admissions_large : receives
    providers_large ||--o{ admissions_large : handles
    admissions_large ||--o{ lab_results_large : produces
    patients_large ||--o{ lab_results_large : has

    patients_large {
        text patient_id PK
        text first_name
        text last_name
        date birth_date
        text gender
        date registration_date
    }

    departments_large {
        text department_id PK
        text department_name
        text department_category
    }

    providers_large {
        text provider_id PK
        text provider_name
        text specialty
        text department_id FK
    }

    admissions_large {
        text admission_id PK
        text patient_id FK
        text department_id FK
        text provider_id FK
        date admission_date
        date discharge_date
        numeric total_cost
    }

    lab_results_large {
        text lab_result_id PK
        text admission_id FK
        text patient_id FK
        text test_name
        numeric result_value
        text result_unit
        date test_date
    }

## Intentional Data Quality Issues

The synthetic dataset will include intentional data quality issues:

- missing patient values
- duplicate identifiers
- unknown foreign keys
- invalid admission dates
- negative cost values
- extreme cost outliers
- inconsistent department names
- invalid lab result values
- future lab result dates
- missing provider or department references

## SQL Skills to Train

This dataset is designed to train:

- DDL with `CREATE TABLE`
- DML with synthetic inserts
- joins
- `GROUP BY`
- `HAVING`
- `CASE WHEN`
- CTEs
- data quality checks
- referential integrity checks
- aggregation checks
- future window functions

## Python Validation Plan

Python will be used to validate SQL outputs and exported datasets with pandas. The validation layer will check:

- row counts
- column names
- missing values
- duplicate identifiers
- expected vs actual data quality counts
- SQL summary outputs against pandas summary outputs

## Agent-Ready Requirements

The dataset and scripts should be designed so that a future agent can work safely within clear boundaries.

Agent-ready requirements:

- work only on sandbox tables
- never modify production tables
- show SQL before execution
- log expected and actual results
- validate outputs with Python
- block destructive SQL unless explicitly approved
- use Git diff review before committing changes
- keep human approval as the final control layer