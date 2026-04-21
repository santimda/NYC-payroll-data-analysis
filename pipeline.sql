-- We plan to do the following: raw → filtered → cleaned → engineered → final_features

-- We start by filtering the data to only include active employees 
-- (leave_status_as_of_june_30 = 'ACTIVE') 
CREATE TABLE payroll_base AS
SELECT *
FROM ny_payroll
WHERE leave_status_as_of_june_30 = 'ACTIVE';


-- We now do the agency cleaning, which requires several intermediate steps
CREATE TABLE payroll_agency_cleaned AS
SELECT
    *,
    -- Apply a sequence of regex-based normalisations to agency_name
    REGEXP_REPLACE(  -- Step 5: singular/plural normalisation
        REGEXP_REPLACE(  -- Step 4: collapse multiple spaces
            REGEXP_REPLACE(  -- Step 3: normalise COMMUNITY BOARD patterns
                REGEXP_REPLACE(  -- Step 2: standardise DEPT → DEPARTMENT
                    UPPER(TRIM(agency_name)),  -- Step 1: basic formatting
                    '\bDEPT\.?\b',
                    'DEPARTMENT',
                    'g'
                ),
                -- Replace:
                --   COMMUNITY BD
                --   COMMUNITY BD #N
                --   COMMUNITY BOARD #N
                -- with:
                --   COMMUNITY BOARD
                'COMMUNITY (BD|BOARD) #?\d*',
                'COMMUNITY BOARD',
                'g'
            ),
            -- Replace multiple spaces with a single space
            '\s+',
            ' ',
            'g'
        ),
        -- Merge plural form into singular for consistency
        '\bBOARD OF CORRECTIONS\b',
        'BOARD OF CORRECTION',
        'g'
    )
    -- Final column name
    AS agency_clean
FROM ny_payroll;


-- Clean additional fields; the prorated annual pay basis has few entries so we remove it.
CREATE TABLE cleaned AS (
    SELECT
        fiscal_year,
        agency_clean,
        COALESCE(LOWER(TRIM(work_location_borough)), 'UNKNOWN') AS work_borough_clean,
        LOWER(TRIM(title_description)) AS title_description_clean,
        LOWER(TRIM(last_name)) AS last_name_clean,
        LOWER(TRIM(pay_basis)) AS pay_basis_clean,
        agency_start_date,
        regular_hours,
        ot_hours,
        regular_gross_paid,
        total_ot_paid,
        total_other_pay
    FROM payroll_agency_cleaned
    WHERE LOWER(TRIM(pay_basis)) != 'prorated annual'
);

-- inspection of cleaned data
SELECT * FROM cleaned
LIMIT 500;


-- Feature engineering
-- 1. Simplify names of columns
-- 2. Create a tenure feature based on how long the person had been working at the agency 
-- as of June 30 of the fiscal year; if they started later, this is set to zero.
-- 3. Compute total hours worked as the sum of regular hours and overtime hours, 
-- and compute the ot_ratio (as ot hours are generally paid more).
-- 4. Calculate the total income as the sum of regular gross paid, total OT paid 
-- and total other pay.
CREATE TABLE features AS (
    SELECT
        fiscal_year,
        agency_clean AS agency_name,
        work_borough_clean AS work_borough,
        last_name_clean AS last_name,
        title_description_clean AS title_description,
        pay_basis_clean AS pay_basis,

        -- tenure (continuous)
        GREATEST(
            0,
            (MAKE_DATE(fiscal_year - 1, 7, 1) - agency_start_date) / 365.25
        ) AS job_antiquity_years,

        -- hour information
        regular_hours,
        ot_hours,
        -- total hours
        COALESCE(regular_hours, 0) + COALESCE(ot_hours, 0) AS total_hours,
        -- overtime intensity
        CASE 
            WHEN COALESCE(regular_hours, 0) > 0 
            THEN COALESCE(ot_hours, 0)::FLOAT / regular_hours
            ELSE NULL
        END AS ot_ratio,

        regular_gross_paid,
        total_ot_paid,
        total_other_pay,

        -- total income (handle NULLs!)
        COALESCE(regular_gross_paid, 0)
        + COALESCE(total_ot_paid, 0)
        + COALESCE(total_other_pay, 0)
        AS total_income

    FROM cleaned
    WHERE COALESCE(regular_hours, 0) > 300
);

-- Filter extreme values: define a minimum salary of 600 ($20 per hour x 300 hr), 
-- and a maximum of $175k (to remove extreme outliers) 
-- Also remove entries where total_other_pay is more than 30% of total income
DROP TABLE IF EXISTS final_table;
CREATE TABLE final_table AS (
    SELECT *
    FROM features
    WHERE
        -- remove extreme outliers (adjust thresholds after inspection)
        (total_income BETWEEN 6000 AND 175000) 
        AND (total_other_pay <= 0.3 * total_income)
);

-- final inspection
SELECT * FROM final_table
LIMIT 1000;


-- Save the table to a CSV file for use in the ML pipeline
COPY (
    SELECT * FROM final_table
) TO '/home/santiagodp/Documents/ML/NY_salaries/cleaned_payroll.csv'
CSV HEADER;
-- I ran this from the terminal with: psql -U santimda -d ny_payroll -h localhost 
-- and using \COPY