# Large Feature Table V1 Design

## Purpose

This document defines the design for the first large admission-level feature table based on the curated healthcare layer.

The goal of this feature table is to create an analysis-ready dataset where each row represents one curated admission. This table will be used as a foundation for later analysis, validation and potential machine learning experiments.

## Grain

The grain of this feature table is:

1 row = 1 curated admission

This means each admission_id should appear only once in the feature table.

The feature table should preserve the row count of curated_admissions_large, unless an additional exclusion rule is explicitly introduced and documented.

## Source Views

The feature table will be based on the following curated views:

- curated_admissions_large
- curated_patients_large
- curated_departments_large
- curated_providers_large

The main source view is curated_admissions_large, because the feature table is admission-level.

The other views provide patient, department and provider context for each curated admission.

## Included Features

The first version of the feature table will include the following features:

- admission_id
- patient_id
- age_at_admission
- gender
- admission_type
- diagnosis_group
- department_id
- department_name
- provider_id
- provider_department_id
- provider_department_mismatch_warning

These features are included because they fit the admission-level grain and can be linked from curated views without causing row multiplication.

Some features may still require careful interpretation for machine learning use cases. For example, gender, provider_id and diagnosis_group may introduce bias, overfitting or timing-related risks depending on the target and prediction moment.

## Excluded or Deferred Features

Lab result features are deferred to large_feature_table_v2.

Lab results are not directly joined in v1 because curated_lab_results_large has a different grain:

1 row = 1 lab result

A direct join between admissions and lab results could multiply admission rows and break the admission-level grain. Lab results must first be aggregated to admission level before they can be safely added as features.

Examples of future lab aggregation features include:

- lab_result_count
- abnormal_lab_result_count
- latest_lab_result_date

The following fields are treated carefully:

- discharge_date
- total_cost
- length_of_stay_days

These fields can be useful for analysis, but they may be post-admission outcome fields. For an early prediction machine learning model, they could cause leakage if used as input features.

## Data Quality Assumptions

This feature table assumes that the curated layer has already applied the main data quality rules.

In particular:

- curated admissions link to curated patients
- curated admissions link to curated departments
- curated admissions link to curated providers

This means the feature table starts from records that have already passed the curated layer inclusion rules.

However, the provider-to-department mismatch remains a warning, not a blocking exclusion rule. This warning is included as a feature so that the known relationship consistency issue remains visible in downstream analysis.

## Leakage Risks
The following fields may cause leakage in early prediction use cases:
discharge_date
total_cost
length_of_stay_days 

These fields may only be known after or near the end of an admission. If the goal is to predict an outcome at admission start, these fields should not be used as input features.

For example, total_cost should not be used as an input feature when predicting high_cost_admission, because it would directly reveal the target.

These fields may still be valid for descriptive analysis, reporting or target creation, depending on the use case.

## Relationship Consistency Warning

The previous relationship consistency check found a high mismatch rate between curated_admissions_large.department_id and curated_providers_large.department_id.

This means some admissions have a provider whose assigned department differs from the admission department.

This issue is treated as a warning, not as a blocking exclusion rule, because the business meaning of admission department and provider department has not yet been confirmed.

The feature table will include provider_department_mismatch_warning.

This makes the warning visible without removing records from the feature table.

## Validation Plan

The feature table should be validated with the following checks:

- check feature table row count
- check one row per admission_id
- check no missing required IDs
- check joins do not multiply rows
- check provider_department_mismatch_warning distribution
- check key feature completeness

The expected row count should match curated_admissions_large, unless an additional exclusion rule is explicitly introduced.

The check for one row per admission_id is important because the feature table grain is admission-level.

## Next Steps

The next steps are:

- create SQL/24_feature_admission_large_v1.sql
- validate row count and grain
- validate required IDs and warning distributions
- review the SQL script before Git commit
- later add lab result aggregations in v2