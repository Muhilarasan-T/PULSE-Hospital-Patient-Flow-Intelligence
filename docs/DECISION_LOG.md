# PULSE — Project Decision & Architecture Log

This document records key architectural, data sourcing, methodology, and governance decisions made throughout the lifecycle of the **PULSE** project.

---

## 📑 Decision Summary Table

| Decision ID | Date | Category | Title | Status |
| :--- | :--- | :--- | :--- | :--- |
| **ADR-001** | Phase 1 / Phase 2 | Data Sourcing | Sourcing & Verification of Mendeley HospitalOPD Dataset | **Approved & Verified** |
| **ADR-002** | Phase 1 | Tech Stack | Sole Use of Microsoft Excel 365 and SQL | **Approved** |
| **ADR-003** | Phase 1 | Governance | Strict Data Exclusion in Version Control | **Approved** |
| **ADR-004** | Phase 1 | Methodology | Zero Fabrication & Phased Milestone Execution | **Approved** |
| **ADR-005** | Phase 2 | Data Architecture | CSV Ingestion & Locale / Timestamp Handling Strategy | **Approved** |
| **ADR-006** | Phase 4 | Tech Stack | Execution Engine: SQLite 3.51 ANSI SQL Dialect | **Approved** |
| **ADR-007** | Phase 4 | Data Modeling | Multi-Grain Fact Architecture (Event vs Visit Grain) | **Approved** |
| **ADR-008** | Phase 4 | Data Hygiene | Non-Destructive Cleaning with Explicit Audit Flags | **Approved** |
| **ADR-009** | Phase 5 | Metric Governance | KPI Framework & Continuous Percentile Methodology | **Approved** |
| **ADR-010** | Phase 5 | SLA Modeling | Exploratory Multi-Tier SLA Scenarios | **Approved** |
| **ADR-011** | Phase 5 | Journey Scoping | Outpatient Boundary Disclosure & Departure Milestone | **Approved** |
| **ADR-012** | Phase 6 | Data Modeling | Excel 365 Power Pivot Hybrid Galaxy Schema | **Approved** |

---

## 📝 Detailed Architecture Decision Records (ADRs)

### ADR-001: Verification and Acquisition of Mendeley HospitalOPD Dataset
- **Status:** **Approved & Verified**
- **Date:** Phase 2 Acquisition
- **Context:**  
  A real-world healthcare operations dataset was required to model outpatient flow, clinical wait times, and bottleneck congestion.
- **Verification Findings:**  
  - **Dataset URL:** [https://data.mendeley.com/datasets/j2hd2239dr/1](https://data.mendeley.com/datasets/j2hd2239dr/1)
  - **DOI:** `10.17632/j2hd2239dr.1` (Version 1, Published 22 June 2026)
  - **Authors / Contributors:** Komal Batool, Arshad Mehmood, Saad Zafar (Riphah International University)
  - **License:** Creative Commons Attribution 4.0 International (`CC BY 4.0`). Commercial and non-commercial sharing/modification permitted with attribution.
  - **Direct Download Access:** Fully public direct access via Mendeley Public API without requiring authentication, credentials, or interactive logins.
  - **File Acquired:** `data/raw/HospitalOPD-noname.csv`
  - **File Size:** `10,306,961` bytes (~9.83 MB)
  - **Checksum:** SHA-256 `07D0096B6E3FCFF78F94AFA6D5AEFFEEB2566F59902ECCC03DA209A3B6502720` (verified 100% match against Mendeley Data API metadata).
  - **Row & Column Count:** 62,423 total lines (1 header row + 62,422 data rows); exactly 25 columns per record.
  - **Observation Period:** April 25, 2024 11:12:00 to April 7, 2026 08:03:00.
  - **Entity Grain:** Service / event log level. Captures 49,912 unique outpatient appointments across 39,442 unique patients.
  - **Anonymization & Column 2 Finding:** Column index 2 has a blank header `""` and 0 populated values across all 62,422 rows. This confirms patient names/PII were completely removed at source prior to publication (`HospitalOPD-noname.csv`).
- **Consequences:**  
  The dataset perfectly matches project objectives. Ground truth is established with zero synthetic records.

---

### ADR-002: Tooling Scope — Exclusive Use of Microsoft Excel 365 and SQL
- **Status:** **Approved**
- **Date:** Phase 1 Initialization
- **Context:**  
  Data Analyst portfolio projects often use Python scripts or Power BI dashboards, sometimes obscuring the analyst's core foundational capabilities in SQL data manipulation and advanced spreadsheet modeling.
- **Decision:**  
  - **SQL** will be used for all relational querying, data quality audits, window functions, and aggregation modeling.
  - **Microsoft Excel 365** (Power Query, Data Modeling, Pivot Tables, Dynamic Formulas, and interactive UI) will be used for final analytical modeling and executive dashboarding.
  - **Constraint:** Python, Power BI, and web applications are strictly excluded from all project deliverables.
- **Consequences:**  
  Demonstrates advanced proficiency in SQL and Excel 365.

---

### ADR-003: Version Control Hygiene & Data Governance
- **Status:** **Approved**
- **Date:** Phase 1 Initialization
- **Context:**  
  Although `CC BY 4.0` allows public redistribution with attribution, storing large raw data files in Git repositories causes repository bloat and slow clone speeds.
- **Decision:**  
  - Keep `data/raw/HospitalOPD-noname.csv` excluded from Git commits via `.gitignore`.
  - Maintain folder tracking using `.gitkeep`.
  - Document complete provenance, SHA256 checksum, and download endpoint in `DECISION_LOG.md` for complete reproducibility.
- **Consequences:**  
  Repository remains lightweight and secure while data integrity is fully verifiable.

---

### ADR-004: Strict Zero-Fabrication Policy & Phased Execution
- **Status:** **Approved**
- **Date:** Phase 1 Initialization
- **Context:**  
  Speculative schema definitions or metric calculations created prior to dataset inspection risk analytical errors.
- **Decision:**  
  No metric formulas, table schemas, or query scripts will be implemented until real columns are verified.
- **Consequences:**  
  Guarantees 100% authenticity and auditability across all project artifacts.

---

### ADR-005: CSV Ingestion, Timestamp Locale, and Excel Capacity Strategy
- **Status:** **Approved**
- **Date:** Phase 2 Acquisition
- **Context:**  
  Verification revealed two technical characteristics of the raw CSV:
  1. Datetimes are formatted in US format (`M/d/yyyy H:mm`). On systems with UK/international locale (`dd/MM/yyyy`), standard string-to-date conversion causes date-parsing errors or day/month transposition.
  2. The dataset contains 62,422 rows. Excel 365 worksheets have a strict limit of 1,048,576 rows.
- **Decision:**  
  - **Timestamp Handling:** Power Query and SQL import scripts must explicitly parse datetimes using invariant / US locale (`en-US`) to ensure 100% accuracy in date dimensions and wait-time computations.
  - **Excel Capacity:** 62,422 rows represents ~5.95% of a single worksheet's capacity. The entire dataset fits comfortably into standard Excel 365 tables and the Power Query Data Model without requiring sampling or partitioning.
- **Consequences:**  
  Eliminates date corruption risks and validates full compatibility with Microsoft Excel 365.

---

### ADR-006: Execution Engine — SQLite 3.51 ANSI SQL Dialect
- **Status:** **Approved**
- **Date:** Phase 4 Cleaning
- **Context:**  
  A reliable, reproducible SQL database engine is required to execute data staging, transformation CTEs, window functions, and data quality reconciliation tests without installing external third-party software.
- **Decision:**  
  - Utilize the pre-installed, 64-bit `sqlite3.exe` (v3.51.0).
  - Author modular, portable SQL scripts adhering to ANSI SQL standards (fully compatible with PostgreSQL, MySQL 8+, and modern cloud data warehouses).
- **Consequences:**  
  Zero installation overhead; 100% reproducible execution directly from command line; outputs persistent database `data/processed/pulse.db`.

---

### ADR-007: Multi-Grain Analytical Architecture (Event vs. Visit Grain)
- **Status:** **Approved**
- **Date:** Phase 4 Cleaning
- **Context:**  
  4,822 outpatient encounters contain multiple event rows due to multiple diagnostic tests or prescriptions. Averaging raw rows distorts arrival counts and wait times by overweighting complex encounters.
- **Decision:**  
  - Separate analytical models into two distinct grains:
    1. **`fct_clinical_events`** (Grain: `record_no`, 62,422 rows): For clinical order volumes, lab turnaround, and medication analyses.
    2. **`fct_appointment_visits`** (Grain: `appointment_id`, 49,912 rows): For arrival flow, peak hour load, and initial patient wait times.
- **Consequences:**  
  Guarantees mathematical integrity; eliminates double-counting in executive KPI reporting.

---

### ADR-008: Non-Destructive Data Hygiene Strategy & Lineage Preservation
- **Status:** **Approved**
- **Date:** Phase 4 Cleaning
- **Context:**  
  Real-world operational data contains edge cases (5 negative wait times, 51 negative durations, 4,702 truncated lab timestamps). Silently deleting rows or imputing values introduces bias.
- **Decision:**  
  - All 62,422 raw rows are retained in the cleaned database.
  - Anomaly audit flags (`is_valid_wait_time`, `is_valid_consult_duration`, `lab_end_reconstruction_status`) are attached to every record.
  - Original raw timestamps are preserved alongside standardized ISO datetimes.
  - The validated clerical error in `record_no = 28837` is corrected with explicit audit flags and justification text.
- **Consequences:**  
  Complete auditability; transparent reporting for clinical administrators and recruiters.

---

### ADR-009: Phase 5 Operational KPI Framework & Continuous Percentile Methodology
- **Status:** **Approved**
- **Date:** Phase 5 Analytics
- **Context:**  
  Hospital wait times exhibit severe positive skewness (right tail up to 695,643 minutes). Using the mathematical mean as the sole measure of central tendency significantly distorts executive reporting. Furthermore, standard SQLite lacks native `PERCENTILE_CONT` functions.
- **Decision:**  
  - Implement ANSI SQL window functions (`ROW_NUMBER() OVER (ORDER BY ... ASC)`) with rank index interpolation to compute exact non-parametric percentiles ($P_{25}$, Median $P_{50}$, $P_{75}$, $P_{90}$, and $P_{95}$).
  - Establish the **Median ($P_{50}$)** as the primary operational baseline for capacity planning and doctor scheduling.
  - Require all average calculations to be accompanied by median and percentile figures, as formalized in `docs/KPI_DEFINITIONS.md`.
- **Consequences:**  
  Robust, outlier-resistant metrics that accurately reflect genuine patient experience.

---

### ADR-010: Exploratory Multi-Tier Service Level Agreement (SLA) Scenarios
- **Status:** **Approved**
- **Date:** Phase 5 Analytics
- **Context:**  
  The dataset does not specify a pre-existing hospital SLA mandate. Imposing an arbitrary SLA threshold risks misrepresenting hospital compliance policies.
- **Decision:**  
  - Model six exploratory operational scenarios ($\le 15$m, $\le 30$m, $\le 45$m, $\le 60$m, $\le 90$m, $\le 120$m) to provide leadership with a flexible sensitivity matrix.
  - Explicitly label all SLA benchmarks in documentation and reports as *exploratory operational scenarios for management evaluation*, not mandated hospital policies.
- **Consequences:**  
  Provides actionable decision-support tools for executive leadership while maintaining professional analytical objectivity.

---

### ADR-011: Outpatient Boundary Disclosure & Departure Milestone Scoping
- **Status:** **Approved**
- **Date:** Phase 5 Analytics
- **Context:**  
  Hospital administrators often ask for "Total Patient Length of Stay (LOS)" in outpatient departments. Inspection of the dataset reveals that while arrival, consultation, lab, and imaging timestamps are present, no physical departure/exit timestamp exists in the schema.
- **Decision:**  
  - Formally document the uncaptured physical exit milestone in `docs/KPI_DEFINITIONS.md`, `docs/SQL_ANALYSIS_REPORT.md`, and `analysis_journey_boundary_audit`.
  - Disclose that total outpatient Length of Stay (LOS) cannot be calculated.
  - Scope operational KPIs strictly to *Initial Wait Time* (Arrival to Consultation) and *Service-Specific Turnaround Times* (Lab TAT, Imaging Exam Duration).
- **Consequences:**  
  Prevents erroneous extrapolation or synthetic milestone creation, upholding complete professional integrity.

---

### ADR-012: Excel 365 Power Pivot Hybrid Galaxy Schema & Grain Isolation
- **Status:** **Approved**
- **Date:** Phase 6 Data Preparation
- **Context:**  
  Importing all 24 Phase 5 summary tables into Excel creates data model confusion and redundancy. Conversely, joining event records directly to appointment visits risks inflating visit counts by up to 28x.
- **Decision:**  
  - Implement a **Hybrid Galaxy Schema** in Excel Data Model (`Power Pivot`):
    1. **Two Core Fact Tables:** `fct_appointment_visits` ($N = 49,912$) and `fct_clinical_events` ($N = 62,422$).
    2. **Two Conformed Dimensions:** `dim_date_calendar` ($N = 1,096$) and `dim_doctors` ($N = 98$).
    3. **Selective Visual Feeders:** Ingest only 5 specialized reference tables for high-speed charts.
  - Maintain an inactive relationship between `fct_appointment_visits` and `fct_clinical_events` inside Power Pivot, routing cross-dimensional slicing strictly through the conformed date and doctor dimensions.
- **Consequences:**  
  Eliminates many-to-many overcounting risks, maintains sub-second Pivot Table performance, and adheres to dimensional modeling best practices.
