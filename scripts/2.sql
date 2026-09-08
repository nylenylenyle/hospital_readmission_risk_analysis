USE  hospital_readmissions;

-- DATA CLEANING
-- Correct table dtypes and nulls 
ALTER TABLE diabetic_data_raw
    MODIFY diag_1 VARCHAR(10);

UPDATE diabetic_data_raw
SET race = NULLIF(race, '?'),
	weight = NULLIF(weight, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');
  
  
-- Calculate data completeness
SELECT
	ROUND(SUM(weight IS NULL)/COUNT(*) * 100, 1) AS pct_missing_weight, 
	ROUND(SUM(payer_code IS NULL)/COUNT(*) * 100, 1) AS pct_missing_payer,
	ROUND(SUM(medical_specialty IS NULL)/COUNT(*) * 100, 1) AS pct_missing_specialty
FROM diabetic_data_raw;


-- Create a new table consisting only of first encounters 
SELECT
	patient_nbr, 
    COUNT(*) as encounter_count
FROM diabetic_data_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
LIMIT 10;

CREATE TABLE diabetic_data_dedup AS
SELECT t.*
FROM diabetic_data_raw as t
INNER JOIN (SELECT 
	patient_nbr, 
    MIN(encounter_id) as first_encounter
FROM diabetic_data_raw
GROUP BY patient_nbr) first_enc
ON t.patient_nbr = first_enc.patient_nbr
AND t.encounter_id = first_enc.first_encounter;


-- Remove admission_types that cannot be readmitted 
-- (e.g. hospice, expired, deceased)
SELECT 
	discharge_disposition_id, 
    COUNT(*) as encounter_count
FROM diabetic_data_raw
GROUP BY discharge_disposition_id
ORDER BY encounter_count DESC;
  
SELECT * FROM ids_mapping_raw
WHERE description LIKE '%hospice%' OR description LIKE '%expired%' OR description LIKE '%deceased%';
-- 11, 13, 14, 19, 20, 21, 26
DELETE FROM diabetic_data_dedup 
WHERE discharge_disposition_id IN (11, 13, 14, 19, 20, 21, 26);

SELECT * FROM ids_mapping_raw;

-- Reformat bracketed age group to integer
ALTER TABLE diabetic_data_dedup ADD COLUMN age_midpoint INT;

UPDATE diabetic_data_dedup
SET age_midpoint = CASE
    WHEN age = '[0-10)'   THEN 5
    WHEN age = '[10-20)'  THEN 15
    WHEN age = '[20-30)'  THEN 25
    WHEN age = '[30-40)'  THEN 35
    WHEN age = '[40-50)'  THEN 45
    WHEN age = '[50-60)'  THEN 55
    WHEN age = '[60-70)'  THEN 65
    WHEN age = '[70-80)'  THEN 75
    WHEN age = '[80-90)'  THEN 85
    WHEN age = '[90-100)' THEN 95
END;

SELECT encounter_id, age, age_midpoint FROM diabetic_data_dedup;
