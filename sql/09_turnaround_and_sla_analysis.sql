-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 09: Turnaround Time (TAT) & Exploratory SLA Scenario Modeling
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Input: fct_appointment_visits (N = 49,912) & fct_clinical_events (N = 62,422)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 9.1: Exploratory Wait-Time SLA Scenarios (Cumulative Compliance)
-- Business Question: What percentage of patients are seen under configurable benchmark thresholds?
-- Note: Clearly labeled as exploratory operational scenarios; not hospital policy.
-- Denominator: Valid appointments (is_valid_wait_time = 1, N = 49,896)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_sla_exploratory_scenarios;

CREATE TABLE analysis_sla_exploratory_scenarios AS
SELECT
    COUNT(*) AS valid_appointments_analyzed,
    16 AS excluded_appointments_count,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 15.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_15min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 30.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_30min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 45.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_45min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 60.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_60min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 90.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_90min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 120.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_seen_within_120min,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes > 120.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_breaching_120min
FROM fct_appointment_visits
WHERE is_valid_wait_time = 1;

-- ------------------------------------------------------------------------------
-- Query 9.2: Exploratory 30-Minute & 60-Minute SLA Compliance by Arrival Hour
-- Business Question: In which hours do SLA breaches concentrate most heavily?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_sla_by_hour;

CREATE TABLE analysis_sla_by_hour AS
SELECT
    arrival_hour,
    COUNT(*) AS total_visits,
    SUM(CASE WHEN initial_wait_time_minutes <= 30.0 THEN 1 ELSE 0 END) AS visits_within_30m,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 30.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_within_30m_sla,
    SUM(CASE WHEN initial_wait_time_minutes <= 60.0 THEN 1 ELSE 0 END) AS visits_within_60m,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes <= 60.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_within_60m_sla,
    SUM(CASE WHEN initial_wait_time_minutes > 60.0 THEN 1 ELSE 0 END) AS breaches_over_60m,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes > 60.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_breaching_60m
FROM fct_appointment_visits
WHERE is_valid_wait_time = 1
GROUP BY arrival_hour
ORDER BY arrival_hour;

-- ------------------------------------------------------------------------------
-- Query 9.3: Diagnostic Laboratory Turnaround Time (TAT) on Valid Timestamps
-- Business Question: What is the processing turnaround for clinical laboratory tests?
-- Denominator: Valid complete timestamps (lab_end_reconstruction_status = 'ORIGINAL_STANDARD', N = 13,327)
-- Exclusions: 4,702 truncated mm:ss.0 timestamps, 44,393 structural nulls
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_lab_turnaround_summary;

CREATE TABLE analysis_lab_turnaround_summary AS
WITH ranked_lab AS (
    SELECT
        lab_turnaround_time_minutes,
        ROW_NUMBER() OVER (ORDER BY lab_turnaround_time_minutes ASC) AS rn,
        COUNT(*) OVER () AS n_lab
    FROM fct_clinical_events
    WHERE lab_end_reconstruction_status = 'ORIGINAL_STANDARD'
)
SELECT
    'Standard Complete Lab Orders' AS metric_scope,
    n_lab AS valid_sample_size,
    4702 AS excluded_truncated_count,
    ROUND(4702 * 100.0 / (n_lab + 4702), 2) AS pct_lab_records_truncated,
    ROUND(AVG(lab_turnaround_time_minutes), 2) AS mean_tat_minutes,
    MIN(lab_turnaround_time_minutes) AS min_tat_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_lab * 0.25) AS INT) THEN lab_turnaround_time_minutes END), 2) AS p25_tat_minutes,
    ROUND(AVG(CASE WHEN rn IN ((n_lab + 1) / 2, (n_lab + 2) / 2) THEN lab_turnaround_time_minutes END), 2) AS median_tat_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_lab * 0.75) AS INT) THEN lab_turnaround_time_minutes END), 2) AS p75_tat_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_lab * 0.90) AS INT) THEN lab_turnaround_time_minutes END), 2) AS p90_tat_minutes,
    MAX(lab_turnaround_time_minutes) AS max_tat_minutes
FROM ranked_lab;

-- ------------------------------------------------------------------------------
-- Query 9.4: Top 10 Laboratory Tests by Order Volume with Median Turnaround
-- Business Question: How does turnaround velocity vary across specific lab tests?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_lab_test_specific_tat;

CREATE TABLE analysis_lab_test_specific_tat AS
WITH lab_ranked AS (
    SELECT
        lab_name,
        lab_turnaround_time_minutes,
        ROW_NUMBER() OVER (PARTITION BY lab_name ORDER BY lab_turnaround_time_minutes ASC) AS rn,
        COUNT(*) OVER (PARTITION BY lab_name) AS valid_test_n
    FROM fct_clinical_events
    WHERE lab_end_reconstruction_status = 'ORIGINAL_STANDARD' AND lab_name IS NOT NULL
),
test_summary AS (
    SELECT
        lab_name,
        valid_test_n,
        ROUND(AVG(lab_turnaround_time_minutes), 2) AS mean_tat_minutes,
        ROUND(AVG(CASE WHEN rn IN ((valid_test_n + 1) / 2, (valid_test_n + 2) / 2) THEN lab_turnaround_time_minutes END), 2) AS median_tat_minutes,
        ROUND(AVG(CASE WHEN rn = CAST(ROUND(valid_test_n * 0.90) AS INT) THEN lab_turnaround_time_minutes END), 2) AS p90_tat_minutes
    FROM lab_ranked
    GROUP BY lab_name, valid_test_n
)
SELECT
    DENSE_RANK() OVER (ORDER BY valid_test_n DESC) AS rank_by_volume,
    lab_name,
    valid_test_n AS valid_observations_count,
    median_tat_minutes,
    mean_tat_minutes,
    p90_tat_minutes
FROM test_summary
ORDER BY rank_by_volume
LIMIT 10;

-- ------------------------------------------------------------------------------
-- Query 9.5: Diagnostic Imaging Examination Turnaround Time (TAT)
-- Business Question: What is the duration of radiological scanning procedures?
-- Denominator: Valid complete imaging encounters (imaging_status = 'VALID', N = 5,513)
-- Exclusions: 10 missing end timestamps, 56,899 structural nulls
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_imaging_turnaround_summary;

CREATE TABLE analysis_imaging_turnaround_summary AS
WITH ranked_img AS (
    SELECT
        imaging_duration_minutes,
        ROW_NUMBER() OVER (ORDER BY imaging_duration_minutes ASC) AS rn,
        COUNT(*) OVER () AS n_img
    FROM fct_clinical_events
    WHERE imaging_status = 'VALID'
)
SELECT
    'Valid Imaging Procedures' AS metric_scope,
    n_img AS valid_sample_size,
    10 AS excluded_missing_end_count,
    ROUND(AVG(imaging_duration_minutes), 2) AS mean_duration_minutes,
    MIN(imaging_duration_minutes) AS min_duration_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_img * 0.25) AS INT) THEN imaging_duration_minutes END), 2) AS p25_duration_minutes,
    ROUND(AVG(CASE WHEN rn IN ((n_img + 1) / 2, (n_img + 2) / 2) THEN imaging_duration_minutes END), 2) AS median_duration_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_img * 0.75) AS INT) THEN imaging_duration_minutes END), 2) AS p75_duration_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_img * 0.90) AS INT) THEN imaging_duration_minutes END), 2) AS p90_duration_minutes,
    MAX(imaging_duration_minutes) AS max_duration_minutes
FROM ranked_img;

-- ------------------------------------------------------------------------------
-- Query 9.6: Patient Journey Boundary Disclosure
-- Business Question: Which milestones does the dataset capture vs hospital exit?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_journey_boundary_audit;

CREATE TABLE analysis_journey_boundary_audit AS
SELECT
    'Arrival / Registration' AS milestone_name,
    'appointment_start_datetime' AS timestamp_column,
    COUNT(appointment_start_datetime) AS captured_count,
    'Yes (100% captured)' AS is_captured_in_data
FROM fct_appointment_visits

UNION ALL

SELECT
    'Doctor Consultation Start',
    'first_prescription_start_datetime',
    COUNT(first_prescription_start_datetime),
    'Yes (99.97% valid)'
FROM fct_appointment_visits

UNION ALL

SELECT
    'Doctor Consultation End',
    'last_prescription_end_datetime',
    COUNT(last_prescription_end_datetime),
    'Yes (99.98% valid)'
FROM fct_appointment_visits

UNION ALL

SELECT
    'Laboratory Investigation End',
    'last_lab_end_datetime',
    COUNT(last_lab_end_datetime),
    'Partial (13,327 valid full timestamps; 4,702 truncated)'
FROM fct_appointment_visits

UNION ALL

SELECT
    'Hospital Physical Exit / Discharge',
    'None (Not in schema)',
    0,
    'NO — Outpatient departure time is not logged in this dataset';
