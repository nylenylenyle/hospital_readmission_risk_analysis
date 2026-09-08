USE hospital_readmissions;

-- KEY FINDINGS

-- Finding 1. Top diagnosis categories driving readmission
	-- diag_1 notes
	-- 390–459: Diseases of the circulatory system
	-- 460–519: Diseases of the respiratory system
	-- 520–579: Diseases of the digestive system
	-- 580–629: Diseases of the genitourinary system
	-- 800–999: Injury and poisoning
WITH diag_categorized AS (
	SELECT
		encounter_id, 
        readmitted, 
        CASE
			WHEN diag_1 LIKE '250%' THEN 'Diabetes'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'Circulatory'
			WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'Respiratory'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'Digestive'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'Genitourinary'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'Injury'
			ELSE 'Other'
			END AS diagnosis_cateogry, 
		CASE
			WHEN readmitted = '<30' THEN 1 
            ELSE 0 
            END AS is_readmitted_30
	FROM diabetic_data_dedup
    WHERE diag_1 IS NOT NULL
)
SELECT
	diagnosis_cateogry, 
    COUNT(*) AS total_encounters, 
    ROUND(AVG(is_readmitted_30) * 100, 1) AS readmission_rate_pct
FROM diag_categorized
GROUP BY diagnosis_cateogry
HAVING AVG(is_readmitted_30) > (
	SELECT AVG(is_readmitted_30) FROM diag_categorized
)
ORDER BY readmission_rate_pct DESC;


-- Finding 2. Does a medication change at discharge affect readmission?
SELECT
	`change`, 
    COUNT(*) as total_encounters,
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY `change`;


-- Finding 3. Discharge disposition impact
SELECT
	m.description as discharge_disposition, 
    COUNT(*) AS total_encounters, 
	ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup as d
JOIN discharge_disposition_map as m
ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY readmission_rate_pct DESC
LIMIT 10;


-- Finding 4. A1C testing and readmission
SELECT
	A1Cresult, 
    COUNT(*) as total_encounters, 
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY A1Cresult;

