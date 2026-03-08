/*
============================================================
03 — SCHEMA CREATION
This script creates the normalised 3-table relational
schema. The original staging table is split into
patients, admissions and insurance.

NOTE ON HOSPITALS TABLE:
A hospitals table was initially planned as a 4th entity.
However profiling revealed 39,876 ostensibly distinct
hospital names for 50,000 rows — caused by fragmented
and shuffled naming in the source data e.g:
"Scott Edwards, Rose And"
"And Rose, Scott Edwards"
Forcing normalisation on unreliable data would produce
incorrect results. Hospital name is therefore retained
as a direct attribute on the admissions table. This is
a deliberate and documented data modelling decision.
============================================================
*/


/*
============================================================
TABLE 1 — PATIENTS
One row per unique patient
============================================================
*/

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    blood_type VARCHAR(5)
);


/*
============================================================
TABLE 2 — ADMISSIONS
One row per hospital admission
Links to patients via patient_id foreign key
============================================================
*/

CREATE TABLE admissions (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    hospital_name VARCHAR(200),
    medical_condition VARCHAR(100),
    date_of_admission DATE,
    discharge_date DATE,
    admission_type VARCHAR(50),
    room_number INT,
    doctor VARCHAR(100),
    medication VARCHAR(100),
    test_results VARCHAR(50)
);


/*
============================================================
TABLE 3 — INSURANCE
One row per admission billing record
Links to admissions via admission_id foreign key
============================================================
*/

CREATE TABLE insurance (
    insurance_id SERIAL PRIMARY KEY,
    admission_id INT REFERENCES admissions(admission_id),
    provider_name VARCHAR(100),
    billing_amount NUMERIC(12,2)
);


/*
============================================================
VERIFY TABLES WERE CREATED
============================================================
*/

-- Expected: admissions, insurance, patients, staging_healthcare
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
