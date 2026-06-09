# 1. Healthcare Data Quality SQL Pipeline

## 1.1 Projectdoel
Dit project controleert de kwaliteit van synthetische healthcare-data met SQL. De focus ligt op missing values, duplicaten, ongeldige waarden, foutieve datums, inconsistente categorieën, referentiële fouten en outliers.

## 1.2 Dataset
De dataset bestaat uit drie CSV-bestanden:

- patients.csv
- admissions.csv
- lab_results.csv

De data bevat bewust fouten, zodat data quality checks getest kunnen worden.

## 1.3 Eerste focus
De eerste fase richt zich op:
- schema exploration
- data profiling
- data quality checks
- documentatie van bevindingen