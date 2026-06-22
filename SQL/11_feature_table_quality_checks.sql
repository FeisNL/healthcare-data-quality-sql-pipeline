/*
===============================================================================
Feature Table Quality Checks
Project: Healthcare Data Quality SQL Pipeline

Doel:
Controleren of de eerste feature table betrouwbaar genoeg is voor verdere
analyse. Deze checks richten zich op row count, grain, NULL patient features,
afgeleide datumfeatures en kostenrisico's.
===============================================================================
*/

-- count number of records in feature_admission_base
SELECT COUNT(*)
FROM feature_admission_base;

-- finding duplicate records in feature_admission_base
select
	admission_id,
	count(*) as record_count
from feature_admission_base
group by admission_id
having count(*) > 1;

-- finding records where either gender_standardized or birth_date or age_at_admission contain NULL values
select
	admission_id,
	patient_id,
	gender_standardized,
	birth_date
	age_at_admission
from feature_admission_base 
where gender_standardized is null
	or birth_date is null 
	or age_at_admission is null;

-- check logic for length_of_stay_days if records with negative days or null value for days are present
select 
	admission_id,
	admission_date,
	discharge_date, 
	length_of_stay_days
from feature_admission_base
where length_of_stay_days < 0
	or length_of_stay_days is null;

-- check for extreme outliers in total_cost
select 
	admission_id,
	patient_id,
	total_cost,
	has_negative_total_cost
from feature_admission_base
where total_cost >= 100000
	or has_negative_total_cost = true; 