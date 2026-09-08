-- ============================================================
-- HOSPITAL READMISSIONS PROJECT
-- 03. READMISSION ANALYSIS
-- ============================================================

USE hospital_readmissions;

-- 1. OVERALL READMISSION RATE

SELECT
    readmitted,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM diabetic_data_dedup), 1) AS pct_of_total
FROM diabetic_data_dedup
GROUP BY readmitted
ORDER BY encounter_count DESC;


-- 2. READMISSION BY AGE

SELECT
    age,
    age_midpoint,
    COUNT(*) AS total_encounters,
    SUM(is_readmitted_30) AS readmitted_under_30,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;


-- 3. READMISSION BY ADMISSION TYPE

SELECT
    m.description AS admission_type,
    COUNT(*) AS total_encounters,
    ROUND(100.0 * AVG(d.is_readmitted_30), 1) AS readmission_rate_pct
FROM diabetic_data_dedup AS d
JOIN ids_mapping_raw AS m
    ON d.admission_type_id = m.admission_type_id
GROUP BY m.description
ORDER BY readmission_rate_pct DESC;


-- 4. DISCHARGE DISPOSITION

SELECT
    m.description AS discharge_disposition,
    COUNT(*) AS total_encounters,
    ROUND(100.0 * AVG(d.is_readmitted_30), 1) AS readmission_rate_pct
FROM diabetic_data_dedup AS d
JOIN discharge_disposition_map AS m
    ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY readmission_rate_pct DESC
LIMIT 10;


-- 5. AVERAGE LENGTH OF STAY BY READMISSION STATUS

SELECT
    CASE
        WHEN is_readmitted_30 = 1 THEN 'Readmitted within 30 days'
        ELSE 'Not readmitted within 30 days'
    END AS readmission_status,
    COUNT(*) AS total_encounters,
    ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay_days
FROM diabetic_data_dedup
GROUP BY is_readmitted_30
ORDER BY is_readmitted_30 DESC;


-- 6. READMISSION RATE BY LENGTH-OF-STAY GROUP

WITH length_of_stay_groups AS (
    SELECT
        encounter_id,
        time_in_hospital,
        is_readmitted_30,
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 2 THEN '1-2 days'
            WHEN time_in_hospital BETWEEN 3 AND 5 THEN '3-5 days'
            WHEN time_in_hospital BETWEEN 6 AND 8 THEN '6-8 days'
            ELSE '9+ days'
        END AS length_of_stay_group
    FROM diabetic_data_dedup
)
SELECT
    length_of_stay_group,
    COUNT(*) AS total_encounters,
    ROUND(AVG(time_in_hospital), 1) AS avg_length_of_stay_days,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM length_of_stay_groups
GROUP BY length_of_stay_group
ORDER BY
    CASE length_of_stay_group
        WHEN '1-2 days' THEN 1
        WHEN '3-5 days' THEN 2
        WHEN '6-8 days' THEN 3
        WHEN '9+ days' THEN 4
    END;


-- 7. PRIOR HEALTHCARE UTILIZATION BY READMISSION STATUS

SELECT
    CASE
        WHEN is_readmitted_30 = 1 THEN 'Readmitted within 30 days'
        ELSE 'Not readmitted within 30 days'
    END AS readmission_status,
    COUNT(*) AS total_encounters,
    ROUND(AVG(number_inpatient), 2) AS avg_prior_inpatient_visits,
    ROUND(AVG(number_outpatient), 2) AS avg_prior_outpatient_visits,
        ROUND(AVG(number_emergency), 2) AS avg_prior_emergency_visits
FROM diabetic_data_dedup
GROUP BY is_readmitted_30
ORDER BY is_readmitted_30 DESC;


-- 8. PRIOR INPATIENT UTILIZATION

WITH inpatient_groups AS (
    SELECT
        encounter_id,
        number_inpatient,
        is_readmitted_30,
        CASE
            WHEN number_inpatient = 0 THEN '0'
            WHEN number_inpatient = 1 THEN '1'
            WHEN number_inpatient = 2 THEN '2'
            ELSE '3+'
        END AS prior_inpatient_group
    FROM diabetic_data_dedup
)

SELECT
    prior_inpatient_group,
    COUNT(*) AS total_encounters,
    ROUND(AVG(number_inpatient), 2) AS avg_prior_inpatient_visits,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM inpatient_groups
GROUP BY prior_inpatient_group
ORDER BY
    CASE prior_inpatient_group
        WHEN '0' THEN 1
        WHEN '1' THEN 2
        WHEN '2' THEN 3
        WHEN '3+' THEN 4
    END;


-- 9. AVERAGE MEDICATION BURDEN BY READMISSION STATUS

SELECT
    CASE
        WHEN is_readmitted_30 = 1 THEN 'Readmitted within 30 days'
        ELSE 'Not readmitted within 30 days'
    END AS readmission_status,
    COUNT(*) AS total_encounters,
    ROUND(AVG(num_medications), 1) AS avg_num_medications
FROM diabetic_data_dedup
GROUP BY is_readmitted_30
ORDER BY is_readmitted_30 DESC;


-- 10. MEDICATION BURDEN

WITH medication_tiers AS (
    SELECT
        encounter_id,
        num_medications,
        is_readmitted_30,
        NTILE(3) OVER (
            ORDER BY num_medications
        ) AS medication_tertile
    FROM diabetic_data_dedup
)
SELECT
    medication_tertile,
    COUNT(*) AS total_encounters,
    ROUND(AVG(num_medications), 1) AS avg_num_medications,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM medication_tiers
GROUP BY medication_tertile
ORDER BY medication_tertile;


-- Rank encounters by medication burden within each age group
SELECT
    encounter_id,
    age_midpoint,
    num_medications,
    RANK() OVER (
        PARTITION BY age_midpoint
        ORDER BY num_medications DESC
    ) AS medication_rank_within_age_group
FROM diabetic_data_dedup
ORDER BY age_midpoint, medication_rank_within_age_group
LIMIT 200;


-- 11. MEDICATION CHANGE AT DISCHARGE

SELECT
    `change`,
    COUNT(*) AS total_encounters,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY `change`
ORDER BY readmission_rate_pct DESC;


-- 12. AVERAGE NUMBER OF DIAGNOSES BY READMISSION STATUS

SELECT
    CASE
        WHEN is_readmitted_30 = 1 THEN 'Readmitted within 30 days'
        ELSE 'Not readmitted within 30 days'
    END AS readmission_status,
    COUNT(*) AS total_encounters,
    ROUND(AVG(number_diagnoses), 1) AS avg_number_diagnoses
FROM diabetic_data_dedup
GROUP BY is_readmitted_30
ORDER BY is_readmitted_30 DESC;


-- 13. DIAGNOSIS COMPLEXITY

WITH diagnosis_complexity AS (
    SELECT
        encounter_id,
        number_diagnoses,
        is_readmitted_30,
        CASE
            WHEN number_diagnoses <= 5 THEN 'Low Complexity'
            WHEN number_diagnoses BETWEEN 6 AND 9 THEN 'Moderate Complexity'
            ELSE 'High Complexity'
        END AS diagnosis_complexity_tier
    FROM diabetic_data_dedup
)
SELECT
    diagnosis_complexity_tier,
    COUNT(*) AS total_encounters,
    ROUND(AVG(number_diagnoses), 1) AS avg_number_diagnoses,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM diagnosis_complexity
GROUP BY diagnosis_complexity_tier
ORDER BY readmission_rate_pct DESC;


-- 14. PRIMARY DIAGNOSIS CATEGORY

-- ICD-9 groupings used:
-- 250: Diabetes mellitus
-- 390-459: Diseases of the circulatory system
-- 460-519: Diseases of the respiratory system
-- 520-579: Diseases of the digestive system
-- 580-629: Diseases of the genitourinary system
-- 800-999: Injury and poisoning

WITH diagnosis_categories AS (
    SELECT
        encounter_id,
        is_readmitted_30,
        CASE
            WHEN diag_1 LIKE '250%' THEN 'Diabetes'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'Circulatory'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'Respiratory'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'Digestive'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'Genitourinary'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'Injury'
            ELSE 'Other'
        END AS diagnosis_category
    FROM diabetic_data_dedup
    WHERE diag_1 IS NOT NULL
)
SELECT
    diagnosis_category,
    COUNT(*) AS total_encounters,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM diagnosis_categories
GROUP BY diagnosis_category
HAVING AVG(is_readmitted_30) > (
    SELECT AVG(is_readmitted_30)
    FROM diagnosis_categories
)
ORDER BY readmission_rate_pct DESC;


-- 15. LAB INTENSITY BY READMISSION STATUS

SELECT
    CASE
        WHEN is_readmitted_30 = 1 THEN 'Readmitted within 30 days'
        ELSE 'Not readmitted within 30 days'
    END AS readmission_status,
    COUNT(*) AS total_encounters,
    ROUND(AVG(num_lab_procedures), 1) AS avg_lab_procedures
FROM diabetic_data_dedup
GROUP BY is_readmitted_30
ORDER BY is_readmitted_30 DESC;


-- 16. A1C TESTING AND READMISSION

SELECT
    A1Cresult,
    COUNT(*) AS total_encounters,
    ROUND(100.0 * AVG(is_readmitted_30), 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY A1Cresult
ORDER BY readmission_rate_pct DESC;