# PULSE — Data Dictionary (Verified Schema)

> **STATUS:** **PHASE 3 VERIFIED SCHEMA & PROFILED**  
> **Source:** Mendeley Data — `HospitalOPD` (DOI: `10.17632/j2hd2239dr.1`)  
> **File:** `data/raw/HospitalOPD-noname.csv` (10,306,961 bytes, SHA-256 verified)  
> **Total Records:** 62,422 data rows | 25 columns | Grain: Service / Activity Event Log  
> **Observation Period:** April 25, 2024 to April 7, 2026

---

## 🗂️ Verified Dataset Columns

| Index | Field Name | Raw Header | Data Type | Populated Count | Null Count | Null % | Sample Value | Analytical Role |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **0** | `record_no` | `record_no` | INTEGER | 62,422 | 0 | 0.00% | `1` | Primary Key (unique row ID 1 to 62,422) |
| **1** | `patient_id` | `patient_id` | INTEGER | 62,422 | 0 | 0.00% | `10` | Patient Dimension (39,442 unique) |
| **2** | `[unnamed_col_2]` | `""` | TEXT (Blank) | 0 | 62,422 | 100.00% | `""` | Deprecated (PII stripped at source) |
| **3** | `appointment_id` | `appointment_id` | INTEGER | 62,422 | 0 | 0.00% | `445911` | Visit Grouping Key (49,912 unique) |
| **4** | `appointment_start_datetime` | `appointment_start_datetime` | DATETIME (`en-US`) | 62,422 | 0 | 0.00% | `3/30/2026 5:36` | Process Milestone: Arrival / Registration |
| **5** | `prescription_doctor_id` | `prescription_doctor_id` | INTEGER | 62,422 | 0 | 0.00% | `225` | Provider Dimension (98 unique IDs) |
| **6** | `prescription_doctor_name` | `prescription_doctor_name` | VARCHAR(100) | 62,422 | 0 | 0.00% | `Dr. Abrar Ahmed Bhatti` | Provider Dimension (98 unique Names) |
| **7** | `prescription_order_id` | `prescription_order_id` | INTEGER | 62,422 | 0 | 0.00% | `106357` | Service Event Key (50,568 unique) |
| **8** | `prescription_start_datetime` | `prescription_start_datetime` | DATETIME (`en-US`) | 62,410 | 12 | 0.02% | `3/30/2026 5:38` | Process Milestone: Consultation Start |
| **9** | `prescription_end_datetime` | `prescription_end_datetime` | DATETIME (`en-US`) | 62,421 | 1 | <0.01% | `3/30/2026 6:48` | Process Milestone: Consultation End |
| **10** | `lab_id` | `lab_id` | INTEGER | 18,029 | 44,393 | 71.12% | `127968` | Diagnostic Key (17,083 unique orders) |
| **11** | `lab_name` | `lab_name` | VARCHAR(150) | 18,029 | 44,393 | 71.12% | `Complete Blood Count` | Diagnostic Dimension (119 test types) |
| **12** | `lab_start_datetime` | `lab_start_datetime` | DATETIME (`en-US`) | 18,029 | 44,393 | 71.12% | `9/18/2025 14:30` | Process Milestone: Lab Processing Start |
| **13** | `lab_end_datetime` | `lab_end_datetime` | DATETIME / Mixed* | 18,029 | 44,393 | 71.12% | `9/18/2025 15:18` | Process Milestone: Lab Result Finalized |
| **14** | `imaging_request_id` | `imaging_request_id` | INTEGER | 5,523 | 56,899 | 91.15% | `69988` | Diagnostic Key (5,360 unique requests) |
| **15** | `imaging_result_id` | `imaging_result_id` | INTEGER | 5,523 | 56,899 | 91.15% | `54620` | Diagnostic Key (5,360 unique results) |
| **16** | `imaging_name` | `imaging_name` | VARCHAR(150) | 5,523 | 56,899 | 91.15% | `FWB` | Diagnostic Dimension (37 modalities) |
| **17** | `imaging_start_datetime` | `imaging_start_datetime` | DATETIME (`en-US`) | 5,523 | 56,899 | 91.15% | `2/17/2026 15:31` | Process Milestone: Imaging Exam Start |
| **18** | `imaging_end_datetime` | `imaging_end_datetime` | DATETIME (`en-US`) | 5,513 | 56,909 | 91.17% | `2/17/2026 15:36` | Process Milestone: Imaging Exam End |
| **19** | `pharmacy_sale_line_id` | `pharmacy_sale_line_id` | INTEGER | 302 | 62,120 | 99.52% | `681621` | Pharmacy Key (262 unique sales) |
| **20** | `medicine_name` | `medicine_name` | VARCHAR(255) | 302 | 62,120 | 99.52% | `Nospa Fort Tablet 30 s  MTH` | Pharmacy Dimension (154 medicines) |
| **21** | `pharmacy_start_datetime` | `pharmacy_start_datetime` | DATETIME (`en-US`) | 302 | 62,120 | 99.52% | `7/7/2025 9:17` | Process Milestone: Pharmacy Queue Start |
| **22** | `pharmacy_end_datetime` | `pharmacy_end_datetime` | DATETIME (`en-US`) | 302 | 62,120 | 99.52% | `7/7/2025 9:17` | Process Milestone: Dispensing Complete |
| **23** | `flow_code` | `flow_code` | INTEGER | 62,422 | 0 | 0.00% | `1` | Pathway Dimension (Workflow Code 1-7) |
| **24** | `flow_name` | `flow_name` | VARCHAR(100) | 62,422 | 0 | 0.00% | `Appointment → Prescription` | Pathway Dimension (Workflow Journey) |

*\*Note on `lab_end_datetime`: 13,327 records contain standard datetimes; 4,702 records contain truncated `mm:ss.0` timestamps to be reconstructed in Phase 4 cleaning.*

---

## 🔀 Patient Workflow Variants Distribution (Verified Ground Truth)

| Code | Flow Variant Description | Record Count | % of Dataset |
| :---: | :--- | :---: | :---: |
| **1** | `Appointment → Prescription` | 40,164 | 64.34% |
| **2** | `Appointment → Prescription → Lab` | 16,434 | 26.33% |
| **3** | `Appointment → Prescription → Imaging` | 3,947 | 6.32% |
| **5** | `Appointment → Prescription → Lab + Imaging` | 1,575 | 2.52% |
| **4** | `Appointment → Prescription → Pharmacy` | 281 | 0.45% |
| **6** | `Appointment → Prescription → Lab + Pharmacy` | 20 | 0.03% |
| **7** | `Appointment → Prescription → Imaging + Pharmacy` | 1 | <0.01% |
| **Total** | | **62,422** | **100.00%** |

---

## 🕒 Planned Derived Metrics (To Be Built in SQL Phase 4/5 & Excel Phase 6)

1. **Patient Initial Wait Time:** `prescription_start_datetime - appointment_start_datetime` (Elapsed time from arrival to doctor consultation; evaluated at `appointment_id` grain).
2. **Physician Consultation Duration:** `prescription_end_datetime - prescription_start_datetime` (Clinical encounter duration).
3. **Laboratory Turnaround Time (TAT):** `lab_end_datetime - lab_start_datetime` (Diagnostic processing turnaround).
4. **Imaging Turnaround Time (TAT):** `imaging_end_datetime - imaging_start_datetime` (Radiological investigation turnaround).
5. **Total Outpatient Turnaround Time:** `MAX(service_end_datetime) - MIN(appointment_start_datetime)` aggregated at `appointment_id` grain.
6. **Arrival Temporal Dimensions:** Hour of day (0-23), Day of week (Monday-Sunday), Year-Month for capacity and queue profiling.
