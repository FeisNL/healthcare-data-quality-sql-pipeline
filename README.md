# Healthcare Data Quality SQL Pipeline

## Project Goal

This project builds a healthcare data quality pipeline using PostgreSQL, SQL validation scripts and documented data quality rules, with Python validation added for selected pipeline outputs.

The main goal is to turn source-like healthcare data into reliable, analysis-ready datasets through a layered pipeline:

```text
Raw layer
↓
Cleaned layer
↓
Curated layer
↓
Later: warehouse layer / Python validation / feature tables / ML baseline
```

The focus is not only on writing SQL queries, but on building a reliable and explainable data pipeline with:

- data quality checks
- reproducible SQL workflows
- cleaned and curated data layers
- documented exclusion rules
- validation scripts
- expected-vs-actual checks
- traceable rejected records
- portfolio-ready documentation

## Current Project Status

The current main focus is the **large synthetic healthcare pipeline**.

This pipeline contains five main healthcare entities:

- patients
- departments
- providers
- admissions
- lab results

The project currently includes:

- raw large healthcare tables
- synthetic healthcare records with intentional data quality issues
- cleaned SQL views with standardized fields and quality flags
- curated analysis-ready SQL views
- SQL validation scripts for row counts, issue counts and parent/reference links
- expected-vs-actual PASS/FAIL validation checks
- documentation for dataset design, cleaned layer design and curated layer results

The curated layer validation currently produces:

```text
15 PASS / 0 FAIL
```

## Dataset

The current large dataset is generated with SQL scripts, while the earlier foundation dataset was loaded from CSV files.

The project uses synthetic healthcare data.

The current large dataset includes:

| Entity | Row count |
|---|---:|
| Patients | 1,000 |
| Departments | 8 |
| Providers | 50 |
| Admissions | 2,000 |
| Lab results | 5,000 |

The data intentionally contains quality issues, including:

- missing values
- duplicate business keys
- unknown references
- invalid dates
- open admissions
- negative values
- extreme values
- inconsistent categories
- invalid parent/reference relationships

These issues are used to practice realistic data quality checks, pipeline design and validation.

## Pipeline Layers

### 1. Raw Layer

The raw layer stores source-like healthcare data.

This layer intentionally allows data quality issues. It should not silently reject problematic records, because those records are needed for data quality investigation.

Main scripts:

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

Main scripts:

- `SQL/19_cleaned_large_layer_views.sql`
- `SQL/20_cleaned_large_quality_checks.sql`

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

Admissions and lab results have higher rejected counts because child records must also link to curated parent/reference records.

## Curated Layer Validation

The curated validation script checks:

- whether all curated views exist
- cleaned vs curated row counts
- rejected row counts
- whether curated records still contain their own quality issues
- whether child records link to curated parent/reference records
- expected-vs-actual validation results
- sample rejected records with parent/join diagnostics

Current validation result:

| Validation type | Result |
|---|---:|
| Row count checks | 5 PASS / 0 FAIL |
| Own quality issue checks | 5 PASS / 0 FAIL |
| Parent/reference link checks | 5 PASS / 0 FAIL |
| Total expected-vs-actual checks | 15 PASS / 0 FAIL |

## Key Design Principle

Cleaned makes data quality issues visible.  
Curated makes documented analysis-ready decisions.  
Validation checks prove whether each step is reliable enough.

Rejected records are not deleted. They remain traceable in the cleaned layer with quality flags.

## Main Large-Dataset Scripts

| File | Purpose |
|---|---|
| `SQL/16_create_large_synthetic_tables.sql` | Create raw large healthcare tables |
| `SQL/17_insert_large_synthetic_data.sql` | Insert synthetic healthcare records with intentional quality issues |
| `SQL/18_large_data_quality_checks.sql` | Profile and count quality issues in the raw large dataset |
| `SQL/19_cleaned_large_layer_views.sql` | Create cleaned views with standardized fields and quality flags |
| `SQL/20_cleaned_large_quality_checks.sql` | Validate cleaned views and expected issue counts |
| `SQL/21_curated_large_layer_views.sql` | Create analysis-ready curated views |
| `SQL/22_curated_large_quality_checks.sql` | Validate curated row counts, exclusions and parent/reference links |

## Supporting Documentation

| File | Purpose |
|---|---|
| `Docs/pipeline_overview.md` | Explains the full raw-to-cleaned-to-curated pipeline |
| `Docs/large_dataset_design.md` | Documents the large synthetic healthcare dataset design |
| `Docs/large_cleaned_layer_design.md` | Documents cleaned layer logic and quality flags |
| `Docs/large_curated_layer_design.md` | Documents curated layer inclusion and exclusion rules |
| `Docs/curated_layer_results.md` | Summarizes curated row counts, rejected records and validation results |

## Project Structure

Main folders:

| Folder | Purpose |
|---|---|
| `Data/Raw/` | Original raw CSV files for the foundation dataset |
| `Data/Processed/` | Exported and validated intermediate CSV files |
| `SQL/` | PostgreSQL scripts for table creation, data quality checks, cleaned views, curated views and validation |
| `src/` | Python scripts for profiling and validation |
| `Docs/` | Project documentation, validation notes, design decisions and learning logs |
| `Notebooks/` | Reserved for exploratory analysis and later ML experiments |

For a more detailed explanation, see:

- `Docs/project_structure.md`
- `Docs/pipeline_overview.md`

## Foundation Pipeline

The project started with a smaller foundation dataset using three CSV files:

- `patients.csv`
- `admissions.csv`
- `lab_results.csv`

This foundation pipeline was used to practice:

- raw table creation
- schema exploration
- SQL data quality checks
- cleaned views
- curated analysis views
- admission-level feature tables
- SQL validation summaries
- Python validation with pandas

The validated foundation feature table was:

```text
feature_admission_v2
```

The foundation pipeline is still part of the repository, but the current main focus is the larger synthetic healthcare pipeline.

Foundation scripts include:

| File | Purpose |
|---|---|
| `SQL/00_create_tables.sql` | Create tables for the raw CSV data |
| `SQL/01_schema_exploration.sql` | Inspect tables, columns, row counts and basic values |
| `SQL/02_data_quality_checks.sql` | Find and prove data quality issues |
| `SQL/05_cleaned_layer_views.sql` | Create cleaned views for the foundation dataset |
| `SQL/06_data_quality_report.sql` | Summarize data quality issues |
| `SQL/07_quality_report_validation.sql` | Validate expected issue counts |
| `SQL/08_curated_analysis_views.sql` | Create curated analysis views |
| `SQL/10_feature_table_draft.sql` | Create the first admission-level feature table |
| `SQL/12_feature_table_v2.sql` | Create the improved feature table |
| `SQL/14_analysis_ready_feature_view.sql` | Create the analysis-ready feature subset |
| `SQL/15_validation_summary.sql` | Summarize final validation results |

Python validation for the foundation feature table is available in:

```text
src/profile_feature_table.py
```

Large-dataset profiling and validation work is available in:

```text
src/profile_large_dataset.py
```

## Current Limitations

This project is not yet a complete machine learning pipeline.

Current limitations:

- the large curated layer has not yet been exported and validated with Python
- no warehouse/star schema has been created yet
- provider-to-department consistency checks can be improved
- no large-dataset feature table has been built yet
- no target variable has been defined for machine learning
- leakage checks, train/test split and model evaluation are not implemented yet
- business review may be needed for strict exclusion rules

## Next Steps

Planned next steps:

1. Add provider-to-department consistency checks.
2. Add Python validation for curated exports.
3. Build a warehouse layer with fact and dimension tables.
4. Create analysis-ready feature tables for the large dataset.
5. Define a target variable for later ML experimentation.
6. Add leakage checks before building any ML model.
7. Prepare portfolio-ready setup and reproducibility instructions.

## Project Standard

Project-facing files should be written in English:

- README
- documentation
- code comments
- commit messages

Chat-based coaching and concept explanations can remain in Dutch when useful.