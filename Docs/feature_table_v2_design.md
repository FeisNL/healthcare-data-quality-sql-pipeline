# Feature Table V2 Design

## Doel

Feature table v2 maakt de eerste feature table beter controleerbaar door extra feature-level quality flags toe te voegen.

De basis is `feature_admission_base`. Deze view bevat al admission-level features zoals `length_of_stay_days`, `total_cost` en `age_at_admission`.

## Waarom een v2?

De eerste feature table liet zien dat data quality-risico’s niet verdwijnen na het maken van features. Door joins en afgeleide kolommen kunnen nieuwe problemen zichtbaar worden, zoals ontbrekende patient features, ontbrekende ligduur en verdachte kostenwaarden.

Daarom krijgt v2 extra flags die deze problemen expliciet zichtbaar maken.

## Nieuwe flags

| Flag | Betekenis | Waarom belangrijk |
|---|---|---|
| has_missing_patient_features | Patient-derived features ontbreken | Leeftijd/gender analyses kunnen onbetrouwbaar zijn |
| has_length_of_stay_issue | Ligduur is NULL of negatief | Ligduur kan niet veilig gebruikt worden |
| has_cost_issue | Kosten zijn negatief of extreem hoog | Kostenanalyse kan vertekend worden |
| is_analysis_ready | Record heeft geen blocking feature-level issues | Eerste selectie voor technische analyse |

## Regels per flag

### has_missing_patient_features

Deze flag wordt TRUE wanneer minimaal één van deze velden ontbreekt:

- `gender_standardized`
- `birth_date`
- `age_at_admission`

### has_length_of_stay_issue

Deze flag wordt TRUE wanneer:

- `length_of_stay_days` NULL is;
- of `length_of_stay_days` negatief is.

### has_cost_issue

Deze flag wordt TRUE wanneer:

- `has_negative_total_cost = TRUE`;
- of `total_cost >= 100000`.

### is_analysis_ready

Deze flag wordt TRUE wanneer:

- `has_missing_patient_features = FALSE`;
- `has_length_of_stay_issue = FALSE`;
- `has_cost_issue = FALSE`.

## Belangrijke keuze

Een record wordt niet automatisch verwijderd. De flags maken zichtbaar welke records wel of niet geschikt zijn voor specifieke analyses.

## Nog geen ML-dataset

Ook feature table v2 is nog geen machine learning dataset. Er ontbreekt nog steeds een target, train/test split, leakage checks, baseline en evaluatiemetric.

## Eigen uitleg

### Waarom voegen we feature-level flags toe?

Om aan te tonen wat de eventuele data quality issues per record zijn, zodat we later kunnen beslissen of we deze wel of niet meenemen. Joins en afgeleide kolommen kunnen nieuwe problemen zichtbaar maken, die in andere layers niet aanwezig waren.

### Wat betekent is_analysis_ready?

Dit houdt volgens een record volgens onze huidige feature level regels geschikt is voor een eerste technische analyse.

### Waarom verwijderen we records niet automatisch?

Er kunnen andere velden in het record staan die bruikbaar zijn voor andere analyses.