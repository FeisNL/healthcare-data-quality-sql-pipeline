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
└── README.md