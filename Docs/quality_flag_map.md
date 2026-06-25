# Quality Flag Map

## Doel

Dit document geeft overzicht van de belangrijkste quality flags in het project. Het doel is om per flag duidelijk te maken waar de flag vandaan komt, wat de flag betekent en wanneer deze gebruikt wordt om records te filteren.

## Flag-categorieën

| Categorie | Betekenis |
|---|---|
| Identification flags | Problemen met unieke ID’s of ontbrekende sleutels |
| Referential flags | Problemen met koppelingen tussen tabellen |
| Date logic flags | Problemen met datums of afgeleide datumvelden |
| Category flags | Problemen met categorieën zoals gender of department |
| Numeric flags | Problemen met negatieve of extreme numerieke waarden |
| Feature-level flags | Problemen die zichtbaar worden na joins of feature engineering |
| Decision flags | Samenvattende flags die aangeven of een record geschikt is voor een bepaald doel |

## Belangrijk principe

Niet elke flag betekent automatisch dat een record verwijderd moet worden. Per analyse moet worden bepaald welke flags blocking zijn en welke flags alleen als waarschuwing worden meegenomen.

## Feature table v2 flags

| Flag | Categorie | Betekenis | Blocking voor feature_table_v2? |
|---|---|---|---|
| has_missing_patient_features | Feature-level flag | Patient-derived features ontbreken, zoals gender, birth_date of age_at_admission | Ja |
| has_length_of_stay_issue | Feature-level flag | length_of_stay_days is NULL of negatief | Ja |
| has_cost_issue | Feature-level flag / numeric flag | total_cost is negatief of extreem hoog | Ja |
| is_analysis_ready | Decision flag | Record voldoet aan de gekozen feature-level regels | Niet zelf een probleem, maar een selectie-indicator |

## Inherited flags in feature_admission_v2

| Flag | Categorie | Betekenis | Altijd blocking? |
|---|---|---|---|
| has_missing_department | Category flag | Department ontbreekt | Nee, afhankelijk van analyse |
| has_negative_total_cost | Numeric flag | total_cost is negatief | Voor kostenanalyse meestal blocking |
| has_unrealistic_age | Date/person logic flag | Leeftijd lijkt onrealistisch | Afhankelijk van analyse |
| has_invalid_gender_value | Category flag | Genderwaarde is ongeldig of onbekend | Blocking voor genderanalyse, niet altijd voor andere analyses |

## Analysis-ready versus fully clean

`analysis_ready` gebruikt alleen de vooraf gekozen feature-level flags voor deze technische analyse.

`fully clean` zou betekenen dat een record geen enkele gekozen quality flag heeft. Dit is strenger. In deze dataset levert een all-flags controle 0 fully clean records op.

## Algemene werkwijze voor nieuwe projecten

Bij elke nieuwe dataset gebruik ik deze vragen:

1. Wat is de grain van de tabel?
2. Welke kolommen zijn keys?
3. Welke joins zijn nodig?
4. Welke flags komen uit eerdere lagen?
5. Welke nieuwe flags ontstaan na joins of afgeleide kolommen?
6. Welke flags zijn blocking voor deze analyse?
7. Welke flags zijn alleen waarschuwingen?
8. Welke records blijven over als analysis-ready?
9. Welke records blijven over als fully clean?

## Eigen leerpunt

Het verschil tussen blocking en contextafhankelijk is:
blocking data zorgt ervoor dat we analyse krijgen met niet representatieve resultaten, daarentegen zorgt contextafhankelijke data ervoor dat wel bepaalde analysis wel of niet kunnen uitvoeren op basis van welke velden beschikbaar zijn

Een flag betekent niet automatisch verwijderen, omdat:
Het record kan nog andere velden bevatten die voor andere analyses wel bruikbaar kunnen zijn

Bij een nieuwe dataset zou ik eerst controleren:
Ik begrijp niet of je het hier hebt over een ruwe of opgeschoonde dataset, zeg het maar