# Data Quality Memo

## 1. Context
Deze dataset bevat synthetische healthcare-data over patiënten, opnames en labresultaten. Het doel is om met SQL te controleren of de data betrouwbaar genoeg is voor rapportage, analyse en latere machine learning.

## 2. Belangrijkste data quality-risico’s
De belangrijkste risico’s zijn ontbrekende patiënt-ID’s, dubbele records, ongeldige datums, inconsistente categorieën, negatieve of extreme waarden en records die niet gekoppeld kunnen worden aan een bestaande patiënt.

## 3. Data Quality Checks - Eerste Resultaten

| Nr | Check                                 | Type                   | Werkelijke uitkomst                                                 | Ernst  | Actie                                                                                                                                               |
| -: | ------------------------------------- | ---------------------- | ------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
|  1 | Missing patient_id in patients        | Completeness           | Laura Meijer heeft geen patient_id                                  | High   | Controleren in het bronsysteem. Zonder patient_id kan het record niet betrouwbaar gekoppeld worden aan opnames of labresultaten.                    |
|  2 | Duplicate patient_id in patients      | Uniqueness             | P007 komt twee keer voor                                            | High   | Onderzoeken of dit een dubbele registratie of dubbele import is. Totdat dit duidelijk is, niet dubbel meetellen.                                    |
|  3 | Future birth_date                     | Date validity          | P003 heeft birth_date 2030-05-01                                    | High   | Geboortedatum controleren en corrigeren voordat leeftijd wordt berekend.                                                                            |
|  4 | Unrealistic age above 120 years       | Date validity          | P004 heeft birth_date 1890-11-30                                    | Medium | Geboortedatum verifiëren voordat deze wordt gebruikt in rapportages of modellen.                                                                    |
|  5 | Invalid gender values                 | Validity / consistency | P005 heeft 'male', P007 heeft 'Unknown'                             | Medium | Coderingsschema controleren en waarden standaardiseren.                                                                                             |
|  6 | Duplicate admission_id in admissions  | Uniqueness             | A009 komt twee keer voor                                            | High   | Onderzoeken of dit dubbele import, dubbele registratie of fout hergebruik van ID is.                                                                |
|  7 | Discharge date before admission date  | Date logic             | A002 heeft discharge_date 2023-03-03 vóór admission_date 2023-03-04 | High   | Opnameperiode controleren voordat ligduur of doorlooptijd wordt berekend.                                                                           |
|  8 | Admissions with unknown patient_id    | Referential integrity  | A004 verwijst naar P010 en A009 verwijst naar P008                  | High   | Controleren of patiëntdata ontbreekt of patient_id fout is ingevoerd. Deze opnames niet gebruiken voor analyses waarbij patiëntgegevens nodig zijn. |
|  9 | Missing department                    | Completeness           | A008 heeft geen department                                          | Medium | Afdeling controleren in het bronsysteem of markeren als onbekend.                                                                                   |
| 10 | Negative total_cost                   | Range validity         | A006 heeft total_cost -300.00                                       | Medium | Controleren of dit een correctieboeking, terugbetaling of invoerfout is.                                                                            |
| 11 | Lab results with unknown patient_id   | Referential integrity  | L007 verwijst naar P010                                             | High   | Labresultaat markeren als referentiële fout en controleren in het bronsysteem.                                                                      |
| 12 | Missing lab test_date                 | Completeness           | L008 heeft geen test_date                                           | Medium | Testdatum controleren voordat het resultaat wordt gebruikt voor tijdsanalyses.                                                                      |
| 13 | Negative or extreme lab result values | Range validity         | L004 heeft -5 en L002 heeft 999                                     | Medium | Controleren of dit meetfouten, invoerfouten of echte extreme waarden zijn.                                                                          |
| 14 | Duplicate lab_result_id               | Uniqueness             | L009 komt twee keer voor                                            | High   | Onderzoeken of dit dubbele import of dubbele registratie is.                                                                                        |

## 4. Belangrijkste bevindingen

De eerste data quality checks tonen aan dat de dataset meerdere soorten kwaliteitsproblemen bevat. De ernstigste problemen zitten in ontbrekende of dubbele identificaties, referentiële fouten tussen tabellen en datums die logisch niet kunnen kloppen.

Vooral de referentiële fouten zijn belangrijk. Admissions en lab_results bevatten records met patient_id’s die niet voorkomen in de patients-tabel. Daardoor kunnen deze records niet betrouwbaar gekoppeld worden aan patiëntgegevens. Dit raakt direct de betrouwbaarheid van analyses waarin patiëntkenmerken, opnames en labresultaten gecombineerd worden.

Daarnaast zijn er meerdere velden die eerst opgeschoond of gecontroleerd moeten worden voordat ze gebruikt kunnen worden voor rapportage of machine learning. Voorbeelden zijn birth_date, gender, total_cost, test_date en result_value.

## 5. Risico voor analyse en machine learning

De gevonden issues kunnen leiden tot verkeerde patiëntkoppelingen, dubbele tellingen, foutieve leeftijdsberekeningen en onbetrouwbare features zoals ligduur, kosten en labwaarden.

Voor machine learning is dit extra belangrijk. Als foutieve datums, dubbele records of verkeerd gekoppelde patiëntgegevens in een trainingsdataset terechtkomen, kan het model patronen leren die niet betrouwbaar zijn. Ook kunnen extreme of foutieve waarden de verdeling van features verstoren.

Daarom moet deze data eerst worden opgeschoond, gevalideerd en gedocumenteerd voordat deze gebruikt wordt voor rapportages, dashboards of voorspellende modellen.

## 6. Beperkingen

Het SQL-gebaseerde data quality report vat de bevindingen uit de cleaned views samen. In dit report worden de quality flags per entiteit geteld en gekoppeld aan een severity level. Hierdoor wordt zichtbaar welke problemen het grootste risico vormen voor rapportage, analyse en latere machine learning.

De belangrijkste high-risk issues zitten in identificatie, koppelingen tussen tabellen en datumlogica. In de patientdata is één record zonder patient_id gevonden en zijn twee records betrokken bij een dubbele patient_id. In de admissions-data zijn drie records gevonden met een patient_id die niet voorkomt in de patients-tabel. Ook is er één opname waarbij de discharge_date vóór de admission_date ligt. In de lab_results-data zijn twee records betrokken bij een dubbele lab_result_id en is één labresultaat gekoppeld aan een onbekende patient_id.

De medium-risk issues bestaan vooral uit waarden die eerst gecontroleerd of geïnterpreteerd moeten worden voordat ze veilig gebruikt kunnen worden. Voorbeelden hiervan zijn een onrealistische geboortedatum, inconsistente genderwaarden, een ontbrekende afdeling, een negatieve total_cost, een ontbrekende test_date en ongeldige labwaarden. Deze issues hoeven niet altijd direct verwijderd te worden, maar moeten wel zichtbaar blijven in de cleaned layer.

Een belangrijk technisch controlepunt is dat alle cleaned views dezelfde row count behouden als de oorspronkelijke raw tabellen. cleaned_patients, cleaned_admissions en cleaned_lab_results bevatten elk 10 records. Dit betekent dat de joins in de cleaned layer geen kunstmatige row multiplication meer veroorzaken.

De data is bruikbaar om data quality workflows te oefenen, maar nog niet geschikt voor betrouwbare rapportage of machine learning zonder aanvullende filtering, correctieregels en validatie. De cleaned layer maakt de risico’s zichtbaar met quality flags, zodat per analyse bepaald kan worden welke records wel of niet veilig gebruikt kunnen worden.

De severity-indeling is voorlopig handmatig bepaald op basis van het risico voor identificatie, koppelingen, datumlogica en analysebetrouwbaarheid. In een echte organisatie moeten deze severity levels worden afgestemd met domeinexperts, data-eigenaren of andere betrokkenen.