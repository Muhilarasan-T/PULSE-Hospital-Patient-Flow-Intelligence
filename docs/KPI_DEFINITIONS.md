# PULSE — Operational KPI & Metric Definitions

**Project:** PULSE — Hospital Patient Flow & Wait-Time Intelligence  
**Phase:** Phase 5 — In-Depth SQL Analysis & Operational KPI Modeling  
**Target Database:** [`data/processed/pulse.db`](file:///c:/Users/DELL/PULSE/data/processed/pulse.db)  
**Deliverable Tools:** SQL (SQLite 3.51+) & Microsoft Excel 365  
**Status:** **Approved Specification**

---

## 🧭 KPI Framework Overview

In hospital operations and clinical governance, outpatient department (OPD) performance is evaluated across four core operational dimensions:
1. **Patient Access & Queue Latency:** How long patients wait before receiving care.
2. **Operational Demand & Capacity:** When volume surges occur and how load distributes over time.
3. **Clinical Throughput & Provider Utilization:** Physician consultation duration and encounter volume.
4. **Diagnostic & Ancillary Velocity:** Turnaround times for laboratory and radiological imaging services.

---

## 📋 Comprehensive Metric Specifications

### 1. Median Initial Wait Time (P50)
- **Business Question:** What is the typical elapsed waiting time for a patient from arrival/registration until their consultation begins?
- **Formula:** 50th percentile of `initial_wait_time_minutes` across valid visits.
- **Unit:** Minutes.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Numerator / Ordering:** Ascending order of `initial_wait_time_minutes`.
- **Denominator / Sample Size:** Valid appointments with valid timestamps (`WHERE is_valid_wait_time = 1`, N = 49,896).
- **Exclusions:**
  - 5 records with invalid negative wait times (`is_valid_wait_time = 0`).
  - 11 appointments with missing consultation start timestamps (`first_prescription_start_datetime IS NULL`).
- **Limitations:** Does not capture queue time prior to formal desk registration if a patient arrived earlier at the hospital entrance.

---

### 2. Average (Mean) Initial Wait Time
- **Business Question:** What is the mathematical mean waiting time across all outpatient appointments?
- **Formula:** `SUM(initial_wait_time_minutes) / COUNT(appointment_id)` where `is_valid_wait_time = 1`.
- **Unit:** Minutes.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Valid appointments (`WHERE is_valid_wait_time = 1`, N = 49,896).
- **Exclusions:** 16 non-valid/missing wait appointments.
- **Limitations:** Heavily distorted by long-tail outliers (extreme delay cases where encounters remained open). The Median is the primary executive metric for operational planning.

---

### 3. 90th-Percentile Initial Wait Time (P90)
- **Business Question:** What is the wait-time threshold within which 90% of outpatient encounters are seen by a physician (measuring tail-risk congestion)?
- **Formula:** 90th percentile rank using window function `ROW_NUMBER() OVER (ORDER BY initial_wait_time_minutes ASC)` evaluated at index `ROUND(total_count * 0.90)`.
- **Unit:** Minutes.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Valid appointments (`WHERE is_valid_wait_time = 1`, N = 49,896).
- **Exclusions:** 16 non-valid/missing wait appointments.
- **Limitations:** Sensitive to multi-hour batch sign-offs or documentation delays.

---

### 4. Wait-Time Distribution & Binning
- **Business Question:** How do patient wait times distribute across operational tolerance tiers?
- **Formula:** Categorical classification into:
  - `< 15 Minutes` (Immediate Service)
  - `15 – 30 Minutes` (Standard Service)
  - `30 – 60 Minutes` (Moderate Delay)
  - `60 – 120 Minutes` (Significant Delay)
  - `> 120 Minutes` (Severe Congestion)
- **Unit:** Count and Percentage of Visits.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Valid appointments (`WHERE is_valid_wait_time = 1`, N = 49,896).
- **Exclusions:** 16 non-valid/missing wait appointments.

---

### 5. Hourly Arrival Volume & Peak Load Window
- **Business Question:** Which operating hours experience the highest surge of patient arrivals?
- **Formula:** `COUNT(appointment_id)` grouped by `arrival_hour` (0 to 23).
- **Unit:** Appointment Encounters per Hour.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Total outpatient visits (N = 49,912).
- **Exclusions:** None (arrival timestamp is 100% populated across all 49,912 encounters).
- **Limitations:** Captures registration time in the EHR, which may lag physical queue entry during severe morning registration desk bottlenecks. Volume shares represent pooled shares of total dataset appointments across the observation window, not daily-normalized averages.

---

### 6. Day-of-Week Appointment Distribution & Load Variance
- **Business Question:** How does patient demand vary across the days of the week?
- **Formula:** `COUNT(appointment_id)` and average/median wait times grouped by `arrival_day_of_week`.
- **Unit:** Appointment Volume and Elapsed Minutes.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Total outpatient visits (N = 49,912).
- **Exclusions:** None for volume; 16 non-valid wait cases excluded from wait-time calculations.

---

### 7. Exploratory Wait-Time SLA Compliance Rates
- **Business Question:** What percentage of patients are seen within specific exploratory benchmark thresholds?
- **Formula:**
  - `% Seen Within 15 Min:` `COUNT(CASE WHEN initial_wait_time_minutes <= 15 THEN 1 END) / COUNT(*)`
  - `% Seen Within 30 Min:` `COUNT(CASE WHEN initial_wait_time_minutes <= 30 THEN 1 END) / COUNT(*)`
  - `% Seen Within 45 Min:` `COUNT(CASE WHEN initial_wait_time_minutes <= 45 THEN 1 END) / COUNT(*)`
  - `% Seen Within 60 Min:` `COUNT(CASE WHEN initial_wait_time_minutes <= 60 THEN 1 END) / COUNT(*)`
- **Unit:** Percentage (%).
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Valid appointments (`WHERE is_valid_wait_time = 1`, N = 49,896).
- **Exclusions:** 16 non-valid/missing wait appointments.
- **Important Note:** *These thresholds represent exploratory operational benchmarks for hospital management scenarios; they are not mandated hospital policies.*

---

### 8. Physician Consultation Duration & Workload Benchmarks
- **Business Question:** What is the appointment volume and average/median consultation duration for each attending physician?
- **Formula:**
  - `Total Appointments Handled:` `COUNT(DISTINCT appointment_id)` per `attending_doctor_id`.
  - `Mean Consultation Duration:` `AVG(consultation_duration_minutes)` where `is_valid_consult_duration = 1`.
  - `Median Consultation Duration:` 50th percentile of valid consultation durations for that doctor.
- **Unit:** Count of Visits and Elapsed Minutes.
- **Grain:** Physician Dimension (`dim_doctors`) / Encounter Level.
- **Source Table:** `fct_appointment_visits` / `dim_doctors`.
- **Denominator:** Valid doctor consultations (`WHERE is_valid_consult_duration = 1`, N = 49,850).
- **Exclusions:** 62 appointments with invalid negative consultation duration (51) or missing start/end (11).
- **Weighting Principle:** Defined strictly as **Visit-Weighted** when examining hospital patient experience, and **Doctor-Averaged** when benchmarking provider scheduling templates.
- **Limitations:** In 65.59% of encounters, consultation start and end timestamps share the exact same minute (`duration = 0`). This is an **inferred operational hypothesis** that doctors complete visits before signing digital orders in batch; it does not measure face-to-face clinical dialogue length. Independent EHR workflow audits would be required to verify definitively.

---

### 9. Clinical Pathway Mix & Service Utilization
- **Business Question:** What proportion of patients follow simple consult-only pathways versus multi-service diagnostic journeys?
- **Formula:**
  - `Pathway Share:` `COUNT(appointment_id) / 49912` grouped by `visit_flow_code`.
  - `Diagnostic Order Rates:`
    - Lab Utilization Rate: `SUM(has_lab) / 49912`
    - Imaging Utilization Rate: `SUM(has_imaging) / 49912`
    - Pharmacy Dispensing Rate: `SUM(has_pharmacy) / 49912`
- **Unit:** Percentage (%) and Integer Counts.
- **Grain:** Encounter / Visit Level (`fct_appointment_visits`).
- **Source Table:** `fct_appointment_visits`.
- **Denominator:** Total outpatient visits (N = 49,912).
- **Exclusions:** Zero.

---

### 10. Diagnostic Laboratory Turnaround Time (TAT)
- **Business Question:** How long does the laboratory require from test start to result availability?
- **Formula:** `(lab_end_datetime - lab_start_datetime)` in minutes.
- **Unit:** Minutes.
- **Grain:** Clinical Event Level (`fct_clinical_events`).
- **Source Table:** `fct_clinical_events`.
- **Denominator:** Standard complete lab records (`WHERE lab_end_reconstruction_status = 'ORIGINAL_STANDARD'`, N = 13,327).
- **Exclusions:**
  - 4,702 lab records with truncated `mm:ss.0` timestamps (hour ambiguity).
  - 44,393 structural null records (non-lab clinical visits).
- **Limitations:** Only measures processing turnaround for tests with uncorrupted date-time logging.

---

### 11. Diagnostic Imaging Examination Turnaround Time (TAT)
- **Business Question:** What is the duration of radiological imaging examinations?
- **Formula:** `(imaging_end_datetime - imaging_start_datetime)` in minutes.
- **Unit:** Minutes.
- **Grain:** Clinical Event Level (`fct_clinical_events`).
- **Source Table:** `fct_clinical_events`.
- **Denominator:** Valid imaging encounters (`WHERE imaging_status = 'VALID'`, N = 5,513).
- **Exclusions:**
  - 10 imaging encounters missing completion timestamps (`imaging_status = 'MISSING_IMAGING_END'`).
  - 56,899 structural null records (non-imaging visits).
- **Limitations:** Reflects exam capture duration; does not capture radiologist dictation/transcription report lag.

---

### 12. Data Quality Exception Rate
- **Business Question:** What proportion of clinical records exhibit logging anomalies that impact KPI calculations?
- **Formula:**
  - `Negative Wait Rate:` `5 / 49912 = 0.010%`
  - `Negative Consult Duration Rate:` `51 / 49912 = 0.102%`
  - `Truncated Lab End Rate:` `4702 / 18029 = 26.08%` of lab records
- **Unit:** Percentage (%).
- **Grain:** Multi-grain audit tracking.
- **Source Table:** `audit_reconciliation_summary`.
- **Analytical Governance:** All exceptions are retained with explicit audit flags, ensuring denominators are mathematically sound.
