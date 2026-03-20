# Healthcare SQL Analysis

## Project Overview

End-to-end SQL analysis of 50,000 hospital admissions built in PostgreSQL. This project covers the full data analyst workflow; from loading raw data and profiling data quality issues, through to schema design, normalisation and 25 analysis queries demonstrating a wide range of SQL skills.

The dataset contains patient admissions, medical conditions, billing amounts, insurance providers and treatment outcomes. The analysis surfaces insights relevant to healthcare operations, insurance performance and patient risk profiling; drawing on professional experience in health insurance and customer service.

---

## Tools & Technologies

- Database engine - PostgreSQL
- GUI client - TablePlus
- Data source - Kaggle

---

## Dataset

- **Source:** [Healthcare Dataset — Kaggle (prasad22)](https://www.kaggle.com/datasets/prasad22/healthcare-dataset)
- **Raw rows:** 55,500
- **Clean rows:** 50,000 (5,500 duplicates removed)
- **Final schema:** 3 normalised tables

---

## SQL Skills Demonstrated

- Data profiling and quality assessment
- Data cleaning (deduplication, type standardisation, outlier handling, negative value correction)
- Relational schema design and normalisation
- Multi-table JOINs across 3 tables
- Aggregations and GROUP BY
- Subqueries including derived table JOINs
- Common Table Expressions (CTEs)
- Window functions — RANK, ROW_NUMBER, NTILE, PERCENT_RANK, LAG, running totals, rolling averages

---

## Schema

```
patients                        admissions                         insurance
─────────────────               ──────────────────────────         ──────────────────────
patient_id  (PK)   ──────────►  admission_id  (PK)                 insurance_id  (PK)
name                            patient_id    (FK → patients) ◄──  admission_id  (FK)
age                             hospital_name                       provider_name
gender                          medical_condition                   billing_amount
blood_type                      date_of_admission
                                discharge_date
                                admission_type
                                room_number
                                doctor
                                medication
                                test_results
```

> A `hospitals` table was initially planned as a 4th entity. Profiling revealed 39,876 ostensibly distinct hospital names caused by shuffled and fragmented naming in the source data — making reliable normalisation impossible. Hospital name is retained as an attribute on `admissions`.

---

## Key Findings

1. **Admissions are evenly distributed across conditions** — all 6 conditions (Arthritis, Asthma, Cancer, Diabetes, Hypertension, Obesity) each account for approximately 16–17% of total admissions, consistent with a synthetically balanced dataset representing a chronic conditions patient population.

3. **Billing amounts are consistent across conditions** — average billing across all conditions sits in the $25,000–$26,000 range with no single condition significantly more expensive than others. This points to billing being driven more by length of stay and admission type than by condition alone.

4. **Admission type does not significantly affect length of stay** — Emergency, Elective and Urgent admissions all produce similar average stay durations, suggesting standardised treatment protocols across admission pathways.

5. **Test results are evenly spread** — Normal, Abnormal and Inconclusive results each represent roughly one third of outcomes across all conditions, with no condition showing a significantly elevated rate of abnormal results.

6. **Insurance providers handle near-equal claim volumes** — Aetna, Blue Cross, Cigna, Medicare and UnitedHealthcare each cover approximately 20% of admissions with no single provider dominating the market and average claim values are consistent across providers.

7. **~24% of patients have more than one admission** — approximately 9,765 patients across 40,235 unique patients were admitted more than once, which is consistent with a chronic conditions dataset where repeat care is expected.

8. **Patients aged 45–74 drive the majority of admissions and total billing** — consistent with the higher prevalence of chronic conditions in middle-aged and older populations. The 75+ band shows higher average billing per admission, reflecting the complexity of care in older patients.

9. **Billing gender gap is minimal** — average billing for the same condition differs by less than $500 between male and female patients across all six conditions.

---

## How to Reproduce

1. Download `healthcare_dataset.csv` from the Kaggle link above
2. Create a PostgreSQL database called `healthcare_analysis`
3. Run the scripts in the `sql/` folder in numbered order:

```
01_staging_table.sql    → creates staging table and loads CSV
02_data_cleaning.sql    → profiles and cleans the raw data
03_schema_creation.sql  → creates the 3 normalised tables
04_data_loading.sql     → populates tables from clean staging data
05_analysis_queries.sql → 20 portfolio analysis queries
```

---

## Repository Structure

```
healthcare-sql-analysis/
├── README.md
├── dataset/
│   └── healthcare_dataset.csv
├── sql-scripts/
│   ├── 01_staging_table.sql
│   ├── 02_data_cleaning.sql
│   ├── 03_schema_creation.sql
│   ├── 04_data_loading.sql
│   └── 05_analysis_queries.sql
└── docs/
    ├── data_cleaning_report.pdf
    └── analysis_queries.pdf
```

---

## Documentation

Full PDF documentation is available in the `docs/` folder:

- **data_cleaning_report.pdf** — detailed write-up of all profiling checks, issues found, fixes applied and schema design decisions
- **analysis_queries.pdf** — all 25 analysis queries with business questions and commentary
