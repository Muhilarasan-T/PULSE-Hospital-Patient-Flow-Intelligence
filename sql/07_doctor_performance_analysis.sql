-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 07: Attending Doctor Operations & Throughput Benchmarks
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Input: fct_appointment_visits (N = 49,912) & fct_clinical_events (N = 62,422)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 7.1: Top 20 Attending Doctors by Distinct Appointment Volume
-- Business Question: Which doctors manage the largest patient workloads?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_doctor_volume_ranking;

CREATE TABLE analysis_doctor_volume_ranking AS
WITH doc_totals AS (
    SELECT
        attending_doctor_id AS doctor_id,
        attending_doctor_name AS doctor_name,
        COUNT(DISTINCT appointment_id) AS distinct_appointments_handled,
        SUM(total_event_records) AS total_clinical_events_generated,
        ROUND(COUNT(DISTINCT appointment_id) * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits), 2) AS pct_of_hospital_visits
    FROM fct_appointment_visits
    GROUP BY attending_doctor_id, attending_doctor_name
)
SELECT
    DENSE_RANK() OVER (ORDER BY distinct_appointments_handled DESC) AS volume_rank,
    doctor_id,
    doctor_name,
    distinct_appointments_handled,
    total_clinical_events_generated,
    pct_of_hospital_visits,
    ROUND(SUM(pct_of_hospital_visits) OVER (ORDER BY distinct_appointments_handled DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_pct_share
FROM doc_totals
ORDER BY volume_rank
LIMIT 20;

-- ------------------------------------------------------------------------------
-- Query 7.2: Doctor Consultation Duration Benchmarks (Median, P90, Mean)
-- Business Question: What is the clinical encounter duration distribution per doctor?
-- Denominator: Valid consultation durations (is_valid_consult_duration = 1, N = 49,850)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_doctor_consultation_benchmarks;

CREATE TABLE analysis_doctor_consultation_benchmarks AS
WITH ranked_doc_durations AS (
    SELECT
        attending_doctor_id AS doctor_id,
        attending_doctor_name AS doctor_name,
        consultation_duration_minutes,
        ROW_NUMBER() OVER (PARTITION BY attending_doctor_id ORDER BY consultation_duration_minutes ASC) AS rn,
        COUNT(*) OVER (PARTITION BY attending_doctor_id) AS valid_observations_count
    FROM fct_appointment_visits
    WHERE is_valid_consult_duration = 1
),
doc_summary AS (
    SELECT
        doctor_id,
        doctor_name,
        valid_observations_count,
        ROUND(AVG(consultation_duration_minutes), 2) AS mean_consult_duration_minutes,
        ROUND(AVG(CASE WHEN rn IN ((valid_observations_count + 1) / 2, (valid_observations_count + 2) / 2) THEN consultation_duration_minutes END), 2) AS median_consult_duration_minutes,
        ROUND(AVG(CASE WHEN rn = CAST(ROUND(valid_observations_count * 0.90) AS INT) THEN consultation_duration_minutes END), 2) AS p90_consult_duration_minutes,
        ROUND(SUM(CASE WHEN consultation_duration_minutes = 0.0 THEN 1 ELSE 0 END) * 100.0 / valid_observations_count, 2) AS pct_zero_duration_encounters
    FROM ranked_doc_durations
    GROUP BY doctor_id, doctor_name, valid_observations_count
)
SELECT
    DENSE_RANK() OVER (ORDER BY valid_observations_count DESC) AS volume_rank,
    doctor_id,
    doctor_name,
    valid_observations_count,
    mean_consult_duration_minutes,
    median_consult_duration_minutes,
    p90_consult_duration_minutes,
    pct_zero_duration_encounters
FROM doc_summary
ORDER BY volume_rank;

-- ------------------------------------------------------------------------------
-- Query 7.3: Sample Size Tier Analysis — Guarding Against Small-N Distortion
-- Business Question: Are extreme doctor consultation averages driven by sparse samples?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_doctor_sample_size_tiers;

CREATE TABLE analysis_doctor_sample_size_tiers AS
WITH doc_stats AS (
    SELECT
        doctor_id,
        doctor_name,
        valid_observations_count,
        mean_consult_duration_minutes,
        median_consult_duration_minutes,
        CASE
            WHEN valid_observations_count >= 1000 THEN '1. High Volume (>= 1,000 visits)'
            WHEN valid_observations_count >= 250  THEN '2. Medium Volume (250 - 999 visits)'
            WHEN valid_observations_count >= 30   THEN '3. Low Volume (30 - 249 visits)'
            ELSE '4. Sparse / Low Sample (< 30 visits)'
        END AS sample_size_tier,
        CASE
            WHEN valid_observations_count >= 1000 THEN 1
            WHEN valid_observations_count >= 250  THEN 2
            WHEN valid_observations_count >= 30   THEN 3
            ELSE 4
        END AS tier_order
    FROM analysis_doctor_consultation_benchmarks
)
SELECT
    tier_order,
    sample_size_tier,
    COUNT(*) AS doctor_count,
    SUM(valid_observations_count) AS total_visits_in_tier,
    ROUND(SUM(valid_observations_count) * 100.0 / (SELECT SUM(valid_observations_count) FROM analysis_doctor_consultation_benchmarks), 2) AS pct_of_all_consultations,
    ROUND(AVG(mean_consult_duration_minutes), 2) AS unweighted_tier_avg_duration,
    ROUND(SUM(mean_consult_duration_minutes * valid_observations_count) / SUM(valid_observations_count), 2) AS visit_weighted_tier_avg_duration
FROM doc_stats
GROUP BY tier_order, sample_size_tier
ORDER BY tier_order;
