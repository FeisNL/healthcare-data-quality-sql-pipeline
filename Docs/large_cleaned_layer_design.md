# Large Cleaned Layer Design

## Purpose

The cleaned layer standardizes the large raw healthcare dataset and adds explicit data quality flags.

The purpose of this layer is not to silently remove bad records. The goal is to make data quality issues visible, traceable and explainable before the data is used for analysis, reporting or machine learning.

## Source Tables

The cleaned layer is based on the following raw/sandbox tables:

- `patients_large`
- `departments_large`
- `providers_large`
- `admissions_large`
- `lab_results_large`

## Cleaned Views

The cleaned layer will contain the following views:

- `cleaned_patients_large`
- `cleaned_departments_large`
- `cleaned_providers_large`
- `cleaned_admissions_large`
- `cleaned_lab_results_large`

## Cleaning Strategy

The cleaned layer follows these rules:

- Keep technical row IDs for traceability.
- Keep source/business IDs for joins and business interpretation.
- Standardize text fields where useful.
- Add boolean flags for data quality issues.
- Do not silently delete invalid records.
- Use SQL views so the cleaned layer can be rebuilt from the raw layer.
- Let the curated layer later decide which records are analysis-ready.

## Main Data Quality Flags

### Patients

Patient quality flags focus on identity, demographics and basic validity.

Planned flags:

- `has_missing_patient_id`
- `has_duplicate_patient_id`
- `has_future_birth_date`
- `has_unrealistic_birth_date`
- `has_missing_gender`
- `has_invalid_gender`
- `has_missing_postcode`
- `has_patient_quality_issue`

### Departments

Department quality flags focus on reference data consistency.

Planned flags:

- `has_missing_department_id`
- `has_missing_department_name`
- `has_inactive_or_unknown_status`
- `has_department_quality_issue`

### Providers

Provider quality flags focus on provider identity and valid department references.

Planned flags:

- `has_missing_provider_id`
- `has_missing_department_id`
- `has_unknown_department_id`
- `has_invalid_active_period`
- `has_provider_quality_issue`

### Admissions

Admission quality flags focus on referential integrity, dates and costs.

Planned flags:

- `has_missing_patient_id`
- `has_unknown_patient_id`
- `has_missing_department_id`
- `has_unknown_department_id`
- `has_missing_provider_id`
- `has_unknown_provider_id`
- `has_discharge_before_admission`
- `has_open_admission`
- `has_negative_total_cost`
- `has_extreme_total_cost`
- `has_admission_quality_issue`

### Lab Results

Lab result quality flags focus on valid references, lab values and test dates.

Planned flags:

- `has_missing_admission_id`
- `has_unknown_admission_id`
- `has_missing_patient_id`
- `has_unknown_patient_id`
- `has_negative_result_value`
- `has_extreme_result_value`
- `has_future_test_date`
- `has_lab_result_quality_issue`

## Design Decision

The raw layer allows bad data so that data quality problems can be detected.

The cleaned layer does not remove bad data. It makes data quality problems explicit by adding standardized fields and boolean flags.

The curated layer will later use these flags to decide which records are safe enough for analysis, reporting or machine learning.

## Expected Row Count Behavior

The cleaned views should keep the same number of rows as the raw tables:

| Raw table | Cleaned view | Expected behavior |
|---|---|---|
| `patients_large` | `cleaned_patients_large` | Same row count |
| `departments_large` | `cleaned_departments_large` | Same row count |
| `providers_large` | `cleaned_providers_large` | Same row count |
| `admissions_large` | `cleaned_admissions_large` | Same row count |
| `lab_results_large` | `cleaned_lab_results_large` | Same row count |

This is intentional. The cleaned layer flags quality issues but does not filter records yet.