-- ==============================================================================
-- PULSE — Phase 5: In-Depth SQL Analysis & Operational KPI Modeling
-- Script 10: Analytical KPI Quality & Denominator Reconciliation Suite
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- ==============================================================================

DROP TABLE IF EXISTS audit_kpi_reconciliation;

CREATE TABLE audit_kpi_reconciliation AS
-- 1. Overall Wait Time Denominator Integrity
SELECT
    '1. Wait Time Analysis Denominator' AS test_name,
    valid_appointments_count + excluded_records_count AS actual_value,
    49912 AS expected_value,
    CASE WHEN (valid_appointments_count + excluded_records_count) = 49912 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Valid visits (49,896) + Excluded (16) must equal total hospital visits (49,912)' AS test_description
FROM analysis_wait_time_overall

UNION ALL

-- 2. Wait Time Distribution Completeness
SELECT
    '2. Wait Time Distribution Tier Sum' AS test_name,
    SUM(appointment_count) AS actual_value,
    49896 AS expected_value,
    CASE WHEN SUM(appointment_count) = 49896 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of all wait-time tolerance tiers must equal 49,896 valid appointments' AS test_description
FROM analysis_wait_time_distribution

UNION ALL

-- 3. Hourly Volume Completeness
SELECT
    '3. Hourly Volume Aggregation Total' AS test_name,
    SUM(appointment_count) AS actual_value,
    49912 AS expected_value,
    CASE WHEN SUM(appointment_count) = 49912 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of all 24-hour arrival volumes must equal 49,912' AS test_description
FROM analysis_volume_hourly

UNION ALL

-- 4. Day-of-Week Volume Completeness
SELECT
    '4. Daily Volume Aggregation Total' AS test_name,
    SUM(total_appointments) AS actual_value,
    49912 AS expected_value,
    CASE WHEN SUM(total_appointments) = 49912 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of 7-day weekly arrival volume must equal 49,912' AS test_description
FROM analysis_volume_daily

UNION ALL

-- 5. Doctor Consultation Denominator Integrity
SELECT
    '5. Doctor Consultation Observations' AS test_name,
    SUM(valid_observations_count) AS actual_value,
    49850 AS expected_value,
    CASE WHEN SUM(valid_observations_count) = 49850 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of valid doctor consults must equal 49,850 (62 excluded for negative/missing durations)' AS test_description
FROM analysis_doctor_consultation_benchmarks

UNION ALL

-- 6. Clinical Pathway Total Visits
SELECT
    '6. Pathway Volume Sum' AS test_name,
    SUM(valid_appointments) AS actual_value,
    49896 AS expected_value,
    CASE WHEN SUM(valid_appointments) = 49896 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of all valid pathway appointments must equal 49,896' AS test_description
FROM analysis_pathway_volume_and_wait

UNION ALL

-- 7. Diagnostic Laboratory Order Completeness
SELECT
    '7. Laboratory Orders Parity' AS test_name,
    valid_sample_size + excluded_truncated_count AS actual_value,
    18029 AS expected_value,
    CASE WHEN (valid_sample_size + excluded_truncated_count) = 18029 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Standard lab records (13,327) + Truncated mm:ss.0 (4,702) must equal total lab orders (18,029)' AS test_description
FROM analysis_lab_turnaround_summary

UNION ALL

-- 8. Diagnostic Imaging Order Completeness
SELECT
    '8. Imaging Orders Parity' AS test_name,
    valid_sample_size + excluded_missing_end_count AS actual_value,
    5523 AS expected_value,
    CASE WHEN (valid_sample_size + excluded_missing_end_count) = 5523 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Valid imaging records (5,513) + Missing end timestamps (10) must equal total imaging orders (5,523)' AS test_description
FROM analysis_imaging_turnaround_summary

UNION ALL

-- 9. Multi-Grain Row Parity
SELECT
    '9. Multi-Grain Event Total' AS test_name,
    SUM(total_clinical_events_generated) AS actual_value,
    62422 AS expected_value,
    CASE WHEN SUM(total_clinical_events_generated) = 62422 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Sum of events generated across all pathways must equal 62,422 event rows' AS test_description
FROM analysis_multi_grain_reconciliation;

-- View audit results
SELECT * FROM audit_kpi_reconciliation;
