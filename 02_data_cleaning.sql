-- ============================================================
-- HOSPITAL READMISSIONS PROJECT
-- 02. DATA CLEANING
-- ============================================================

USE hospital_readmissions;

-- 1. STANDARDIZE DATA TYPES AND MISSING VALUES

ALTER TABLE diabetic_data_raw
    MODIFY diag_1 VARCHAR(10);

UPDATE diabetic_data_raw
SET
    race = NULLIF(race, '?'),
    weight = NULLIF(weight, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');


-- 2. ASSESS DATA COMPLETENESS

SELECT
    ROUND(100.0 * SUM(weight IS NULL) / COUNT(*), 1) AS pct_missing_weight,
    ROUND(100.0 * SUM(payer_code IS NULL) / COUNT(*), 1) AS pct_missing_payer,
    ROUND(100.0 * SUM(medical_specialty IS NULL) / COUNT(*), 1) AS pct_missing_specialty
FROM diabetic_data_raw;


-- 3. REVIEW REPEATED PATIENT ENCOUNTERS

SELECT
    patient_nbr,
    COUNT(*) AS encounter_count
FROM diabetic_data_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
LIMIT 10;


-- ============================================================
-- 4. CREATE ANALYTIC COHORT
--    - Keep each patient's first encounter
--    - Exclude patients who could not be readmitted
-- ============================================================

DROP TABLE IF EXISTS diabetic_data_dedup;

CREATE TABLE diabetic_data_dedup AS
SELECT d.*
FROM diabetic_data_raw AS d
INNER JOIN (
    SELECT
        patient_nbr,
        MIN(encounter_id) AS first_encounter
    FROM diabetic_data_raw
    GROUP BY patient_nbr
) AS first_encounter
    ON d.patient_nbr = first_encounter.patient_nbr
   AND d.encounter_id = first_encounter.first_encounter
WHERE d.discharge_disposition_id NOT IN (11, 13, 14, 19, 20, 21, 26);


-- 5. CREATE DERIVED VARIABLES

ALTER TABLE diabetic_data_dedup
    ADD COLUMN age_midpoint INT,
    ADD COLUMN is_readmitted_30 TINYINT;

UPDATE diabetic_data_dedup
SET
    age_midpoint = CASE
        WHEN age = '[0-10)' THEN 5
        WHEN age = '[10-20)' THEN 15
        WHEN age = '[20-30)' THEN 25
        WHEN age = '[30-40)' THEN 35
        WHEN age = '[40-50)' THEN 45
        WHEN age = '[50-60)' THEN 55
        WHEN age = '[60-70)' THEN 65
        WHEN age = '[70-80)' THEN 75
        WHEN age = '[80-90)' THEN 85
        WHEN age = '[90-100)' THEN 95
        ELSE NULL
    END,
    is_readmitted_30 = CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END;


-- 6. VALIDATE CLEANED DATASET

SELECT
    COUNT(*) AS analytic_rows,
    COUNT(DISTINCT patient_nbr) AS unique_patients
FROM diabetic_data_dedup;

SELECT
    age,
    age_midpoint,
    COUNT(*) AS encounter_count
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;

SELECT
    is_readmitted_30,
    COUNT(*) AS encounter_count
FROM diabetic_data_dedup
GROUP BY is_readmitted_30;