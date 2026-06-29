# Project Structure

This document explains the current folder and file structure of the Healthcare Data Quality SQL Pipeline project. The goal is to make the repository easier to understand, maintain and review.

## Main Folders

* `Data/Raw/`
  Contains the original raw CSV files used as input data.

* `Data/Processed/`
  Contains exported and validated intermediate data files.
  Current file: `feature_admission_v2.csv`.

* `SQL/`
  Contains PostgreSQL scripts for table creation, schema exploration, data quality checks, cleaned views, curated views, feature tables and validation summaries.

* `src/`
  Contains Python scripts used for profiling, validation and later analysis.

* `Docs/`
  Contains project documentation, validation contracts, design decisions, learning logs and project notes.

* `Notebooks/`
  Reserved for exploratory analysis and later ML experiments.
  Not currently part of the reproducible pipeline.

## Current Important Files

### SQL

* `SQL/00_create_tables.sql`
  Creates the base PostgreSQL tables.

* `SQL/02_data_quality_checks.sql`
  Contains initial data quality checks on the raw data.

* `SQL/05_cleaned_layer_views.sql`
  Creates cleaned views with standardized values and quality flags.

* `SQL/08_curated_analysis_views.sql`
  Creates curated views used for analysis.

* `SQL/12_feature_table_v2.sql`
  Creates the second version of the feature table.

* `SQL/13_feature_table_v2_quality_checks.sql`
  Validates the feature table.

* `SQL/14_analysis_ready_feature_view.sql`
  Creates an analysis-ready subset.

* `SQL/15_validation_summary.sql`
  Central SQL validation summary used to compare SQL results with Python output.

### Python

* `src/profile_feature_table.py`
  Reads the exported CSV file and validates row counts, missing values and quality flag distributions with pandas.

### Documentation

* `Docs/validation_contract.md`
  Defines the expected SQL results that Python output must match.

* `Docs/python_sql_validation_notes.md`
  Explains how the SQL output was validated with Python.

* `Docs/python_learning_log.md`
  Contains Python and debugging learning notes.

* `Docs/git_learning_log.md`
  Contains Git workflow and debugging notes.

* `Docs/data_quality_memo.md`
  Documents data quality findings, risks and actions.

* `Docs/quality_flag_map.md`
  Explains the quality flags used in the project.

## Documentation Categories

### Portfolio-Facing Documentation

These files explain the project to someone reviewing the repository:

* `validation_contract.md`
* `python_sql_validation_notes.md`
* `data_quality_memo.md`
* `quality_flag_map.md`
* `project_structure.md`

### Design Documentation

These files explain design decisions and pipeline layers:

* `cleaned_layer_design.md`
* `curated_layer_design.md`
* `feature_table_design.md`
* `feature_table_v2_design.md`
* `feature_table_v2_interpretation.md`
* `analysis_ready_decision_memo.md`
* `pipeline_overview.md`

### Learning Documentation

These files document learning progress and debugging lessons:

* `python_learning_log.md`
* `git_learning_log.md`
* `course_learning_log.md`
* `daily_recall.md`

## Current Pipeline Overview

Current flow:

1. Raw CSV data is loaded into PostgreSQL.
2. SQL data quality checks are performed.
3. Cleaned views are created.
4. Curated analysis views are created.
5. A feature table is built.
6. SQL validation results are stored in a validation summary.
7. The feature table is exported to CSV.
8. Python validates the CSV export against the SQL validation contract.

## Current Project Standard

Project-facing files should be written in English.

Chat-based coaching and concept explanation can remain in Dutch when needed. The preferred standard going forward:

* README: English
* Project documentation: English
* Code comments: English
* Commit messages: English