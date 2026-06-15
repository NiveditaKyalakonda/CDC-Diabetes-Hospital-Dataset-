-- ============================================================
-- Hospital Readmission Analytics — Data Extraction Queries
-- ============================================================

-- ─── 1. Full patient risk profile export ──────────────────────────────────────
SELECT
    p.patient_id,
    p.gender,
    p.age,
    p.race,
    a.encounter_id,
    a.admission_type,
    a.discharge_disposition,
    a.time_in_hospital,
    a.num_lab_procedures,
    a.num_procedures,
    a.num_medications,
    a.number_outpatient,
    a.number_emergency,
    a.number_inpatient,
    a.number_diagnoses,
    a.diag_1,
    a.diag_2,
    a.diag_3,
    c.A1Cresult,
    c.insulin,
    c.metformin,
    c.diabetes_med,
    c.med_change        AS `change`,
    o.readmitted
FROM Admissions a
JOIN Patients p             ON a.patient_id = p.patient_id
LEFT JOIN ClinicalDetails c ON a.encounter_id = c.encounter_id
LEFT JOIN Outcomes o        ON a.encounter_id = o.encounter_id
ORDER BY a.encounter_id;


-- ─── 2. Readmission rates by demographic cohort ───────────────────────────────
SELECT
    p.age,
    p.gender,
    p.race,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END)      AS readmitted_30d,
    ROUND(
        100.0 * SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                                           AS readmission_rate_pct,
    ROUND(AVG(a.time_in_hospital), 1)                           AS avg_los_days,
    ROUND(AVG(a.num_medications), 1)                            AS avg_medications,
    ROUND(AVG(a.number_diagnoses), 1)                           AS avg_diagnoses
FROM Admissions a
JOIN Patients p     ON a.patient_id = p.patient_id
LEFT JOIN Outcomes o ON a.encounter_id = o.encounter_id
GROUP BY p.age, p.gender, p.race
ORDER BY readmission_rate_pct DESC;


-- ─── 3. High-risk patient identification ─────────────────────────────────────
SELECT
    p.patient_id,
    p.age,
    p.gender,
    a.encounter_id,
    a.admission_type,
    a.time_in_hospital,
    a.num_medications,
    a.number_inpatient,
    a.number_emergency,
    a.number_diagnoses,
    c.A1Cresult,
    c.insulin,
    o.readmitted,
    mp.risk_probability,
    mp.risk_band
FROM Admissions a
JOIN Patients p             ON a.patient_id = p.patient_id
LEFT JOIN ClinicalDetails c ON a.encounter_id = c.encounter_id
LEFT JOIN Outcomes o        ON a.encounter_id = o.encounter_id
LEFT JOIN ModelPredictions mp ON a.encounter_id = mp.encounter_id
WHERE
    mp.risk_band = 'HIGH'
    OR (
        a.number_inpatient >= 2
        AND a.time_in_hospital >= 7
        AND a.number_diagnoses >= 8
    )
ORDER BY mp.risk_probability DESC
LIMIT 100;


-- ─── 4. Monthly readmission trend ────────────────────────────────────────────
SELECT
    DATE_FORMAT(a.admission_date, '%Y-%m')  AS month,
    COUNT(*)                                 AS total_admissions,
    SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END) AS readmissions_30d,
    ROUND(
        100.0 * SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                        AS readmission_rate_pct
FROM Admissions a
LEFT JOIN Outcomes o ON a.encounter_id = o.encounter_id
WHERE a.admission_date IS NOT NULL
GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
ORDER BY month;


-- ─── 5. Medication & A1C impact analysis ─────────────────────────────────────
SELECT
    c.A1Cresult,
    c.insulin,
    c.diabetes_med,
    COUNT(*)                                                    AS total_patients,
    ROUND(AVG(a.num_medications), 1)                            AS avg_medications,
    ROUND(AVG(a.time_in_hospital), 1)                           AS avg_los,
    SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END)      AS readmissions_30d,
    ROUND(
        100.0 * SUM(CASE WHEN o.readmitted = '<30' THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                                           AS readmission_rate_pct
FROM ClinicalDetails c
JOIN Admissions a    ON c.encounter_id = a.encounter_id
LEFT JOIN Outcomes o ON c.encounter_id = o.encounter_id
GROUP BY c.A1Cresult, c.insulin, c.diabetes_med
ORDER BY readmission_rate_pct DESC;


-- ─── 6. Cost impact summary ───────────────────────────────────────────────────
SELECT
    o.readmitted,
    COUNT(*)                                AS encounter_count,
    SUM(o.readmission_cost_usd)             AS total_cost_usd,
    ROUND(AVG(o.readmission_cost_usd), 2)   AS avg_cost_usd,
    ROUND(AVG(a.time_in_hospital), 1)       AS avg_los
FROM Outcomes o
JOIN Admissions a ON o.encounter_id = a.encounter_id
WHERE o.readmission_cost_usd IS NOT NULL
GROUP BY o.readmitted;
