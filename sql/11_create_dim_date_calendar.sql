-- ==============================================================================
-- PULSE — Phase 6: Excel 365 & Power Query Data Model Preparation
-- Script 11: Create Dimensional Calendar Table (dim_date_calendar)
-- Dialect: ANSI SQL / SQLite 3.51+
-- Database: data/processed/pulse.db
-- Output Table: dim_date_calendar (1,096 days covering 2024-01-01 to 2026-12-31)
-- Output File: data/processed/dim_date_calendar.csv
-- ==============================================================================

DROP TABLE IF EXISTS dim_date_calendar;

CREATE TABLE dim_date_calendar AS
WITH RECURSIVE date_series(d) AS (
    SELECT '2024-01-01'
    UNION ALL
    SELECT date(d, '+1 day')
    FROM date_series
    WHERE d < '2026-12-31'
),
hospital_dates AS (
    SELECT DISTINCT appointment_date
    FROM fct_appointment_visits
    WHERE appointment_date IS NOT NULL
)
SELECT
    d AS date_key,
    CAST(strftime('%Y%m%d', d) AS INT) AS date_int,
    d AS full_date,
    CAST(strftime('%Y', d) AS INT) AS year,
    'Q' || ((CAST(strftime('%m', d) AS INT) - 1) / 3 + 1) AS quarter,
    strftime('%Y', d) || '-Q' || ((CAST(strftime('%m', d) AS INT) - 1) / 3 + 1) AS year_quarter,
    CAST(strftime('%m', d) AS INT) AS month_number,
    CASE strftime('%m', d)
        WHEN '01' THEN 'January'
        WHEN '02' THEN 'February'
        WHEN '03' THEN 'March'
        WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'June'
        WHEN '07' THEN 'July'
        WHEN '08' THEN 'August'
        WHEN '09' THEN 'September'
        WHEN '10' THEN 'October'
        WHEN '11' THEN 'November'
        WHEN '12' THEN 'December'
    END AS month_name,
    CASE strftime('%m', d)
        WHEN '01' THEN 'Jan'
        WHEN '02' THEN 'Feb'
        WHEN '03' THEN 'Mar'
        WHEN '04' THEN 'Apr'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'Jun'
        WHEN '07' THEN 'Jul'
        WHEN '08' THEN 'Aug'
        WHEN '09' THEN 'Sep'
        WHEN '10' THEN 'Oct'
        WHEN '11' THEN 'Nov'
        WHEN '12' THEN 'Dec'
    END AS month_short,
    strftime('%Y-%m', d) AS year_month,
    CAST(strftime('%d', d) AS INT) AS day_of_month,
    CASE strftime('%w', d)
        WHEN '0' THEN 7
        ELSE CAST(strftime('%w', d) AS INT)
    END AS day_of_week_number,
    CASE strftime('%w', d)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS day_of_week_name,
    CASE strftime('%w', d)
        WHEN '0' THEN 'Sun'
        WHEN '1' THEN 'Mon'
        WHEN '2' THEN 'Tue'
        WHEN '3' THEN 'Wed'
        WHEN '4' THEN 'Thu'
        WHEN '5' THEN 'Fri'
        WHEN '6' THEN 'Sat'
    END AS day_of_week_short,
    CASE WHEN strftime('%w', d) IN ('0', '6') THEN 1 ELSE 0 END AS is_weekend,
    CASE WHEN strftime('%w', d) NOT IN ('0', '6') THEN 1 ELSE 0 END AS is_weekday,
    CASE WHEN hd.appointment_date IS NOT NULL THEN 1 ELSE 0 END AS has_hospital_appointments
FROM date_series ds
LEFT JOIN hospital_dates hd ON ds.d = hd.appointment_date
ORDER BY d ASC;

CREATE UNIQUE INDEX idx_dim_date_key ON dim_date_calendar(date_key);
CREATE INDEX idx_dim_date_year_month ON dim_date_calendar(year_month);
CREATE INDEX idx_dim_date_dow ON dim_date_calendar(day_of_week_number);
