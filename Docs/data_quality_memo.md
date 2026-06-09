# Data Quality Memo

## 1. Context
Deze dataset bevat synthetische healthcare-data over patiënten, opnames en labresultaten. Het doel is om met SQL te controleren of de data betrouwbaar genoeg is voor rapportage, analyse en latere machine learning.

## 2. Belangrijkste data quality-risico’s
De belangrijkste risico’s zijn ontbrekende patiënt-ID’s, dubbele records, ongeldige datums, inconsistente categorieën, negatieve of extreme waarden en records die niet gekoppeld kunnen worden aan een bestaande patiënt.

## 3. Uitgevoerde checks

| Check | Tabel | Risico | Verwachte actie |
|---|---|---|---|
| Missing patient_id | patients | Records kunnen niet betrouwbaar gekoppeld worden | Brondata corrigeren of record uitsluiten |
| Duplicate patient_id | patients | Eén patiënt kan dubbel meetellen | Duplicaten onderzoeken en deduplicatieregel bepalen |
| Future birth_date | patients | Onmogelijke geboortedatum | Invoerfout corrigeren |
| Unrealistic age | patients | Leeftijd kan analyses vertekenen | Controleren met bronsysteem |
| Inconsistent gender values | patients | Groeperingen worden onbetrouwbaar | Categorieën standaardiseren |
| Invalid admission dates | admissions | Onmogelijke opnameperiode | Datums corrigeren |
| Unknown patient_id | admissions/lab_results | Records kunnen niet gekoppeld worden | Referentiële fout onderzoeken |
| Invalid numeric values | admissions/lab_results | Kosten of labwaardes zijn niet betrouwbaar | Waarde controleren of markeren |

## 4. Eerste bevindingen
De eerste checks tonen aan dat de dataset bewust meerdere kwaliteitsproblemen bevat. Er zijn dubbele ID’s, ontbrekende waarden, ongeldige datums, inconsistente categorieën en referentiële fouten tussen tabellen.

## 5. Beperkingen
De dataset is synthetisch en klein. Daardoor is deze geschikt om data quality checks te ontwerpen, maar niet om echte medische conclusies te trekken.

## 6. Volgende stap
De volgende stap is het uitbreiden van de checks met severity levels, duidelijke foutcategorieën en een herhaalbaar SQL-rapport.