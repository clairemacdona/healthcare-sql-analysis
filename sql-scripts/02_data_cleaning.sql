/*
============================================================
Script 02 - DATA CLEANING
============================================================
This script performs all data cleaning on the staging
table. Each step is documented with the issue found and
the fix applied.
============================================================
*/


/*
============================================================
1 - DATA PROFILING
Understand and check the data quality
============================================================
*/

-- 1.1 Row count
-- Result: 55,500
SELECT COUNT(*) AS total_rows FROM staging_healthcare;

-- 1.2 Check across all columns for NULLs
-- Result: 0 NULLs across all columns
SELECT
    COUNT(*) - COUNT(name) AS name_nulls,
    COUNT(*) - COUNT(age) AS age_nulls,
    COUNT(*) - COUNT(gender) AS gender_nulls,
    COUNT(*) - COUNT(blood_type) AS blood_type_nulls,
    COUNT(*) - COUNT(medical_condition) AS condition_nulls,
    COUNT(*) - COUNT(date_of_admission) AS admission_date_nulls,
    COUNT(*) - COUNT(discharge_date) AS discharge_date_nulls,
    COUNT(*) - COUNT(doctor) AS doctor_nulls,
    COUNT(*) - COUNT(hospital) AS hospital_nulls,
    COUNT(*) - COUNT(insurance_provider) AS insurance_nulls,
    COUNT(*) - COUNT(billing_amount) AS billing_nulls,
    COUNT(*) - COUNT(room_number) AS room_nulls,
    COUNT(*) - COUNT(admission_type) AS admission_type_nulls,
    COUNT(*) - COUNT(medication) AS medication_nulls,
    COUNT(*) - COUNT(test_results) AS test_results_nulls
FROM staging_healthcare;

-- 1.3 Check for duplicates
-- Result: Duplicates found — investigation required
SELECT
    name,
    date_of_admission,
    hospital,
    COUNT(*) AS duplicate_count
FROM staging_healthcare
GROUP BY name, date_of_admission, hospital
HAVING COUNT(*) > 1
LIMIT 20;

-- 1.4 Check the youngest, oldest and average age
-- Result: Min 13, Max 89, Avg 51.54 — acceptable range
SELECT MIN(age) AS min_age,
       MAX(age) AS max_age,
       AVG(age) AS avg_age
FROM staging_healthcare;

-- 1.5 Check the smallest, largest and average bills
-- Result: Min -2008.49 (negative = data error), Max 52764.28, Avg 25539.32
SELECT MIN(billing_amount) AS min_billing,
       MAX(billing_amount) AS max_billing,
       AVG(billing_amount) AS avg_billing
FROM staging_healthcare;

-- 1.6 Check values of categorical data
-- Result: All categorical columns clean
SELECT DISTINCT gender FROM staging_healthcare;
SELECT DISTINCT blood_type FROM staging_healthcare;
SELECT DISTINCT admission_type FROM staging_healthcare;
SELECT DISTINCT test_results FROM staging_healthcare;
SELECT DISTINCT medical_condition FROM staging_healthcare;

-- 1.7 Check no discharge date precedes admission date
-- Result: 0 invalid date combinations
SELECT COUNT(*) AS bad_dates
FROM staging_healthcare
WHERE discharge_date < date_of_admission;


/*
============================================================
2 — FIX INCONSISTENT TEXT CASING
Issue: Names and doctors had random mixed caps
e.g. "AARon smITh", "ABIGAiL wateRS"
This was masking the true scale of the duplicate problem
Fix: Apply INITCAP() to standardise to proper case
============================================================
*/

-- 2.1 Standardise names
UPDATE staging_healthcare SET name = INITCAP(name);
UPDATE staging_healthcare SET doctor = INITCAP(doctor);

-- 2.2 Verify casing is now standardised
SELECT name, doctor
FROM staging_healthcare
LIMIT 10;


/*
============================================================
3 — REMOVE DUPLICATE ROWS
Issue: 5,500 duplicate rows confirmed after fixing casing
Fix: Add row_id, keep earliest occurrence of each record
============================================================
*/

-- 3.1 Add a unique row identifier
ALTER TABLE staging_healthcare ADD COLUMN row_id SERIAL;

-- 3.2 Remove duplicates keeping the lowest row_id
DELETE FROM staging_healthcare
WHERE row_id NOT IN (
    SELECT MIN(row_id)
    FROM staging_healthcare
    GROUP BY name, date_of_admission, hospital
);

-- 3.3 Verify: should return 0 rows
SELECT name, date_of_admission, hospital, COUNT(*)
FROM staging_healthcare
GROUP BY name, date_of_admission, hospital
HAVING COUNT(*) > 1;

-- 3.4 Verify row count
-- Expected: 50,000 rows
SELECT COUNT(*) AS total_rows FROM staging_healthcare;


/*
============================================================
4 — FIX NEGATIVE BILLING AMOUNTS
Issue: Min billing was -$2,008.49 — not valid
Fix: Convert negative values to absolute value with ABS()
============================================================
*/

-- 4.1 Inspect negative values first
SELECT * FROM staging_healthcare WHERE billing_amount < 0;

-- 4.2 Convert to positive values
UPDATE staging_healthcare
SET billing_amount = ABS(billing_amount)
WHERE billing_amount < 0;

-- 4.3 Verify: minimum is now be positive
SELECT MIN(billing_amount) FROM staging_healthcare;

/*
============================================================
5 — BILLING OUTLIER CHECK
Result: 0 outliers found beyond 2 standard deviations
High values are plausible (e.g. cancer treatment at $52k)
============================================================
*/

-- 5.1 Add a boolean outlier check
ALTER TABLE staging_healthcare
ADD COLUMN billing_outlier BOOLEAN DEFAULT FALSE;

-- 5.2 Flag if bill is 2 standard deviations above the mean
UPDATE staging_healthcare
SET billing_outlier = TRUE
WHERE billing_amount > (
    SELECT AVG(billing_amount) + 2 * STDDEV(billing_amount)
    FROM staging_healthcare
);

-- 5.3 Check for flagged bills
-- Result: 0 outliers flagged
SELECT COUNT(*) AS outlier_count
FROM staging_healthcare
WHERE billing_outlier = TRUE;

/*
============================================================
6 — TRIM WHITESPACE FROM ALL TEXT COLUMNS
Preventative measure
============================================================
*/

UPDATE staging_healthcare SET name = TRIM(name);
UPDATE staging_healthcare SET gender = TRIM(gender);
UPDATE staging_healthcare SET blood_type = TRIM(blood_type);
UPDATE staging_healthcare SET medical_condition = TRIM(medical_condition);
UPDATE staging_healthcare SET hospital = TRIM(hospital);
UPDATE staging_healthcare SET insurance_provider = TRIM(insurance_provider);
UPDATE staging_healthcare SET admission_type = TRIM(admission_type);
UPDATE staging_healthcare SET medication = TRIM(medication);
UPDATE staging_healthcare SET test_results = TRIM(test_results);
UPDATE staging_healthcare SET doctor = TRIM(doctor);

-- Verify sample looks clean
SELECT name, gender, medical_condition FROM staging_healthcare LIMIT 5;

/*
============================================================
7 — FINAL VERIFICATION
============================================================
*/

-- 7.1 Final clean row count
-- Expected: 50,000
SELECT COUNT(*) AS final_row_count FROM staging_healthcare;

-- 7.2 Confirm billing is all positive
-- Expected: Min is 9.24
SELECT MIN(billing_amount) AS min_bill,
       MAX(billing_amount) AS max_bill
FROM staging_healthcare;

-- 7.3 Confirm no duplicates remain
-- Expected: 0 rows
SELECT name, date_of_admission, hospital, COUNT(*)
FROM staging_healthcare
GROUP BY name, date_of_admission, hospital
HAVING COUNT(*) > 1;
