# Analysis Ready Decision Memo

## Context

Dit document beschrijft waarom er een aparte analysis-ready feature view is gemaakt.

De view `feature_admission_analysis_ready` is gebaseerd op `feature_admission_v2`. Deze bron bevat feature-level quality flags, zoals `has_missing_patient_features`, `has_length_of_stay_issue`, `has_cost_issue` en `is_analysis_ready`.

## Doel

Het doel van de analysis-ready view is om een eerste analysegerichte subset te maken. Alleen records die voldoen aan de huidige feature-level regels worden meegenomen.

## Selectieregel

Een record komt in `feature_admission_analysis_ready` wanneer:

- `is_analysis_ready = TRUE`

Deze selectie gebruikt de vooraf gekozen feature-level quality rules uit `feature_admission_v2`.

## Resultaten

De analysis-ready view bevat 1 record(s).

De rejected records zijn:

- A001

## Waarom niet fully clean?

De analysis-ready view is niet hetzelfde als een fully clean dataset. Fully clean zou betekenen dat een record geen enkele gekozen quality flag heeft. In deze kleine dataset levert een strengere all-flags controle 0 volledig schone records op.

Analysis-ready is doelafhankelijk. Voor deze eerste technische analyse gebruiken we alleen de feature-level flags die relevant zijn voor de gekozen analyse.

## Waarom nog niet ML-ready?

Deze subset is nog niet ML-ready. Er is nog geen target bepaald, er is nog geen train/test split, er zijn nog geen leakage checks uitgevoerd en er is nog geen evaluatiemetric gekozen.

De view is bedoeld voor eerste technische analyse, niet voor modeltraining.

## Beperkingen

- De dataset is klein en synthetisch.
- De feature-level regels zijn voorlopig gekozen.
- Sommige flags zijn contextafhankelijk.
- De rejected-reason query toont per record één hoofdoorzaak, terwijl een record meerdere issues kan hebben.
- Domeinvalidatie ontbreekt nog.

## Eigen uitleg

### Waarom maken we een analysis-ready subset?

Zodat we een subset aan data hebben voor onze eerste technische analyse die we gaan uitvoeren

### Waarom gebruiken we niet automatisch fully clean?

Gezien de grote van onze dataset houden we niks over nadat we alle quality flags eruit filteren, daarom gebruiken we speciale quality flags afhankelijk van de type analyse die we gaan doen

### Welke records vallen eruit en waarom?

A003 ->missing_patient_features
A005 ->length_of_stay_issue
A006 ->cost_issue
A007 ->cost_issue
A008 ->missing_patient_features

### Wat moet er nog gebeuren voordat deze data ML-ready is?

target is niet bepaald, train/test split is niet bepaald, evalution metrics zijn niet bepaald, geen analyse naar leakage gedaan