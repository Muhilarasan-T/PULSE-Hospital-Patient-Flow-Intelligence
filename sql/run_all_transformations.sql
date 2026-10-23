-- ==============================================================================
-- PULSE — Phase 4: Master Execution & Export Orchestration
-- Database: data/processed/pulse.db
-- ==============================================================================

-- 1. Create raw import schema and load CSV
DROP TABLE IF EXISTS raw_csv_import;

CREATE TABLE raw_csv_import (
    record_no                   TEXT,
    patient_id                  TEXT,
    raw_col_2_anonymized        TEXT,  -- Blank column in source CSV
    appointment_id              TEXT,
    appointment_start_datetime  TEXT,
    prescription_doctor_id      TEXT,
    prescription_doctor_name    TEXT,
    prescription_order_id       TEXT,
    prescription_start_datetime TEXT,
    prescription_end_datetime   TEXT,
    lab_id                      TEXT,
    lab_name                    TEXT,
    lab_start_datetime          TEXT,
    lab_end_datetime            TEXT,
    imaging_request_id          TEXT,
    imaging_result_id           TEXT,
    imaging_name                TEXT,
    imaging_start_datetime      TEXT,
    imaging_end_datetime        TEXT,
    pharmacy_sale_line_id       TEXT,
    medicine_name               TEXT,
    pharmacy_start_datetime     TEXT,
    pharmacy_end_datetime       TEXT,
    flow_code                   TEXT,
    flow_name                   TEXT
);

.mode csv
.import --skip 1 data/raw/HospitalOPD-noname.csv raw_csv_import

-- 2. Execute Script 01: Staging
.read sql/01_source_ingestion_and_staging.sql

-- 3. Execute Script 02: Clean Clinical Events
.read sql/02_clean_clinical_events.sql

-- 4. Execute Script 03: Aggregate Appointment Visits
.read sql/03_aggregate_appointment_visits.sql

-- 5. Execute Script 04: Data Quality Reconciliation
.read sql/04_data_quality_reconciliation.sql

-- 6. Export Cleaned Datasets to data/processed/ for Excel 365 Ingestion
.mode csv
.headers on

.output data/processed/fct_clinical_events.csv
SELECT * FROM fct_clinical_events;

.output data/processed/fct_appointment_visits.csv
SELECT * FROM fct_appointment_visits;

.output data/processed/dim_doctors.csv
SELECT * FROM dim_doctors;

.output data/processed/audit_reconciliation_summary.csv
SELECT * FROM audit_reconciliation_summary;

-- 7. Reset output to console and display reconciliation results
.output stdout
.mode column
.headers on
SELECT * FROM audit_reconciliation_summary;
