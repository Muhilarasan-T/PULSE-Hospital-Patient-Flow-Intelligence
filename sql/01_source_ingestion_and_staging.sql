-- ==============================================================================
-- PULSE — Phase 4: Data Quality Auditing & Cleaning
-- Script 01: Source Ingestion and Staging
-- Dialect: ANSI SQL / SQLite 3.51+
-- Target Database: data/processed/pulse.db
-- Input: raw_csv_import (from data/raw/HospitalOPD-noname.csv)
-- ==============================================================================

-- Drop previous staging table if re-running
DROP TABLE IF EXISTS stg_hospital_opd;

-- Create typed Staging Table (stg_hospital_opd)
-- In accordance with Project Requirement B:
-- "Omit the fully blank column only in the cleaned/staging model; document the omitted source column."
CREATE TABLE stg_hospital_opd AS
SELECT
    CAST(TRIM(record_no) AS INTEGER) AS record_no,
    CAST(TRIM(patient_id) AS INTEGER) AS patient_id,
    -- raw_col_2_anonymized is intentionally omitted here as documented in DATA_DICTIONARY.md
    CAST(TRIM(appointment_id) AS INTEGER) AS appointment_id,
    TRIM(appointment_start_datetime) AS raw_appointment_start_datetime,
    CAST(TRIM(prescription_doctor_id) AS INTEGER) AS prescription_doctor_id,
    TRIM(prescription_doctor_name) AS prescription_doctor_name,
    CAST(TRIM(prescription_order_id) AS INTEGER) AS prescription_order_id,
    CASE WHEN TRIM(prescription_start_datetime) = '' THEN NULL ELSE TRIM(prescription_start_datetime) END AS raw_prescription_start_datetime,
    CASE WHEN TRIM(prescription_end_datetime) = '' THEN NULL ELSE TRIM(prescription_end_datetime) END AS raw_prescription_end_datetime,
    CASE WHEN TRIM(lab_id) = '' THEN NULL ELSE CAST(TRIM(lab_id) AS INTEGER) END AS lab_id,
    CASE WHEN TRIM(lab_name) = '' THEN NULL ELSE TRIM(lab_name) END AS lab_name,
    CASE WHEN TRIM(lab_start_datetime) = '' THEN NULL ELSE TRIM(lab_start_datetime) END AS raw_lab_start_datetime,
    CASE WHEN TRIM(lab_end_datetime) = '' THEN NULL ELSE TRIM(lab_end_datetime) END AS raw_lab_end_datetime,
    CASE WHEN TRIM(imaging_request_id) = '' THEN NULL ELSE CAST(TRIM(imaging_request_id) AS INTEGER) END AS imaging_request_id,
    CASE WHEN TRIM(imaging_result_id) = '' THEN NULL ELSE CAST(TRIM(imaging_result_id) AS INTEGER) END AS imaging_result_id,
    CASE WHEN TRIM(imaging_name) = '' THEN NULL ELSE TRIM(imaging_name) END AS imaging_name,
    CASE WHEN TRIM(imaging_start_datetime) = '' THEN NULL ELSE TRIM(imaging_start_datetime) END AS raw_imaging_start_datetime,
    CASE WHEN TRIM(imaging_end_datetime) = '' THEN NULL ELSE TRIM(imaging_end_datetime) END AS raw_imaging_end_datetime,
    CASE WHEN TRIM(pharmacy_sale_line_id) = '' THEN NULL ELSE CAST(TRIM(pharmacy_sale_line_id) AS INTEGER) END AS pharmacy_sale_line_id,
    CASE WHEN TRIM(medicine_name) = '' THEN NULL ELSE TRIM(medicine_name) END AS medicine_name,
    CASE WHEN TRIM(pharmacy_start_datetime) = '' THEN NULL ELSE TRIM(pharmacy_start_datetime) END AS raw_pharmacy_start_datetime,
    CASE WHEN TRIM(pharmacy_end_datetime) = '' THEN NULL ELSE TRIM(pharmacy_end_datetime) END AS raw_pharmacy_end_datetime,
    CAST(TRIM(flow_code) AS INTEGER) AS flow_code,
    TRIM(flow_name) AS flow_name
FROM raw_csv_import;

-- Create indexes on staging table
CREATE UNIQUE INDEX idx_stg_record_no ON stg_hospital_opd(record_no);
CREATE INDEX idx_stg_appointment_id ON stg_hospital_opd(appointment_id);
CREATE INDEX idx_stg_patient_id ON stg_hospital_opd(patient_id);
