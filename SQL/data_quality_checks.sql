-- Check 1: Missing patient_id in patients
-- Waarom: patient_id is nodig om patiëntrecords betrouwbaar te koppelen aan opnames en labresultaten.
SELECT *
FROM patients
WHERE patient_id IS NULL OR patient_id = '';

-- Check 2: Duplicate patient_id in patients
-- Waarom: dubbele patient_id's kunnen leiden tot verkeerde koppelingen en foutieve analyses.
SELECT patient_id, COUNT(*) AS duplicate_count
FROM patients
WHERE patient_id IS NOT NULL AND patient_id <> ''
GROUP BY patient_id
HAVING COUNT(*) > 1;

-- Check 3: Future birth_date
-- Waarom: een geboortedatum in de toekomst is onmogelijk en wijst op invoerfout.
SELECT *
FROM patients
WHERE birth_date > CURRENT_DATE;

-- Check 4: Unrealistic age above 120 years
-- Waarom: extreem oude leeftijden kunnen analyses en risicomodellen vertekenen.
SELECT *
FROM patients
WHERE birth_date < CURRENT_DATE - INTERVAL '120 years';

-- Check 5: Inconsistent gender values
-- Waarom: inconsistente categorieën maken groeperingen en rapportages onbetrouwbaar.
SELECT gender, COUNT(*) AS count
FROM patients
GROUP BY gender
ORDER BY count DESC;

-- Check 6: Discharge date before admission date
-- Waarom: ontslagdatum vóór opnamedatum is logisch onmogelijk.
SELECT *
FROM admissions
WHERE discharge_date < admission_date;

-- Check 7: Admissions with unknown patient_id
-- Waarom: opnamegegevens zonder bestaande patiënt kunnen niet betrouwbaar gekoppeld worden.
SELECT a.*
FROM admissions a
LEFT JOIN patients p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check 8: Negative total_cost
-- Waarom: negatieve zorgkosten zijn meestal foutieve invoer of verkeerd geboekte correcties.
SELECT *
FROM admissions
WHERE total_cost < 0;

-- Check 9: Extreme total_cost outliers
-- Waarom: extreme kosten kunnen echte uitzonderingen zijn, maar moeten gecontroleerd worden.
SELECT *
FROM admissions
WHERE total_cost > (
    SELECT AVG(total_cost) + 3 * STDDEV(total_cost)
    FROM admissions
);

-- Check 10: Lab results with unknown patient_id
-- Waarom: labresultaten zonder bestaande patiënt zijn niet betrouwbaar bruikbaar.
SELECT l.*
FROM lab_results l
LEFT JOIN patients p
    ON l.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check 11: Invalid lab result values
-- Waarom: negatieve of extreme labwaardes kunnen analyses en medische interpretaties verstoren.
SELECT *
FROM lab_results
WHERE result_value < 0
   OR result_value > 500;

-- Check 12: Future lab test dates
-- Waarom: toekomstige testdatums in historische data wijzen op invoer- of systeemfouten.
SELECT *
FROM lab_results
WHERE test_date > CURRENT_DATE;

-- Check 13: Missing lab test dates
-- Waarom: zonder testdatum is trendanalyse of tijdsvolgorde niet betrouwbaar.
SELECT *
FROM lab_results
WHERE test_date IS NULL;

-- Check 14: Duplicate lab_result_id
-- Waarom: dubbele labresultaat-ID's kunnen tellingen en analyses vervuilen.
SELECT lab_result_id, COUNT(*) AS duplicate_count
FROM lab_results
GROUP BY lab_result_id
HAVING COUNT(*) > 1;