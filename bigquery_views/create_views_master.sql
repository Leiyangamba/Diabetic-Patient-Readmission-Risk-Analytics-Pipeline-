-- 0: Validating the data View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_00_data_validation` AS
SELECT 
count(*) as total_encounter,
count(distinct(race)) as Distinct_race,
count(distinct(discharge_disposition_id)) as Diposition_id,
count(distinct(age)) as age_group,
round(avg(time_in_hospital),2) as Avg_LOS_days,
round(avg(num_medications),2) as avg_medication,
sum(readmitted_binary) as total_readmitted,
round((sum(readmitted_binary)/count(*)) *100 ,2)as readmission_rate      
FROM `healthcare-507513.diabetes_data.diabetes_clean`;

--Business Question: What is the overall 30-day readmission rate, and how does it vary across key patient segments?
--Understanding readmission rates by segment is the foundation of any hospital quality improvement program. CMS penalises hospitals   financially for elevated 30-day readmission rates, so identifying which segments drive the rate is the first step toward targeted intervention.
-- 1: Overall readmission rate and volume summary View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q1_overall_readmission` AS
select
 count(*) as total_encounter,
 sum(readmitted_binary) as total_readmitted,
 count(*) - sum(readmitted_binary) as not_admitted,
 round((sum(readmitted_binary)/count(*)) *100 ,2)as readmission_rate,
ROUND((COUNT(*) - SUM(readmitted_binary)) / COUNT(*) *100, 2)  AS non_readmission_rate_pct
FROM `healthcare-507513.diabetes_data.diabetes_clean`;

-- 2: Readmission rate by age group View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q2_age_group` AS
SELECT
    age                                                     AS age_group,
    age_mid,
    COUNT(*)                                                AS total_patients,
    SUM(readmitted_binary)                                  AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)     AS readmission_rate_pct
FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY age, age_mid
ORDER BY age_mid ASC;

-- 3: Readmission rate by primary diagnosis category View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q3_diagnosis_category` AS
SELECT                                    #The numbers in columns diag_1, diag_2, and diag_3 are ICD-9-CM codes
    CASE
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 390 AND 459
          OR SAFE_CAST(diag_1 AS FLOAT64) = 785   THEN 'Circulatory'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 460 AND 519
          OR SAFE_CAST(diag_1 AS FLOAT64) = 786   THEN 'Respiratory'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 520 AND 579
          OR SAFE_CAST(diag_1 AS FLOAT64) = 787   THEN 'Digestive'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 250 AND 250.99  THEN 'Diabetes'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 800 AND 999     THEN 'Injury'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 710 AND 739     THEN 'Musculoskeletal'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 580 AND 629
          OR SAFE_CAST(diag_1 AS FLOAT64) = 788   THEN 'Genitourinary'
        WHEN SAFE_CAST(diag_1 AS FLOAT64) BETWEEN 140 AND 239     THEN 'Neoplasms'
        WHEN diag_1 LIKE 'E%' 
          OR diag_1 LIKE 'V%'             THEN 'External/Supplementary'
        ELSE 'Other'
    END AS diagnosis_category,
    
    COUNT(*) AS total_encounters,
    SUM(readmitted_binary) AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2) AS readmission_rate_pct

FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY diagnosis_category
ORDER BY readmission_rate_pct DESC;

-- High cohort identification
---Which patient groups carry the highest readmission risk and should be prioritised for care management intervention?
--Identifying high risk cohorts is the core output that hospital administrators and care managers act on. A patient who is high risk on multiple dimensions simultaneously — frequent prior admissions, elevated A1C, high service utilisation — represents the highest return on intervention investment.

-- 4: Readmission rate by prior inpatient visit count View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q4_prior_inpatient` AS
SELECT
    CASE
        WHEN number_inpatient = 0 THEN '0 prior visits'
        WHEN number_inpatient = 1 THEN '1 prior visit'
        WHEN number_inpatient = 2 THEN '2 prior visits'
        WHEN number_inpatient BETWEEN 3 AND 5 THEN '3 to 5 prior visits'
        ELSE '6 or more prior visits'
    END                                                     AS prior_inpatient_group,
    number_inpatient,
    COUNT(*)                                                AS total_patients,
    SUM(readmitted_binary)                                  AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)     AS readmission_rate_pct
FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY prior_inpatient_group, number_inpatient
ORDER BY number_inpatient ASC
LIMIT 12;

-- 5: Multi-factor high risk patient identification View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q5_risk_score` AS
WITH risk_flags AS (
    SELECT
        race,
        gender,
        age,
        time_in_hospital,
        number_inpatient,
        number_emergency,
        A1Cresult,
        insulin,
        readmitted_binary,
        service_utilization,
        -- Flag 1: High prior inpatient utilisation
        CASE WHEN number_inpatient >= 3 THEN 1 ELSE 0 END      AS flag_high_inpatient,
        -- Flag 2: Prior emergency visits
        CASE WHEN number_emergency >= 1 THEN 1 ELSE 0 END       AS flag_emergency,
        -- Flag 3: Elevated or very high A1C result
        CASE WHEN A1Cresult IN ('>7', '>8') THEN 1 ELSE 0 END   AS flag_high_a1c,
        -- Flag 4: Insulin dose reduced at discharge (higher risk)
        CASE WHEN insulin = 'Down' THEN 1 ELSE 0 END             AS flag_insulin_down,
        -- Flag 5: Long length of stay
        CASE WHEN time_in_hospital >= 7 THEN 1 ELSE 0 END        AS flag_long_stay
    FROM `healthcare-507513.diabetes_data.diabetes_clean`
),
risk_scored AS (
    SELECT *,
        flag_high_inpatient + flag_emergency + flag_high_a1c
        + flag_insulin_down + flag_long_stay                      AS risk_score
    FROM risk_flags
)
SELECT                                        #Since there are 5 total binary tests, adding them together produces a cumulative score from 0 to 5
    risk_score,
    COUNT(*)                                                       AS patient_count,
    SUM(readmitted_binary)                                         AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)            AS readmission_rate_pct
FROM risk_scored
GROUP BY risk_score
ORDER BY risk_score ASC;

-- 6: Readmission rate by discharge disposition View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q6_discharge_disposition` AS
SELECT                                        #Use CMS/UB-04 discharge codes to map 
    discharge_disposition_id                                AS disposition_id,
    CASE discharge_disposition_id
        WHEN 1  THEN 'Discharged to Home'
        WHEN 2  THEN 'Discharged to Short-Term Hospital'
        WHEN 3  THEN 'Discharged to SNF'
        WHEN 4  THEN 'Discharged to ICF'
        WHEN 5  THEN 'Discharged to Other Inpatient Care'
        WHEN 6  THEN 'Discharged to Home Health'
        WHEN 7  THEN 'Left AMA'
        WHEN 8  THEN 'Discharged to Home IV'
        WHEN 9  THEN 'Admitted as Inpatient'
        WHEN 10 THEN 'Neonate Transfer'
        WHEN 15 THEN 'Discharged Alive NEC'
        WHEN 16 THEN 'Discharged Alive NOS'
        WHEN 17 THEN 'Discharged Rehab Facility'
        WHEN 22 THEN 'Rehab'
        WHEN 23 THEN 'Long-Term Care Hospital'
        WHEN 24 THEN 'Medicaid Cert Nursing'
        WHEN 25 THEN 'Not Mapped'
        WHEN 27 THEN 'Federal Health Care'
        WHEN 28 THEN 'Veterans Administration'
        WHEN 29 THEN 'Critical Access Hospital'
        WHEN 30 THEN 'Unipayer'
        ELSE CONCAT('Other (', SAFE_CAST(discharge_disposition_id AS STRING), ')')
    END                                                     AS disposition_label,
    COUNT(*)                                                AS total_encounters,
    SUM(readmitted_binary)                                  AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)     AS readmission_rate_pct
FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY 1, 2
HAVING total_encounters >= 100
ORDER BY readmission_rate_pct DESC;
--Module 4: Medication & Treatment SQL Analytics.
--In health informatics, medication patterns are primary drivers of clinical outcomes. By analyzing how drug adjustments, polypharmacy, and drug combinations correlate with 30-day readmissions, we provide hospital administrators and clinical staff with actionable risk indicators.

-- 7: Readmission rate by insulin change at discharge View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q7_insulin_change` AS
SELECT
    CASE insulin
        WHEN 'No'     THEN 'Not Prescribed'
        WHEN 'Steady' THEN 'Steady (no change)'
        WHEN 'Up'     THEN 'Increased at Discharge'
        WHEN 'Down'   THEN 'Reduced at Discharge'
        ELSE insulin
    END                                                     AS insulin_change,
    COUNT(*)                                                AS total_encounters,
    SUM(readmitted_binary)                                  AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)     AS readmission_rate_pct
FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY insulin
ORDER BY readmission_rate_pct DESC;

--How does the total number of medications prescribed during an inpatient stay impact the likelihood of 30-day readmission?
-- 8: Polypharmacy Risk Analysis View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q8_polypharmacy` AS
WITH med_buckets AS (
    SELECT
        num_medications,
        readmitted_binary,
        CASE
            WHEN num_medications BETWEEN 1 AND 10 THEN '1-10 Medications (Low)'
            WHEN num_medications BETWEEN 11 AND 20 THEN '11-20 Medications (Moderate)'
            ELSE '21+ Medications (High Polypharmacy)'
        END AS polypharmacy_group,
        CASE
            WHEN num_medications BETWEEN 1 AND 10 THEN 1
            WHEN num_medications BETWEEN 11 AND 20 THEN 2
            ELSE 3
        END AS group_order
    FROM `healthcare-507513.diabetes_data.diabetes_clean`
)
SELECT
    polypharmacy_group,
    COUNT(*)                                            AS total_encounters,
    SUM(readmitted_binary)                              AS total_readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM med_buckets
GROUP BY polypharmacy_group, group_order
ORDER BY group_order ASC;

--Module 5 — Utilisation and Cost Proxies
/*Business Question:How do length of stay, procedure volume, and overall service utilisation relate to 30-day readmission outcomes?

These metrics serve as cost proxies in managed care settings. High utilisation patients are both the most expensive and the most likely to be readmitted — making them the primary target for care coordination and cost containment programmes. */

-- 9: Average utilisation metrics by readmission group View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q9_average_utilisation` AS
SELECT
    CASE 
        WHEN readmitted_binary = 1 THEN 'Readmitted (<30 Days)'
        ELSE 'Not Readmitted'
    END                                                     AS readmission_status,
    COUNT(*)                                                AS total_encounters,
    ROUND(AVG(time_in_hospital), 2)                         AS avg_length_of_stay_days,
    ROUND(AVG(num_lab_procedures), 2)                       AS avg_lab_procedures,
    ROUND(AVG(num_procedures), 2)                           AS avg_non_lab_procedures,
    ROUND(AVG(num_medications), 2)                          AS avg_medications_prescribed,
    ROUND(AVG(number_outpatient + number_emergency + number_inpatient), 2) AS avg_prior_visits_total
FROM `healthcare-507513.diabetes_data.diabetes_clean`
GROUP BY readmitted_binary, readmission_status
ORDER BY readmitted_binary DESC;

-- 10: Length of stay distribution and readmission risk View
CREATE OR REPLACE VIEW `healthcare-507513.diabetes_data.vw_q10_length_of_stay` AS
WITH los_buckets AS (
    SELECT
        time_in_hospital,
        readmitted_binary,
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3 THEN 'Short Stay (1-3 Days)'
            WHEN time_in_hospital BETWEEN 4 AND 7 THEN 'Moderate Stay (4-7 Days)'
            ELSE 'Long Stay (8+ Days)'
        END AS los_category,
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3 THEN 1
            WHEN time_in_hospital BETWEEN 4 AND 7 THEN 2
            ELSE 3
        END AS group_order
    FROM `healthcare-507513.diabetes_data.diabetes_clean`
)
SELECT
    los_category,
    COUNT(*)                                                AS total_encounters,
    SUM(readmitted_binary)                                  AS readmissions,
    ROUND(100.0 * SUM(readmitted_binary) / COUNT(*), 2)     AS readmission_rate_pct
FROM los_buckets
GROUP BY los_category, group_order
ORDER BY group_order ASC;
