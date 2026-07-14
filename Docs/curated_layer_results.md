# Curated Layer Results

## Purpose

The curated layer creates analysis-ready healthcare datasets from the cleaned layer.

The cleaned layer keeps all records and adds data quality flags. The curated layer applies documented exclusion rules to keep only records that are suitable for analysis, reporting or later machine learning.

Rejected records are not deleted. They remain available in the cleaned layer with quality flags, so the exclusion decisions stay traceable.

## Curated Layer Row Counts

| Dataset | Cleaned row count | Curated row count | Rejected row count | Rejected percentage |
|---|---:|---:|---:|---:|
| Patients | 1,000 | 969 | 31 | 3.10% |
| Departments | 8 | 7 | 1 | 12.50% |
| Providers | 50 | 48 | 2 | 4.00% |
| Admissions | 2,000 | 1,635 | 365 | 18.25% |
| Lab results | 5,000 | 4,079 | 921 | 18.42% |

## Rejection Summary

| Dataset | Total rejected | Rejected due to own quality issue | Rejected due to parent/join rule |
|---|---:|---:|---:|
| Patients | 31 | 31 | 0 |
| Departments | 1 | 1 | 0 |
| Providers | 2 | 2 | 0 |
| Admissions | 365 | 55 | 310 |
| Lab results | 921 | 65 | 856 |

## Interpretation

Patients, departments and providers are rejected only when they have their own quality issue.

Admissions and lab results are stricter. They must not only be valid themselves, but they must also link to curated parent or reference records.

For admissions, this means:

- the admission itself must have no admission-level quality issue
- the patient must exist in `curated_patients_large`
- the department must exist in `curated_departments_large`
- the provider must exist in `curated_providers_large`

For lab results, this means:

- the lab result itself must have no lab-result-level quality issue
- the admission must exist in `curated_admissions_large`
- the patient must exist in `curated_patients_large`

This explains why admissions and lab results have more rejected records than their own quality issue counts.

## Validation Results

The curated layer validation script produced:

| Validation type | Result |
|---|---:|
| Row count checks | 5 PASS / 0 FAIL |
| Own quality issue checks | 5 PASS / 0 FAIL |
| Parent/reference link checks | 5 PASS / 0 FAIL |
| Total expected-vs-actual checks | 15 PASS / 0 FAIL |

The validation confirms that:

- all curated views exist
- curated row counts match expected values
- curated records do not contain their own quality issues
- curated admissions link to curated patients, departments and providers
- curated lab results link to curated admissions and patients

## Key Design Decision

The curated layer is stricter than the cleaned layer.

The cleaned layer is used for traceability and quality investigation. The curated layer is used for analysis-ready datasets. This separation makes the pipeline more reliable because records are not silently removed; exclusions are documented and validated.

## Example: Parent/Join Rule

An admission can have no admission-level quality issue and still be rejected if its department does not exist in `curated_departments_large`.

A lab result can have a valid result value and still be rejected if its admission does not exist in `curated_admissions_large`.

This means a child record is only analysis-ready when both the child record and its required parent records are analysis-ready.

## Limitations

The current curated layer is based on SQL views and predefined exclusion rules.

Current limitations:

- rejection rules are strict and may need business review
- provider-to-department consistency is not yet fully validated
- the curated layer has not yet been exported or validated with Python
- no warehouse/star schema has been created yet
- no machine learning feature table has been built from the large curated dataset yet

## Next Improvements

Potential next improvements:

- add provider-to-department consistency checks
- create Python validation for curated exports
- build a warehouse layer with fact and dimension tables
- create analysis-ready feature tables
- document the full raw-to-cleaned-to-curated pipeline in the README