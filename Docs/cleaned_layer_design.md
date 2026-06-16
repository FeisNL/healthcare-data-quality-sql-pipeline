# Cleaned Layer Design

## 1. Doel

Deze cleaned layer beschrijft hoe de ruwe healthcare-data wordt omgezet naar betrouwbaardere tabellen voor analyse, rapportage en latere machine learning.

De raw data blijft behouden zoals deze is ingeladen. In de cleaned layer worden records gestandaardiseerd, gevalideerd en voorzien van kwaliteitsindicatoren.

## 2. Raw versus cleaned

Raw data bevat de originele records uit de bronbestanden. Deze data wordt niet direct aangepast, zodat fouten altijd terug te herleiden zijn naar de oorspronkelijke invoer.

Cleaned data is bedoeld als betrouwbaardere laag voor analyse. In deze laag worden foutieve of verdachte waarden niet blind verwijderd, maar gemarkeerd met quality flags.

## 3. Cleaning principles

De cleaned layer volgt deze principes:

- Raw data blijft behouden.
- Verdachte records worden gemarkeerd met quality flags.
- Categorieën worden gestandaardiseerd waar dat veilig kan.
- Records met ernstige koppelfouten worden niet gebruikt voor analyses waarbij gekoppelde patiëntgegevens nodig zijn.
- Fouten worden gedocumenteerd voordat records worden uitgesloten.

## 4. Cleaning rules

| Nr | Tabel | Kolom | Probleem | Cleaning rule | Verwijderen of markeren? |
|---:|---|---|---|---|---|
| 1 | patients | patient_id | Missing patient_id | Voeg quality flag `has_missing_patient_id` toe | Markeren |
| 2 | patients | patient_id | Duplicate patient_id | Voeg quality flag `has_duplicate_patient_id` toe | Markeren |
| 3 | patients | birth_date | Future birth_date | Voeg quality flag `has_future_birth_date` toe | Markeren |
| 4 | patients | birth_date | Unrealistic age above 120 | Voeg quality flag `has_unrealistic_age` toe | Markeren |
| 5 | patients | gender | Waarden zoals `male` en `Unknown` | Maak `gender_standardized`; zet `male` om naar `M`; zet onbekende waarden op `NULL` of `Unknown` volgens gekozen regel | Standaardiseren + markeren |
| 6 | admissions | admission_id | Duplicate admission_id | Voeg quality flag `has_duplicate_admission_id` toe | Markeren |
| 7 | admissions | patient_id | Unknown patient_id | Voeg quality flag `has_unknown_patient_id` toe | Markeren |
| 8 | admissions | discharge_date | Discharge date before admission date | Voeg quality flag `has_invalid_admission_period` toe | Markeren |
| 9 | admissions | department | Missing department | Voeg quality flag `has_missing_department` toe | Markeren |
| 10 | admissions | total_cost | Negative total_cost | Voeg quality flag `has_negative_total_cost` toe | Markeren |
| 11 | lab_results | patient_id | Unknown patient_id | Voeg quality flag `has_unknown_patient_id` toe | Markeren |
| 12 | lab_results | test_date | Missing test_date | Voeg quality flag `has_missing_test_date` toe | Markeren |
| 13 | lab_results | result_value | Negative or extreme value | Voeg quality flag `has_invalid_result_value` toe | Markeren |
| 14 | lab_results | lab_result_id | Duplicate lab_result_id | Voeg quality flag `has_duplicate_lab_result_id` toe | Markeren |

## 5. Records markeren versus verwijderen

In deze eerste versie worden verdachte records vooral gemarkeerd in plaats van verwijderd. Dit is belangrijk omdat een record met één fout veld soms nog bruikbaar kan zijn voor andere analyses.

Voorbeeld: een admission met negatieve total_cost is mogelijk niet betrouwbaar voor kostenanalyse, maar kan nog wel bruikbaar zijn voor tellingen van opnames per afdeling als de overige velden kloppen.

Records worden pas uitgesloten wanneer duidelijk is dat het kwaliteitsprobleem de betreffende analyse direct onbetrouwbaar maakt.

## 6. Voorbeelden van quality flags

Voorbeelden van quality flags in de cleaned layer:

- `has_missing_patient_id`
- `has_duplicate_patient_id`
- `has_future_birth_date`
- `has_unrealistic_age`
- `has_unknown_patient_id`
- `has_invalid_admission_period`
- `has_negative_total_cost`
- `has_missing_test_date`
- `has_invalid_result_value`

## 7. Volgende stap

De volgende stap is het schrijven van SQL views die deze cleaning rules toepassen. De eerste view wordt `cleaned_patients`. Daarna volgen `cleaned_admissions` en `cleaned_lab_results`.