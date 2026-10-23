# PULSE — Project Implementation Plan & Milestones

**Project:** PULSE — Hospital Patient Flow & Wait-Time Intelligence  
**Focus:** Healthcare Operations, Queue Optimization & Clinical Throughput Analytics  
**Primary Tools:** Microsoft Excel 365, SQL (No Python, No Power BI)  
**Current Milestone:** Phase 4 (Completed) ➔ Phase 5 (Awaiting User Approval)

---

## 🧭 Milestone Roadmap Overview

The PULSE project follows an industry-grade, structured analytics lifecycle designed to ensure data integrity, repeatable analytical modeling, and executive-ready reporting.

```
[Phase 1] Project Initialization (DONE)
   │
[Phase 2] Dataset Verification & Acquisition (DONE)
   │
[Phase 3] Exploratory Data Profiling & Structural Inspection (DONE)
   │
[Phase 4] Data Quality Auditing & Cleaning (SQL) (DONE)
   │
[Phase 5] SQL Analysis & Operational KPI Modeling (NEXT)
   │
[Phase 6] Excel Data Preparation & Transformation
   │
[Phase 7] Interactive Excel 365 Dashboard Build
   │
[Phase 8] Business Insights & Operational Recommendations
   │
[Phase 9] Quality Assurance & Cross-Tool Validation
   │
[Phase 10] GitHub Presentation & Portfolio Packaging
```

---

## 📋 Phased Milestone Breakdown

### Phase 1: Project Initialization & Repository Setup
- **Status:** **Completed**
- **Objective:** Establish directory structure, version control hygiene, project charter, and governance documentation.
- **Tasks:**
  - [x] Inspect workspace and verify working environment (`PULSE`).
  - [x] Create project directory layout (`data/raw`, `data/processed`, `sql`, `excel`, `docs`).
  - [x] Establish `.gitignore` to safeguard raw data, temp files, and Excel lock files.
  - [x] Create `README.md` outlining project scope, planned analyses, and tooling.
  - [x] Author `docs/PROJECT_PLAN.md`, `docs/DATA_DICTIONARY.md` (template), and `docs/DECISION_LOG.md`.
- **Deliverables:** Initialized repository with complete documentation framework and zero fabricated data.

---

### Phase 2: Dataset Verification & Acquisition
- **Status:** **Completed**
- **Objective:** Obtain and verify the target dataset (`HospitalOPD` from Mendeley Data) to establish real schema ground truth.
- **Tasks:**
  - [x] Review dataset source page: `https://data.mendeley.com/datasets/j2hd2239dr/1`.
  - [x] Verify license conditions, usage rights, and data confidentiality (`CC BY 4.0`).
  - [x] Download raw file(s) into `data/raw/HospitalOPD-noname.csv` via Mendeley public API.
  - [x] Verify file integrity (file size: 10,306,961 bytes, SHA-256 match, 62,423 lines, 25 columns).
  - [x] Log source details, checksum/size, and acquisition timestamp in `docs/DECISION_LOG.md`.
  - [x] Confirm Excel compatibility (62,422 rows fits within 1,048,576 row limit).
- **Deliverables:** Verified raw data file in `data/raw/HospitalOPD-noname.csv`, updated `docs/DECISION_LOG.md`, and updated `docs/DATA_DICTIONARY.md`.
- **Exit Gate:** Real columns and actual record counts confirmed; no synthetic columns introduced.

---

### Phase 3: Exploratory Data Profiling & Structural Inspection
- **Status:** **Completed**
- **Objective:** Understand the real schema, column semantics, data distributions, and operational healthcare context.
- **Tasks:**
  - [x] Read raw dataset headers and inspect genuine column definitions.
  - [x] Populate `docs/DATA_DICTIONARY.md` with true column names, types, descriptions, and verified counts.
  - [x] Reconcile flow_code categorical counts vs nulls (root caused to naive comma split vs RFC-4180 quotes).
  - [x] Profile categorical attributes (98 doctors, 119 lab tests, 37 imaging modalities, 154 medicines).
  - [x] Profile temporal attributes (arrival, consultation, lab, imaging, pharmacy timestamps).
  - [x] Identify relationship cardinality (49,912 appointments across 39,442 patients; 4,822 multi-row visits).
  - [x] Author comprehensive `docs/PROFILING_REPORT.md` documenting structural findings and anomalies.
- **Deliverables:** Fully populated `docs/DATA_DICTIONARY.md` and complete `docs/PROFILING_REPORT.md`.
- **Exit Gate:** Every dataset column documented with verified counts, anomalies cataloged, and multi-grain risks identified.

---

### Phase 4: Data Quality Auditing & Cleaning
- **Status:** **Completed**
- **Objective:** Identify and remediate data hygiene issues using robust SQL queries.
- **Tasks:**
  - [x] Ingest raw CSV into staging model (`stg_hospital_opd`) and drop empty anonymized column index 2.
  - [x] Standardize all datetime strings from US format (`M/d/yyyy H:mm`) into ISO-8601 (`YYYY-MM-DD HH:MM:SS`).
  - [x] Implement validated clerical year typo correction for `record_no = 28837` with audit trail and original preserved.
  - [x] Non-destructively flag 5 negative wait times and 51 negative consultation durations with explicit audit flags.
  - [x] Standardize 13,327 complete lab end datetimes and flag 4,702 truncated `mm:ss.0` timestamps as `TRUNCATED_TIME_ONLY`.
  - [x] Build multi-grain fact architecture: `fct_clinical_events` (62,422 rows) and `fct_appointment_visits` (49,912 rows).
  - [x] Create automated SQL reconciliation test suite (`sql/04_data_quality_reconciliation.sql`) with 13 checks passing 100%.
  - [x] Export cleaned datasets to `data/processed/` (`.db` and `.csv` formats).
  - [x] Author detailed `docs/CLEANING_RULES.md` and update `docs/DECISION_LOG.md`.
- **Deliverables:** Modular SQL suite (`sql/`), cleaned persistent SQLite database (`pulse.db`), exported CSV models in `data/processed/`, and `docs/CLEANING_RULES.md`.
- **Exit Gate:** 100% reconciliation audit pass; zero records dropped; multi-grain models deployed.

---

### Phase 5: SQL Analysis & Operational KPI Modeling
- **Status:** **Completed**
- **Objective:** Perform deep SQL querying to calculate hospital operational KPIs, throughput rates, and queue bottlenecks.
- **Tasks:**
  - [x] Establish standardized metric framework and governance rules in `docs/KPI_DEFINITIONS.md`.
  - [x] Develop modular analytical SQL scripts utilizing CTEs, non-parametric percentile window functions, and multi-grain aggregations:
    - `sql/05_wait_time_analysis.sql`: Percentiles ($P_{25}, P_{50}, P_{75}, P_{90}, P_{95}$), 5-tier binning, hourly/daily variation, sensitivity audit.
    - `sql/06_operational_volume_analysis.sql`: 24-hour surge analysis, twin peak discovery, 7-day variation, 24-month trends, patient recurrence cohorts.
    - `sql/07_doctor_performance_analysis.sql`: 98 provider roster benchmarks, workload concentration tiers (top 21 handle 71.7%), consult durations.
    - `sql/08_pathway_and_service_analysis.sql`: 7 deterministic clinical pathways, diagnostic utilization mix, top 15 lab tests, top 10 imaging modalities, multi-grain inflation audit.
    - `sql/09_turnaround_and_sla_analysis.sql`: Laboratory TAT (median 125 min), imaging duration (median 3 min), 6 exploratory SLA scenarios, hourly SLA risk, journey boundary audit.
    - `sql/10_kpi_quality_validation.sql`: Automated 9-test reconciliation audit verifying 100% mathematical consistency.
    - `sql/run_all_analyses.sql`: Master runner automating end-to-end analytical pipeline and CSV table exports.
  - [x] Materialize 24 analytical result tables in `data/processed/pulse.db` and export clean CSVs into `data/processed/analysis/`.
  - [x] Author comprehensive `docs/SQL_ANALYSIS_REPORT.md` synthesized for executive leadership.
  - [x] Author detailed technical audit in `docs/archive/PHASE5_VALIDATION.md`.
- **Deliverables:** Modular SQL suite (`sql/05`–`10`, `run_all_analyses.sql`), 24 materialized analysis tables in `pulse.db`, 24 clean CSV export tables in `data/processed/analysis/`, `docs/KPI_DEFINITIONS.md`, `docs/SQL_ANALYSIS_REPORT.md`, and `docs/archive/PHASE5_VALIDATION.md`.
- **Exit Gate:** 100% test passage across 9 reconciliation checks; 24 export tables verified; Phase 5 validation report complete.

---

### Phase 6: Excel Data Preparation & Transformation
- **Status:** **Completed**
- **Objective:** Import cleaned data into Microsoft Excel 365, structure analytical tables, and configure dimensional modeling.
- **Tasks:**
  - [x] Ingest processed data into Excel 365 using Power Query (M-code authored and validated in `docs/EXCEL_POWER_QUERY_GUIDE.md`).
  - [x] Create conformed calendar dimension `dim_date_calendar` (1,096 days covering 2024-01-01 to 2026-12-31) via `sql/11_create_dim_date_calendar.sql` and export to `data/processed/dim_date_calendar.csv`.
  - [x] Build Hybrid Galaxy Schema relationship model in Excel Data Model / Power Pivot (2 core fact tables, 2 conformed dimensions, 0 orphaned keys verified).
  - [x] Formulate DAX measure catalog for encounter volumes, wait-time percentiles, exploratory SLA thresholds (30m, 60m), doctor benchmarks, and diagnostic TATs in `docs/EXCEL_DASHBOARD_SPEC.md`.
  - [x] Validate model integrity, row counts, relationship keys, and denominator alignment in `docs/archive/PHASE6_VALIDATION.md`.
- **Deliverables:** `sql/11_create_dim_date_calendar.sql`, `data/processed/dim_date_calendar.csv`, `docs/EXCEL_POWER_QUERY_GUIDE.md`, `docs/EXCEL_DASHBOARD_SPEC.md`, `docs/archive/PHASE5_FINAL_AUDIT.md`, and `docs/archive/PHASE6_VALIDATION.md`.
- **Exit Gate:** 100% pass across relationship integrity tests; 0 orphan keys; complete Power Query and DAX blueprint approved.

---

### Phase 7: Interactive Excel 365 Dashboard Build & Audit Upgrade (v2)
- **Status:** **Completed & Audited (v2 Production Ready)**
- **Objective:** Construct and audit an executive-level, interactive healthcare operations dashboard adhering to professional data visualization standards.
- **Tasks:**
  - [x] Design high-impact layout across six dedicated worksheets (`Executive_Summary`, `Wait_Time_Dynamics`, `Surges_Capacity`, `Doctor_Workload`, `Diagnostic_Turnaround`, `Data_Model_Audit`).
  - [x] Build top-line KPI summary cards with prominent typography and color-coded performance accents (Total Visits, Median Wait, P90 Wait, 30m SLA, 60m SLA, Severe Delays >60m).
  - [x] Build 10 native Excel charts tailored to specific clinical business questions (Monthly Volume Trend, Wait Tier Stratification, Hourly Median/P90 Profile, Weekday Congestion, 24-Hour Arrival Curve, Patient Recurrence Mix, Top 10 Doctor Volume, Doctor Tier Share, Top 10 Lab Tests Volume, Imaging Modality Distribution).
  - [x] Embed production Power Query M-code scripts into workbook catalog (`wb.Queries`) for seamless connection to processed datasets.
  - [x] Conduct rigorous Phase 7 audit, backup original workbook to `excel/backup/`, and investigate metric differences.
  - [x] Reconcile Diagnostic Turnaround metrics: CBC verified at 3,750 valid orders (73.0m median TAT), correcting narrative draft typos in `docs/SQL_ANALYSIS_REPORT.md`.
  - [x] Upgrade all 14 data ranges to official Excel Tables (`ListObjects`) with structured references.
  - [x] Replace static values with dynamic Excel formulas for KPI cards (`=C34`, `=(D38+D39)/D43`, etc.) and table summary rows.
  - [x] Add 4 native interactive Excel Slicers (`Slicer_WaitBand`, `Slicer_Day`, `Slicer_Congestion`, `Slicer_DoctorTier`).
  - [x] Author automated validation test harness (`excel/validate_dashboard_v2.ps1`) executing 11 tests with 100% pass rate.
  - [x] Author comprehensive audit report in `docs/archive/PHASE7_AUDIT_AND_FIX_REPORT.md` including exact desktop 2-click Power Pivot Data Model loading instructions.
- **Deliverables:** Master Excel workbook v1 (`excel/PULSE_Executive_Dashboard.xlsx`), upgraded production workbook v2 (`excel/PULSE_Executive_Dashboard_v2.xlsx`), automated COM builder script v2 (`excel/build_dashboard_v2.ps1`), test harness (`excel/validate_dashboard_v2.ps1`), backups in `excel/backup/`, and `docs/archive/PHASE7_AUDIT_AND_FIX_REPORT.md`.
- **Exit Gate:** 11/11 automated tests passed; 14 ListObjects, 4 Slicers, 10 dynamic formulas, 10 charts verified; 0 discrepancies; Phase 7 complete.

---

### Phase 8: Business Insights & Operational Recommendations
- **Status:** **Completed**
- **Objective:** Translate quantitative findings into strategic, actionable recommendations for hospital operations management.
- **Tasks:**
  - [x] Synthesize key bottlenecks identified in SQL and Excel dashboards (Twin-peak arrivals at 06:00 and 13:00, Monday 20.1% surge, pre-dawn holding queues, top 21 doctors handling 71.7%, ultrasound concentration).
  - [x] Formulate four strategic transformation pillars:
    - Pillar I: Dynamic Shift Scheduling & Day-of-Week Workload Leveling (3-tier shifts: 05:30, 08:30, 11:30; 125% staffing on Mondays, 60% on Sundays).
    - Pillar II: Pre-Dawn Queue Elimination via Digital Token Allocation (SMS/WhatsApp arrival windows, eliminating 03:00–05:00 AM holding queue).
    - Pillar III: Physician Workload Balancing & Clinical Scribe Support (Staggered clinic start times, scribes for batch sign-offs).
    - Pillar IV: Dedicated Maternal Ultrasound Suite & Rapid Phlebotomy Track (Decoupling FWB/Pelvic scans, <45 min CBC target, LIS timestamp bug fix).
  - [x] Model projected operational impact: 33% wait-time reduction (27m to 18m), 55% severe delay reduction (22.4% to <10%), +14.3% throughput capacity unlock without adding doctor headcount.
  - [x] Document comprehensive executive strategy in `docs/BUSINESS_RECOMMENDATIONS.md`.
- **Deliverables:** `docs/BUSINESS_RECOMMENDATIONS.md` (Executive Memo to CMO/COO, Root-Cause Forensics, Gantt Roadmap, KPI Governance Matrix).
- **Exit Gate:** Complete operational memo linking empirical data findings directly to actionable hospital management decisions.

---

### Phase 9: Quality Assurance & Cross-Tool Validation
- **Status:** **Completed**
- **Objective:** Validate that all figures, metrics, and KPI cards across SQL and Excel match with 100% precision.
- **Tasks:**
  - [x] Reconcile total visit counts, patient volumes, and department totals between SQL views and Excel tables (49,912 total visits, 39,442 unique patients).
  - [x] Verify that average and median wait times match to the decimal across both tools (P50 = 27.0 min, P90 = 98.0 min).
  - [x] Stress-test Excel slicers and dynamic formulas to confirm error-free display (0 `#REF!`, `#DIV/0!`, `#VALUE!`).
  - [x] Execute automated 11-test validation harness (`excel/validate_dashboard_v2.ps1`) confirming 100% mathematical consistency.
- **Deliverables:** Verified production workbook (`excel/PULSE_Executive_Dashboard.xlsx`), validation harness (`excel/validate_dashboard_v2.ps1`), and reconciled audit logs.
- **Exit Gate:** 100% pass rate across all cross-tool reconciliation checks.

---

### Phase 10: Portfolio Packaging & GitHub Presentation
- **Status:** **Completed & Ready for Push**
- **Objective:** Structure and document the repository for executive evaluation, technical recruitment, and GitHub presentation.
- **Tasks:**
  - [x] Verify clean project directory structure (`data/`, `docs/`, `excel/`, `sql/`, `.gitignore`, `README.md`).
  - [x] Purge temporary, superseded, and intermediate test files (`docs/archive/` removed; `excel/` streamlined).
  - [x] Prepare git staging and commit history for remote GitHub push.
  - [x] Author comprehensive, visual `README.md` showcasing problem context, architecture, key findings, and tools.
- **Deliverables:** Pristine Git-ready repository, production Excel dashboard, modular SQL analytical suite, and 10 clean documentation guides in `docs/`.
- **Exit Gate:** Clean workspace; 0 unwanted files; Git repository initialized and ready for remote push.
- **Deliverables:** Completed validation audit ensuring zero numerical discrepancies.
- **Exit Gate:** Signed-off reconciliation matrix confirming SQL-to-Excel parity.

---

### Phase 10: GitHub Presentation & Portfolio Packaging
- **Status:** **Planned**
- **Objective:** Package the project for recruiters, engineering managers, and hiring teams as a standout portfolio piece.
- **Tasks:**
  - [ ] Update `README.md` with high-resolution dashboard screenshots, executive summary, methodology, and key insights.
  - [ ] Provide clear instructions for cloning, running SQL queries, and exploring the Excel dashboard.
  - [ ] Include portfolio-ready project highlights emphasizing SQL proficiency, analytical rigor, and Excel dashboard architecture.
  - [ ] Final repository cleanup and release tag.
- **Deliverables:** Completed, recruiter-ready GitHub repository with comprehensive documentation and visual previews.
- **Exit Gate:** Professional showcase demonstrating end-to-end data analyst expertise.
