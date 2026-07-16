# Healthcare Data Quality SQL Pipeline

**Status:** Active development — the raw, cleaned and curated layers are complete; large feature-table design is in progress.

## Overview

This project demonstrates how I design, build and validate a layered healthcare data quality pipeline using PostgreSQL, SQL and selected Python validation scripts.

The pipeline transforms synthetic source data containing intentional quality issues into cleaned and curated datasets, while keeping rejected records visible and traceable. The repository provides practical evidence of skills in:

- PostgreSQL and SQL
- data modelling
- data quality analysis
- layered pipeline design
- validation and expected-vs-actual testing
- documentation
- Python and pandas validation
- Git and GitHub workflows

The project follows this architecture:

```text
Raw layer
    ↓
Cleaned layer
    ↓
Curated layer
    ↓
Planned: warehouse layer
    ↓
Planned: feature tables and ML evaluation
```

## Key Results

The current large synthetic healthcare pipeline contains five related entities:

| Entity | Raw row count |
|---|---:|
| Patients | 1,000 |
| Departments | 8 |
| Providers | 50 |
| Admissions | 2,000 |
| Lab results | 5,000 |

The current curated-layer validation produces:

```text
15 PASS / 0 FAIL
```

This result confirms that the implemented validation rules currently produce the expected outcomes. It does not prove that every possible data-quality risk has already been identified.

## Project Goal

The main goal is to turn source-like healthcare data into reliable, analysis-ready datasets through a reproducible and explainable pipeline.

The project focuses on more than writing individual SQL queries. It includes:

- source-data profiling
- documented data-quality rules
- cleaned and curated data layers
- traceable rejection logic
- validation scripts
- expected-vs-actual checks
- parent and reference integrity checks
- reproducible execution order
- portfolio-ready technical documentation

## Technology Stack

- PostgreSQL
- SQL
- Python
- pandas
- Git and GitHub
- Markdown documentation
- DBeaver or `psql`

## Dataset

The current large dataset is generated with SQL scripts. An earlier foundation dataset was loaded from CSV files.

All healthcare data in this repository is synthetic. The project does not contain real patient information.

The generated data intentionally includes quality problems such as:

- missing values
- duplicate business keys
- unknown references
- invalid dates
- open admissions
- negative values
- extreme values
- inconsistent categories
- invalid parent and reference relationships

These issues are used to practise realistic data-quality investigation, pipeline design and validation.

## Pipeline Layers

### 1. Raw Layer

The raw layer stores source-like healthcare data.

This layer intentionally allows data-quality issues. Problematic records are not silently rejected because they are needed for profiling, investigation and traceability.

Main scripts:

- `SQL/16_create_large_synthetic_tables.sql`
- `SQL/17_insert_large_synthetic_data.sql`
- `SQL/18_large_data_quality_checks.sql`

### 2. Cleaned Layer

The cleaned layer standardises selected fields and adds explicit quality flags.

It keeps the same row counts as the raw layer. Its purpose is to make quality problems visible and consistent, not to remove records.

Examples of cleaned-layer logic:

- trim and standardise text fields
- standardise categories
- convert empty strings to `NULL`
- flag missing values
- flag duplicate business keys
- flag unknown foreign-key references
- flag invalid dates
- flag negative or extreme numeric values

Main scripts:

- `SQL/19_cleaned_large_layer_views.sql`
- `SQL/20_cleaned_large_quality_checks.sql`

### 3. Curated Layer

The curated layer creates analysis-ready views from the cleaned layer.

It applies documented inclusion and exclusion rules. Records with blocking quality issues are excluded from curated views, but remain available in the cleaned layer with their quality flags.

For admissions:

- the admission must have no blocking admission-level quality issue
- the admission must link to a curated patient
- the admission must link to a curated department
- the admission must link to a curated provider

For lab results:

- the lab result must have no blocking lab-result-level quality issue
- the lab result must link to a curated admission
- the lab result must link to a curated patient

Main scripts:

- `SQL/21_curated_large_layer_views.sql`
- `SQL/22_curated_large_quality_checks.sql`

## Curated Layer Results

| Dataset | Cleaned row count | Curated row count | Rejected row count | Rejected percentage |
|---|---:|---:|---:|---:|
| Patients | 1,000 | 969 | 31 | 3.10% |
| Departments | 8 | 7 | 1 | 12.50% |
| Providers | 50 | 48 | 2 | 4.00% |
| Admissions | 2,000 | 1,635 | 365 | 18.25% |
| Lab results | 5,000 | 4,079 | 921 | 18.42% |

Admissions and lab results have higher rejection rates because child records must also link to curated parent and reference records.

## Curated Layer Validation

The curated validation script checks:

- whether all curated views exist
- cleaned versus curated row counts
- rejected row counts
- whether curated records still contain blocking quality issues
- whether child records link to curated parent and reference records
- expected-versus-actual outcomes
- sample rejected records with join diagnostics

Current validation results:

| Validation type | Result |
|---|---:|
| Row-count checks | 5 PASS / 0 FAIL |
| Own quality-issue checks | 5 PASS / 0 FAIL |
| Parent and reference link checks | 5 PASS / 0 FAIL |
| Total expected-versus-actual checks | 15 PASS / 0 FAIL |

## Key Design Principles

1. **Raw preserves the source.**  
   Source-like records remain available for investigation.

2. **Cleaned exposes quality issues.**  
   Fields are standardised and records receive explicit quality flags.

3. **Curated applies documented decisions.**  
   Only records meeting the defined requirements are made available for analysis.

4. **Validation tests the pipeline.**  
   Expected outcomes are compared with actual results.

5. **Rejected records remain traceable.**  
   Records are excluded from curated outputs, not silently deleted from the pipeline.

## Main Large-Dataset Scripts

| File | Purpose |
|---|---|
| `SQL/16_create_large_synthetic_tables.sql` | Create the raw large healthcare tables |
| `SQL/17_insert_large_synthetic_data.sql` | Insert synthetic healthcare records with intentional quality issues |
| `SQL/18_large_data_quality_checks.sql` | Profile and count quality issues in the raw dataset |
| `SQL/19_cleaned_large_layer_views.sql` | Create cleaned views with standardised fields and quality flags |
| `SQL/20_cleaned_large_quality_checks.sql` | Validate cleaned views and expected issue counts |
| `SQL/21_curated_large_layer_views.sql` | Create analysis-ready curated views |
| `SQL/22_curated_large_quality_checks.sql` | Validate curated row counts, exclusions and parent/reference links |

## Supporting Documentation

| File | Purpose |
|---|---|
| `Docs/pipeline_overview.md` | Explains the raw-to-cleaned-to-curated pipeline |
| `Docs/large_dataset_design.md` | Documents the large synthetic healthcare dataset design |
| `Docs/large_cleaned_layer_design.md` | Documents cleaned-layer logic and quality flags |
| `Docs/large_curated_layer_design.md` | Documents curated-layer inclusion and exclusion rules |
| `Docs/curated_layer_results.md` | Summarises curated row counts, rejected records and validation results |
| `Docs/project_structure.md` | Explains the repository structure and file organisation |

## Project Structure

| Folder | Purpose |
|---|---|
| `Data/Raw/` | Original CSV files for the foundation dataset |
| `Data/Processed/` | Exported and validated intermediate CSV files |
| `SQL/` | PostgreSQL scripts for table creation, profiling, cleaned views, curated views and validation |
| `src/` | Python scripts for profiling and validation |
| `Docs/` | Design decisions, validation notes, project documentation and learning logs |
| `Notebooks/` | Reserved for exploratory analysis and later machine-learning experiments |

## Foundation Pipeline

The project started with a smaller foundation dataset containing:

- `patients.csv`
- `admissions.csv`
- `lab_results.csv`

This first version was used to practise:

- raw table creation
- schema exploration
- SQL data-quality checks
- cleaned views
- curated analysis views
- admission-level feature tables
- SQL validation summaries
- Python validation with pandas

The validated foundation feature table is:

```text
feature_admission_v2
```

Foundation scripts include:

| File | Purpose |
|---|---|
| `SQL/00_create_tables.sql` | Create tables for the raw CSV data |
| `SQL/01_schema_exploration.sql` | Inspect tables, columns, row counts and basic values |
| `SQL/02_data_quality_checks.sql` | Identify and demonstrate data-quality issues |
| `SQL/05_cleaned_layer_views.sql` | Create cleaned views for the foundation dataset |
| `SQL/06_data_quality_report.sql` | Summarise data-quality issues |
| `SQL/07_quality_report_validation.sql` | Validate expected issue counts |
| `SQL/08_curated_analysis_views.sql` | Create curated analysis views |
| `SQL/10_feature_table_draft.sql` | Create the first admission-level feature table |
| `SQL/12_feature_table_v2.sql` | Create the improved feature table |
| `SQL/14_analysis_ready_feature_view.sql` | Create the analysis-ready feature subset |
| `SQL/15_validation_summary.sql` | Summarise final validation results |

Python validation for the foundation feature table is available in:

```text
src/profile_feature_table.py
```

Large-dataset profiling work is available in:

```text
src/profile_large_dataset.py
```

## How to Run the Current Large Pipeline

### Prerequisites

To run the current large-dataset pipeline, you need:

- PostgreSQL
- a PostgreSQL client such as DBeaver or `psql`
- a development database in which you have permission to create tables and views
- Git, when cloning the repository locally

### 1. Clone the Repository

```bash
git clone https://github.com/FeisNL/healthcare-data-quality-sql-pipeline.git
cd healthcare-data-quality-sql-pipeline
```

### 2. Connect to a Development Database

Open the SQL scripts in DBeaver, `psql`, or another PostgreSQL-compatible client.

Use a non-production database. The scripts create tables and views and are intended for development and portfolio use.

### 3. Run the SQL Scripts in Order

Run these scripts in numerical order:

1. `SQL/16_create_large_synthetic_tables.sql`  
   Creates the five raw healthcare tables.

2. `SQL/17_insert_large_synthetic_data.sql`  
   Generates and inserts synthetic healthcare records with intentional data-quality issues.

3. `SQL/18_large_data_quality_checks.sql`  
   Profiles the raw data and counts the identified quality issues.

4. `SQL/19_cleaned_large_layer_views.sql`  
   Creates cleaned views with standardised fields and quality flags.

5. `SQL/20_cleaned_large_quality_checks.sql`  
   Validates cleaned row counts and expected quality-issue counts.

6. `SQL/21_curated_large_layer_views.sql`  
   Creates curated views using the documented inclusion and exclusion rules.

7. `SQL/22_curated_large_quality_checks.sql`  
   Validates curated row counts, rejected records and parent/reference relationships.

### 4. Verify the Result

After running the final validation script, the current expected result is:

```text
15 PASS / 0 FAIL
```

A different result means that one or more scripts may not have been executed in the intended order, the database state differs from the expected setup, or an implementation change requires the expected values to be reviewed.

Python validation for the large curated datasets is still under development and is therefore not yet part of the required execution steps.

## Current Limitations

This project is not yet a complete machine-learning pipeline.

Current limitations:

- the large curated layer has not yet been exported and validated with Python
- no warehouse or star schema has been created yet
- provider-to-department consistency checks can be improved
- no large-dataset feature table has been implemented yet
- no target variable has been defined for machine learning
- leakage checks, train/test splitting and model evaluation are not implemented yet
- strict exclusion rules may require review by healthcare-domain stakeholders
- the synthetic dataset does not represent the full complexity of real healthcare systems

## Next Steps

1. Add provider-to-department consistency checks.
2. Add Python validation for curated exports.
3. Build a warehouse layer with fact and dimension tables.
4. Create analysis-ready feature tables for the large dataset.
5. Define a target variable for later machine-learning experimentation.
6. Add leakage checks before building any model.
7. Add automated tests and improve reproducibility instructions.
8. Expand the README with final architecture and result visuals.

## Repository Conventions

- Project-facing documentation is written in English.
- SQL scripts use numbered filenames to make the intended execution order clear.
- Data-quality rules and design decisions are documented separately from implementation.
- Validation results are compared with explicit expected outcomes.
- Rejected records remain traceable instead of being silently deleted.
- Changes are versioned through Git and documented with focused commits.

## Disclaimer

This repository is an educational and portfolio project. It uses synthetic healthcare data and is not intended for clinical decision-making or production healthcare use.