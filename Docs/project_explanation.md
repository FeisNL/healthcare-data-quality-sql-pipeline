# Project Explanation

## One-Minute Explanation

This project is a healthcare data quality pipeline built with PostgreSQL.

The goal is to turn source-like healthcare data into reliable, analysis-ready datasets. I built the pipeline in layers: raw, cleaned and curated.

The raw layer keeps source-like data, including intentional quality issues. The cleaned layer keeps all records, standardizes selected fields and adds quality flags. The curated layer applies documented exclusion rules to create analysis-ready views.

A key part of the project is validation. I wrote SQL checks for row counts, data quality issues, rejected records, parent/reference links and expected-vs-actual results.

The current large synthetic healthcare pipeline includes patients, departments, providers, admissions and lab results. The curated validation produced 15 checks: 15 PASS / 0 FAIL.

The project is not yet a full machine learning pipeline. The next steps are Python validation for large curated exports, warehouse modeling, feature tables and later ML evaluation.

## Problem

Healthcare data can contain many quality issues, such as:

- missing values
- duplicate business keys
- unknown references
- invalid dates
- open admissions
- negative values
- extreme values
- invalid parent/reference relationships

If these issues are not detected and documented, analysis and machine learning outputs can become unreliable.

## Approach

I used a layered SQL pipeline:

```text
Raw layer
↓
Cleaned layer
↓
Curated layer
```

### Raw Layer

The raw layer preserves source-like data, including quality issues.

This is important because problematic records should not be silently removed before they are investigated.

### Cleaned Layer

The cleaned layer standardizes selected fields and adds quality flags.

It does not remove records. It makes problems visible and traceable.

Examples of cleaned-layer checks include:

- missing IDs
- duplicate patient IDs
- unknown patient, department and provider references
- invalid admission dates
- negative or extreme costs
- invalid lab result values

### Curated Layer

The curated layer creates analysis-ready datasets.

It applies documented exclusion rules. Records with relevant quality issues are excluded from curated views, but remain available in the cleaned layer.

For child tables, the curated layer also checks parent/reference records.

For example:

- admissions must link to curated patients, departments and providers
- lab results must link to curated admissions and patients

## Validation

The curated validation script checks:

- whether all curated views exist
- cleaned vs curated row counts
- rejected row counts
- own quality issue counts
- parent/reference link checks
- expected-vs-actual PASS/FAIL results
- sample rejected records with parent/join diagnostics

Current result:

```text
15 PASS / 0 FAIL
```

## Key Results

| Dataset | Cleaned row count | Curated row count | Rejected row count | Rejected percentage |
|---|---:|---:|---:|---:|
| Patients | 1,000 | 969 | 31 | 3.10% |
| Departments | 8 | 7 | 1 | 12.50% |
| Providers | 50 | 48 | 2 | 4.00% |
| Admissions | 2,000 | 1,635 | 365 | 18.25% |
| Lab results | 5,000 | 4,079 | 921 | 18.42% |

Admissions and lab results have higher rejected counts because they must also link to curated parent/reference records.

## What This Project Demonstrates

This project demonstrates that I can:

- design a layered SQL data quality pipeline
- identify and document data quality issues
- separate raw, cleaned and curated responsibilities
- write SQL validation checks
- use expected-vs-actual PASS/FAIL validation
- keep rejected records traceable
- explain technical decisions clearly

## Current Limitations

The project is still in progress.

Current limitations:

- the large curated layer has not yet been exported and validated with Python
- no warehouse/star schema has been created yet
- no large-dataset feature table has been built yet
- provider-to-department consistency checks can be improved
- no target variable has been defined for machine learning
- leakage checks and model evaluation are not implemented yet

## Next Steps

Planned next steps:

1. Add provider-to-department consistency checks.
2. Add Python validation for curated exports.
3. Build a warehouse layer with fact and dimension tables.
4. Create analysis-ready feature tables for the large dataset.
5. Prepare the project for later ML evaluation.

## Interview Version

I built a healthcare data quality pipeline in PostgreSQL using a raw, cleaned and curated architecture.

The raw layer preserves source-like data, including quality issues. The cleaned layer keeps all records but standardizes fields and adds quality flags. The curated layer applies documented exclusion rules to create analysis-ready views.

The most important part is that I did not just transform the data. I validated the pipeline with SQL checks for row counts, rejected records, own quality issues, parent/reference links and expected-vs-actual PASS/FAIL results.

For the current large synthetic healthcare dataset, the curated validation produced 15 PASS and 0 FAIL checks. This shows that the curated views match expected row counts, contain no own quality issues and only include child records that link to curated parent records.

The project is still being extended with Python validation, warehouse modeling, feature tables and later ML evaluation.