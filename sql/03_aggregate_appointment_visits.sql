-- ==============================================================================
-- PULSE — Phase 4: Data Quality Auditing & Cleaning
-- Script 03: Aggregate Appointment Visits (fct_appointment_visits)
-- Dialect: ANSI SQL / SQLite 3.51+
-- Target Table: fct_appointment_visits (Expected Rows: 49,912)
-- ==============================================================================

DROP TABLE IF EXISTS fct_appointment_visits;

CREATE TABLE fct_appointment_visits AS
WITH appt_summary AS (
    SELECT
        appointment_id,
        patient_id,
        
        -- Arrival timestamp is strictly consistent across all rows of an appointment
        MIN(appointment_start_datetime) AS appointment_start_datetime,
        
        -- Primary Attending Doctor (from earliest valid consultation)
        MIN(prescription_doctor_id) AS attending_doctor_id,
        MIN(prescription_doctor_name) AS attending_doctor_name,
        
        -- Total Event Records in this encounter
        COUNT(record_no) AS total_event_records,
        
        -- Earliest valid consultation start & latest consultation end
        MIN(CASE WHEN is_valid_wait_time = 1 THEN prescription_start_datetime ELSE NULL END) AS first_valid_prescription_start,
        MIN(prescription_start_datetime) AS raw_first_prescription_start,
        MAX(prescription_end_datetime) AS last_prescription_end,
        
        -- Service Presence & Counts
        MAX(CASE WHEN lab_id IS NOT NULL THEN 1 ELSE 0 END) AS has_lab,
        COUNT(DISTINCT lab_id) AS total_lab_orders,
        MAX(CASE WHEN imaging_request_id IS NOT NULL THEN 1 ELSE 0 END) AS has_imaging,
        COUNT(DISTINCT imaging_request_id) AS total_imaging_requests,
        MAX(CASE WHEN pharmacy_sale_line_id IS NOT NULL THEN 1 ELSE 0 END) AS has_pharmacy,
        COUNT(DISTINCT pharmacy_sale_line_id) AS total_pharmacy_lines,
        
        -- Conflict Detection: Flag if any event record had an anomaly
        MAX(CASE WHEN is_valid_wait_time = 0 OR is_valid_consult_duration = 0 THEN 1 ELSE 0 END) AS has_conflicting_timestamps,
        
        -- Earliest lab/imaging/pharmacy start/end timestamps
        MIN(lab_start_datetime) AS first_lab_start_datetime,
        MAX(lab_end_datetime) AS last_lab_end_datetime,
        MIN(imaging_start_datetime) AS first_imaging_start_datetime,
        MAX(imaging_end_datetime) AS last_imaging_end_datetime,
        MIN(pharmacy_start_datetime) AS first_pharmacy_start_datetime,
        MAX(pharmacy_end_datetime) AS last_pharmacy_end_datetime,
        
        -- Temporal Dimensions
        MIN(appointment_date) AS appointment_date,
        MIN(arrival_year) AS arrival_year,
        MIN(arrival_month) AS arrival_month,
        MIN(arrival_hour) AS arrival_hour,
        MIN(arrival_day_of_week) AS arrival_day_of_week

    FROM fct_clinical_events
    GROUP BY appointment_id, patient_id
)
SELECT
    appointment_id,
    patient_id,
    attending_doctor_id,
    attending_doctor_name,
    total_event_records,
    
    -- Derived Clinical Pathway at Visit Level (Deterministic based on services utilized)
    CASE 
        WHEN has_lab = 1 AND has_imaging = 1 AND has_pharmacy = 1 THEN 7
        WHEN has_lab = 1 AND has_imaging = 1 THEN 5
        WHEN has_lab = 1 AND has_pharmacy = 1 THEN 6
        WHEN has_imaging = 1 AND has_pharmacy = 1 THEN 7
        WHEN has_lab = 1 THEN 2
        WHEN has_imaging = 1 THEN 3
        WHEN has_pharmacy = 1 THEN 4
        ELSE 1
    END AS visit_flow_code,
    
    CASE 
        WHEN has_lab = 1 AND has_imaging = 1 AND has_pharmacy = 1 THEN 'Appointment → Prescription → Lab + Imaging + Pharmacy'
        WHEN has_lab = 1 AND has_imaging = 1 THEN 'Appointment → Prescription → Lab + Imaging'
        WHEN has_lab = 1 AND has_pharmacy = 1 THEN 'Appointment → Prescription → Lab + Pharmacy'
        WHEN has_imaging = 1 AND has_pharmacy = 1 THEN 'Appointment → Prescription → Imaging + Pharmacy'
        WHEN has_lab = 1 THEN 'Appointment → Prescription → Lab'
        WHEN has_imaging = 1 THEN 'Appointment → Prescription → Imaging'
        WHEN has_pharmacy = 1 THEN 'Appointment → Prescription → Pharmacy'
        ELSE 'Appointment → Prescription'
    END AS visit_flow_name,
    
    -- Service Utilization Flags & Order Counts
    has_lab,
    total_lab_orders,
    has_imaging,
    total_imaging_requests,
    has_pharmacy,
    total_pharmacy_lines,
    
    -- Visit Timestamps
    appointment_start_datetime,
    first_valid_prescription_start AS first_prescription_start_datetime,
    last_prescription_end AS last_prescription_end_datetime,
    first_lab_start_datetime,
    last_lab_end_datetime,
    first_imaging_start_datetime,
    last_imaging_end_datetime,
    first_pharmacy_start_datetime,
    last_pharmacy_end_datetime,
    
    -- Initial Wait Time (Arrival to Earliest Valid Consultation Start)
    CASE 
        WHEN first_valid_prescription_start IS NULL THEN NULL
        ELSE ROUND((julianday(first_valid_prescription_start) - julianday(appointment_start_datetime)) * 1440.0, 2)
    END AS initial_wait_time_minutes,
    
    CASE 
        WHEN first_valid_prescription_start IS NULL THEN NULL
        WHEN ROUND((julianday(first_valid_prescription_start) - julianday(appointment_start_datetime)) * 1440.0, 2) >= 0 THEN 1
        ELSE 0
    END AS is_valid_wait_time,
    
    -- Consultation Duration (First Start to Final End)
    CASE 
        WHEN first_valid_prescription_start IS NULL OR last_prescription_end IS NULL THEN NULL
        ELSE ROUND((julianday(last_prescription_end) - julianday(first_valid_prescription_start)) * 1440.0, 2)
    END AS consultation_duration_minutes,
    
    CASE 
        WHEN first_valid_prescription_start IS NULL OR last_prescription_end IS NULL THEN NULL
        WHEN ROUND((julianday(last_prescription_end) - julianday(first_valid_prescription_start)) * 1440.0, 2) >= 0 THEN 1
        ELSE 0
    END AS is_valid_consult_duration,
    
    -- Conflict Flag
    has_conflicting_timestamps,
    
    -- Temporal Dimensions
    appointment_date,
    arrival_year,
    arrival_month,
    arrival_hour,
    arrival_day_of_week

FROM appt_summary;

-- Indexing for visit-level metrics
CREATE UNIQUE INDEX idx_fct_appt_id ON fct_appointment_visits(appointment_id);
CREATE INDEX idx_fct_appt_pat_id ON fct_appointment_visits(patient_id);
CREATE INDEX idx_fct_appt_doc_id ON fct_appointment_visits(attending_doctor_id);
CREATE INDEX idx_fct_appt_date ON fct_appointment_visits(appointment_date);
CREATE INDEX idx_fct_appt_flow ON fct_appointment_visits(visit_flow_code);

-- Doctor Dimension Table
DROP TABLE IF EXISTS dim_doctors;

CREATE TABLE dim_doctors AS
SELECT
    prescription_doctor_id AS doctor_id,
    prescription_doctor_name AS doctor_name,
    COUNT(DISTINCT appointment_id) AS total_visits_handled,
    COUNT(record_no) AS total_events_handled,
    ROUND(AVG(CASE WHEN is_valid_consult_duration = 1 THEN consultation_duration_minutes ELSE NULL END), 2) AS avg_consult_duration_minutes,
    MIN(appointment_date) AS first_active_date,
    MAX(appointment_date) AS last_active_date
FROM fct_clinical_events
GROUP BY prescription_doctor_id, prescription_doctor_name;

CREATE UNIQUE INDEX idx_dim_doctor_id ON dim_doctors(doctor_id);
