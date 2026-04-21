-- Check all data
SELECT * FROM ny_payroll LIMIT 100;

-- Explore title_descriptions and work_location_borough for the 
-- most common agency (POLICE DEPARTMENT)
SELECT agency_name, work_location_borough, title_description 
FROM ny_payroll 
WHERE agency_name = 'POLICE DEPARTMENT'
LIMIT 1000;

-- Check the distinct agencies in the dataset and count the number of employees in each agency 
SELECT agency_name, COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY agency_name
ORDER BY employee_count DESC;

-- We will need to normalise the formatting of the agency names and group similar agencies.

-- First step: set everything in upper cases and trim whitespaces:
WITH step1 AS (
    SELECT
        agency_name,
        UPPER(TRIM(agency_name)) AS agency_clean
    FROM ny_payroll
),
-- Second step: replace DEPT and DEPT. for DEPARTMENT 
step2 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(agency_clean, '\bDEPT\.?\b', 'DEPARTMENT', 'g') AS agency_clean
    FROM step1
),
-- Third step: replace COMMUNITY BD for COMMUNITY BOARD.
step3 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(agency_clean, '\bCOMMUNITY BD\b', 'COMMUNITY BOARD', 'g') AS agency_clean
    FROM step2
),
-- Forth step: merge all <PLACE> COMMUNITY BOARD #<N> into a single <PLACE> COMMUNITY BOARD
step4 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(agency_clean, 'COMMUNITY BOARD #\d+', 'COMMUNITY BOARD', 'g') AS agency_clean
    FROM step3
),
step5 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(agency_clean, '\s+', ' ', 'g') AS agency_clean
    FROM step4
),
-- Step 6: singular/plural normalisation
step6 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(
            agency_clean,
            '\bBOARD OF CORRECTIONS\b',
            'BOARD OF CORRECTION',
            'g'
        ) AS agency_clean
    FROM step5
),
-- Step 7: fix STATEN ISLAND COMMUNITY BD pattern
step7 AS (
    SELECT
        agency_name,
        REGEXP_REPLACE(
            agency_clean,
            'STATEN ISLAND COMMUNITY BD #\d+',
            'STATEN ISLAND COMMUNITY BOARD',
            'g'
        ) AS agency_clean
    FROM step6
)
SELECT
    agency_clean,
    COUNT(*) AS employee_count
FROM step5
GROUP BY agency_clean
ORDER BY employee_count DESC;


-- Find the most common last_names in the dataset (potential for defining a "latino" variable) 
SELECT UPPER(TRIM(last_name)), COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY UPPER(TRIM(last_name))
ORDER BY employee_count DESC
LIMIT 50;


-- Now clean the title_description column. As a quick check, 
-- see how many distinct title_descriptions we have and how many
-- of them are unique after trimming, uppercasing the text and removing special characeters
SELECT 
    COUNT(DISTINCT title_description) AS original_distinct_count,
    COUNT(DISTINCT LOWER(TRIM(REPLACE(REPLACE(title_description, '*', ''), '?', '')))) AS normalized_distinct_count
    FROM ny_payroll
WHERE title_description IS NOT NULL;

-- We can see what has been cleaned
SELECT 
    title_description AS original,
    LOWER(TRIM(REPLACE(REPLACE(title_description, '*', ''), '?', ''))) AS cleaned,
    COUNT(*) AS count
FROM ny_payroll
WHERE title_description LIKE '%*%' OR title_description LIKE '%?%'
GROUP BY title_description, LOWER(TRIM(REPLACE(REPLACE(title_description, '*', ''), '?', '')))
ORDER BY count DESC;

-- We can see the title descriptions (these are way too many!)
SELECT 
    LOWER(TRIM(REPLACE(REPLACE(title_description, '*', ''), '?', ''))) AS title_description_clean,
    COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY title_description_clean
--ORDER BY title_description_clean DESC;
ORDER BY employee_count DESC
LIMIT 150;


-- Analyze the pay basis types
SELECT LOWER(TRIM(pay_basis)) AS pay_basis_clean, COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY pay_basis_clean
ORDER BY employee_count DESC;


-- Analyze the activity status
SELECT leave_status_as_of_june_30, COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY leave_status_as_of_june_30
ORDER BY employee_count DESC;


-- Check that there is nothing weird with the fiscal years
SELECT fiscal_year, COUNT(*) AS employee_count
FROM ny_payroll
GROUP BY fiscal_year
ORDER BY employee_count DESC;


-- Analyse the regular hours distribution (=0 is likely just for no yearly employees)
WITH clustered_data AS (
    SELECT 
        regular_hours,
        CASE 
            WHEN regular_hours = 0 THEN '0'
            WHEN regular_hours > 0 AND regular_hours < 300 THEN '0-300'
            WHEN regular_hours >= 300 AND regular_hours < 1000 THEN '300-1000'
            WHEN regular_hours >= 1000 AND regular_hours < 1400 THEN '1000-1400'
            WHEN regular_hours >= 1400 AND regular_hours < 1700 THEN '1400-1700'
            WHEN regular_hours >= 1700 AND regular_hours < 1850 THEN '1700-1850'
            WHEN regular_hours >= 1850 AND regular_hours < 2000 THEN '1850-2000'
            WHEN regular_hours >= 2000 AND regular_hours < 2100 THEN '2000-2100'
            ELSE 'Other'
        END AS range_label,
        CASE 
            WHEN regular_hours = 0 THEN 1
            WHEN regular_hours > 1 AND regular_hours < 300 THEN 2
            WHEN regular_hours >= 300 AND regular_hours < 1000 THEN 3
            WHEN regular_hours >= 1000 AND regular_hours < 1400 THEN 4
            WHEN regular_hours >= 1400 AND regular_hours < 1700 THEN 5
            WHEN regular_hours >= 1700 AND regular_hours < 1850 THEN 6
            WHEN regular_hours >= 1850 AND regular_hours < 2000 THEN 7
            WHEN regular_hours >= 2000 AND regular_hours < 2100 THEN 8
            ELSE 9
        END AS range_order
    FROM ny_payroll
    WHERE NOT (regular_hours < 0) 
)
SELECT 
    range_label,
    COUNT(*) AS count,
    MIN(regular_hours) AS min_value,
    MAX(regular_hours) AS max_value,
    ROUND(AVG(regular_hours), 2) AS avg_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM clustered_data
GROUP BY range_label, range_order
ORDER BY range_order;


-- Analyse total hours:
WITH base AS (
    SELECT
        CASE 
            WHEN COALESCE(regular_hours, 0) > 0 
            THEN COALESCE(ot_hours, 0)::FLOAT / regular_hours
            ELSE NULL
        END AS ot_ratio
    FROM ny_payroll
    WHERE leave_status_as_of_june_30 = 'ACTIVE'
      AND COALESCE(regular_hours, 0) > 300
)
SELECT
    CASE
        WHEN ot_ratio IS NULL THEN 'null'
        WHEN ot_ratio = 0 THEN '0'
        WHEN ot_ratio > 0 AND ot_ratio <= 0.1 THEN '0–0.1'
        WHEN ot_ratio <= 0.25 THEN '0.1–0.25'
        WHEN ot_ratio <= 0.5 THEN '0.25–0.5'
        ELSE '>0.5'
    END AS ot_ratio_bin,
    COUNT(*) AS n
FROM base
GROUP BY ot_ratio_bin
ORDER BY n DESC;


-- Explore the difference between regular and ot hours payment
SELECT
    regular_hours,
    ot_hours,
    regular_gross_paid,
    total_ot_paid,

    -- regular hourly rate
    CASE 
        WHEN COALESCE(regular_hours, 0) > 0 
        THEN regular_gross_paid / regular_hours
        ELSE NULL
    END AS regular_rate,

    -- overtime hourly rate
    CASE 
        WHEN COALESCE(ot_hours, 0) > 0 
        THEN total_ot_paid / ot_hours
        ELSE NULL
    END AS ot_rate,

    -- ratio between them
    CASE 
        WHEN COALESCE(regular_hours, 0) > 0 
         AND COALESCE(ot_hours, 0) > 0
        THEN (total_ot_paid / ot_hours) 
           / (regular_gross_paid / regular_hours)
        ELSE NULL
    END AS ot_premium_ratio

FROM ny_payroll
WHERE leave_status_as_of_june_30 = 'ACTIVE'
LIMIT 1000;



-- Convert the agency start date to a job antiquity in years in that fiscal year
-- Set to zero if they started after the start of the fiscal year
SELECT
    fiscal_year,
    agency_start_date,
    GREATEST(0, (fy_start - agency_start_date)/365.25) AS job_antiquity_years
FROM (
    SELECT
        fiscal_year,
        agency_start_date,
        MAKE_DATE(fiscal_year - 1, 7, 1) AS fy_start
    FROM ny_payroll
) base
LIMIT 1000;
