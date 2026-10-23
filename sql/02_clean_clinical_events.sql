-- ==============================================================================
-- PULSE — Phase 4: Data Quality Auditing & Cleaning
-- Script 02: Clean Clinical Events (fct_clinical_events)
-- Dialect: ANSI SQL / SQLite 3.51+
-- Target Table: fct_clinical_events (Expected Rows: 62,422)
-- ==============================================================================

DROP TABLE IF EXISTS fct_clinical_events;

-- Create Cleaned Events Table using CTE
CREATE TABLE fct_clinical_events AS
WITH parsed_base AS (
    SELECT
        record_no,
        patient_id,
        appointment_id,
        raw_appointment_start_datetime,
        prescription_doctor_id,
        prescription_doctor_name,
        prescription_order_id,
        raw_prescription_start_datetime,
        raw_prescription_end_datetime,
        lab_id,
        lab_name,
        raw_lab_start_datetime,
        raw_lab_end_datetime,
        imaging_request_id,
        imaging_result_id,
        imaging_name,
        raw_imaging_start_datetime,
        raw_imaging_end_datetime,
        pharmacy_sale_line_id,
        medicine_name,
        raw_pharmacy_start_datetime,
        raw_pharmacy_end_datetime,
        flow_code,
        flow_name,

        -- 1. Parse appointment_start_datetime
        printf('%04d-%02d-%02d %02d:%02d:00',
            CAST(substr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), instr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), '/') + instr(substr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), instr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
            CAST(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, '/') - 1) AS INTEGER),
            CAST(substr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), instr(raw_appointment_start_datetime, '/') + 1, instr(substr(substr(raw_appointment_start_datetime, 1, instr(raw_appointment_start_datetime, ' ') - 1), instr(raw_appointment_start_datetime, '/') + 1), '/') - 1) AS INTEGER),
            CAST(substr(substr(raw_appointment_start_datetime, instr(raw_appointment_start_datetime, ' ') + 1), 1, instr(substr(raw_appointment_start_datetime, instr(raw_appointment_start_datetime, ' ') + 1), ':') - 1) AS INTEGER),
            CAST(substr(substr(raw_appointment_start_datetime, instr(raw_appointment_start_datetime, ' ') + 1), instr(substr(raw_appointment_start_datetime, instr(raw_appointment_start_datetime, ' ') + 1), ':') + 1) AS INTEGER)
        ) AS clean_appt_start,

        -- 2. Parse prescription_start_datetime (handling record_no = 28837 proposed correction)
        CASE 
            WHEN raw_prescription_start_datetime IS NULL OR TRIM(raw_prescription_start_datetime) = '' THEN NULL
            WHEN record_no = 28837 THEN '2025-07-23 16:43:00' -- Validated year 2026 typo correction to 2025
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), instr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), '/') + instr(substr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), instr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), instr(raw_prescription_start_datetime, '/') + 1, instr(substr(substr(raw_prescription_start_datetime, 1, instr(raw_prescription_start_datetime, ' ') - 1), instr(raw_prescription_start_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_start_datetime, instr(raw_prescription_start_datetime, ' ') + 1), 1, instr(substr(raw_prescription_start_datetime, instr(raw_prescription_start_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_start_datetime, instr(raw_prescription_start_datetime, ' ') + 1), instr(substr(raw_prescription_start_datetime, instr(raw_prescription_start_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_rx_start,

        -- 3. Parse prescription_end_datetime
        CASE 
            WHEN raw_prescription_end_datetime IS NULL OR TRIM(raw_prescription_end_datetime) = '' THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), instr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), '/') + instr(substr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), instr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), instr(raw_prescription_end_datetime, '/') + 1, instr(substr(substr(raw_prescription_end_datetime, 1, instr(raw_prescription_end_datetime, ' ') - 1), instr(raw_prescription_end_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_end_datetime, instr(raw_prescription_end_datetime, ' ') + 1), 1, instr(substr(raw_prescription_end_datetime, instr(raw_prescription_end_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_prescription_end_datetime, instr(raw_prescription_end_datetime, ' ') + 1), instr(substr(raw_prescription_end_datetime, instr(raw_prescription_end_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_rx_end,

        -- 4. Parse lab_start_datetime
        CASE 
            WHEN raw_lab_start_datetime IS NULL THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), instr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), '/') + instr(substr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), instr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), instr(raw_lab_start_datetime, '/') + 1, instr(substr(substr(raw_lab_start_datetime, 1, instr(raw_lab_start_datetime, ' ') - 1), instr(raw_lab_start_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_start_datetime, instr(raw_lab_start_datetime, ' ') + 1), 1, instr(substr(raw_lab_start_datetime, instr(raw_lab_start_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_start_datetime, instr(raw_lab_start_datetime, ' ') + 1), instr(substr(raw_lab_start_datetime, instr(raw_lab_start_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_lab_start,

        -- 5. Parse lab_end_datetime (13,327 standard timestamps parsed; 4,702 mm:ss.0 left as NULL with flag)
        CASE 
            WHEN raw_lab_end_datetime IS NULL THEN NULL
            WHEN raw_lab_end_datetime NOT LIKE '%/%' THEN NULL -- mm:ss.0 truncated format retained in raw
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), instr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), '/') + instr(substr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), instr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), instr(raw_lab_end_datetime, '/') + 1, instr(substr(substr(raw_lab_end_datetime, 1, instr(raw_lab_end_datetime, ' ') - 1), instr(raw_lab_end_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_end_datetime, instr(raw_lab_end_datetime, ' ') + 1), 1, instr(substr(raw_lab_end_datetime, instr(raw_lab_end_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_lab_end_datetime, instr(raw_lab_end_datetime, ' ') + 1), instr(substr(raw_lab_end_datetime, instr(raw_lab_end_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_lab_end,

        -- 6. Parse imaging_start_datetime
        CASE 
            WHEN raw_imaging_start_datetime IS NULL THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), instr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), '/') + instr(substr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), instr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), instr(raw_imaging_start_datetime, '/') + 1, instr(substr(substr(raw_imaging_start_datetime, 1, instr(raw_imaging_start_datetime, ' ') - 1), instr(raw_imaging_start_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_start_datetime, instr(raw_imaging_start_datetime, ' ') + 1), 1, instr(substr(raw_imaging_start_datetime, instr(raw_imaging_start_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_start_datetime, instr(raw_imaging_start_datetime, ' ') + 1), instr(substr(raw_imaging_start_datetime, instr(raw_imaging_start_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_img_start,

        -- 7. Parse imaging_end_datetime
        CASE 
            WHEN raw_imaging_end_datetime IS NULL THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), instr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), '/') + instr(substr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), instr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), instr(raw_imaging_end_datetime, '/') + 1, instr(substr(substr(raw_imaging_end_datetime, 1, instr(raw_imaging_end_datetime, ' ') - 1), instr(raw_imaging_end_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_end_datetime, instr(raw_imaging_end_datetime, ' ') + 1), 1, instr(substr(raw_imaging_end_datetime, instr(raw_imaging_end_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_imaging_end_datetime, instr(raw_imaging_end_datetime, ' ') + 1), instr(substr(raw_imaging_end_datetime, instr(raw_imaging_end_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_img_end,

        -- 8. Parse pharmacy_start_datetime
        CASE 
            WHEN raw_pharmacy_start_datetime IS NULL THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), instr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), '/') + instr(substr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), instr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), instr(raw_pharmacy_start_datetime, '/') + 1, instr(substr(substr(raw_pharmacy_start_datetime, 1, instr(raw_pharmacy_start_datetime, ' ') - 1), instr(raw_pharmacy_start_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_start_datetime, instr(raw_pharmacy_start_datetime, ' ') + 1), 1, instr(substr(raw_pharmacy_start_datetime, instr(raw_pharmacy_start_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_start_datetime, instr(raw_pharmacy_start_datetime, ' ') + 1), instr(substr(raw_pharmacy_start_datetime, instr(raw_pharmacy_start_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_pharm_start,

        -- 9. Parse pharmacy_end_datetime
        CASE 
            WHEN raw_pharmacy_end_datetime IS NULL THEN NULL
            ELSE printf('%04d-%02d-%02d %02d:%02d:00',
                CAST(substr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), instr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), '/') + instr(substr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), instr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), '/') + 1), '/') + 1) AS INTEGER),
                CAST(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), instr(raw_pharmacy_end_datetime, '/') + 1, instr(substr(substr(raw_pharmacy_end_datetime, 1, instr(raw_pharmacy_end_datetime, ' ') - 1), instr(raw_pharmacy_end_datetime, '/') + 1), '/') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_end_datetime, instr(raw_pharmacy_end_datetime, ' ') + 1), 1, instr(substr(raw_pharmacy_end_datetime, instr(raw_pharmacy_end_datetime, ' ') + 1), ':') - 1) AS INTEGER),
                CAST(substr(substr(raw_pharmacy_end_datetime, instr(raw_pharmacy_end_datetime, ' ') + 1), instr(substr(raw_pharmacy_end_datetime, instr(raw_pharmacy_end_datetime, ' ') + 1), ':') + 1) AS INTEGER)
            )
        END AS clean_pharm_end

    FROM stg_hospital_opd
)
SELECT
    record_no,
    patient_id,
    appointment_id,
    prescription_doctor_id,
    prescription_doctor_name,
    prescription_order_id,
    lab_id,
    lab_name,
    imaging_request_id,
    imaging_result_id,
    imaging_name,
    pharmacy_sale_line_id,
    medicine_name,
    flow_code,
    flow_name,

    -- Lineage: Original Raw Timestamps
    raw_appointment_start_datetime,
    raw_prescription_start_datetime,
    raw_prescription_end_datetime,
    raw_lab_start_datetime,
    raw_lab_end_datetime,
    raw_imaging_start_datetime,
    raw_imaging_end_datetime,
    raw_pharmacy_start_datetime,
    raw_pharmacy_end_datetime,

    -- Cleaned ISO Timestamps
    clean_appt_start AS appointment_start_datetime,
    clean_rx_start AS prescription_start_datetime,
    clean_rx_end AS prescription_end_datetime,
    clean_lab_start AS lab_start_datetime,
    clean_lab_end AS lab_end_datetime,
    clean_img_start AS imaging_start_datetime,
    clean_img_end AS imaging_end_datetime,
    clean_pharm_start AS pharmacy_start_datetime,
    clean_pharm_end AS pharmacy_end_datetime,

    -- Requirement C: Proposed Correction Flag & Reason for record_no = 28837
    CASE WHEN record_no = 28837 THEN 1 ELSE 0 END AS is_corrected_datetime,
    CASE 
        WHEN record_no = 28837 THEN 'Prescription start year 2026 corrected to 2025 based on arrival 2025-07-23 16:13 and prescription end 2025-07-23 16:50'
        ELSE NULL 
    END AS datetime_correction_reason,

    -- Initial Wait Time (Arrival to Consultation Start)
    CASE 
        WHEN clean_rx_start IS NULL THEN NULL
        ELSE ROUND((julianday(clean_rx_start) - julianday(clean_appt_start)) * 1440.0, 2)
    END AS wait_time_minutes,

    -- Requirement D: Initial Wait Time Validity Flag & Status (0 for the 5 negative wait rows)
    CASE 
        WHEN clean_rx_start IS NULL THEN NULL
        WHEN ROUND((julianday(clean_rx_start) - julianday(clean_appt_start)) * 1440.0, 2) >= 0 THEN 1
        ELSE 0
    END AS is_valid_wait_time,
    CASE 
        WHEN clean_rx_start IS NULL THEN 'MISSING_CONSULTATION_START'
        WHEN ROUND((julianday(clean_rx_start) - julianday(clean_appt_start)) * 1440.0, 2) >= 0 THEN 'VALID'
        ELSE 'INVALID_NEGATIVE_WAIT'
    END AS wait_time_status,

    -- Consultation Duration (Consultation Start to End)
    CASE 
        WHEN clean_rx_start IS NULL OR clean_rx_end IS NULL THEN NULL
        ELSE ROUND((julianday(clean_rx_end) - julianday(clean_rx_start)) * 1440.0, 2)
    END AS consultation_duration_minutes,

    -- Requirement D: Consultation Duration Validity Flag & Status (0 for the 52 negative duration rows)
    CASE 
        WHEN clean_rx_start IS NULL OR clean_rx_end IS NULL THEN NULL
        WHEN ROUND((julianday(clean_rx_end) - julianday(clean_rx_start)) * 1440.0, 2) >= 0 THEN 1
        ELSE 0
    END AS is_valid_consult_duration,
    CASE 
        WHEN clean_rx_start IS NULL THEN 'MISSING_CONSULTATION_START'
        WHEN clean_rx_end IS NULL THEN 'MISSING_CONSULTATION_END'
        WHEN ROUND((julianday(clean_rx_end) - julianday(clean_rx_start)) * 1440.0, 2) >= 0 THEN 'VALID'
        ELSE 'INVALID_NEGATIVE_DURATION'
    END AS consult_duration_status,

    -- Requirement E: Lab End Reconstruction Status
    CASE 
        WHEN lab_id IS NULL THEN 'STRUCTURAL_NULL'
        WHEN raw_lab_end_datetime NOT LIKE '%/%' THEN 'TRUNCATED_TIME_ONLY'
        ELSE 'ORIGINAL_STANDARD'
    END AS lab_end_reconstruction_status,

    -- Lab Turnaround Time (populated only for the 13,327 standard timestamps)
    CASE 
        WHEN clean_lab_start IS NULL OR clean_lab_end IS NULL THEN NULL
        ELSE ROUND((julianday(clean_lab_end) - julianday(clean_lab_start)) * 1440.0, 2)
    END AS lab_turnaround_time_minutes,

    -- Imaging Status & Duration
    CASE 
        WHEN imaging_request_id IS NULL THEN 'STRUCTURAL_NULL'
        WHEN clean_img_end IS NULL THEN 'MISSING_IMAGING_END'
        ELSE 'VALID'
    END AS imaging_status,
    CASE 
        WHEN clean_img_start IS NULL OR clean_img_end IS NULL THEN NULL
        ELSE ROUND((julianday(clean_img_end) - julianday(clean_img_start)) * 1440.0, 2)
    END AS imaging_duration_minutes,

    -- Pharmacy Status & Duration
    CASE 
        WHEN pharmacy_sale_line_id IS NULL THEN 'STRUCTURAL_NULL'
        ELSE 'VALID'
    END AS pharmacy_status,
    CASE 
        WHEN clean_pharm_start IS NULL OR clean_pharm_end IS NULL THEN NULL
        ELSE ROUND((julianday(clean_pharm_end) - julianday(clean_pharm_start)) * 1440.0, 2)
    END AS pharmacy_duration_minutes,

    -- Temporal Analytical Dimensions
    strftime('%Y-%m-%d', clean_appt_start) AS appointment_date,
    CAST(strftime('%Y', clean_appt_start) AS INTEGER) AS arrival_year,
    strftime('%Y-%m', clean_appt_start) AS arrival_month,
    CAST(strftime('%H', clean_appt_start) AS INTEGER) AS arrival_hour,
    CASE strftime('%w', clean_appt_start)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS arrival_day_of_week

FROM parsed_base;

-- Indexing for high-performance joins and aggregations
CREATE UNIQUE INDEX idx_fct_events_record_no ON fct_clinical_events(record_no);
CREATE INDEX idx_fct_events_appt_id ON fct_clinical_events(appointment_id);
CREATE INDEX idx_fct_events_pat_id ON fct_clinical_events(patient_id);
CREATE INDEX idx_fct_events_doctor_id ON fct_clinical_events(prescription_doctor_id);
CREATE INDEX idx_fct_events_date ON fct_clinical_events(appointment_date);
