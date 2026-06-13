-- Row counts
SELECT 'patients' AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL
SELECT 'admissions' AS table_name, COUNT(*) AS row_count FROM admissions
UNION ALL
SELECT 'lab_results' AS table_name, COUNT(*) AS row_count FROM lab_results;

-- Preview patients
SELECT *
FROM patients
LIMIT 10;

-- Preview admissions
SELECT *
FROM admissions
LIMIT 10;

-- Preview lab results
SELECT *
FROM lab_results
LIMIT 10;

-- Column overview
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('patients', 'admissions', 'lab_results')
ORDER BY table_name, ordinal_position;