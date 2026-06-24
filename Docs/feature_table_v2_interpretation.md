# Feature Table V2 Interpretation

## Context

`feature_admission_v2` is een admission-level feature table. De grain is één rij per admission. De view bouwt voort op `feature_admission_base` en voegt feature-level quality flags toe.

## Resultaten

De feature table bevat 6 records.

Op basis van de huidige feature-level regels is 1 record analysis-ready en zijn 5 records not analysis-ready.

## Belangrijkste issues

| Issue | Aantal records | Betekenis |
|---|---:|---|
| Missing patient features | 2 | Patient-derived features zoals gender, birth_date of age_at_admission ontbreken |
| Length of stay issue | 1 | Ligduur is NULL of negatief |
| Cost issue | 2 | Kosten zijn negatief of extreem hoog |

## Interpretatie

De resultaten laten zien dat feature engineering data quality-risico’s niet automatisch oplost. Door joins en afgeleide kolommen kunnen nieuwe problemen zichtbaar worden.

Voor analyses met leeftijd of gender zijn records met missing patient features niet geschikt zonder aanvullende beslissing. Voor analyses met ligduur moet het record met ontbrekende discharge_date apart worden behandeld. Voor kostenanalyses moeten negatieve en extreme total_cost-waarden apart worden onderzocht of gefilterd.

## Analysis-ready versus fully clean

`analysis_ready` betekent dat een record voldoet aan de gekozen feature-level regels voor deze eerste technische analyse. Dit betekent niet dat het record volledig vrij is van alle quality flags.

Een strengere all-flags controle gaf 0 volledig schone records. Dit laat zien dat een te strenge definitie ervoor kan zorgen dat er geen bruikbare data overblijft. Daarom moet per analysedoel worden bepaald welke flags blocking zijn en welke flags alleen als waarschuwing worden meegenomen.

## Belangrijke beperking

`is_analysis_ready` betekent niet dat de data perfect is. Het betekent alleen dat een record voldoet aan onze huidige feature-level regels voor eerste technische analyse.

## Vervolgstap

Een logische vervolgstap is het maken van een analyse-ready subset op basis van `feature_admission_v2`, waarbij alleen records met `is_analysis_ready = TRUE` worden gebruikt voor eerste eenvoudige analyses.