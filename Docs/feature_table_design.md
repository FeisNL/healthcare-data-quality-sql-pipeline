# Feature Table Design

## Doel

Dit document beschrijft een eerste ontwerp voor een admission-level feature table. Deze feature table is nog geen definitieve machine learning dataset, maar een voorbereidende analyse-laag.

Het doel is om curated admissions en curated patients te combineren tot één overzichtelijke tabel waarin per opname relevante kenmerken beschikbaar zijn voor latere analyse.

## Grain

De grain van de feature table is:

* één rij per admission

Dit betekent dat `admission_id` de centrale eenheid is. Elke rij stelt één opname voor.

Deze keuze is logisch omdat de admissions-tabel de opnamegegevens bevat, zoals afdeling, opnamedatum, ontslagdatum en kosten. Patiëntgegevens worden later toegevoegd via `patient_id`.

## Mogelijke features

| Feature                 | Bron                                  | Opmerking                                                   |
| ----------------------- | ------------------------------------- | ----------------------------------------------------------- |
| admission_id            | curated_admissions                    | Unieke opname-ID                                            |
| patient_id              | curated_admissions                    | Koppeling naar patient                                      |
| department_standardized | curated_admissions                    | Gestandaardiseerde afdeling                                 |
| admission_date          | curated_admissions                    | Startdatum opname                                           |
| discharge_date          | curated_admissions                    | Einddatum opname                                            |
| length_of_stay_days     | curated_admissions                    | Afgeleid uit discharge_date - admission_date                |
| total_cost              | curated_admissions                    | Alleen bruikbaar na controle op negatieve en extreme kosten |
| birth_date              | curated_patients                      | Nodig voor leeftijdsbepaling                                |
| gender_standardized     | curated_patients                      | Gestandaardiseerde genderwaarde                             |
| age_at_admission        | curated_patients + curated_admissions | Leeftijd op moment van opname                               |

## Nog geen target

Er is nog geen targetvariabele gedefinieerd. Daarom is deze feature table nog niet geschikt voor supervised machine learning.

Mogelijke latere targets zijn:

* heropname binnen een bepaalde periode;
* hoge zorgkosten;
* afwijkende labwaarde;
* lange ligduur.

Voordat machine learning gebruikt kan worden, moeten eerst een target, train/test split, leakage checks, baseline model en evaluatiemetric worden bepaald.

## Data quality-risico’s

Voor een betrouwbare feature table moeten de volgende risico’s gecontroleerd blijven:

* duplicate IDs;
* unknown patient_id’s;
* ongeldige datums;
* negatieve of extreme kosten;
* missing values;
* onrealistische leeftijd;
* inconsistente categorieën;
* target leakage;
* te kleine dataset.

## Belangrijke beperking

Deze feature table is een eerste technische voorbereiding. De dataset is synthetisch en klein, waardoor deze nog niet geschikt is voor echte machine learning of medische conclusies.

De feature table laat vooral zien hoe curated data kan worden gebruikt als basis voor verdere analyse en latere feature engineering.

## Eigen uitleg

### Waarom is de grain één rij per admission?

De analyse draait voorlopig om opnames, hierbij heeft elke opname zijn eigen admission_id, department_standardized, admission_date, discharge_date en total_cost

### Waarom is deze feature table nog geen ML-dataset?

Target is nog niet bepaald, we hebben geen train/test split, we hebben geen leakage(informatie in de features die het model niet kan weten) checks tot slot hebben we geen baseline en evaluation metric

### Welke data quality-risico’s vind ik het belangrijkst?
Extreme kosten
→ raakt total_cost en kostenanalyses.

Ongeldige datums
→ raakt length_of_stay_days en age_at_admission.

Ontbrekende/onjuiste koppelingen
→ raakt de join tussen admissions en patients en dus patiëntfeatures.

### Interviewwaardige uitleg
Bij het ontwerpen van de feature table heb ik gekeken welke data quality issues de belangrijkste features direct kunnen beïnvloeden. Extreme kosten kunnen kostenfeatures en gemiddelden vertekenen. Ongeldige datums kunnen afgeleide features zoals length_of_stay_days en age_at_admission fout maken. Onjuiste koppelingen tussen admissions en patients kunnen ervoor zorgen dat patiëntfeatures ontbreken of verkeerd gekoppeld worden. Daarom zijn dit de belangrijkste risico’s voor deze eerste feature table.