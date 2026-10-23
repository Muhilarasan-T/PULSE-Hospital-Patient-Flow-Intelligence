# PULSE — Hospital Patient Flow & Wait-Time Intelligence

**Healthcare Operations & Outpatient Throughput Analytics**  
*A Data Analyst Portfolio Project built with SQL & Microsoft Excel 365*

---

## 🏥 Project Overview

In healthcare delivery, hospital Outpatient Departments (OPDs) frequently face severe operational friction: extended patient wait times, unpredictable arrival surges, departmental bottlenecks, and suboptimal clinical room utilization. These delays degrade patient satisfaction, increase staff fatigue, and hinder hospital throughput.

**PULSE** (*Patient Utility, Latency & Service Efficiency*) is an analytics initiative designed to evaluate patient journey milestones, isolate operational bottlenecks, and provide hospital management with data-backed recommendations to optimize outpatient flow and reduce non-value-added waiting times.

---

## 🎯 Project Objectives

- **Quantify Patient Wait Times:** Measure elapsed times across critical outpatient touchpoints (e.g., arrival, registration, triage, physician consultation, pharmacy/billing).
- **Identify Bottlenecks & Peak Congestion:** Pinpoint peak arrival windows, days of highest load, and stages where queues accumulate.
- **Evaluate Departmental Throughput:** Compare patient volume, average consultation duration, and queue velocity across medical specialties.
- **Formulate Actionable Hospital Recommendations:** Provide operational strategies (scheduling adjustments, queue management, staffing allocation) to enhance clinical flow.
- **Demonstrate Core Analyst Competencies:** Showcase robust data modeling, advanced SQL querying, and executive-level Microsoft Excel 365 dashboard architecture without relying on external BI platforms or code wrappers.

---

## 🛠️ Tooling & Stack

| Tool | Role & Scope in PULSE |
| :--- | :--- |
| **SQL** | Relational data structuring, data quality auditing, Common Table Expressions (CTEs), window functions, time-difference calculations, and KPI aggregations. |
| **Microsoft Excel 365** | Power Query ETL, dimensional data modeling, dynamic formulas, Pivot Tables/Pivot Charts, interactive slicers, and executive dashboard design. |

> **Note on Tooling Boundaries:** In strict adherence to project scope, **Python and Power BI are intentionally excluded** from project deliverables. The focus is to demonstrate deep mastery of SQL for data extraction and transformation alongside Microsoft Excel 365 for business modeling and executive reporting.

---

## 🔄 Planned Project Workflow

```
[Phase 1] Project Initialization & Architecture (Current)
   │
   ▼
[Phase 2] Dataset Acquisition & Verification (Mendeley Data: HospitalOPD)
   │
   ▼
[Phase 3] Exploratory Data Profiling & Schema Mapping
   │
   ▼
[Phase 4] Data Quality Auditing & Data Cleaning (SQL)
   │
   ▼
[Phase 5] SQL Analysis & Operational KPI Modeling
   │
   ▼
[Phase 6] Excel Data Preparation & Power Query Integration
   │
   ▼
[Phase 7] Interactive Executive Excel Dashboard (Excel 365)
   │
   ▼
[Phase 8] Business Insights & Operational Recommendations
   │
   ▼
[Phase 9] Cross-Tool Validation & Numerical Audit
   │
   ▼
[Phase 10] Final Portfolio Documentation & GitHub Packaging
```

---

## 📊 Completed Analyses & Operational Findings *(Phase 5 Verified)*

> *All metrics below reflect empirically measured values calculated in SQLite 3.51 with 100% mathematical integrity across 9 automated reconciliation audit tests.*

1. **Patient Wait-Time & Queue Latency:**
   - **Median Initial Wait Time ($P_{50}$):** **27.0 Minutes** ($P_{25} = 12.0$ min, $P_{75} = 56.0$ min, $P_{90} = 98.0$ min).
   - **Mean Wait Time:** **119.30 Minutes** (pulled up by extreme right-tail EHR delay outliers up to 695,643 min).
   - **Exploratory SLA Compliance:** $\le 15$ min: 33.33% | $\le 30$ min: 54.41% | $\le 60$ min: 77.64% | $> 60$ min (severe delay): 22.36%.
2. **Surge Windows & Temporal Demand:**
   - **Twin-Peak Daily Arrival Surges:** Morning Peak (05:00–08:00 AM; 33.20% volume; Hour 6 peak = 6,208 visits) and Afternoon Peak (12:00–15:00 PM; 30.70% volume; Hour 13 peak = 5,872 visits). Together, these 6 hours absorb **63.90% of all hospital visits**.
   - **Day-of-Week Variation:** Monday is the heaviest day (**10,036 visits, 20.11%**; Median Wait = 33.0 min); Sunday has lowest load (**2,208 visits, 4.43%**; Median Wait = 12.0 min).
3. **Physician Workload Concentration:**
   - Out of 98 attending doctors, **21 high-volume doctors handle 71.68% of all consultations**.
   - Top 2 physicians (`Dr. Junaid Ul Hassan Khalid` [3,672 visits] and `Dr. Abrar Ahmed Bhatti` [3,604 visits]) handle ~15% of all hospital visits.
4. **Clinical Pathways & Multi-Grain Risk:**
   - 79.46% of visits are consultation-only; 12.76% use laboratory testing; 10.66% use imaging; 0.22% use pharmacy.
   - Event-to-visit multiplication reaches up to 28x in complex workups, proving that raw row counts overestimate patient visits by 25.06%.
5. **Diagnostic Velocity (TAT):**
   - **Laboratory TAT:** Median = **125.0 Minutes (~2.1h)** across 13,327 valid standard complete orders ($P_{90} = 469.0$ min; 4,702 truncated records excluded).
   - **Imaging Duration:** Median = **3.0 Minutes** across 5,513 valid procedures ($P_{90} = 9.0$ min; FWB & pelvis ultrasounds account for 66.4% of imaging).

---

## 📁 Repository Structure

```
PULSE/
├── .gitignore               # Excludes temp files, lock files, and raw data
├── README.md                # Project charter, workflow, and portfolio summary
├── data/
│   ├── raw/                 # Raw source dataset (CC BY 4.0; untracked in Git)
│   └── processed/           # Cleaned SQLite db, dimension tables, and fact tables
│       └── analysis/        # 24 exported analytical CSV tables ready for Excel
├── docs/
│   ├── PROJECT_PLAN.md      # Detailed 10-phase milestone roadmap
│   ├── DATA_DICTIONARY.md   # Complete schema definition across all models
│   ├── DECISION_LOG.md      # Architectural Decision Records (ADR-001 to ADR-011)
│   ├── PROFILING_REPORT.md  # Exploratory data profiling & anomaly catalog
│   ├── CLEANING_RULES.md    # Non-destructive transformation rules & lineage
│   ├── KPI_DEFINITIONS.md   # Standardized KPI governance & formulas
│   ├── SQL_ANALYSIS_REPORT.md # Executive healthcare operations intelligence report
│   ├── BUSINESS_RECOMMENDATIONS.md # Strategic operations transformation memo
│   ├── EXCEL_POWER_QUERY_GUIDE.md # Power Query M-code ETL guide
│   └── EXCEL_DASHBOARD_SPEC.md    # Excel dashboard wireframes & DAX specification
├── sql/                     # Modular SQL scripts (staging, cleaning, KPI views)
│   ├── 01_source_ingestion_and_staging.sql
│   ├── 02_clean_clinical_events.sql
│   ├── 03_aggregate_appointment_visits.sql
│   ├── 04_data_quality_reconciliation.sql
│   ├── 05_wait_time_analysis.sql
│   ├── 06_operational_volume_analysis.sql
│   ├── 07_doctor_performance_analysis.sql
│   ├── 08_pathway_and_service_analysis.sql
│   ├── 09_turnaround_and_sla_analysis.sql
│   ├── 10_kpi_quality_validation.sql
│   ├── 11_create_dim_date_calendar.sql
│   ├── run_all_transformations.sql
│   └── run_all_analyses.sql
└── excel/                   # Excel 365 workbooks and interactive dashboards
    └── PULSE_Executive_Dashboard.xlsx # Master interactive executive dashboard (Power Pivot)
```

---

## 📌 Project Status

| Phase | Milestone | Status |
| :--- | :--- | :--- |
| **Phase 1** | **Project Initialization & Workspace Setup** | **Completed** |
| **Phase 2** | **Dataset Acquisition & Verification (HospitalOPD)** | **Completed** |
| **Phase 3** | **Data Profiling & Structural Inspection** | **Completed** |
| **Phase 4** | **Data Quality Auditing & Cleaning (SQL)** | **Completed** |
| **Phase 5** | **In-Depth SQL Analysis & Operational KPI Modeling** | **Completed** |
| **Phase 6** | **Excel Data Preparation & Power Query Integration** | **Completed** |
| **Phase 7** | **Interactive Excel 365 Executive Dashboard Build** | **Completed** |
| **Phase 8** | **Business Recommendations & Operational Strategy** | **Completed** |
| **Phase 9** | **Quality Assurance & Cross-Tool Validation** | **Completed** |
| **Phase 10** | **Portfolio Packaging & GitHub Presentation** | **Ready for Remote Push** |

---

## 🚀 Strategic Recommendations & Operational Impact Summary

Based on quantitative findings across 49,912 outpatient encounters, the strategic transformation plan ([`docs/BUSINESS_RECOMMENDATIONS.md`](file:///C:/Users/DELL/PULSE/docs/BUSINESS_RECOMMENDATIONS.md)) delivers four core pillars:

1. **Dynamic Shift Scheduling:** Three-tier staggered shifts (05:30, 08:30, 11:30 AM) to match twin-peak arrival surges (06:00 AM & 13:00 PM), with 125% staffing on Mondays and 60% on Sundays.
2. **Pre-Dawn Queue Elimination:** Automated SMS/WhatsApp appointment token allocation with dynamic 30-minute arrival windows, eliminating the 03:00–05:00 AM holding queue (3,179 patients; 53 min median wait).
3. **Physician Workload Balancing:** Staggered clinic start times for the top 21 doctors (handling 71.7% of visits) and clinical scribe support to reduce EHR documentation bottlenecks.
4. **Dedicated Maternal Ultrasound Suite & Rapid Lab Track:** Dedicated scanning suites for FWB and pelvic ultrasounds (66.4% of all imaging) and point-of-care CBC phlebotomy to compress lab TAT from 73 min to $\le 45$ min.

### Targeted Operational Outcomes:
- **Median Wait Time:** Compressed from **27.0 min to $\le 18.0$ min** (-33.3%).
- **Severe Delay Rate ($>60$ min):** Reduced from **22.4% to $< 10.0\%$** (-55.3%).
- **Hospital Capacity:** **+14.3% outpatient throughput gain** (~7,000 additional encounters over 2 years) with zero added physician salary overhead.
