-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 08: Clinical Pathway & Service Utilization Analysis
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Input: fct_appointment_visits (N = 49,912) & fct_clinical_events (N = 62,422)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 8.1: Clinical Pathway Volume & Wait-Time Profiles (Visit Grain)
-- Business Question: What is the volume and waiting experience across clinical pathways?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_pathway_volume_and_wait;

CREATE TABLE analysis_pathway_volume_and_wait AS
WITH pathway_ranked AS (
    SELECT
        visit_flow_code AS flow_code,
        visit_flow_name AS flow_name,
        initial_wait_time_minutes,
        ROW_NUMBER() OVER (PARTITION BY visit_flow_code ORDER BY initial_wait_time_minutes ASC) AS rn,
        COUNT(*) OVER (PARTITION BY visit_flow_code) AS flow_appointments_count
    FROM fct_appointment_visits
    WHERE is_valid_wait_time = 1
)
SELECT
    flow_code,
    flow_name,
    flow_appointments_count AS valid_appointments,
    ROUND(flow_appointments_count * 100.0 / (SELECT COUNT(*) FROM fct_appointment_visits WHERE is_valid_wait_time = 1), 2) AS pct_of_hospital_visits,
    ROUND(AVG(initial_wait_time_minutes), 2) AS mean_wait_minutes,
    ROUND(AVG(CASE WHEN rn IN ((flow_appointments_count + 1) / 2, (flow_appointments_count + 2) / 2) THEN initial_wait_time_minutes END), 2) AS median_wait_minutes,
    ROUND(AVG(CASE WHEN rn = CAST(ROUND(flow_appointments_count * 0.90) AS INT) THEN initial_wait_time_minutes END), 2) AS p90_wait_minutes
FROM pathway_ranked
GROUP BY flow_code, flow_name, flow_appointments_count
ORDER BY flow_code;

-- ------------------------------------------------------------------------------
-- Query 8.2: Service Mix & Ancillary Diagnostic Utilization Rates
-- Business Question: What percentage of patient visits require diagnostic support?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_service_utilization_mix;

CREATE TABLE analysis_service_utilization_mix AS
SELECT
    COUNT(*) AS total_hospital_visits,
    SUM(has_lab) AS visits_with_lab_orders,
    ROUND(SUM(has_lab) * 100.0 / COUNT(*), 2) AS pct_visits_utilizing_lab,
    SUM(has_imaging) AS visits_with_imaging_orders,
    ROUND(SUM(has_imaging) * 100.0 / COUNT(*), 2) AS pct_visits_utilizing_imaging,
    SUM(has_pharmacy) AS visits_with_pharmacy_dispensing,
    ROUND(SUM(has_pharmacy) * 100.0 / COUNT(*), 2) AS pct_visits_utilizing_pharmacy,
    SUM(CASE WHEN has_lab = 1 AND has_imaging = 1 THEN 1 ELSE 0 END) AS visits_with_both_lab_and_imaging,
    ROUND(SUM(CASE WHEN has_lab = 1 AND has_imaging = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_complex_multi_diagnostic,
    SUM(CASE WHEN has_lab = 0 AND has_imaging = 0 AND has_pharmacy = 0 THEN 1 ELSE 0 END) AS visits_consultation_only,
    ROUND(SUM(CASE WHEN has_lab = 0 AND has_imaging = 0 AND has_pharmacy = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_consultation_only
FROM fct_appointment_visits;

-- ------------------------------------------------------------------------------
-- Query 8.3: Top 15 Most Frequently Ordered Laboratory Tests (Event Grain)
-- Business Question: Which laboratory tests drive the highest clinical volume?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_top_lab_tests;

CREATE TABLE analysis_top_lab_tests AS
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS test_volume_rank,
    lab_name,
    COUNT(*) AS total_orders_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fct_clinical_events WHERE lab_id IS NOT NULL), 2) AS pct_of_all_lab_orders,
    COUNT(DISTINCT appointment_id) AS distinct_appointments_ordering
FROM fct_clinical_events
WHERE lab_name IS NOT NULL
GROUP BY lab_name
ORDER BY test_volume_rank
LIMIT 15;

-- ------------------------------------------------------------------------------
-- Query 8.4: Top 10 Most Frequently Ordered Imaging Modalities (Event Grain)
-- Business Question: What imaging examinations represent the highest departmental demand?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_top_imaging_modalities;

CREATE TABLE analysis_top_imaging_modalities AS
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS imaging_rank,
    imaging_name,
    COUNT(*) AS total_requisitions_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fct_clinical_events WHERE imaging_request_id IS NOT NULL), 2) AS pct_of_all_imaging_orders,
    COUNT(DISTINCT appointment_id) AS distinct_appointments_ordering
FROM fct_clinical_events
WHERE imaging_name IS NOT NULL
GROUP BY imaging_name
ORDER BY imaging_rank
LIMIT 10;

-- ------------------------------------------------------------------------------
-- Query 8.5: Multi-Grain Reconciliation — Visit Grain vs. Event Grain
-- Business Question: Why do total hospital appointments differ from clinical event rows?
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS analysis_multi_grain_reconciliation;

CREATE TABLE analysis_multi_grain_reconciliation AS
SELECT
    v.visit_flow_code AS flow_code,
    v.visit_flow_name AS flow_name,
    COUNT(DISTINCT v.appointment_id) AS total_visits_count,
    SUM(v.total_event_records) AS total_clinical_events_generated,
    ROUND(SUM(v.total_event_records) * 1.0 / COUNT(DISTINCT v.appointment_id), 2) AS avg_events_per_visit,
    MAX(v.total_event_records) AS max_events_in_single_visit
FROM fct_appointment_visits v
GROUP BY v.visit_flow_code, v.visit_flow_name
ORDER BY v.visit_flow_code;
