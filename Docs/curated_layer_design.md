# Curated Layer Design

## Doel

De curated layer bevat records die veilig genoeg zijn voor eerste analyses. De raw data blijft behouden en de cleaned layer blijft alle records tonen met quality flags. De curated layer gebruikt deze flags om records met kritieke problemen uit analyseviews te filteren.

## Verschil tussen raw, cleaned en curated

| Layer | Doel | Wat gebeurt er met fouten? |
|---|---|---|
| Raw | Oorspronkelijke brondata bewaren | Fouten blijven onveranderd aanwezig |
| Cleaned | Data standaardiseren en quality flags toevoegen | Fouten worden zichtbaar gemaakt, maar records blijven behouden |
| Curated | Analyseveilige subset maken | Records met kritieke fouten worden uitgesloten of apart gehouden |

## Curated rules

### Patients

Voor analyse worden patient records uitgesloten wanneer:

- `has_missing_patient_id = TRUE`
- `has_duplicate_patient_id = TRUE`
- `has_future_birth_date = TRUE`

Medium-risk issues zoals `has_unrealistic_age` en `has_invalid_gender_value` worden voorlopig niet automatisch uitgesloten, maar blijven zichtbaar voor interpretatie.

### Admissions

Voor analyse worden admission records uitgesloten wanneer:

- `has_duplicate_admission_id = TRUE`
- `has_unknown_patient_id = TRUE`
- `has_invalid_admission_period = TRUE`

Medium-risk issues zoals `has_missing_department` en `has_negative_total_cost` worden voorlopig niet automatisch uitgesloten, maar kunnen per analyse gefilterd worden.

### Lab results

Voor analyse worden lab result records uitgesloten wanneer:

- `has_duplicate_lab_result_id = TRUE`
- `has_unknown_patient_id = TRUE`

Medium-risk issues zoals `has_missing_test_date` en `has_invalid_result_value` worden voorlopig apart geïnterpreteerd. Voor tijdsanalyses is `has_missing_test_date = TRUE` niet bruikbaar. Voor labwaarde-analyses is `has_invalid_result_value = TRUE` niet bruikbaar.

## Waarom medium-risk records niet altijd automatisch worden verwijderd

Medium-risk issues kunnen belangrijk zijn, maar hoeven niet altijd te betekenen dat een record volledig onbruikbaar is.

Voorbeelden:

- Een admission met `has_negative_total_cost = TRUE` is niet geschikt voor kostenanalyse, maar kan mogelijk nog wel gebruikt worden voor tellingen per afdeling.
- Een labresultaat met `has_missing_test_date = TRUE` is niet geschikt voor tijdsanalyses, maar de testwaarde kan mogelijk nog wel bruikbaar zijn voor een niet-tijdgebonden controle.
- Een patient met `has_invalid_gender_value = TRUE` kan nog steeds bruikbaar zijn voor analyses waarbij gender geen rol speelt.

Daarom worden medium-risk issues voorlopig zichtbaar gehouden in de cleaned layer en per analyse beoordeeld.

## Belangrijke beperking

Deze curated rules zijn voorlopig en gebaseerd op technische data quality-risico’s. In een echte organisatie moeten deze regels worden afgestemd met domeinexperts, data-eigenaren en de specifieke analysevraag.

De curated layer maakt de data nog niet automatisch geschikt voor machine learning. Daarvoor zijn later ook een duidelijke targetvariabele, feature table, train/test split, leakage-controle en evaluatiemethode nodig.