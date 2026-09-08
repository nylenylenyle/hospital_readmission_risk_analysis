USE hospital_readmissions;

-- Create a flag for when patient is readmitted >30 days
WITH patient_risk_base AS (
	SELECT
		encounter_id, 
        patient_nbr, 
        age_midpoint, 
        time_in_hospital, 
        num_medications, 
        num_lab_procedures, 
        number_diagnoses, 
        number_inpatient, 
        number_emergency, 
        number_outpatient, 
        diag_1, 
        readmitted, 
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
	FROM diabetic_data_dedup
)
SELECT * FROM patient_risk_base
LIMIT 20;



-- Find which patients in each age group are at risk of readmission based on number of medications perscribed
WITH patient_risk_base AS (
	SELECT 
		encounter_id, age_midpoint, num_medications, readmitted, 
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
	FROM diabetic_data_dedup
)
SELECT
	encounter_id, 
    age_midpoint, 
    num_medications, 
    RANK() OVER (PARTITION BY age_midpoint ORDER BY num_medications DESC) as med_rank_age_group
FROM patient_risk_base
ORDER BY age_midpoint, med_rank_age_group
LIMIT 200;


-- Create risk groups based on hospitalization history
WITH patient_risk_base AS (
	SELECT 
		encounter_id, number_inpatient, readmitted, 
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
     FROM diabetic_data_dedup
)
SELECT
	encounter_id, 
    number_inpatient, 
    NTILE(4) OVER (ORDER BY number_inpatient DESC) as risk_quartile
FROM patient_risk_base;


-- Assign medication burden and diagnosis complexity for each patient
SELECT
	encounter_id, 
    num_medications, 
    CASE
		WHEN num_medications <= 10 THEN 'Low'
        WHEN num_medications BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'High'
	END AS medication_burden_tier, 
    CASE
		WHEN number_diagnoses <= 5 THEN 'Low Complexity'
        WHEN number_diagnoses BETWEEN 6 AND 9 THEN 'Moderate Complexity'
        ELSE 'High Complexity'
	END AS diagnosis_complexity_tier
FROM diabetic_data_dedup

