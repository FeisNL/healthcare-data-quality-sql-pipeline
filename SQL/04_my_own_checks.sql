-- Check 1: Missing patient_id in patients
-- Verwachte uitkomst: Laura Meijer, omdat patient_id leeg is.
SELECT *
FROM patients
WHERE patient_id IS NULL
   OR TRIM(patient_id) = '';

-- Check 2: Duplicate admission_id
-- Verwachte uitkomst: A009, omdat deze admission_id twee keer voorkomt.
SELECT admission_id, COUNT(*) AS duplicate_count
FROM admissions
GROUP BY admission_id
HAVING COUNT(*) > 1;

-- Check 3: Discharge date before admission date
-- Verwachte uitkomst: A002, omdat discharge_date eerder is dan admission_date.
SELECT 
    admission_id,
    patient_id,
    admission_date,
    discharge_date
FROM admissions
WHERE discharge_date < admission_date;

-- Check 4: Admissions with unknown patient_id
-- Verwachte uitkomst: P010 en P008, omdat deze patient_id's niet bestaan in patients.
SELECT 
    a.admission_id,
    a.patient_id,
    a.admission_date,
    a.department
FROM admissions a
LEFT JOIN patients p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check 5: Negative lab result value
-- Verwachte uitkomst: L004, omdat result_value negatief is.
SELECT *
FROM lab_results
WHERE result_value < 0;