/*
============================================================
04 — DATA LOADING
This script populates the 3 normalised tables from the
cleaned staging table. Each block is run and the row counts
verified before proceeding.
============================================================
*/


/*
============================================================
BLOCK 1 — POPULATE PATIENTS
- One row per unique patient name
- Where the same patient appears with different ages
(admitted in different years), we keep the most recent
(highest) age using DISTINCT ON
============================================================
*/

INSERT INTO patients (name, age, gender, blood_type)
SELECT DISTINCT ON (name) name, age, gender, blood_type
FROM staging_healthcare
ORDER BY name, age DESC;

-- Verify
-- Result: 40,235 unique patients
SELECT COUNT(*) AS patient_count FROM patients;


/*
============================================================
BLOCK 2 — POPULATE ADMISSIONS
One row per admission
Joins back to patients to get the patient_id foreign key
============================================================
*/

INSERT INTO admissions (
    patient_id,
    hospital_name,
    medical_condition,
    date_of_admission,
    discharge_date,
    admission_type,
    room_number,
    doctor,
    medication,
    test_results
)
SELECT
    p.patient_id,
    s.hospital,
    s.medical_condition,
    s.date_of_admission,
    s.discharge_date,
    s.admission_type,
    s.room_number,
    s.doctor,
    s.medication,
    s.test_results
FROM staging_healthcare s
JOIN patients p ON p.name = s.name;

-- Verify
-- Result: 50,000
SELECT COUNT(*) AS admissions_count FROM admissions;


/*
============================================================
BLOCK 3 — POPULATE INSURANCE
One row per admission billing record
JOIN uses 4 columns to uniquely identify each admission
and avoid duplicate matches for patients admitted
more than once on the same date
============================================================
*/

INSERT INTO insurance (admission_id, provider_name, billing_amount)
SELECT
    a.admission_id,
    s.insurance_provider,
    s.billing_amount
FROM staging_healthcare s
JOIN patients p ON p.name = s.name
JOIN admissions a ON a.patient_id = p.patient_id
                 AND a.date_of_admission = s.date_of_admission
                 AND a.medical_condition = s.medical_condition
                 AND a.room_number = s.room_number;

-- Verify
-- Result: 50,000
SELECT COUNT(*) AS insurance_count FROM insurance;


/*
============================================================
FINAL VERIFICATION
Run all counts and a joined check
============================================================
*/

-- Row counts across all tables
SELECT COUNT(*) AS patients_count   FROM patients;
SELECT COUNT(*) AS admissions_count FROM admissions;
SELECT COUNT(*) AS insurance_count  FROM insurance;

-- Joined check — should return 10 clean rows
SELECT
    p.name,
    p.age,
    p.gender,
    a.hospital_name,
    a.medical_condition,
    a.date_of_admission,
    a.discharge_date,
    (a.discharge_date - a.date_of_admission) AS length_of_stay_days,
    i.provider_name,
    i.billing_amount
FROM admissions a
JOIN patients  p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
LIMIT 10;
