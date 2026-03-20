/*
============================================================
01 — STAGING TABLE
============================================================
This script creates the raw staging table that mirrors the
structure of the source CSV file exactly.
This step preserves the original data and allows all cleaning
to be performed before any normalisation takes place.
-- ============================================================
*/

-- 1.1 Create the database
-- CREATE DATABASE healthcare_analysis;

-- 1.2 Create the staging table
CREATE TABLE staging_healthcare (
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    blood_type VARCHAR(5),
    medical_condition VARCHAR(100),
    date_of_admission DATE,
    doctor VARCHAR(100),
    hospital VARCHAR(150),
    insurance_provider VARCHAR(100),
    billing_amount NUMERIC(12,2),
    room_number INT,
    admission_type VARCHAR(50),
    discharge_date DATE,
    medication VARCHAR(100),
    test_results VARCHAR(50)
);

-- 1.3 Load the CSV into the staging table
-- update the filepath before running
COPY staging_healthcare
FROM '/filepath/healthcare_dataset.csv'
WITH (FORMAT csv, HEADER true);

-- 1.4 Verify the data loaded correctly
SELECT COUNT(*) AS total_rows FROM staging_healthcare;
-- Expected: 55,500 rows

SELECT * FROM staging_healthcare LIMIT 10;
