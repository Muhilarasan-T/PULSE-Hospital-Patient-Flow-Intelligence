# PULSE — Data Quality & Cleaning Specification

**Project:** PULSE — Hospital Patient Flow & Wait-Time Intelligence  
**Phase:** Phase 4 — Data Quality Auditing & Cleaning (SQL)  
**Engine:** SQLite 3.51.0 (64-bit) / ANSI SQL Compatible  
**Database:** [`data/processed/pulse.db`](file:///c:/Users/DELL/PULSE/data/processed/pulse.db)  
**Status:** **Executed, Reconciled & Audited**

---

## 🧭 Overview & Architecture

Phase 4 establishes a non-destructive, auditable SQL data cleansing pipeline. Rather than deleting anomalous records or imputing speculative values, all original raw fields are retained alongside standardized ISO-8601 timestamps, explicit validity flags, and audit status columns.

Two distinct fact models were designed and deployed:
1. **`fct_clinical_events`** (Grain: `record_no`, **62,422 rows**): Captures every individual clinical order, diagnostic procedure, and prescription event.
2. **`fct_appointment_visits`** (Grain: `appointment_id`, **49,912 rows**): Aggregates all events to the true patient encounter level to eliminate double-counting when measuring arrival flow, queue wait times, and department throughput.

---

## 📋 Comprehensive Cleaning Rules & Transformations

### Rule 1: Omission of Unnamed Source Column 2
- **Source Context:** Column index 2 in `data/raw/HospitalOPD-noname.csv` has a blank header `""` and 0 populated values across all 62,422 rows.
- **Transformation:** Dropped during staging (`stg_hospital_opd`).
- **Audit Verification:** Verified 100% empty; zero clinical information was lost.

---

### Rule 2: Validated Typographical Correction for `record_no = 28837`
- **Source Values:**
  - `appointment_start = 7/23/2025 16:13`
  - `raw_prescription_start = 7/23/2026 16:43` *(Clerical typo: year 2026)*
  - `prescription_end = 7/23/2025 16:50`
- **Surrounding Lineage:** Surrounding records (`record_no = 28836` to `28838`) and prescription order ID `16730` confirm the encounter took place on **July 23, 2025**.
- **Transformation:**
  - `raw_prescription_start_datetime`: Preserved exactly as `'7/23/2026 16:43'`.
  - `prescription_start_datetime`: Standardized to `'2025-07-23 16:43:00'`.
  - `is_corrected_datetime`: Set to `1` (0 for all other 62,421 rows).
  - `datetime_correction_reason`: `'Prescription start year 2026 corrected to 2025 based on arrival 2025-07-23 16:13 and prescription end 2025-07-23 16:50'`.
- **Result:** Wait time resolves to **30.0 minutes** (`16:43 - 16:13`), and consultation duration resolves to **7.0 minutes** (`16:50 - 16:43`).

---

### Rule 3: Non-Destructive Flagging of Negative Wait Times (5 records)
- **Source Values:** Exactly 5 records (0.008% of dataset) have `prescription_start < appointment_start` (e.g., patient was seen prior to front-desk registration being recorded).
- **Transformation:**
  - Records are **retained** in both `fct_clinical_events` and `fct_appointment_visits`.
  - `wait_time_minutes`: Calculated as actual elapsed minutes (negative values retained for transparency).
  - `is_valid_wait_time`: Set to `0` (`1` for valid, `NULL` for missing).
  - `wait_time_status`: Set to `'INVALID_NEGATIVE_WAIT'`.
- **Analytical Guardrail:** Downstream SQL queries and Excel DAX measures must filter `WHERE is_valid_wait_time = 1` when calculating hospital average/median wait times.

---

### Rule 4: Non-Destructive Flagging of Negative Consult Durations (51 records)
- **Source Values:** Exactly 51 records (excluding corrected record 28837) have `prescription_end < prescription_start`. 47 of these records reflect an off-by-one-day system logging discrepancy (~ -1430 minutes).
- **Transformation:**
  - Records are **retained** without deletion.
  - `consultation_duration_minutes`: Actual mathematical difference retained.
  - `is_valid_consult_duration`: Set to `0` (`1` for valid, `NULL` for missing).
  - `consult_duration_status`: Set to `'INVALID_NEGATIVE_DURATION'`.
- **Analytical Guardrail:** Filter `WHERE is_valid_consult_duration = 1` when calculating physician consultation turnaround times.

---

### Rule 5: Handling Truncated `mm:ss.0` Laboratory End Formats (4,702 records)
- **Source Values:** 4,702 records in `lab_end_datetime` were exported as `mm:ss.0` (minute:second.tenth), stripping date and hour components.
- **Transformation:**
  - `raw_lab_end_datetime`: Retains original raw string (e.g., `'53:45.0'`).
  - `lab_end_datetime`: Set to `NULL` (zero fabricated datetimes).
  - `lab_end_reconstruction_status`: Set to `'TRUNCATED_TIME_ONLY'`.
  - `lab_turnaround_time_minutes`: Set to `NULL`.
- **Analytical Guardrail:** Lab turnaround calculations are restricted to the **13,327 standard complete datetimes** (`lab_end_reconstruction_status = 'ORIGINAL_STANDARD'`), preventing artificial distortion of diagnostic turnaround times.

---

### Rule 6: Preservation of Structural Nulls
- **Source Values:** Nulls in `lab_*` (44,393 rows), `imaging_*` (56,899 rows), and `pharmacy_*` (62,120 rows).
- **Transformation:** Kept as SQL `NULL`s.
- **Audit Verification:** Cross-tabulation proved that 100% of these nulls correspond to patient pathways where that specific diagnostic or pharmacy service was not ordered (e.g., Flow 1 has 0 lab orders).

---

## 🗂️ Multi-Grain Model Architecture

```
[Raw Event Ingestion] data/raw/HospitalOPD-noname.csv (62,422 rows)
        │
        ▼
[Staging] stg_hospital_opd (62,422 rows, blank column 2 dropped)
        │
        ├───────────────────────────────────────────┐
        ▼                                           ▼
[fct_clinical_events]                      [fct_appointment_visits]
Grain: 1 row per record_no                 Grain: 1 row per appointment_id
Total Rows: 62,422                         Total Rows: 49,912
Use: Diagnostic turnaround, order counts   Use: Arrival curves, wait times, SLA
```

### Visit-Level Aggregation Rules (`fct_appointment_visits`):
1. **`appointment_start_datetime`**: `MIN(appointment_start_datetime)` (100% identical across all rows of an encounter).
2. **`first_prescription_start_datetime`**: Earliest valid doctor consultation start (`MIN(prescription_start_datetime)` where `is_valid_wait_time = 1`).
3. **`last_prescription_end_datetime`**: Final doctor consultation end timestamp (`MAX(prescription_end_datetime)`).
4. **`initial_wait_time_minutes`**: Elapsed time from arrival to first valid consultation start.
5. **`visit_flow_code`**: Deterministic classification based on actual service utilization (e.g., if appointment utilized Lab + Imaging, classified as Flow 5).
6. **`has_conflicting_timestamps`**: Flagged as `1` if any event record within the encounter contained negative wait or duration anomalies.

---

## 🧪 Reconciliation & Audit Results

Every reconciliation check was executed directly against [`data/processed/pulse.db`](file:///c:/Users/DELL/PULSE/data/processed/pulse.db) with 100% PASS:

| Check ID | Audit Test Description | Expected Value | Actual Value | Status |
| :---: | :--- | :---: | :---: | :---: |
| **1** | Row Count: Staging Table | 62,422 | 62,422 | **PASS** |
| **2** | Row Count: `fct_clinical_events` | 62,422 | 62,422 | **PASS** |
| **3** | Row Count: `fct_appointment_visits` | 49,912 | 49,912 | **PASS** |
| **4** | Duplicate Check: `record_no` in `fct_clinical_events` | 0 | 0 | **PASS** |
| **5** | Duplicate Check: `appointment_id` in `fct_appointment_visits` | 0 | 0 | **PASS** |
| **6** | Null Check: `patient_id` in `fct_clinical_events` | 0 | 0 | **PASS** |
| **7** | Null Check: `appointment_start_datetime` | 0 | 0 | **PASS** |
| **8** | Anomaly Audit: Negative Wait Times Flagged | 5 | 5 | **PASS** |
| **9** | Anomaly Audit: Negative Consult Durations Flagged | 51 | 51 | **PASS** |
| **10** | Correction Audit: `record_no = 28837` Typo Corrected | 1 | 1 | **PASS** |
| **11** | Lab Audit: Truncated `mm:ss.0` Timestamps Flagged | 4,702 | 4,702 | **PASS** |
| **12** | Lab Audit: Standard Full Datetimes Cleaned | 13,327 | 13,327 | **PASS** |
| **13** | Lab Audit: Structural Nulls Preserved | 44,393 | 44,393 | **PASS** |

---

## 📦 Exported Deliverables in `data/processed/`

- [`data/processed/pulse.db`](file:///c:/Users/DELL/PULSE/data/processed/pulse.db): 64.2 MB SQLite analytical database with indices.
- [`data/processed/fct_clinical_events.csv`](file:///c:/Users/DELL/PULSE/data/processed/fct_clinical_events.csv): 23.5 MB (62,422 event rows + header).
- [`data/processed/fct_appointment_visits.csv`](file:///c:/Users/DELL/PULSE/data/processed/fct_appointment_visits.csv): 11.0 MB (49,912 visit rows + header).
- [`data/processed/dim_doctors.csv`](file:///c:/Users/DELL/PULSE/data/processed/dim_doctors.csv): 6.0 KB (98 doctor profiles + metrics).
- [`data/processed/audit_reconciliation_summary.csv`](file:///c:/Users/DELL/PULSE/data/processed/audit_reconciliation_summary.csv): 1.8 KB (13 reconciliation test checks).
