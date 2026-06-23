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
Later: feature table v2 / Python / ML baseline


# Pipeline Overview

## 1. Source CSV files
De oorspronkelijke bestanden uit `Data/Raw/`. Deze data bevat bewust fouten en wordt niet aangepast.

## 2. Raw tables
De CSV-bestanden worden ingeladen in PostgreSQL-tabellen. De raw layer bewaart de data zoals die binnenkomt.

## 3. Schema exploration
Eerste inspectie van tabellen, kolommen, row counts, categorieën en opvallende waarden.

## 4. Data quality checks
Losse SQL-checks die problemen vinden en bewijzen, zoals duplicates, missing values, unknown patient_id’s, ongeldige datums en extreme waarden.

## 5. Cleaned views
Views waarin alle records behouden blijven, maar waarden worden gestandaardiseerd en quality flags worden toegevoegd.

## 6. Data quality report
Samenvatting van quality flags per entiteit, met issue counts en severity.

## 7. Validation checks
Automatische controle of de issue counts in het data quality report kloppen met de verwachte uitkomsten.

## 8. Curated analysis views
Analysegerichte subsets op basis van cleaned views. Blocking high-risk records worden uitgesloten volgens expliciete regels.

## 9. Curated analysis queries
Eerste technische analyses op curated data, zoals admissions per afdeling en gemiddelde kosten.

## 10. Feature table draft
Eerste admission-level feature table. De grain is één rij per admission. Admissions worden gecombineerd met patient features.

## 11. Feature table quality checks
Controles op row count, grain, NULL patient features, length_of_stay, kostenrisico’s en andere feature-level problemen.

## Belangrijkste principe
Cleaned maakt problemen zichtbaar. Curated maakt keuzes. Feature tables maken analyse mogelijk. Quality checks bewijzen of elke stap betrouwbaar genoeg is.

## File-to-layer mapping

| Layer / stap | Bestand | Doel |
|---|---|---|
| Raw table creation | `SQL/00_create_tables.sql` | Tabellen aanmaken voor de ruwe CSV-data |
| Schema exploration | `SQL/01_schema_exploration.sql` | Tabellen, kolommen, row counts en basiswaarden inspecteren |
| Data quality checks | `SQL/02_data_quality_checks.sql` | Problemen vinden en bewijzen |
| Cleaned views | `SQL/05_cleaned_layer_views.sql` | Alle records behouden, standaardiseren en quality flags toevoegen |
| Data quality report | `SQL/06_data_quality_report.sql` | Quality flags samenvatten met issue counts en severity |
| Report validation | `SQL/07_quality_report_validation.sql` | Controleren of issue counts kloppen |
| Curated views | `SQL/08_curated_analysis_views.sql` | Analysegerichte subset maken op basis van blocking flags |
| Curated analyses | `SQL/09_curated_analysis_queries.sql` | Eerste technische analyses uitvoeren |
| Feature table draft | `SQL/10_feature_table_draft.sql` | Eerste admission-level feature table maken |
| Feature table checks | `SQL/11_feature_table_quality_checks.sql` | Feature table controleren op grain, NULLs, datums en kosten |
| Feature table v2 | `SQL/12_feature_table_v2.sql` | Extra feature-level quality flags toevoegen |
| Feature table v2 checks | `SQL/13_feature_table_v2_quality_checks.sql` | Nieuwe flags en analysis readiness controleren |