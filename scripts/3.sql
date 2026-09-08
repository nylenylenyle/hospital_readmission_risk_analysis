
-- Readmission count and rate
SELECT DISTINCT(readmitted) FROM diabetic_data_dedup;

SELECT
	readmitted, 
    COUNT(*) as encounter_count, 
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM diabetic_data_dedup) * 100, 1) as pct_of_total 
FROM diabetic_data_dedup
GROUP BY readmitted
ORDER BY encounter_count DESC;


-- Readmission counts and rates by age
SELECT
	age, 
    age_midpoint, 
    COUNT(*) as total_encounters, 
    SUM(readmitted = '<30') as readmitted_under_30,
    ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) as readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;


-- Readmission counts and rates by admission types
SELECT
	m.description as admission_type, 
    COUNT(*) as total_encounters, 
    ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) as readmission_rate_pct
FROM diabetic_data_dedup AS d
JOIN ids_mapping_raw AS m
ON d.admission_type_id = m.admission_type_id
GROUP BY m.description
ORDER BY readmission_rate_pct DESC;