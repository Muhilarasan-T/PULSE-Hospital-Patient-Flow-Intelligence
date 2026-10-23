-- ==============================================================================
-- PULSE — Phase 5: Master Analysis Execution & Export Orchestration
-- Database: data/processed/pulse.db
-- Output Directory: data/processed/analysis/
-- ==============================================================================

-- 1. Execute Script 05: Wait Time Analysis
.read sql/05_wait_time_analysis.sql

-- 2. Execute Script 06: Operational Volume Analysis
.read sql/06_operational_volume_analysis.sql

-- 3. Execute Script 07: Doctor Operations Analysis
.read sql/07_doctor_performance_analysis.sql

-- 4. Execute Script 08: Clinical Pathway & Service Analysis
.read sql/08_pathway_and_service_analysis.sql

-- 5. Execute Script 09: Turnaround Time & SLA Analysis
.read sql/09_turnaround_and_sla_analysis.sql

-- 6. Execute Script 10: KPI Quality & Reconciliation Suite
.read sql/10_kpi_quality_validation.sql

-- 7. Export All Analysis Tables to data/processed/analysis/ CSVs
.mode csv
.headers on

.output data/processed/analysis/analysis_wait_time_overall.csv
SELECT * FROM analysis_wait_time_overall;

.output data/processed/analysis/analysis_wait_time_distribution.csv
SELECT * FROM analysis_wait_time_distribution;

.output data/processed/analysis/analysis_wait_time_by_hour.csv
SELECT * FROM analysis_wait_time_by_hour;

.output data/processed/analysis/analysis_wait_time_by_day.csv
SELECT * FROM analysis_wait_time_by_day;

.output data/processed/analysis/analysis_wait_time_sensitivity.csv
SELECT * FROM analysis_wait_time_sensitivity;

.output data/processed/analysis/analysis_volume_hourly.csv
SELECT * FROM analysis_volume_hourly;

.output data/processed/analysis/analysis_volume_daily.csv
SELECT * FROM analysis_volume_daily;

.output data/processed/analysis/analysis_volume_monthly_trend.csv
SELECT * FROM analysis_volume_monthly_trend;

.output data/processed/analysis/analysis_patient_recurrence.csv
SELECT * FROM analysis_patient_recurrence;

.output data/processed/analysis/analysis_doctor_volume_ranking.csv
SELECT * FROM analysis_doctor_volume_ranking;

.output data/processed/analysis/analysis_doctor_consultation_benchmarks.csv
SELECT * FROM analysis_doctor_consultation_benchmarks;

.output data/processed/analysis/analysis_doctor_sample_size_tiers.csv
SELECT * FROM analysis_doctor_sample_size_tiers;

.output data/processed/analysis/analysis_pathway_volume_and_wait.csv
SELECT * FROM analysis_pathway_volume_and_wait;

.output data/processed/analysis/analysis_service_utilization_mix.csv
SELECT * FROM analysis_service_utilization_mix;

.output data/processed/analysis/analysis_top_lab_tests.csv
SELECT * FROM analysis_top_lab_tests;

.output data/processed/analysis/analysis_top_imaging_modalities.csv
SELECT * FROM analysis_top_imaging_modalities;

.output data/processed/analysis/analysis_multi_grain_reconciliation.csv
SELECT * FROM analysis_multi_grain_reconciliation;

.output data/processed/analysis/analysis_sla_exploratory_scenarios.csv
SELECT * FROM analysis_sla_exploratory_scenarios;

.output data/processed/analysis/analysis_sla_by_hour.csv
SELECT * FROM analysis_sla_by_hour;

.output data/processed/analysis/analysis_lab_turnaround_summary.csv
SELECT * FROM analysis_lab_turnaround_summary;

.output data/processed/analysis/analysis_lab_test_specific_tat.csv
SELECT * FROM analysis_lab_test_specific_tat;

.output data/processed/analysis/analysis_imaging_turnaround_summary.csv
SELECT * FROM analysis_imaging_turnaround_summary;

.output data/processed/analysis/analysis_journey_boundary_audit.csv
SELECT * FROM analysis_journey_boundary_audit;

.output data/processed/analysis/audit_kpi_reconciliation.csv
SELECT * FROM audit_kpi_reconciliation;

-- 8. Display Reconciliation Summary to Terminal
.output stdout
.mode column
.headers on
SELECT * FROM audit_kpi_reconciliation;
