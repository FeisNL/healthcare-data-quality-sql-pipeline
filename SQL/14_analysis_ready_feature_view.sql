/*
===============================================================================
Analysis Ready Feature View
Project: Healthcare Data Quality SQL Pipeline

Doel:
Een eerste analysegerichte subset maken op basis van feature_admission_v2.

Deze view bevat alleen records die volgens de huidige feature-level regels
analysis-ready zijn.

Belangrijk:
Analysis-ready betekent niet dat de data perfect of ML-ready is. Het betekent
alleen dat het record voldoet aan de gekozen regels voor eerste technische
analyse.
===============================================================================
*/

CREATE OR REPLACE VIEW feature_admission_analysis_ready AS
SELECT
    admission_id,
	patient_id,
	department_standardized,
	admission_date,
	discharge_date,
	length_of_stay_days,
	total_cost,
	gender_standardized,
	age_at_admission,
	is_analysis_ready
FROM feature_admission_v2
WHERE is_analysis_ready = true;

-- Hoeveel records zitten in de analysis-ready view?
select
	admission_id,
	count(*) as row_count
from feature_admission_analysis_ready
group by admission_id
order by row_count;

-- Controleer dat er geen FALSE-records in de view zitten.
select
	is_analysis_ready,
	count(*) as number_of_records
from feature_admission_analysis_ready
group by is_analysis_ready;

-- Controleer dat admission_id uniek blijft.
select 
	admission_id,
	count(*)
from feature_admission_analysis_ready
group by admission_id
having count(*) > 1;

-- query die laat zien welke records niet in de analysis-ready view komen en waarom
select 	
	admission_id,
	patient_id,
	has_missing_patient_features,
	has_length__of_stay_issue,
	has_cost_issue,
	is_analysis_ready
from feature_admission_v2
where is_analysis_ready = false;

-- compacte rejected-reason query
-- Let op: als een record meerdere issues heeft, toont deze CASE alleen de eerste match volgens de volgorde.
SELECT
    admission_id,
    patient_id,
    CASE
        WHEN has_missing_patient_features = true then 'missing_patient_features'
        WHEN has_length__of_stay_issue = true then 'length_of_stay_issue'
        WHEN has_cost_issue = true then 'cost_issue'
        ELSE 'unknown'
    END AS rejection_reason
FROM feature_admission_v2
WHERE is_analysis_ready = FALSE
ORDER BY admission_id;

-- Severity of quality flags per admission_id
select 
	admission_id,
	case 
		when has_missing_patient_features = true then 'high'
		when has_length__of_stay_issue = true then 'medium'
		when has_cost_issue = true then 'medium'
	end as severity
from feature_admission_v2
where is_analysis_ready = false; 

-- issue count per rejection reason
WITH rejected_records AS (
    SELECT
        admission_id,
        CASE
            WHEN has_missing_patient_features = true then 'missing_patient_features'
            WHEN has_length__of_stay_issue = true then 'length_of_stay_issue'
            WHEN has_cost_issue = true then 'cost_issue'
            ELSE 'unknown'
        END AS rejection_reason
    FROM feature_admission_v2
    WHERE is_analysis_ready = FALSE
)
SELECT
    rejection_reason,
    COUNT(*) AS record_count
FROM rejected_records
GROUP BY rejection_reason
ORDER BY record_count DESC;

-- debug query A
SELECT
    admission_id,
    COUNT(*) AS record_count
FROM feature_admission_v2
WHERE COUNT(*) > 1
GROUP BY admission_id;

-- solution to query A, removing the where and insert having count(*) at the end
-- Filter op gewone kolommen → WHERE
-- Filter op aggregaties zoals COUNT/SUM/AVG → HAVING
select
	admission_id,
	count(*) as record_count
from feature_admission_v2
group by admission_id
having count(*) > 1;
	

-- debug query B
SELECT
    admission_id,
    has_cost_issue,
    is_analysis_ready
FROM feature_admission_v2
WHERE has_cost_issue = FALSE
   OR has_length__of_stay_issue = FALSE
   OR has_missing_patient_features = FALSE;

-- solution to query B: 
-- Correct: use AND because analysis-ready records must have no blocking feature-level issues.
-- OR would return records where at least one flag is FALSE, even if another blocking flag is TRUE.
SELECT
    admission_id,
    has_cost_issue,
    is_analysis_ready
FROM feature_admission_v2
WHERE has_cost_issue = FALSE
   and has_length__of_stay_issue = FALSE
   and has_missing_patient_features = FALSE;

-- debug query C: query is counting al records in is_analysis_ready
-- COUNT(is_analysis_ready) telt alle niet-NULL waarden. TRUE en FALSE tellen allebei mee.
SELECT
    COUNT(is_analysis_ready) AS analysis_ready_count
FROM feature_admission_v2;

-- solution to query C: adding sum(case ..) as ... to add up the right values
select 
	sum(case when is_analysis_ready = true then 1 else 0 end) as analysis_ready_count
from feature_admission_v2;

-- Stretch block: wrong query
select
	rejection_reason,
	count(*) as record_count
from feature_admission_v2
group by rejection_reason;

-- Corrected query:
-- rejection_reason is not a column in feature_admission_v2.
-- First calculate rejection_reason in a CTE, then group by that derived column.
with rejected_records as (
	select 
		admission_id,
		case 
			when has_missing_patient_features = true then 'missing_patient_features'
			when has_length__of_stay_issue = true then 'length_of_stay_issue'
			when has_cost_issue = true then 'cost_issue'
			else 'unknown'
		end as rejection_reason
		from feature_admission_v2
		where is_analysis_ready = false
)
select 
	rejection_reason,
	count(*) as record_count
from rejected_records
group by rejection_reason
order by record_count desc, rejection reason;