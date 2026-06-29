# Healthcare Data Quality SQL Pipeline

## Project Goal

This project builds a healthcare data quality pipeline using PostgreSQL and Python.

The goal is to load raw healthcare data, identify data quality issues, create cleaned and curated SQL views, build an admission-level feature table, and validate exported data with Python.

The focus is not only on writing SQL queries, but also on:

* data quality thinking
* reproducible SQL workflows
* validation checks
* documentation
* Python-based data validation
* portfolio-ready project structure

## Dataset

The project uses synthetic healthcare data from three CSV files:

* `patients.csv`
* `admissions.csv`
* `lab_results.csv`

The data intentionally contains quality issues, including:

* missing values
* duplicate records
* invalid dates
* inconsistent categories
* referential integrity issues
* negative values
* extreme values
* missing patient-derived features

These issues are used to practice realistic data quality checks and pipeline design.

## Current Status

The project currently includes:

* raw healthcare CSV data
* PostgreSQL table creation scripts
* schema exploration queries
* SQL data quality checks
* cleaned SQL views with quality flags
* curated analysis views
* an admission-level feature table
* feature-level quality flags
* an analysis-ready subset
* a SQL validation summary
* a validation contract
* Python validation of the exported feature table CSV

The current validated feature table is:

`feature_admission_v2`

## Project Structure

Main folders:

* `Data/Raw/`
  Original raw CSV files.

* `Data/Processed/`
  Exported and validated intermediate CSV files.

* `SQL/`
  PostgreSQL scripts for table creation, data quality checks, cleaned views, curated views, feature tables and validation summaries.

* `src/`
  Python scripts for profiling and validation.

* `Docs/`
  Project documentation, validation contracts, design notes and learning logs.

* `Notebooks/`
  Reserved for exploratory analysis and later ML experiments. Not currently part of the reproducible pipeline.

For a more detailed explanation, see:

`Docs/project_structure.md`

## Pipeline Overview

Current pipeline flow:

1. Load raw CSV data into PostgreSQL.
2. Explore table schemas and row counts.
3. Run initial SQL data quality checks.
4. Create cleaned views with standardized values and quality flags.
5. Create curated analysis views.
6. Build an admission-level feature table.
7. Add feature-level quality flags.
8. Create an analysis-ready subset.
9. Generate a SQL validation summary.
10. Export `feature_admission_v2` to CSV.
11. Validate the exported CSV with Python and pandas.

## Reproducible Run Order

To reproduce the current SQL pipeline, run the scripts in this order:

1. `SQL/00_create_tables.sql`
2. Import the CSV files from `Data/Raw/` into PostgreSQL.
3. `SQL/01_schema_exploration.sql`
4. `SQL/02_data_quality_checks.sql`
5. `SQL/05_cleaned_layer_views.sql`
6. `SQL/06_data_quality_report.sql`
7. `SQL/07_quality_report_validation.sql`
8. `SQL/08_curated_analysis_views.sql`
9. `SQL/09_curated_analysis_queries.sql`
10. `SQL/10_feature_table_draft.sql`
11. `SQL/11_feature_table_quality_checks.sql`
12. `SQL/12_feature_table_v2.sql`
13. `SQL/13_feature_table_v2_quality_checks.sql`
14. `SQL/14_analysis_ready_feature_view.sql`
15. `SQL/15_validation_summary.sql`

## Current Feature Table

The current feature table is created in:

`SQL/12_feature_table_v2.sql`

It contains admission-level records and includes feature-level quality flags:

* `has_missing_patient_features`
* `has_length_of_stay_issue`
* `has_cost_issue`
* `is_analysis_ready`

Current result:

* total records: `6`
* analysis-ready records: `1`
* rejected records: `5`

The analysis-ready subset is created in:

`SQL/14_analysis_ready_feature_view.sql`

This subset currently includes only records where:

`is_analysis_ready = TRUE`

## SQL Validation

The central SQL validation summary is stored in:

`SQL/15_validation_summary.sql`

This script produces the expected values used to validate the exported CSV in Python.

Current expected values:

| Check                                 | Expected Value |
| ------------------------------------- | -------------: |
| `feature_admission_v2` row count      |              6 |
| `is_analysis_ready = TRUE`            |              1 |
| `is_analysis_ready = FALSE`           |              5 |
| `has_missing_patient_features = TRUE` |              2 |
| `has_length_of_stay_issue = TRUE`     |              1 |
| `has_cost_issue = TRUE`               |              2 |

The validation contract is documented in:

`Docs/validation_contract.md`

## Python Validation

The project includes a first Python validation step.

The SQL view `feature_admission_v2` was exported to:

`Data/Processed/feature_admission_v2.csv`

The Python script:

`src/profile_feature_table.py`

loads the CSV with pandas and validates:

* row count
* column count
* missing values
* `is_analysis_ready` distribution
* issue flag distributions

Python confirmed that the exported CSV matches the SQL validation contract.

Current validation result:

* row count: `PASS`
* column count: `PASS`
* analysis-ready distribution: `PASS`
* issue flag counts: `PASS`

Related documentation:

* `Docs/validation_contract.md`
* `Docs/python_sql_validation_notes.md`
* `Docs/python_learning_log.md`

## Current Limitations

This project is not yet a complete machine learning pipeline.

Before machine learning can be added, the project still needs:

* target definition
* leakage checks
* train/test split
* metric selection
* baseline model
* error analysis
* clearer handling of rejected records
* larger or more realistic healthcare data

The current Python layer is used for validation and profiling, not for modeling yet.

## Next Steps

Planned next steps:

1. Clean up and standardize project documentation in English.
2. Improve README and documentation structure.
3. Add reproducible setup instructions.
4. Extend Python profiling beyond basic validation.
5. Prepare the feature table for later ML experimentation.
6. Add leakage checks before creating any ML model.
7. Convert project outputs into portfolio-ready documentation.

## Project Standard

Going forward, project-facing files should be written in English:

* README
* documentation
* code comments
* commit messages

Chat-based coaching and concept explanations remain in Dutch when useful.