-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 05: Patient Wait-Time Analysis
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Input: fct_appointment_visits (Encounter Grain, N = 49,912)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 5.1: Overall Wait-Time Summary & Percentile Benchmark
-- Business Question: What are the median, mean, and dispersion metrics for patient wait time?
-- Denominator: Valid appointments (is_valid_wait_time = 1, N = 49,896)
-- Exclusions: 5 negative waits, 11 missing consultation starts (Total = 16 excluded)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_wait_time_overall;

CREATE TABLE analysis_wait_time_overall AS
WITH ordered_waits AS (
    SELECT
        initial_wait_time_minutes,
        ROW_NUMBER() OVER (ORDER BY initial_wait_time_minutes ASC) AS rn,
        COUNT(*) OVER () AS total_count
    FROM fct_appointment_visits
    WHERE is_valid_wait_time = 1
)
SELECT
    'Valid Appointments' AS metric_scope,
    total_count AS valid_appointments_count,
    16 AS excluded_records_count,
    49912 AS total_hospital_appointments,
    ROUND(total_count * 100.0 / 49912, 2) AS pct_sample_analyzed,
    ROUND(AVG(initial_wait_time_minutes), 2) AS mean_wait_minutes,
    MIN(initial_wait_time_minutes) AS min_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(total_count * 0.25) AS INT) THEN initial_wait_time_minutes END), 2) AS p25_wait_minutes,
    ROUND(AVG(CASE WHEN rn IN ((total_count + 1) / 2, (total_count + 2) / 2) THEN initial_wait_time_minutes END), 2) AS median_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(total_count * 0.75) AS INT) THEN initial_wait_time_minutes END), 2) AS p75_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(total_count * 0.90) AS INT) THEN initial_wait_time_minutes END), 2) AS p90_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(total_count * 0.95) AS INT) THEN initial_wait_time_minutes END), 2) AS p95_wait_minutes,
    MAX(initial_wait_time_minutes) AS max_wait_minutes
FROM ordered_waits;

-- ------------------------------------------------------------------------------
-- Query 5.2: Wait-Time Distribution Across Operational Tolerance Tiers
-- Business Question: What percentage of patients fall into standard vs delayed waiting bins?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_wait_time_distribution;

CREATE TABLE analysis_wait_time_distribution AS
WITH binned_waits AS (
    SELECT
        appointment_id,
        initial_wait_time_minutes,
        CASE
            WHEN initial_wait_time_minutes < 15.0 THEN '1. Under 15 Min (Immediate)'
            WHEN initial_wait_time_minutes <= 30.0 THEN '2. 15 to 30 Min (Target Standard)'
            WHEN initial_wait_time_minutes <= 60.0 THEN '3. 30 to 60 Min (Moderate Delay)'
            WHEN initial_wait_time_minutes <= 120.0 THEN '4. 60 to 120 Min (Significant Delay)'
            ELSE '5. Over 120 Min (Severe Congestion)'
        END AS wait_tier,
        CASE
            WHEN initial_wait_time_minutes < 15.0 THEN 1
            WHEN initial_wait_time_minutes <= 30.0 THEN 2
            WHEN initial_wait_time_minutes <= 60.0 THEN 3
            WHEN initial_wait_time_minutes <= 120.0 THEN 4
            ELSE 5
        END AS tier_order
    FROM fct_appointment_visits
    WHERE is_valid_wait_time = 1
)
SELECT
    tier_order,
    wait_tier,
    COUNT(*) AS appointment_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits WHERE is_valid_wait_time = 1), 2) AS pct_of_valid_visits,
    ROUND(AVG(initial_wait_time_minutes), 2) AS avg_wait_in_tier,
    MIN(initial_wait_time_minutes) AS min_wait_in_tier,
    MAX(initial_wait_time_minutes) AS max_wait_in_tier
FROM binned_waits
GROUP BY tier_order, wait_tier
ORDER BY tier_order;

-- ------------------------------------------------------------------------------
-- Query 5.3: Hourly Wait-Time Variation & Delay Concentration
-- Business Question: Which arrival hours suffer the highest waiting times?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_wait_time_by_hour;

CREATE TABLE analysis_wait_time_by_hour AS
WITH ranked_hourly AS (
    SELECT
        arrival_hour,
        initial_wait_time_minutes,
        ROW_NUMBER() OVER (PARTITION BY arrival_hour ORDER BY initial_wait_time_minutes ASC) AS rn,
        COUNT(*) OVER (PARTITION BY arrival_hour) AS n_hour
    FROM fct_appointment_visits
    WHERE is_valid_wait_time = 1
)
SELECT
    arrival_hour,
    n_hour AS valid_appointments,
    ROUND(AVG(initial_wait_time_minutes), 2) AS mean_wait_minutes,
    ROUND(AVG(CASE WHEN rn IN ((n_hour + 1) / 2, (n_hour + 2) / 2) THEN initial_wait_time_minutes END), 2) AS median_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_hour * 0.90) AS INT) THEN initial_wait_time_minutes END), 2) AS p90_wait_minutes,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes > 60.0 THEN 1 ELSE 0 END) * 100.0 / n_hour, 2) AS pct_exceeding_60min
FROM ranked_hourly
GROUP BY arrival_hour, n_hour
ORDER BY arrival_hour;

-- ------------------------------------------------------------------------------
-- Query 5.4: Day-of-Week Wait-Time Profiles
-- Business Question: How does queue latency shift across the operating week?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_wait_time_by_day;

CREATE TABLE analysis_wait_time_by_day AS
WITH ranked_daily AS (
    SELECT
        arrival_day_of_week,
        initial_wait_time_minutes,
        CASE arrival_day_of_week
            WHEN 'Monday' THEN 1
            WHEN 'Tuesday' THEN 2
            WHEN 'Wednesday' THEN 3
            WHEN 'Thursday' THEN 4
            WHEN 'Friday' THEN 5
            WHEN 'Saturday' THEN 6
            WHEN 'Sunday' THEN 7
        END AS day_order,
        ROW_NUMBER() OVER (PARTITION BY arrival_day_of_week ORDER BY initial_wait_time_minutes ASC) AS rn,
        COUNT(*) OVER (PARTITION BY arrival_day_of_week) AS n_day
    FROM fct_appointment_visits
    WHERE is_valid_wait_time = 1
)
SELECT
    day_order,
    arrival_day_of_week,
    n_day AS valid_appointments,
    ROUND(AVG(initial_wait_time_minutes), 2) AS mean_wait_minutes,
    ROUND(AVG(CASE WHEN rn IN ((n_day + 1) / 2, (n_day + 2) / 2) THEN initial_wait_time_minutes END), 2) AS median_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(n_day * 0.90) AS INT) THEN initial_wait_time_minutes END), 2) AS p90_wait_minutes,
    ROUND(SUM(CASE WHEN initial_wait_time_minutes > 60.0 THEN 1 ELSE 0 END) * 100.0 / n_day, 2) AS pct_exceeding_60min
FROM ranked_daily
GROUP BY day_order, arrival_day_of_week, n_day
ORDER BY day_order;

-- ------------------------------------------------------------------------------
-- Query 5.5: Sensitivity Audit — Impact of Excluding Invalid Wait Times
-- Business Question: How sensitive are the findings to excluding negative records?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_wait_time_sensitivity;

CREATE TABLE analysis_wait_time_sensitivity AS
SELECT
    'Strict Filter (is_valid_wait_time = 1)' AS scenario,
    COUNT(*) AS sample_size,
    ROUND(AVG(initial_wait_time_minutes), 2) AS mean_wait,
    MIN(initial_wait_time_minutes) AS min_wait,
    MAX(initial_wait_time_minutes) AS max_wait
FROM fct_appointment_visits
WHERE is_valid_wait_time = 1

UNION ALL

SELECT
    'Unfiltered Raw Visits (Including 5 Negative Records)' AS scenario,
    COUNT(*) AS sample_size,
    ROUND(AVG(raw_wait), 2) AS mean_wait,
    MIN(raw_wait) AS min_wait,
    MAX(raw_wait) AS max_wait
FROM (
    SELECT
        appointment_id,
        ROUND((julianday(MIN(prescription_start_datetime)) - julianday(MIN(appointment_start_datetime))) * 1440.0, 2) AS raw_wait
    FROM fct_clinical_events
    WHERE prescription_start_datetime IS NOT NULL
    GROUP BY appointment_id
);
