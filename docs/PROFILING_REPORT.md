# PULSE — Exploratory Data Profiling & Structural Inspection Report

**Project:** PULSE — Hospital Patient Flow & Wait-Time Intelligence  
**Phase:** Phase 3 — Exploratory Data Profiling & Structural Inspection  
**Source Dataset:** [`data/raw/HospitalOPD-noname.csv`](file:///c:/Users/DELL/PULSE/data/raw/HospitalOPD-noname.csv)  
**Tools Employed:** Microsoft Excel 365 / RFC-4180 .NET Data Inspection Engine  
**Status:** **Completed & Audited**

---

## 🧭 Executive Summary

During Phase 3, an in-depth structural inspection of the raw `HospitalOPD` dataset was executed against all 62,422 data rows. This investigation confirmed data provenance, mapped entity relationships, uncovered specific source-system timestamp anomalies, and resolved the discrepancy noted in the Phase 2 initialization report.

### Key Headline Findings:
1. **Critical Reconciliation Resolved:** The apparent discrepancy in `flow_code` (reported as having 163 nulls in naive profiling) is **100% resolved**. Naive comma-splitting was broken by 165 rows containing quoted commas in diagnostic test names (e.g., `"Electrolytes (Na,K+,Cl)"`). With RFC-4180 compliant CSV parsing, **`flow_code` and `flow_name` have exactly 0 nulls**, and the seven flow categories sum to **62,422 rows (100.00%)**.
2. **Zero Primary Key Duplicates:** `record_no` is perfectly sequential and unique (1 to 62,422) with **0 duplicates**.
3. **Multi-Record Appointment Grain:** The dataset contains **49,912 unique outpatient visits** across **39,442 unique patients**. 4,822 visits span multiple records (up to 5+ rows) due to multiple diagnostic tests or prescriptions ordered during a single encounter.
4. **Structural vs. Defective Nulls:** Null values in diagnostic and pharmacy columns are **structural**, governed strictly by the patient's clinical workflow. Patients in Pathway 1 (`Appointment → Prescription`) naturally have null laboratory, imaging, and pharmacy fields.
5. **Timestamp Quality & Anomalies:**
   - **5 records** display negative initial wait times (`prescription_start < appointment_start`).
   - **52 records** display negative consultation durations (`prescription_end < prescription_start`), predominantly driven by 24-hour off-by-one-day date logging errors.
   - **1 record** (`record_no = 28837`) contains a future typographical error (`RxStart = 2026-07-23` while appointment occurred in `2025-07-23`).
   - **4,702 lab records** have `lab_end_datetime` exported in truncated `mm:ss.0` format (stripping the date and hour).

---

## 🔍 Critical Reconciliation: The Flow Code Discrepancy Resolved

In the preliminary Phase 2 profile, naive string splitting (`$line.Split(',')`) reported 62,259 populated rows and 163 nulls for `flow_code`, while the categorical frequency table summed to 62,422.

### Root Cause Analysis:
- The raw CSV strictly adheres to RFC-4180 standards: fields containing commas are enclosed in double quotes.
- Specifically, laboratory test names such as `"Electrolytes (Na,K+,Cl)"` contain **two commas inside quotes**.
- A naive comma split splits this single field into three separate tokens, shifting all subsequent columns (timestamps, flow codes, flow names) 2 positions to the right.
- There are **165 rows** in `HospitalOPD-noname.csv` with quoted text containing commas.

### Verified Ground Truth (RFC-4180 Compliant Parsing):
When parsed using quote-aware parsing, the fields align with 100% consistency:

| Flow Code | Flow Name | Verified Record Count | % of Total |
| :---: | :--- | :---: | :---: |
| **1** | `Appointment → Prescription` | 40,164 | 64.34% |
| **2** | `Appointment → Prescription → Lab` | 16,434 | 26.33% |
| **3** | `Appointment → Prescription → Imaging` | 3,947 | 6.32% |
| **5** | `Appointment → Prescription → Lab + Imaging` | 1,575 | 2.52% |
| **4** | `Appointment → Prescription → Pharmacy` | 281 | 0.45% |
| **6** | `Appointment → Prescription → Lab + Pharmacy` | 20 | 0.03% |
| **7** | `Appointment → Prescription → Imaging + Pharmacy` | 1 | <0.01% |
| **Null** | *Missing / Uncategorized* | **0** | **0.00%** |
| **Total** | | **62,422** | **100.00%** |

---

## 📊 Comprehensive 25-Column Profile

| Index | Column Header | Inferred Data Type | Populated Count | Null Count | Null % | Distinct Count | Operational Description |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **0** | `record_no` | Integer | 62,422 | 0 | 0.00% | 62,422 | Unique event row key (1 to 62,422) |
| **1** | `patient_id` | Integer | 62,422 | 0 | 0.00% | 39,442 | Unique patient identifier |
| **2** | `[unnamed_col_2]` | Blank Text | 0 | 62,422 | 100.00% | 0 | Stripped patient name (PII anonymization) |
| **3** | `appointment_id` | Integer | 62,422 | 0 | 0.00% | 49,912 | Outpatient visit identifier |
| **4** | `appointment_start_datetime` | Datetime (`en-US`) | 62,422 | 0 | 0.00% | 39,121 | Patient arrival / registration timestamp |
| **5** | `prescription_doctor_id` | Integer | 62,422 | 0 | 0.00% | 98 | Attending physician numerical ID |
| **6** | `prescription_doctor_name` | Varchar(100) | 62,422 | 0 | 0.00% | 98 | Attending physician name |
| **7** | `prescription_order_id` | Integer | 62,422 | 0 | 0.00% | 50,568 | Clinical prescription order ID |
| **8** | `prescription_start_datetime` | Datetime (`en-US`) | 62,410 | 12 | 0.02% | 41,508 | Doctor consultation start timestamp |
| **9** | `prescription_end_datetime` | Datetime (`en-US`) | 62,421 | 1 | <0.01% | 41,529 | Doctor consultation end timestamp |
| **10** | `lab_id` | Integer | 18,029 | 44,393 | 71.12% | 17,083 | Laboratory requisition identifier |
| **11** | `lab_name` | Varchar(150) | 18,029 | 44,393 | 71.12% | 119 | Laboratory test name |
| **12** | `lab_start_datetime` | Datetime (`en-US`) | 18,029 | 44,393 | 71.12% | 14,068 | Laboratory sample processing start |
| **13** | `lab_end_datetime` | Datetime / Mixed | 18,029 | 44,393 | 71.12% | 13,852 | Laboratory result completion timestamp |
| **14** | `imaging_request_id` | Integer | 5,523 | 56,899 | 91.15% | 5,360 | Radiological exam order ID |
| **15** | `imaging_result_id` | Integer | 5,523 | 56,899 | 91.15% | 5,360 | Radiological result report ID |
| **16** | `imaging_name` | Varchar(150) | 5,523 | 56,899 | 91.15% | 37 | Imaging modality (Ultrasound, X-ray, etc.) |
| **17** | `imaging_start_datetime` | Datetime (`en-US`) | 5,523 | 56,899 | 91.15% | 5,302 | Imaging examination start |
| **18** | `imaging_end_datetime` | Datetime (`en-US`) | 5,513 | 56,909 | 91.17% | 5,296 | Imaging examination completion |
| **19** | `pharmacy_sale_line_id` | Integer | 302 | 62,120 | 99.52% | 262 | Pharmacy dispensing sale line ID |
| **20** | `medicine_name` | Varchar(255) | 302 | 62,120 | 99.52% | 154 | Prescribed medicine dispensed |
| **21** | `pharmacy_start_datetime` | Datetime (`en-US`) | 302 | 62,120 | 99.52% | 296 | Pharmacy queue presentation timestamp |
| **22** | `pharmacy_end_datetime` | Datetime (`en-US`) | 302 | 62,120 | 99.52% | 296 | Medication dispensing completion |
| **23** | `flow_code` | Integer | 62,422 | 0 | 0.00% | 7 | Clinical workflow code (1 to 7) |
| **24** | `flow_name` | Varchar(100) | 62,422 | 0 | 0.00% | 7 | Clinical workflow description |

---

## 🔗 Entity Relationships & Granularity Analysis

### 1. Patient Frequency Distribution
- **Total Unique Patients:** 39,442
- **Patients with 1 visit:** 32,322 (81.95%)
- **Patients with 2 visits:** 5,067 (12.85%)
- **Patients with 3 visits:** 1,317 (3.34%)
- **Patients with 4+ visits:** 736 (1.87%)

### 2. Appointment Visit Granularity
- **Total Unique Appointments:** 49,912
- **Appointments with 1 event row:** 45,090 (90.34%)
- **Appointments with 2 event rows:** 2,175 (4.36%)
- **Appointments with 3 event rows:** 937 (1.88%)
- **Appointments with 4 event rows:** 624 (1.25%)
- **Appointments with 5+ event rows:** 1,086 (2.18%)

### 3. Multi-Service Encounters
- **4,107 appointments** generated >1 laboratory test order (e.g., patient received CBC, Electrolytes, and LFTs in a single visit).
- **640 appointments** generated >1 prescription order.
- **98 appointments** generated >1 imaging examination.
- **79 appointments** generated >1 pharmacy sale line.

> [!WARNING] Double-Counting Risk
> Because 4,822 visits have multiple rows, **naively averaging wait times or patient counts across the raw CSV will over-weight complex patients** who received multiple diagnostic tests.  
> **Architecture Mandate:** In SQL and Excel, all arrival, registration, and initial wait-time KPIs must be aggregated at the **`appointment_id` grain** before computing summary statistics.

---

## 🕒 Timestamp Auditing & Operational Anomalies

All 9 timestamp fields were evaluated against the US format (`M/d/yyyy H:mm`).

### 1. Timestamp Observed Ranges

| Milestone | Column Name | Minimum Datetime | Maximum Datetime | Standard Format Rows |
| :--- | :--- | :---: | :---: | :---: |
| **Arrival** | `appointment_start_datetime` | 2024-04-25 11:12 | 2026-04-07 08:03 | 62,422 (100.00%) |
| **Consultation Start** | `prescription_start_datetime` | 2024-04-26 05:15 | 2026-07-23 16:43* | 62,410 (99.98%) |
| **Consultation End** | `prescription_end_datetime` | 2024-04-26 05:21 | 2026-04-07 09:01 | 62,421 (>99.99%) |
| **Lab Start** | `lab_start_datetime` | 2025-03-25 07:39 | 2026-04-07 07:06 | 18,029 (100.00%) |
| **Lab End** | `lab_end_datetime` | 2025-03-26 07:20 | 2026-04-07 09:03 | 13,327 (73.92%) |
| **Imaging Start** | `imaging_start_datetime` | 2025-03-25 06:27 | 2026-04-07 06:40 | 5,523 (100.00%) |
| **Imaging End** | `imaging_end_datetime` | 2025-03-25 06:29 | 2026-04-07 06:42 | 5,513 (99.82%) |
| **Pharmacy Start** | `pharmacy_start_datetime` | 2025-06-06 15:42 | 2026-03-27 13:49 | 302 (100.00%) |
| **Pharmacy End** | `pharmacy_end_datetime` | 2025-06-06 15:42 | 2026-03-27 13:50 | 302 (100.00%) |

*\*Note: Maximum date in `prescription_start_datetime` represents a known typographical error (`record_no = 28837`).*

### 2. Detailed Anomaly Inventory

#### A. Future Year Typographical Error (`record_no = 28837`)
- **Record:** `record_no = 28837`, `appointment_id = 276617`
- **Data Values:** `appointment_start = 7/23/2025 16:13`, `prescription_start = 7/23/2026 16:43`, `prescription_end = 7/23/2025 16:50`
- **Diagnosis:** A clerical entry error where the physician/staff entered year `2026` instead of `2025`.

#### B. Negative Wait Times (`prescription_start < appointment_start`)
- **Count:** Exactly **5 records** (0.008% of dataset).
- **Examples:**
  - `record_no = 21504`: Appt 14:36, RxStart 14:30 (-6 min)
  - `record_no = 22917`: Appt 8/13 06:48, RxStart 8/11 07:36 (-2 days)
  - `record_no = 30296`: Appt 9/15 04:16, RxStart 9/14 19:00 (-9.2 hours)
  - `record_no = 34795`: Appt 9/12 11:16, RxStart 9/08 12:12 (-4 days)
  - `record_no = 35225`: Appt 9/14 18:54, RxStart 9/13 18:55 (-24 hours)

#### C. Negative Consultation Durations (`prescription_end < prescription_start`)
- **Count:** Exactly **52 records** (0.08% of dataset).
- **Pattern:** 47 of the 52 records have a negative duration of approximately `-1420 to -1440 minutes` (exactly 24 hours). This indicates the system clock or entry system recorded `prescription_start` with the subsequent day's date while `prescription_end` maintained the true visit date.

#### D. Truncated Lab End Formats (`mm:ss.0`)
- **Count:** Exactly **4,702 records** out of 18,029 lab records.
- **Pattern:** The timestamp was exported without date or hour (e.g., `'53:45.0'`, `'46:40.0'`). Cross-referencing against `lab_start_datetime` reveals that `'53:45.0'` represents the minute and second of completion within the start hour (e.g., Start `5:50` ➔ End `5:53:45`).

#### E. Missing Start/End Datetimes
- **Prescription:** 12 records have `prescription_end` but missing `prescription_start`; 1 record has `prescription_start` without `prescription_end`.
- **Imaging:** 10 records have `imaging_start` without `imaging_end`.

---

## 🧩 Clinical Workflow & Service Presence Cross-Tabulation

To verify whether null values in diagnostic and pharmacy fields represent missing data or clinical pathway definitions, an empirical cross-tabulation was performed:

| Flow Code | Pathway Description | Total Records | Prescription Populated | Lab Populated | Imaging Populated | Pharmacy Populated |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| **1** | `Appointment → Prescription` | 40,164 | 40,164 (100%) | 0 (0%) | 0 (0%) | 0 (0%) |
| **2** | `Appointment → Prescription → Lab` | 16,434 | 16,434 (100%) | 16,434 (100%) | 0 (0%) | 0 (0%) |
| **3** | `Appointment → Prescription → Imaging` | 3,947 | 3,947 (100%) | 0 (0%) | 3,947 (100%) | 0 (0%) |
| **5** | `Appointment → Prescription → Lab + Imaging` | 1,575 | 1,575 (100%) | 1,575 (100%) | 1,575 (100%) | 0 (0%) |
| **4** | `Appointment → Prescription → Pharmacy` | 281 | 281 (100%) | 0 (0%) | 0 (0%) | 281 (100%) |
| **6** | `Appointment → Prescription → Lab + Pharmacy` | 20 | 20 (100%) | 20 (100%) | 0 (0%) | 20 (100%) |
| **7** | `Appointment → Prescription → Imaging + Pharmacy` | 1 | 1 (100%) | 0 (0%) | 1 (100%) | 1 (100%) |
| **Total** | | **62,422** | **62,422** | **18,029** | **5,523** | **302** |

> [!NOTE] Definitive Conclusion on Null Values
> Null values in diagnostic and pharmacy columns are **100% structurally valid**. They reflect non-utilization of clinical services for that specific patient journey variant, rather than data collection failures.

---

## 🛠️ Data Cleaning Recommendations for Phase 4 (SQL)

Based on this profiling analysis, the following data-cleansing rules are recommended for implementation in Phase 4:

1. **Omit Column 2:** Drop the 100% empty anonymized column index 2.
2. **Correct Typographical Year in `record_no = 28837`:** Adjust `prescription_start_datetime` from `2026-07-23` to `2025-07-23` to align with appointment and completion dates.
3. **Handle Negative Wait Times (5 rows):** Flag the 5 records with negative wait times (`RxStart < ApptStart`). For visit-level wait-time calculations, exclude negative latencies or set to null with an audit flag.
4. **Handle Negative Consultation Durations (52 rows):** Flag consultation encounters where end precedes start. For duration metrics, exclude anomalous encounters from physician consultation TAT averages.
5. **Reconstruct Truncated Lab End Timestamps (4,702 rows):** In SQL, parse the `mm:ss.0` string and reconstruct the full datetime using the date and hour from `lab_start_datetime`.
6. **Establish Multi-Grain Data Models:**
   - **Table 1: `fct_appointment_visits`** (Grain: `appointment_id`, 49,912 rows) for overall arrival, queue wait times, and department volume.
   - **Table 2: `fct_clinical_events`** (Grain: `record_no`, 62,422 rows) for diagnostic order volume, test turnaround times, and service utilization.
   - **Dimension Tables:** `dim_doctor` (98 physicians), `dim_patient` (39,442 patients), `dim_workflow` (7 pathways), `dim_date`.
