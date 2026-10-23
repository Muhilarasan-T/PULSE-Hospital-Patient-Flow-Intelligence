-- ==============================================================================
-- PULSE — Phase 4: Data Quality Auditing & Cleaning
-- Script 04: Data Quality Auditing & Reconciliation Suite
-- Dialect: ANSI SQL / SQLite 3.51+
-- Target Database: data/processed/pulse.db
-- ==============================================================================

DROP TABLE IF EXISTS audit_reconciliation_summary;

CREATE TABLE audit_reconciliation_summary AS
-- 1. Table Row Counts & Grain Parity
SELECT 
    '1. Row Count: Staging Table' AS check_name,
    COUNT(*) AS actual_value,
    62422 AS expected_value,
    CASE WHEN COUNT(*) = 62422 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Staging table must match total raw event rows exactly' AS check_description
FROM stg_hospital_opd

UNION ALL

SELECT 
    '2. Row Count: fct_clinical_events' AS check_name,
    COUNT(*) AS actual_value,
    62422 AS expected_value,
    CASE WHEN COUNT(*) = 62422 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Cleaned event table must preserve all 62,422 rows with row-level lineage' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '3. Row Count: fct_appointment_visits' AS check_name,
    COUNT(*) AS actual_value,
    49912 AS expected_value,
    CASE WHEN COUNT(*) = 49912 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Appointment visit grain table must equal distinct appointment_ids' AS check_description
FROM fct_appointment_visits

UNION ALL

-- 2. Primary Key Uniqueness
SELECT 
    '4. Duplicate Check: record_no in fct_clinical_events' AS check_name,
    COUNT(*) - COUNT(DISTINCT record_no) AS actual_value,
    0 AS expected_value,
    CASE WHEN COUNT(*) = COUNT(DISTINCT record_no) THEN 'PASS' ELSE 'FAIL' END AS status,
    'Primary key record_no must have zero duplicates' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '5. Duplicate Check: appointment_id in fct_appointment_visits' AS check_name,
    COUNT(*) - COUNT(DISTINCT appointment_id) AS actual_value,
    0 AS expected_value,
    CASE WHEN COUNT(*) = COUNT(DISTINCT appointment_id) THEN 'PASS' ELSE 'FAIL' END AS status,
    'Primary key appointment_id must have zero duplicates' AS check_description
FROM fct_appointment_visits

UNION ALL

-- 3. Core Foreign Key Nullability
SELECT 
    '6. Null Check: patient_id in fct_clinical_events' AS check_name,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS actual_value,
    0 AS expected_value,
    CASE WHEN SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'patient_id must be 100% populated' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '7. Null Check: appointment_start_datetime in fct_clinical_events' AS check_name,
    SUM(CASE WHEN appointment_start_datetime IS NULL THEN 1 ELSE 0 END) AS actual_value,
    0 AS expected_value,
    CASE WHEN SUM(CASE WHEN appointment_start_datetime IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Arrival timestamp must be 100% populated' AS check_description
FROM fct_clinical_events

UNION ALL

-- 4. Anomaly Audits & Correction Flags
SELECT 
    '8. Anomaly Audit: Negative Wait Times Flagged' AS check_name,
    SUM(CASE WHEN is_valid_wait_time = 0 THEN 1 ELSE 0 END) AS actual_value,
    5 AS expected_value,
    CASE WHEN SUM(CASE WHEN is_valid_wait_time = 0 THEN 1 ELSE 0 END) = 5 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 5 negative wait times retained and flagged with is_valid_wait_time = 0' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '9. Anomaly Audit: Negative Consult Durations Flagged' AS check_name,
    SUM(CASE WHEN is_valid_consult_duration = 0 THEN 1 ELSE 0 END) AS actual_value,
    51 AS expected_value,
    CASE WHEN SUM(CASE WHEN is_valid_consult_duration = 0 THEN 1 ELSE 0 END) = 51 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 51 negative durations retained and flagged with is_valid_consult_duration = 0 (52 in raw minus record 28837 corrected)' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '10. Correction Audit: record_no 28837 Year Typo Corrected' AS check_name,
    SUM(is_corrected_datetime) AS actual_value,
    1 AS expected_value,
    CASE WHEN SUM(is_corrected_datetime) = 1 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 1 validated datetime correction applied with audit trail and original preserved' AS check_description
FROM fct_clinical_events

UNION ALL

-- 5. Truncated Lab End Reconstruction Audits
SELECT 
    '11. Lab Audit: Truncated mm:ss.0 Timestamps Flagged' AS check_name,
    SUM(CASE WHEN lab_end_reconstruction_status = 'TRUNCATED_TIME_ONLY' THEN 1 ELSE 0 END) AS actual_value,
    4702 AS expected_value,
    CASE WHEN SUM(CASE WHEN lab_end_reconstruction_status = 'TRUNCATED_TIME_ONLY' THEN 1 ELSE 0 END) = 4702 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 4,702 truncated lab timestamps retained in raw and flagged for analytical transparency' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '12. Lab Audit: Standard Full Datetimes Cleaned' AS check_name,
    SUM(CASE WHEN lab_end_reconstruction_status = 'ORIGINAL_STANDARD' THEN 1 ELSE 0 END) AS actual_value,
    13327 AS expected_value,
    CASE WHEN SUM(CASE WHEN lab_end_reconstruction_status = 'ORIGINAL_STANDARD' THEN 1 ELSE 0 END) = 13327 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 13,327 standard lab end datetimes parsed into ISO format' AS check_description
FROM fct_clinical_events

UNION ALL

SELECT 
    '13. Lab Audit: Structural Nulls Preserved' AS check_name,
    SUM(CASE WHEN lab_end_reconstruction_status = 'STRUCTURAL_NULL' THEN 1 ELSE 0 END) AS actual_value,
    44393 AS expected_value,
    CASE WHEN SUM(CASE WHEN lab_end_reconstruction_status = 'STRUCTURAL_NULL' THEN 1 ELSE 0 END) = 44393 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Exactly 44,393 structural nulls retained for non-lab workflows' AS check_description
FROM fct_clinical_events;

-- View results
SELECT * FROM audit_reconciliation_summary;
