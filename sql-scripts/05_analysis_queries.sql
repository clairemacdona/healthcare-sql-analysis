/*
============================================================
05 — ANALYSIS QUERIES

This file contains 25 SQL analysis queries organised across
5 sections, written against a cleaned and normalised
PostgreSQL database of 50,000 hospital admissions.

Each query is framed around a real-world business question
relevant to healthcare operations, insurance performance
and patient risk profiling

SECTIONS:
1. Aggregations & GROUP BY  (Queries 1.1 – 1.8)
2. JOINs                    (Queries 2.1 – 2.5)
3. Subqueries & CTEs        (Queries 3.1 – 3.5)
4. Window Functions         (Queries 4.1 – 4.5)
5. Combined Analysis   		(Queries 5.1 – 5.2)
============================================================
*/


/*
============================================================
SECTION 1: AGGREGATIONS & GROUP BY
============================================================
*/

-- 1.1 Total admissions per medical condition
-- Question: Which conditions drive the most hospital admissions?

SELECT
    medical_condition,
    COUNT(*) AS total_admissions,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM admissions
GROUP BY medical_condition
ORDER BY total_admissions DESC;

-- 1.2 Average billing amount per medical condition
-- Question: Which conditions are the most expensive to treat?

SELECT
    medical_condition,
	COUNT(*) AS total_admissions,
    ROUND(AVG(i.billing_amount), 2) AS avg_billing,
    ROUND(MIN(i.billing_amount), 2) AS min_billing,
    ROUND(MAX(i.billing_amount), 2) AS max_billing
FROM admissions a
JOIN insurance i ON i.admission_id = a.admission_id
GROUP BY medical_condition
ORDER BY avg_billing DESC;

-- 1.3 Admissions and revenue by insurance provider
-- Question: Which insurer handles the most claims and generates the most revenue?

SELECT
    i.provider_name,
    COUNT(*) AS total_claims,
    ROUND(SUM(i.billing_amount), 2) AS total_revenue,
    ROUND(AVG(i.billing_amount), 2) AS avg_claim_value
FROM insurance i
JOIN admissions a ON a.admission_id = i.admission_id
GROUP BY i.provider_name
ORDER BY total_revenue DESC;

-- 1.4 Average length of stay per admission type
-- Question: Do emergency admissions result in longer stays than elective ones?

SELECT
    admission_type,
    COUNT(*) AS total_admissions,
    ROUND(AVG(discharge_date - date_of_admission), 1) AS avg_stay_days,
    MIN(discharge_date - date_of_admission) AS min_stay_days,
    MAX(discharge_date - date_of_admission) AS max_stay_days
FROM admissions
GROUP BY admission_type
ORDER BY avg_stay_days DESC;

-- 1.5 Admissions by year and month
-- Question: Are there seasonal trends in hospital admissions?

SELECT
    EXTRACT(YEAR  FROM date_of_admission) AS admission_year,
    EXTRACT(MONTH FROM date_of_admission) AS admission_month,
    COUNT(*) AS total_admissions
FROM admissions
GROUP BY admission_year, admission_month
ORDER BY admission_year, admission_month;

-- 1.6 Test result distribution per medical condition
-- Question: Which conditions most frequently produce abnormal test results?

SELECT
    medical_condition,
    test_results,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER
            (PARTITION BY medical_condition), 2) AS pct_within_condition
FROM admissions
GROUP BY medical_condition, test_results
ORDER BY medical_condition, total DESC;

-- 1.7 Blood type distribution across patients
-- Question: What is the blood type makeup of the patient population?

SELECT
    blood_type,
    COUNT(DISTINCT p.patient_id) AS total_patients,
    ROUND(COUNT(DISTINCT p.patient_id) * 100.0
          / SUM(COUNT(DISTINCT p.patient_id)) OVER (), 2) AS pct_of_patients
FROM patients p
GROUP BY p.blood_type
ORDER BY total_patients DESC;

-- 1.8 Average billing by gender and medical condition
-- Question: Is there a billing difference between genders for the same condition?

SELECT
    p.gender,
    a.medical_condition,
    COUNT(*) AS admissions,
    ROUND(AVG(i.billing_amount), 2) AS avg_billing
FROM admissions a
JOIN patients  p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
GROUP BY p.gender, a.medical_condition
ORDER BY a.medical_condition, p.gender;


/*
============================================================
SECTION 2: JOINS
============================================================
*/

-- 2.1 Full patient admission detail
-- Question: Produce a complete view of each admission joining
-- all three tables.

SELECT
    p.patient_id,
    p.name,
    p.age,
    p.gender,
    p.blood_type,
    a.admission_id,
    a.medical_condition,
    a.admission_type,
    a.date_of_admission,
    a.discharge_date,
    (a.discharge_date - a.date_of_admission) AS length_of_stay_days,
    a.test_results,
    a.medication,
    a.hospital_name,
    i.provider_name,
    i.billing_amount
FROM admissions a
JOIN patients  p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
ORDER BY a.date_of_admission DESC
LIMIT 100;

-- 2.2 High-cost admissions with patient detail
-- Question: Who are the patients with billing above $50,000
-- and what conditions do they have?

SELECT
    p.name,
    p.age,
    p.gender,
    a.medical_condition,
    a.admission_type,
    a.hospital_name,
    i.provider_name,
    i.billing_amount
FROM admissions a
JOIN patients  p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
WHERE i.billing_amount > 50000
ORDER BY i.billing_amount DESC;

-- 2.3 Patients with abnormal test results and their insurer
-- Question: Which insurance providers are covering the most
-- abnormal-result admissions?

SELECT
    i.provider_name,
    a.medical_condition,
    COUNT(*) AS abnormal_admissions,
    ROUND(AVG(i.billing_amount), 2) AS avg_billing
FROM admissions a
JOIN insurance i ON i.admission_id = a.admission_id
WHERE a.test_results = 'Abnormal'
GROUP BY i.provider_name, a.medical_condition
ORDER BY abnormal_admissions DESC;

-- 2.4 Patients admitted more than once
-- Question: Which patients are repeat admissions and what
-- conditions are they returning for?

SELECT
    p.name,
    p.age,
    p.gender,
    a.medical_condition,
    a.date_of_admission,
    a.admission_type,
    i.billing_amount
FROM admissions a
JOIN patients  p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
WHERE p.patient_id IN (
    SELECT patient_id
    FROM admissions
    GROUP BY patient_id
    HAVING COUNT(*) > 1
)
ORDER BY p.name, a.date_of_admission;

-- 2.5 Medication usage by medical condition
-- Question: What medications are most commonly prescribed
-- per condition?

SELECT
    a.medical_condition,
    a.medication,
    COUNT(*) AS times_prescribed
FROM admissions a
JOIN patients p ON p.patient_id = a.patient_id
GROUP BY a.medical_condition, a.medication
ORDER BY a.medical_condition, times_prescribed DESC;


/*
============================================================
SECTION 3: SUBQUERIES & CTEs
============================================================
*/

-- 3.1 Patients billed above average for their condition
-- Question: Which patients were charged more than the average
-- for their specific medical condition?

SELECT
    p.name,
    p.age,
    a.medical_condition,
    i.billing_amount,
    ROUND(avg_by_condition.avg_billing, 2) AS condition_avg,
    ROUND(i.billing_amount - avg_by_condition.avg_billing, 2) AS above_avg_by
FROM admissions a
JOIN patients p ON p.patient_id   = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
JOIN (
    SELECT
        a2.medical_condition,
        AVG(i2.billing_amount) AS avg_billing
    FROM admissions a2
    JOIN insurance i2 ON i2.admission_id = a2.admission_id
    GROUP BY a2.medical_condition
) AS avg_by_condition
  ON avg_by_condition.medical_condition = a.medical_condition
WHERE i.billing_amount > avg_by_condition.avg_billing
ORDER BY above_avg_by DESC
LIMIT 50;

-- 3.2 Monthly admissions trend using CTE
-- Question: How have admissions trended month over month?

WITH monthly_admissions AS (
    SELECT
        DATE_TRUNC('month', date_of_admission) AS admission_month,
        COUNT(*) AS total_admissions
    FROM admissions
    GROUP BY DATE_TRUNC('month', date_of_admission)
),
with_change AS (
    SELECT
        admission_month,
        total_admissions,
        LAG(total_admissions) OVER
            (ORDER BY admission_month) AS prev_month_admissions
    FROM monthly_admissions
)
SELECT
    TO_CHAR(admission_month, 'Mon YYYY') AS month,
    total_admissions,
    prev_month_admissions,
    total_admissions
        - COALESCE(prev_month_admissions, 0) AS month_on_month_change
FROM with_change
ORDER BY admission_month;


-- 3.3 Top earning insurer per medical condition (CTE)
-- Question: Which insurer dominates billing for each condition?

WITH insurer_condition_revenue AS (
    SELECT
        i.provider_name,
        a.medical_condition,
        ROUND(SUM(i.billing_amount), 2) AS total_revenue,
        COUNT(*) AS total_claims
    FROM insurance i
    JOIN admissions a ON a.admission_id = i.admission_id
    GROUP BY i.provider_name, a.medical_condition
),
ranked AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY medical_condition
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM insurer_condition_revenue
)
SELECT
    medical_condition,
    provider_name,
    total_revenue,
    total_claims,
    revenue_rank
FROM ranked
WHERE revenue_rank = 1
ORDER BY medical_condition;


-- 3.4 Patients with longest stays vs condition average (CTE)
-- Question: Which patients stayed significantly longer than 
-- average for their condition?

WITH condition_avg_stay AS (
    SELECT
        medical_condition,
        ROUND(AVG(discharge_date - date_of_admission), 1) AS avg_stay_days
    FROM admissions
    GROUP BY medical_condition
),
patient_stays AS (
    SELECT
        p.name,
        p.age,
        a.medical_condition,
        a.admission_type,
        (a.discharge_date - a.date_of_admission) AS stay_days,
        c.avg_stay_days
    FROM admissions a
    JOIN patients p ON p.patient_id = a.patient_id
    JOIN condition_avg_stay c ON c.medical_condition = a.medical_condition
)
SELECT
    name,
    age,
    medical_condition,
    admission_type,
    stay_days,
    avg_stay_days,
    ROUND(stay_days - avg_stay_days, 1) AS days_above_avg
FROM patient_stays
WHERE stay_days > avg_stay_days
ORDER BY days_above_avg DESC
LIMIT 30;

-- 3.5 Admission risk profile by age band (CTE)
-- Question: How do admission patterns and billing vary across
-- patient age groups?

WITH age_banded AS (
    SELECT
        p.patient_id,
        a.admission_id,
        a.medical_condition,
        a.admission_type,
        i.billing_amount,
        CASE
            WHEN p.age BETWEEN 13 AND 17 THEN '13–17'
            WHEN p.age BETWEEN 18 AND 29 THEN '18–29'
            WHEN p.age BETWEEN 30 AND 44 THEN '30–44'
            WHEN p.age BETWEEN 45 AND 59 THEN '45–59'
            WHEN p.age BETWEEN 60 AND 74 THEN '60–74'
            ELSE '75+'
        END AS age_band
    FROM patients p
    JOIN admissions a ON a.patient_id = p.patient_id
    JOIN insurance i ON i.admission_id = a.admission_id
)
SELECT
    age_band,
    COUNT(*) AS total_admissions,
    COUNT(DISTINCT patient_id) AS unique_patients,
    ROUND(AVG(billing_amount), 2) AS avg_billing,
    ROUND(SUM(billing_amount), 2) AS total_billing
FROM age_banded
GROUP BY age_band
ORDER BY age_band;


/*
============================================================
SECTION 4: WINDOW FUNCTIONS
============================================================
*/

-- 4.1 Rank insurers by total revenue per year
-- Question: How does each insurer's revenue ranking change
-- from year to year?

SELECT
    EXTRACT(YEAR FROM a.date_of_admission) AS year,
    i.provider_name,
    ROUND(SUM(i.billing_amount), 2) AS total_revenue,
    RANK() OVER (
        PARTITION BY EXTRACT(YEAR FROM a.date_of_admission)
        ORDER BY SUM(i.billing_amount) DESC
    ) AS revenue_rank
FROM insurance i
JOIN admissions a ON a.admission_id = i.admission_id
GROUP BY year, i.provider_name
ORDER BY year, revenue_rank;


-- 4.2 Most recent admission per patient (ROW_NUMBER)
-- Question: What was each patient's most recent admission
-- and how much did it cost?

WITH ranked_admissions AS (
    SELECT
        p.name,
        p.age,
        p.gender,
        a.medical_condition,
        a.date_of_admission,
        a.admission_type,
        i.billing_amount,
        ROW_NUMBER() OVER (
            PARTITION BY p.patient_id
            ORDER BY a.date_of_admission DESC
        ) AS rn
    FROM patients  p
    JOIN admissions a ON a.patient_id   = p.patient_id
    JOIN insurance i ON i.admission_id = a.admission_id
)
SELECT
    name,
    age,
    gender,
    medical_condition,
    date_of_admission AS most_recent_admission,
    admission_type,
    billing_amount
FROM ranked_admissions
WHERE rn = 1
ORDER BY date_of_admission DESC
LIMIT 50;


-- 4.3 Billing percentile rank per condition
-- Question: Where does each admission's billing fall within
-- the distribution for its condition?

SELECT
    p.name,
    a.medical_condition,
    i.billing_amount,
    ROUND(CAST(PERCENT_RANK() OVER (
        PARTITION BY a.medical_condition
        ORDER BY i.billing_amount
    ) * 100 AS NUMERIC), 1) AS billing_percentile,
    NTILE(4) OVER (
        PARTITION BY a.medical_condition
        ORDER BY i.billing_amount
    ) AS billing_quartile
FROM admissions a
JOIN patients p ON p.patient_id = a.patient_id
JOIN insurance i ON i.admission_id = a.admission_id
ORDER BY a.medical_condition, billing_percentile DESC
LIMIT 100;


-- 4.4 Condition ranking by avg billing within admission type
-- Question: Within each admission type, which condition 
-- is the most expensive?

WITH avg_billing_by_type AS (
    SELECT
        a.admission_type,
        a.medical_condition,
        ROUND(AVG(i.billing_amount), 2) AS avg_billing
    FROM admissions a
    JOIN insurance i ON i.admission_id = a.admission_id
    GROUP BY a.admission_type, a.medical_condition
)
SELECT
    admission_type,
    medical_condition,
    avg_billing,
    RANK() OVER (
        PARTITION BY admission_type
        ORDER BY avg_billing DESC
    ) AS cost_rank
FROM avg_billing_by_type
ORDER BY admission_type, cost_rank;


-- 4.5 Patient admission frequency tier
-- Question: Segment patients into frequency tiers based
-- on how often they are admitted.

WITH patient_admission_counts AS (
    SELECT
        p.patient_id,
        p.name,
        p.age,
        p.gender,
        COUNT(a.admission_id) AS total_admissions
    FROM patients p
    JOIN admissions a ON a.patient_id = p.patient_id
    GROUP BY p.patient_id, p.name, p.age, p.gender
)
SELECT
    name,
    age,
    gender,
    total_admissions,
    NTILE(4) OVER (ORDER BY total_admissions DESC) AS frequency_tier,
    CASE NTILE(4) OVER (ORDER BY total_admissions DESC)
        WHEN 1 THEN 'High Frequency'
        WHEN 2 THEN 'Medium-High'
        WHEN 3 THEN 'Medium-Low'
        WHEN 4 THEN 'Low Frequency'
    END AS tier_label
FROM patient_admission_counts
ORDER BY total_admissions DESC
LIMIT 50;


/*
============================================================
SECTION 5: COMBINED ANALYSIS
============================================================
*/

-- 5.1 Full patient risk summary
-- Question: Produce an executive-level summary of each patient
-- combining admissions, billing, stay length and test outcomes.

WITH patient_summary AS (
    SELECT
        p.patient_id,
        p.name,
        p.age,
        p.gender,
        p.blood_type,
        COUNT(a.admission_id) AS total_admissions,
        ROUND(SUM(i.billing_amount), 2) AS lifetime_billing,
        ROUND(AVG(i.billing_amount), 2) AS avg_billing_per_admission,
        ROUND(AVG(a.discharge_date - a.date_of_admission), 1) AS avg_stay_days,
        SUM(CASE WHEN a.test_results = 'Abnormal'
            THEN 1 ELSE 0 END) AS abnormal_results,
        SUM(CASE WHEN a.admission_type = 'Emergency'
            THEN 1 ELSE 0 END) AS emergency_admissions,
        MAX(a.date_of_admission) AS most_recent_admission
    FROM patients p
    JOIN admissions a ON a.patient_id = p.patient_id
    JOIN insurance i ON i.admission_id = a.admission_id
    GROUP BY p.patient_id, p.name, p.age, p.gender, p.blood_type
)
SELECT
    name,
    age,
    gender,
    blood_type,
    total_admissions,
    lifetime_billing,
    avg_billing_per_admission,
    avg_stay_days,
    abnormal_results,
    emergency_admissions,
    most_recent_admission,
    RANK() OVER (ORDER BY lifetime_billing DESC) AS billing_rank,
    NTILE(5) OVER (ORDER BY lifetime_billing DESC) AS billing_quintile
FROM patient_summary
ORDER BY lifetime_billing DESC
LIMIT 100;


-- 5.2 Insurer performance
-- Question: Rank each insurer across multiple dimensions — claims
-- volume, revenue, avg billing and proportion of high-cost claims.

WITH insurer_stats AS (
    SELECT
        i.provider_name,
        COUNT(*) AS total_claims,
        ROUND(SUM(i.billing_amount), 2) AS total_revenue,
        ROUND(AVG(i.billing_amount), 2) AS avg_claim,
        ROUND(MAX(i.billing_amount), 2) AS max_claim,
        SUM(CASE WHEN i.billing_amount > 40000
            THEN 1 ELSE 0 END) AS high_cost_claims,
        SUM(CASE WHEN a.test_results = 'Abnormal'
            THEN 1 ELSE 0 END) AS abnormal_results
    FROM insurance i
    JOIN admissions a ON a.admission_id = i.admission_id
    GROUP BY i.provider_name
)
SELECT
    provider_name,
    total_claims,
    total_revenue,
    avg_claim,
    max_claim,
    high_cost_claims,
    ROUND(high_cost_claims * 100.0 / total_claims, 2) AS pct_high_cost,
    abnormal_results,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY total_claims DESC) AS volume_rank,
    RANK() OVER (ORDER BY avg_claim DESC) AS avg_cost_rank
FROM insurer_stats
ORDER BY revenue_rank;
