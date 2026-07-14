# Pipeline Overview

## Purpose

This project builds a healthcare data quality pipeline using PostgreSQL, SQL validation scripts and documented data quality rules.

The goal is to turn source-like healthcare data into reliable, analysis-ready datasets through a layered pipeline.

Current main pipeline:

```text
Raw layer
↓
Cleaned layer
↓
Curated layer
↓
Later: warehouse layer / Python validation / feature tables / ML baseline
```

Each layer has a different responsibility. This separation makes the pipeline easier to validate, explain and extend.

## Project Structure

The project contains two related pipeline stages:

1. **Foundation pipeline**  
   A smaller healthcare dataset used to practice core SQL, data quality checks, cleaned views, curated views and feature table logic.

2. **Large synthetic healthcare pipeline**  
   A larger synthetic healthcare dataset used to build a more realistic raw-to-cleaned-to-curated data quality pipeline.

The large pipeline is currently the main focus.

## Current Pipeline Layers

### 1. Raw Layer

The raw layer stores source-like healthcare data.

This layer intentionally allows data quality issues such as:

- missing values
- duplicate business keys
- unknown references
- invalid dates
- negative values
- extreme values
- inconsistent categories

The raw layer is used for loading and initial investigation. It should not silently reject problematic records, because those records are needed for data quality analysis.

Main large-dataset scripts:

- `SQL/16_create_large_synthetic_tables.sql`
- `SQL/17_insert_large_synthetic_data.sql`
- `SQL/18_large_data_quality_checks.sql`

### 2. Cleaned Layer

The cleaned layer standardizes selected fields and adds quality flags.

The cleaned layer does not remove records. It keeps the same row counts as the raw layer, but makes data quality issues visible and traceable.

Examples of cleaned-layer logic:

- trim and standardize text fields
- standardize categories
- convert empty strings to `NULL`
- flag missing values
- flag duplicate business keys
- flag unknown foreign key references
- flag invalid dates
- flag negative or extreme numeric values

Main large-dataset scripts:

- `SQL/19_cleaned_large_layer_views.sql`
- `SQL/20_cleaned_large_quality_checks.sql`

Key design decision:

The cleaned layer is used for transparency. It shows which records have quality issues, but it does not decide yet whether records are safe enough for analysis.

### 3. Curated Layer

The curated layer creates analysis-ready views from the cleaned layer.

This layer applies documented exclusion rules. Records with relevant quality issues are excluded from curated views, but they remain available in the cleaned layer with their quality flags.

For child tables, the curated layer is stricter than checking only the record itself.

For admissions:

- the admission itself must have no admission-level quality issue
- the admission must link to a curated patient
- the admission must link to a curated department
- the admission must link to a curated provider

For lab results:

- the lab result itself must have no lab-result-level quality issue
- the lab result must link to a curated admission
- the lab result must link to a curated patient

Main large-dataset scripts:

- `SQL/21_curated_large_layer_views.sql`
- `SQL/22_curated_large_quality_checks.sql`

Supporting documentation:

- `Docs/large_curated_layer_design.md`
- `Docs/curated_layer_results.md`

## Layer Responsibilities

| Layer | Main responsibility | Removes records? | Main purpose |
|---|---|---:|---|
| Raw | Store source-like data | No | Preserve loaded data for investigation |
| Cleaned | Standardize fields and add quality flags | No | Make data quality issues visible |
| Curated | Apply documented analysis-ready rules | Yes | Create reliable datasets for analysis |

## Validation Approach

Transformation scripts create or update pipeline objects. Validation scripts check whether those objects behave as expected.

Validation includes:

- row count checks
- issue count checks
- expected-vs-actual checks
- own quality issue checks
- parent/reference link checks
- rejected record inspection

The curated layer validation produced:

```text
15 PASS / 0 FAIL
```

This means:

- curated row counts matched expected values
- curated records did not contain their own quality issues
- curated admissions linked to curated patients, departments and providers
- curated lab results linked to curated admissions and patients

## Curated Layer Results

| Dataset | Cleaned row count | Curated row count | Rejected row count | Rejected percentage |
|---|---:|---:|---:|---:|
| Patients | 1,000 | 969 | 31 | 3.10% |
| Departments | 8 | 7 | 1 | 12.50% |
| Providers | 50 | 48 | 2 | 4.00% |
| Admissions | 2,000 | 1,635 | 365 | 18.25% |
| Lab results | 5,000 | 4,079 | 921 | 18.42% |

Admissions and lab results have higher rejected counts because they must also link to curated parent/reference records.

## Foundation Pipeline

The foundation pipeline was used to build the first version of the project on a smaller healthcare dataset.

It includes:

```text
Source CSV files
↓
Raw tables
↓
Schema exploration
↓
Data quality checks
↓
Cleaned views
↓
Data quality report
↓
Validation checks
↓
Curated analysis views
↓
Curated analysis queries
↓
Feature table draft
↓
Feature table quality checks
↓
Feature table v2
↓
Analysis-ready feature view
```

Foundation scripts:

| Layer / step | File | Purpose |
|---|---|---|
| Raw table creation | `SQL/00_create_tables.sql` | Create tables for the raw CSV data |
| Schema exploration | `SQL/01_schema_exploration.sql` | Inspect tables, columns, row counts and basic values |
| Data quality checks | `SQL/02_data_quality_checks.sql` | Find and prove data quality issues |
| SQL refresh exercises | `SQL/03_sql_refresh_exercises.sql` | Practice SQL fundamentals |
| Own checks | `SQL/04_my_own_checks.sql` | Practice writing independent data quality checks |
| Cleaned views | `SQL/05_cleaned_layer_views.sql` | Keep all records, standardize fields and add quality flags |
| Data quality report | `SQL/06_data_quality_report.sql` | Summarize quality flags with issue counts and severity |
| Report validation | `SQL/07_quality_report_validation.sql` | Validate whether issue counts match expected results |
| Curated views | `SQL/08_curated_analysis_views.sql` | Create analysis-focused subsets based on blocking flags |
| Curated analyses | `SQL/09_curated_analysis_queries.sql` | Run first technical analyses on curated data |
| Feature table draft | `SQL/10_feature_table_draft.sql` | Create the first admission-level feature table |
| Feature table checks | `SQL/11_feature_table_quality_checks.sql` | Check feature table grain, NULLs, dates and costs |
| Feature table v2 | `SQL/12_feature_table_v2.sql` | Add extra feature-level quality flags |
| Feature table v2 checks | `SQL/13_feature_table_v2_quality_checks.sql` | Validate new flags and analysis readiness |
| Analysis-ready feature view | `SQL/14_analysis_ready_feature_view.sql` | Create the final analysis-ready feature view for the small dataset |
| Validation summary | `SQL/15_validation_summary.sql` | Summarize final validation results |

## Large Synthetic Healthcare Pipeline

The large synthetic healthcare pipeline extends the same principles to a more realistic dataset size and structure.

Large pipeline scripts:

| Layer / step | File | Purpose |
|---|---|---|
| Large table creation | `SQL/16_create_large_synthetic_tables.sql` | Create raw large healthcare tables |
| Large data generation | `SQL/17_insert_large_synthetic_data.sql` | Insert synthetic healthcare records with intentional quality issues |
| Large data quality checks | `SQL/18_large_data_quality_checks.sql` | Profile and count quality issues in the raw large dataset |
| Cleaned large views | `SQL/19_cleaned_large_layer_views.sql` | Create cleaned views with standardized fields and quality flags |
| Cleaned large validation | `SQL/20_cleaned_large_quality_checks.sql` | Validate cleaned views and expected issue counts |
| Curated large views | `SQL/21_curated_large_layer_views.sql` | Create analysis-ready curated views |
| Curated large validation | `SQL/22_curated_large_quality_checks.sql` | Validate curated row counts, exclusions and parent/reference links |

Supporting large-pipeline documentation:

- `Docs/large_dataset_design.md`
- `Docs/large_cleaned_layer_design.md`
- `Docs/large_curated_layer_design.md`
- `Docs/curated_layer_results.md`

## Traceability

Rejected records are not deleted from the project.

They remain available in the cleaned layer with quality flags. This makes it possible to explain:

- which records were excluded
- why records were excluded
- whether the exclusion rules are too strict
- which rules may need business review

## Key Principle

Cleaned makes problems visible.  
Curated makes documented analysis-ready decisions.  
Validation checks prove whether each step is reliable enough.

## Next Pipeline Improvements

Planned next improvements:

- add provider-to-department consistency checks
- add Python validation for curated exports
- build a warehouse layer with fact and dimension tables
- create analysis-ready feature tables for the large dataset
- prepare the dataset for later machine learning evaluation