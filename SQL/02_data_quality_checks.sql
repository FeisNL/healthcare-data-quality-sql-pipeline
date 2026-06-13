```sql
/* 
===============================================================================
Healthcare Data Quality Checks
Project: Healthcare Data Quality SQL Pipeline
Database: healthcare_dq

Doel:
Deze SQL-checks controleren de kwaliteit van synthetische healthcare-data.
De focus ligt op completeness, uniqueness, validity, date logic,
referential integrity en outlier/range checks.
===============================================================================
*/


/* 
===============================================================================
1. PATIENTS TABLE CHECKS
===============================================================================
*/


-- Check 1: Missing patient_id in patients
-- Type: Completeness
-- Regel: Elke patiënt moet een patient_id hebben.
-- Risico: Zonder patient_id kan een patiënt niet betrouwbaar gekoppeld worden aan opnames of labresultaten.
-- Verwachte uitkomst: Laura Meijer, omdat haar patient_id leeg is.
-- Actie: Markeren als data quality issue en controleren in het bronsysteem.

SELECT 
    patient_id,
    first_name,
    last_name
FROM patients
WHERE patient_id IS NULL
   OR TRIM(patient_id) = '';


-- Check 2: Duplicate patient_id in patients
-- Type: Uniqueness
-- Regel: Elke patient_id moet uniek zijn.
-- Risico: Dubbele patient_id's kunnen leiden tot dubbele tellingen en foutieve koppelingen.
-- Verwachte uitkomst: P007, omdat deze patient_id twee keer voorkomt.
-- Actie: Onderzoeken of dit een dubbele registratie, dubbele import of echte duplicaat is.

SELECT 
    patient_id,
    COUNT(*) AS duplicate_count
FROM patients
WHERE patient_id IS NOT NULL
  AND TRIM(patient_id) <> ''
GROUP BY patient_id
HAVING COUNT(*) > 1;


-- Check 3: Future birth_date
-- Type: Date validity
-- Regel: Een geboortedatum mag niet in de toekomst liggen.
-- Risico: Een toekomstige geboortedatum is onmogelijk en verstoort leeftijdsberekeningen.
-- Verwachte uitkomst: P003, omdat birth_date 2030-05-01 is.
-- Actie: Controleren in het bronsysteem en corrigeren voordat leeftijd wordt berekend.

SELECT 
    patient_id,
    first_name,
    last_name,
    birth_date
FROM patients
WHERE birth_date > CURRENT_DATE;


-- Check 4: Unrealistic age above 120 years
-- Type: Date validity
-- Regel: Een leeftijd boven 120 jaar is zeer uitzonderlijk en moet worden gecontroleerd.
-- Risico: Onrealistische leeftijden kunnen analyses en risicomodellen vertekenen.
-- Verwachte uitkomst: P004, omdat birth_date 1890-11-30 is.
-- Actie: Geboortedatum verifiëren voordat deze wordt gebruikt in rapportages of modellen.

SELECT 
    patient_id,
    first_name,
    last_name,
    birth_date
FROM patients
WHERE birth_date < CURRENT_DATE - INTERVAL '120 years';


-- Check 5: Invalid gender values
-- Type: Validity / consistency
-- Regel: Genderwaarden moeten voldoen aan het afgesproken coderingsschema van de dataset.
-- Risico: Waarden buiten het afgesproken schema maken rapportages en groeperingen onbetrouwbaar.
-- Verwachte uitkomst: P005 met 'male' en P007 met 'Unknown'.
-- Actie: Coderingsschema controleren en waarden standaardiseren.

SELECT 
    patient_id,
    first_name,
    last_name,
    gender
FROM patients
WHERE gender NOT IN ('M', 'F');


-- Check 6: Gender value distribution
-- Type: Profiling / consistency
-- Regel: Categorieën moeten inzichtelijk zijn voordat ze worden opgeschoond.
-- Risico: Zonder profieloverzicht kunnen inconsistente categorieën gemist worden.
-- Verwachte uitkomst: Overzicht van M, F, male en Unknown.
-- Actie: Gebruiken om standaardisatieregels te bepalen.

SELECT 
    gender,
    COUNT(*) AS record_count
FROM patients
GROUP BY gender
ORDER BY record_count DESC;


/* 
===============================================================================
2. ADMISSIONS TABLE CHECKS
===============================================================================
*/


-- Check 7: Duplicate admission_id in admissions
-- Type: Uniqueness
-- Regel: Elke opname moet een unieke admission_id hebben.
-- Risico: Dubbele admission_id's kunnen leiden tot dubbele tellingen in rapportages.
-- Verwachte uitkomst: A009, omdat deze admission_id twee keer voorkomt.
-- Actie: Onderzoeken of dit komt door dubbele import, dubbele registratie of foutieve hergebruikte ID.

SELECT 
    admission_id,
    COUNT(*) AS duplicate_count
FROM admissions
GROUP BY admission_id
HAVING COUNT(*) > 1;


-- Check 8: Discharge date before admission date
-- Type: Date logic
-- Regel: Een ontslagdatum mag niet vóór de opnamedatum liggen.
-- Risico: Dit maakt ligduur, doorlooptijd en opnameanalyses onbetrouwbaar.
-- Verwachte uitkomst: A002, omdat discharge_date 2023-03-03 vóór admission_date 2023-03-04 ligt.
-- Actie: Opnameperiode controleren in het bronsysteem voordat ligduur wordt berekend.

SELECT 
    admission_id,
    patient_id,
    admission_date,
    discharge_date
FROM admissions
WHERE discharge_date < admission_date;


-- Check 9: Admissions with unknown patient_id
-- Type: Referential integrity
-- Regel: Elke opname moet gekoppeld zijn aan een bestaande patiënt in de patients-tabel.
-- Risico: Opnames zonder bestaande patiënt kunnen niet betrouwbaar gekoppeld worden aan patiëntgegevens.
-- Verwachte uitkomst: A004/P010 en A009/P008.
-- Actie: Markeren als referentiële fout en controleren of patiëntdata ontbreekt of verkeerd is geïmporteerd.

SELECT 
    a.admission_id,
    a.patient_id AS admission_patient_id,
    p.patient_id AS matched_patient_id,
    p.first_name,
    p.last_name,
    a.admission_date,
    a.department
FROM admissions a
LEFT JOIN patients p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IS NULL;


-- Check 10: Missing department
-- Type: Completeness
-- Regel: Elke opname moet een afdeling hebben.
-- Risico: Zonder afdeling zijn afdelingsrapportages en capaciteitsanalyses onvolledig.
-- Verwachte uitkomst: A008, omdat department leeg is.
-- Actie: Afdeling controleren in het bronsysteem en aanvullen of markeren als onbekend.

SELECT 
    admission_id,
    patient_id,
    admission_date,
    department
FROM admissions
WHERE department IS NULL
   OR TRIM(department) = '';


-- Check 11: Inconsistent department values
-- Type: Consistency
-- Regel: Afdelingsnamen moeten consistent worden geregistreerd.
-- Risico: Verschillende schrijfwijzen zoals 'Cardiology' en 'cardiology' kunnen rapportages vertekenen.
-- Verwachte uitkomst: Overzicht van afdelingswaarden, inclusief eventuele afwijkende schrijfwijzen.
-- Actie: Standaardisatieregel bepalen, bijvoorbeeld hoofdlettergebruik normaliseren.

SELECT 
    department,
    COUNT(*) AS record_count
FROM admissions
GROUP BY department
ORDER BY record_count DESC;


-- Check 12: Missing diagnosis_code
-- Type: Completeness
-- Regel: Elke opname moet een diagnosis_code hebben als deze vereist is voor analyse.
-- Risico: Ontbrekende diagnosecodes maken diagnoseanalyses en risicosegmentatie onvolledig.
-- Verwachte uitkomst: A009, omdat diagnosis_code leeg is.
-- Actie: Controleren of diagnosecode ontbreekt, later wordt aangevuld of bewust onbekend is.

SELECT 
    admission_id,
    patient_id,
    diagnosis_code
FROM admissions
WHERE diagnosis_code IS NULL
   OR TRIM(diagnosis_code) = '';


-- Check 13: Negative total_cost
-- Type: Range validity
-- Regel: total_cost moet normaal gesproken nul of positief zijn, tenzij negatieve bedragen correctieboekingen zijn.
-- Risico: Negatieve kosten kunnen kostenrapportages en gemiddelde kosten vertekenen.
-- Verwachte uitkomst: A006, omdat total_cost -300.00 is.
-- Actie: Controleren of dit een invoerfout, correctieboeking of terugbetaling is.

SELECT 
    admission_id,
    patient_id,
    total_cost
FROM admissions
WHERE total_cost < 0;


-- Check 14: Extreme total_cost outliers
-- Type: Outlier detection
-- Regel: Extreem hoge kosten moeten worden onderzocht voordat ze worden gebruikt in analyses.
-- Risico: Outliers kunnen gemiddelden, rapportages en modellen sterk beïnvloeden.
-- Verwachte uitkomst: Mogelijk A007, omdat total_cost 999999.99 is.
-- Actie: Controleren of dit een echte uitzonderlijke opname of invoerfout is.

SELECT 
    admission_id,
    patient_id,
    total_cost
FROM admissions
WHERE total_cost > (
    SELECT AVG(total_cost) + 3 * STDDEV(total_cost)
    FROM admissions
);


/* 
===============================================================================
3. LAB_RESULTS TABLE CHECKS
===============================================================================
*/


-- Check 15: Duplicate lab_result_id
-- Type: Uniqueness
-- Regel: Elk labresultaat moet een unieke lab_result_id hebben.
-- Risico: Dubbele labresultaat-ID's kunnen tellingen en medische analyses vervuilen.
-- Verwachte uitkomst: L009, omdat deze lab_result_id twee keer voorkomt.
-- Actie: Onderzoeken of dit dubbele import of dubbele registratie is.

SELECT 
    lab_result_id,
    COUNT(*) AS duplicate_count
FROM lab_results
GROUP BY lab_result_id
HAVING COUNT(*) > 1;


-- Check 16: Lab results with unknown patient_id
-- Type: Referential integrity
-- Regel: Elk labresultaat moet gekoppeld zijn aan een bestaande patiënt.
-- Risico: Labresultaten zonder bestaande patiënt zijn niet betrouwbaar bruikbaar in analyses.
-- Verwachte uitkomst: L007/P010, omdat P010 niet bestaat in patients.
-- Actie: Markeren als referentiële fout en controleren in het bronsysteem.

SELECT 
    l.lab_result_id,
    l.patient_id AS lab_patient_id,
    p.patient_id AS matched_patient_id,
    p.first_name,
    p.last_name,
    l.test_name,
    l.test_date,
    l.result_value
FROM lab_results l
LEFT JOIN patients p
    ON l.patient_id = p.patient_id
WHERE p.patient_id IS NULL;


-- Check 17: Missing test_date
-- Type: Completeness
-- Regel: Elk labresultaat moet een testdatum hebben.
-- Risico: Zonder testdatum zijn trendanalyse en tijdsvolgorde niet betrouwbaar.
-- Verwachte uitkomst: L008, omdat test_date ontbreekt.
-- Actie: Testdatum controleren in het bronsysteem voordat het resultaat wordt gebruikt.

SELECT 
    lab_result_id,
    patient_id,
    test_name,
    test_date,
    result_value
FROM lab_results
WHERE test_date IS NULL;


-- Check 18: Future lab test dates
-- Type: Date validity
-- Regel: Een testdatum mag niet in de toekomst liggen binnen historische data.
-- Risico: Toekomstige testdatums wijzen op invoerfouten of systeemfouten.
-- Verwachte uitkomst: L006, omdat test_date 2026-01-01 is als deze datum in de toekomst ligt.
-- Actie: Testdatum controleren in het bronsysteem.

SELECT 
    lab_result_id,
    patient_id,
    test_name,
    test_date,
    result_value
FROM lab_results
WHERE test_date > CURRENT_DATE;


-- Check 19: Negative or extreme lab result values
-- Type: Range validity
-- Regel: Labwaarden mogen niet negatief zijn en extreme waarden moeten worden onderzocht.
-- Risico: Ongeldige labwaarden kunnen medische interpretatie en modellen verstoren.
-- Verwachte uitkomst: L004 met -5 en L002 met 999.
-- Actie: Controleren of dit meetfout, invoerfout of echte extreme waarde is.

SELECT 
    lab_result_id,
    patient_id,
    test_name,
    test_date,
    result_value,
    result_unit
FROM lab_results
WHERE result_value < 0
   OR result_value > 500;


-- Check 20: Inconsistent test_name values
-- Type: Consistency
-- Regel: Testnamen moeten consistent worden geregistreerd.
-- Risico: Verschillende schrijfwijzen zoals 'Glucose' en 'glucose' kunnen analyses per testtype verstoren.
-- Verwachte uitkomst: Overzicht van testnamen, inclusief afwijkende schrijfwijzen.
-- Actie: Standaardisatieregel bepalen, bijvoorbeeld LOWER(TRIM(test_name)).

SELECT 
    test_name,
    COUNT(*) AS record_count
FROM lab_results
GROUP BY test_name
ORDER BY record_count DESC;
```
