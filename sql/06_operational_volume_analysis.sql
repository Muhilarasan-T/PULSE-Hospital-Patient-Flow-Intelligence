-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 06: Operational Volume & Peak Congestion Analysis
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Input: fct_appointment_visits (N = 49,912)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 6.1: 24-Hour Patient Arrival Volume & Peak Surge Windows
-- Business Question: When do patient queues accumulate, and what are the peak hours?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_volume_hourly;

CREATE TABLE analysis_volume_hourly AS
WITH hourly_counts AS (
    SELECT
        arrival_hour,
        COUNT(*) AS appointment_count
    FROM fct_appointment_visits
    GROUP BY arrival_hour
),
ranked_hourly AS (
    SELECT
        arrival_hour,
        appointment_count,
        ROUND(appointment_count * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits), 2) AS pct_of_total_volume,
        ROUND(SUM(appointment_count) OVER (ORDER BY arrival_hour) * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits), 2) AS cumulative_pct,
        CASE
            WHEN appointment_count >= 4500 THEN 'HIGH_SURGE_PEAK'
            WHEN appointment_count >= 2000 THEN 'MODERATE_LOAD'
            WHEN appointment_count >= 500  THEN 'REGULAR_SHIFT'
            ELSE 'OFF_PEAK_OVERNIGHT'
        END AS congestion_classification,
        DENSE_RANK() OVER (ORDER BY appointment_count DESC) AS hour_volume_rank
    FROM hourly_counts
)
SELECT * FROM ranked_hourly
ORDER BY arrival_hour;

-- ------------------------------------------------------------------------------
-- Query 6.2: Day-of-Week Volume & Capacity Allocation
-- Business Question: What is the weekly load distribution across outpatient clinics?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_volume_daily;

CREATE TABLE analysis_volume_daily AS
SELECT
    CASE arrival_day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END AS day_order,
    arrival_day_of_week,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits), 2) AS pct_weekly_volume,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS day_volume_rank
FROM fct_appointment_visits
GROUP BY day_order, arrival_day_of_week
ORDER BY day_order;

-- ------------------------------------------------------------------------------
-- Query 6.3: Monthly Demand & Growth Trajectory (Using Window LAG)
-- Business Question: How has hospital outpatient volume trended over the 2-year period?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_volume_monthly_trend;

CREATE TABLE analysis_volume_monthly_trend AS
WITH monthly_base AS (
    SELECT
        arrival_year,
        arrival_month,
        COUNT(*) AS monthly_appointments,
        COUNT(DISTINCT patient_id) AS distinct_patients,
        COUNT(DISTINCT appointment_date) AS operating_days_in_month
    FROM fct_appointment_visits
    GROUP BY arrival_year, arrival_month
)
SELECT
    arrival_year,
    arrival_month,
    monthly_appointments,
    distinct_patients,
    operating_days_in_month,
    ROUND(monthly_appointments * 1.0 / operating_days_in_month, 1) AS avg_visits_per_operating_day,
    LAG(monthly_appointments, 1) OVER (ORDER BY arrival_month) AS prior_month_appointments,
    ROUND((monthly_appointments - LAG(monthly_appointments, 1) OVER (ORDER BY arrival_month)) * 100.0 / 
          LAG(monthly_appointments, 1) OVER (ORDER BY arrival_month), 2) AS mom_growth_pct
FROM monthly_base
ORDER BY arrival_month;

-- ------------------------------------------------------------------------------
-- Query 6.4: Patient Visit Recurrence Distribution
-- Business Question: What proportion of patients are one-time vs recurrent attenders?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_patient_recurrence;

CREATE TABLE analysis_patient_recurrence AS
WITH patient_visits AS (
    SELECT
        patient_id,
        COUNT(DISTINCT appointment_id) AS visits_count
    FROM fct_appointment_visits
    GROUP BY patient_id
),
binned_recurrence AS (
    SELECT
        patient_id,
        visits_count,
        CASE
            WHEN visits_count = 1 THEN '1 Visit (Single Encounter)'
            WHEN visits_count = 2 THEN '2 Visits (Follow-up)'
            WHEN visits_count = 3 THEN '3 Visits (Frequent Attender)'
            ELSE '4+ Visits (Chronic / High Utilizer)'
        END AS recurrence_tier,
        CASE
            WHEN visits_count = 1 THEN 1
            WHEN visits_count = 2 THEN 2
            WHEN visits_count = 3 THEN 3
            ELSE 4
        END AS tier_order
    FROM patient_visits
)
SELECT
    tier_order,
    recurrence_tier,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT patient_id) FROM fct_appointment_visits), 2) AS pct_of_patients,
    SUM(visits_count) AS total_appointments_generated,
    ROUND(SUM(visits_count) * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits), 2) AS pct_of_total_hospital_visits
FROM binned_recurrence
GROUP BY tier_order, recurrence_tier
ORDER BY tier_order;
