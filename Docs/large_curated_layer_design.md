# Large Curated Layer Design

## Purpose

The curated layer turns the cleaned healthcare dataset into analysis-ready datasets.

The cleaned layer keeps all records and makes data quality issues visible with flags. The curated layer uses those flags to decide which records are suitable for analysis, reporting or machine learning.

The goal is not to hide data quality problems. The goal is to make explicit, documented and reproducible decisions about which records can safely be used.

## Source Views

The curated layer is based on the following cleaned views:

- `cleaned_patients_large`
- `cleaned_departments_large`
- `cleaned_providers_large`
- `cleaned_admissions_large`
- `cleaned_lab_results_large`

## Curated Views

The curated layer will contain the following views:

- `curated_patients_large`
- `curated_departments_large`
- `curated_providers_large`
- `curated_admissions_large`
- `curated_lab_results_large`

## Layer Logic

### Raw Layer

The raw layer stores source-like data, including missing values, duplicates, invalid references and unrealistic values.

### Cleaned Layer

The cleaned layer standardizes selected fields and adds data quality flags. It does not remove records.

### Curated Layer

The curated layer applies explicit inclusion and exclusion rules. Records that are not safe enough for analysis are excluded from curated views, but they remain traceable in the cleaned layer.

## Curated Patient Rules

A patient record is considered analysis-ready when:

- `patient_id_cleaned` is present
- the patient ID is not duplicated
- birth date is not in the future
- birth date is not unrealistic
- gender is present
- gender is valid
- postcode is present

Patient records are excluded when one or more of the following flags are TRUE:

- `has_missing_patient_id`
- `has_duplicate_patient_id`
- `has_future_birth_date`
- `has_unrealistic_birth_date`
- `has_missing_gender`
- `has_invalid_gender`
- `has_missing_postcode`

## Curated Department Rules

A department record is considered analysis-ready when:

- department ID is present
- department name is present
- department status is active

Department records are excluded when one or more of the following flags are TRUE:

- `has_missing_department_id`
- `has_missing_department_name`
- `has_inactive_or_unknown_status`

## Curated Provider Rules

A provider record is considered analysis-ready when:

- provider ID is present
- department ID is present
- department ID exists in the department data
- active period is valid

Provider records are excluded when one or more of the following flags are TRUE:

- `has_missing_provider_id`
- `has_missing_department_id`
- `has_unknown_department_id`
- `has_invalid_active_period`

## Curated Admission Rules

An admission record is considered analysis-ready when:

- admission ID is present
- patient ID is present and known
- department ID is present and known
- provider ID is present and known
- discharge date is not before admission date
- total cost is not negative
- total cost is not an extreme outlier

Open admissions are excluded from the first curated admissions view because they are not suitable for completed-admission analysis such as length of stay and final cost analysis.

Admission records are excluded when one or more of the following flags are TRUE:

- `has_missing_admission_id`
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

## Curated Lab Result Rules

A lab result record is considered analysis-ready when:

- lab result ID is present
- admission ID is present and known
- patient ID is present and known
- test name is present
- result value is present
- result value is not negative
- result value is not an extreme outlier
- test date is not in the future

Lab result records are excluded when one or more of the following flags are TRUE:

- `has_missing_lab_result_id`
- `has_missing_admission_id`
- `has_unknown_admission_id`
- `has_missing_patient_id`
- `has_unknown_patient_id`
- `has_missing_test_name`
- `has_missing_result_value`
- `has_negative_result_value`
- `has_extreme_result_value`
- `has_future_test_date`

## Traceability

Rejected records are not deleted from the project. They remain available in the cleaned layer with their quality flags.

This makes it possible to explain:

- how many records were excluded
- which rules caused exclusion
- whether exclusion rules are too strict
- whether business stakeholders want different rules

## Design Decision

The curated layer is stricter than the cleaned layer.

The cleaned layer keeps all records and makes quality issues visible. The curated layer applies documented rules to create analysis-ready views. This makes the pipeline more reliable because data exclusions are explicit, reproducible and explainable.

## Expected Row Count Behavior

Curated views are expected to have fewer rows than cleaned views when records contain quality issues.

| Cleaned view | Curated view | Expected behavior |
|---|---|---|
| `cleaned_patients_large` | `curated_patients_large` | Curated row count may be lower |
| `cleaned_departments_large` | `curated_departments_large` | Curated row count may be lower |
| `cleaned_providers_large` | `curated_providers_large` | Curated row count may be lower |
| `cleaned_admissions_large` | `curated_admissions_large` | Curated row count may be lower |
| `cleaned_lab_results_large` | `curated_lab_results_large` | Curated row count may be lower |

This is intentional. The curated layer filters records that are not safe enough for analysis.