# Healthcare Data Quality SQL Pipeline

## 1. Projectdoel

Dit project controleert de kwaliteit van synthetische healthcare-data met SQL. De focus ligt op missing values, duplicaten, ongeldige waarden, foutieve datums, inconsistente categorieën, referentiële fouten en outliers.

Het project is opgezet als eerste portfolio-project binnen het AI/Data Application Engineer-traject. De nadruk ligt niet alleen op SQL-query’s schrijven, maar ook op data quality-denken, documentatie, reproduceerbaarheid en het ontwerpen van een eerste cleaned layer.

## 2. Dataset

De dataset bestaat uit drie CSV-bestanden:

- `patients.csv`
- `admissions.csv`
- `lab_results.csv`

De data bevat bewust fouten, zodat data quality checks getest kunnen worden. Voorbeelden van ingebouwde fouten zijn ontbrekende patiënt-ID’s, dubbele records, toekomstige datums, inconsistente categorieën, referentiële fouten en negatieve of extreme waarden.

## 3. Eerste focus

De eerste fase richt zich op:

- schema exploration;
- data profiling;
- data quality checks;
- documentatie van bevindingen;
- ontwerp van een cleaned layer;
- SQL views met quality flags;
- versiebeheer met Git.

## 4. Projectstructuur

```text
healthcare-data-quality-sql-pipeline/
├── Data/
│   └── Raw/
│       ├── patients.csv
│       ├── admissions.csv
│       └── lab_results.csv
├── Docs/
│   ├── data_quality_memo.md
│   └── cleaned_layer_design.md
├── SQL/
│   ├── 00_create_tables.sql
│   ├── 01_schema_exploration.sql
│   ├── 02_data_quality_checks.sql
│   ├── 03_sql_refresh_exercises.sql
│   ├── 04_my_own_checks.sql
│   └── 05_cleaned_layer_views.sql
└── README.mdBlok 7 klaar:

## 5. Data Quality Report

The project now includes an initial SQL-based data quality report:

- `SQL/06_data_quality_report.sql`

This report summarizes quality flags from the cleaned views and counts the number of issue records per entity and quality check.

Current report scope:

- patient quality checks;
- admission quality checks;
- lab result quality checks.

The report uses `UNION ALL` to combine issue counts from multiple cleaned views into one reproducible overview. Duplicate flags are counted at record level, meaning that all records involved in a duplicate issue are included in the issue count.

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

The cleaned views should preserve the raw row counts:

- `cleaned_patients`: 10 records
- `cleaned_admissions`: 10 records
- `cleaned_lab_results`: 10 records

If a cleaned view returns more rows than the raw table, this may indicate row multiplication caused by a join on a non-unique key.

## Feature Table Draft

The project now includes a first draft of an admission-level feature table:

- `SQL/10_feature_table_draft.sql`
- `Docs/feature_table_design.md`

The feature table uses curated admissions and curated patients as input. It includes derived fields such as `length_of_stay_days` and `age_at_admission`.

The first feature table check showed that some admissions can have NULL patient features when the admission remains in `curated_admissions`, but the linked patient is excluded from `curated_patients`. These cases are documented as a data quality design issue.

This is not yet a machine learning dataset. A target variable, leakage checks, train/test split and evaluation strategy still need to be defined.