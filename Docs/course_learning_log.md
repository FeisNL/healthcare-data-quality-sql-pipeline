## Datum: 17-6-2026

## Cursus / thema
Data Engineering + SQL fundamentals

## Onderwerpen
- Raw, cleaned en curated layers
- Quality flags
- Curated analysis views
- Auditqueries
- Reproduceerbare SQL run order

## Koppeling met project
Vandaag heb ik geleerd hoe cleaned data wordt omgezet naar een curated analysis layer. Daarbij worden records met blocking high-risk issues uitgesloten voor eerste analyses, terwijl raw en cleaned data behouden blijven voor traceerbaarheid.

## Belangrijkste inzicht
Cleaned maakt data quality issues zichtbaar. Curated maakt bewuste keuzes voor analyse. Auditqueries maken zichtbaar welke records zijn uitgesloten en waarom.

## Nog oefenen
- Zelf auditqueries schrijven
- AND versus OR toepassen vanuit het doel van de query
- Functies combineren zoals ROUND(AVG(...), 2)

## Take away 1:
In dit project heb ik een healthcare dataset geladen in PostgreSQL en eerst data quality checks geschreven. Daarna heb ik cleaned views gemaakt waarin alle records behouden blijven, maar quality flags worden toegevoegd voor problemen zoals duplicaten, missing values, referentiële fouten en ongeldige datums.

## Take away 2:
Vervolgens heb ik een data quality report gemaakt met severity levels en een validation script om issue counts automatisch te controleren. Daarna heb ik een curated analysis layer toegevoegd. In deze laag worden records met blocking high-risk issues uitgesloten voor eerste analyses, terwijl raw en cleaned data behouden blijven voor traceerbaarheid.

## Take away 3:
De belangrijkste les is dat data niet zomaar verwijderd moet worden. Fouten moeten eerst zichtbaar, controleerbaar en uitlegbaar worden gemaakt.

## Datum: 22-6-2026

## Cursus / thema
Data Engineering + SQL fundamentals

## Onderwerpen
- Feature table grain
- LEFT JOIN tussen curated views
- Derived columns
- `length_of_stay_days`
- `age_at_admission`
- NULL-controle na joins
- Data quality-risico’s in feature tables

## Koppeling met project
Vandaag heb ik een eerste admission-level feature table gebouwd. Hierbij werd duidelijk dat een feature table niet alleen bestaat uit kolommen selecteren, maar ook uit keuzes maken over grain, joins, afgeleide kolommen en data quality-risico’s.

## Belangrijkste inzicht
Cleaned en curated data vormen de basis voor feature engineering, maar joins kunnen nieuwe NULL-problemen zichtbaar maken. Deze NULLs moeten worden onderzocht voordat de data geschikt is voor analyse of machine learning.

## Nog oefenen
- Zelf feature queries schrijven
- LEFT JOIN-resultaten controleren
- NULLs na joins interpreteren
- SQL-functies zoals `AGE()` en `DATE_PART()` beter begrijpen