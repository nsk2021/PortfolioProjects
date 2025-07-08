-- Hospital Analytics Portfolio Project (Maven Analytics)
-- Client: Massachusetts General Hospital
-- Goal: Analyze patient encounters, costs, and behavior to support the annual performance report.

USE hospital_db;

----------------------------------------------------------------------------------------------------
-- ## OBJECTIVE 1: ENCOUNTERS OVERVIEW
-- This section analyzes trends in patient encounter volume, types, and durations.
----------------------------------------------------------------------------------------------------

-- a. How many total encounters occurred each year?

SELECT
    YEAR(start) AS encounter_year,
    COUNT(id) AS total_encounters
FROM
    encounters
GROUP BY
    encounter_year
ORDER BY
    encounter_year;

-- b. For each year, what percentage of all encounters belonged to each encounter class?

SELECT
    YEAR(start) AS encounter_year,
    ROUND(AVG(CASE WHEN encounterclass = 'ambulatory' THEN 1 ELSE 0 END) * 100, 1) AS pct_ambulatory,
    ROUND(AVG(CASE WHEN encounterclass = 'outpatient' THEN 1 ELSE 0 END) * 100, 1) AS pct_outpatient,
    ROUND(AVG(CASE WHEN encounterclass = 'wellness' THEN 1 ELSE 0 END) * 100, 1) AS pct_wellness,
    ROUND(AVG(CASE WHEN encounterclass = 'urgentcare' THEN 1 ELSE 0 END) * 100, 1) AS pct_urgentcare,
    ROUND(AVG(CASE WHEN encounterclass = 'emergency' THEN 1 ELSE 0 END) * 100, 1) AS pct_emergency,
    ROUND(AVG(CASE WHEN encounterclass = 'inpatient' THEN 1 ELSE 0 END) * 100, 1) AS pct_inpatient
FROM
    encounters
GROUP BY
    encounter_year
ORDER BY
    encounter_year;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?
-- Note: Using TIMESTAMPDIFF to calculate the difference in hours between the start and stop times.

SELECT
    ROUND(AVG(CASE WHEN TIMESTAMPDIFF(HOUR, start, stop) >= 24 THEN 1 ELSE 0 END) * 100, 1) AS pct_over_24_hours,
    ROUND(AVG(CASE WHEN TIMESTAMPDIFF(HOUR, start, stop) < 24 THEN 1 ELSE 0 END) * 100, 1) AS pct_under_24_hours
FROM
    encounters;

----------------------------------------------------------------------------------------------------
-- ## OBJECTIVE 2: COST & COVERAGE INSIGHTS
-- This section analyzes payer coverage, top procedures by cost and frequency, and claim costs.
----------------------------------------------------------------------------------------------------

-- a. What percentage of total encounters had zero payer coverage?

SELECT
    ROUND(AVG(CASE WHEN payer_coverage = 0 THEN 1 ELSE 0 END) * 100, 1) AS pct_zero_payer_coverage
FROM
    encounters;

-- b. What are the top 10 most frequent procedures performed and their average base cost?

SELECT
    code,
    description,
    COUNT(patient) AS num_procedures,
    AVG(base_cost) AS avg_base_cost
FROM
    procedures
GROUP BY
    code,
    description
ORDER BY
    num_procedures DESC
LIMIT 10;

-- c. What are the top 10 most expensive procedures by average base cost?

SELECT
    code,
    description,
    AVG(base_cost) AS avg_base_cost,
    COUNT(patient) AS num_procedures
FROM
    procedures
GROUP BY
    code,
    description
ORDER BY
    avg_base_cost DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?

SELECT
    p.name AS payer_name,
    AVG(e.total_claim_cost) AS avg_total_claim_cost
FROM
    payers AS p
LEFT JOIN
    encounters AS e ON p.id = e.payer
GROUP BY
    p.name
ORDER BY
    avg_total_claim_cost DESC;


----------------------------------------------------------------------------------------------------
-- ## OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
-- This section analyzes patient visit patterns, including quarterly admissions and readmissions.
----------------------------------------------------------------------------------------------------

-- a. How many unique patients were admitted each quarter over time?

SELECT
    YEAR(start) AS encounter_year,
    QUARTER(start) AS encounter_quarter,
    COUNT(DISTINCT patient) AS unique_patients
FROM
    encounters
GROUP BY
    encounter_year,
    encounter_quarter
ORDER BY
    encounter_year,
    encounter_quarter;

-- b. How many unique patients were readmitted within 30 days of a previous encounter?
-- Note: A CTE is used to identify the next encounter for each patient.

WITH EncounterGaps AS (
    SELECT
        patient,
        stop AS previous_encounter_end,
        LEAD(start) OVER (PARTITION BY patient ORDER BY start) AS next_encounter_start
    FROM
        encounters
)
SELECT
    COUNT(DISTINCT patient) AS readmitted_patients
FROM
    EncounterGaps
WHERE
    DATEDIFF(next_encounter_start, previous_encounter_end) < 30;

-- c. Which patients had the most readmissions within 30 days?

WITH EncounterGaps AS (
    SELECT
        patient,
        stop AS previous_encounter_end,
        LEAD(start) OVER (PARTITION BY patient ORDER BY start) AS next_encounter_start
    FROM
        encounters
)
SELECT
    patient,
    COUNT(*) AS num_readmissions
FROM
    EncounterGaps
WHERE
    DATEDIFF(next_encounter_start, previous_encounter_end) < 30
GROUP BY
    patient
ORDER BY
    num_readmissions DESC;