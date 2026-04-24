CREATE DATABASE ny_payroll;

-- Create a raw table to load the data as is from the CSV file, with all columns as text. 
-- This allows us to handle any data cleaning or transformation before inserting into the 
-- final table with appropriate data types.

-- The columns are:
-- Fiscal Year, Agency Name, Last Name, First Name, Mid Init,
-- Agency Start Date, Work Location Borough, Title Description,
-- Leave Status as of June 30, Base Salary, Pay Basis, Regular Hours,
-- Regular Gross Paid, OT Hours, Total OT Paid, Total Other Pay
-- IMPORTANT: all columns with monetary values have a $ sign in the original csv file, 
-- so we need to remove it before inserting the data into the table.
CREATE TABLE ny_payroll_raw (
    fiscal_year TEXT,
    agency_name TEXT,
    last_name TEXT,
    first_name TEXT,
    mid_init TEXT,
    agency_start_date TEXT,
    work_location_borough TEXT,
    title_description TEXT,
    leave_status_as_of_june_30 TEXT,
    base_salary TEXT,
    pay_basis TEXT,
    regular_hours TEXT,
    regular_gross_paid TEXT,
    ot_hours TEXT,
    total_ot_paid TEXT,
    total_other_pay TEXT
);

-- Read the csv file into the raw table. 
COPY ny_payroll_raw
FROM '/home/santiagodp/Documents/ML/NYC-payroll-data-analysis/Citywide_Payroll_Data__Fiscal_Year_.csv'
DELIMITER ',' CSV HEADER;

-- Convert the data from the raw table to the final table with appropriate data types,
-- removing the $ sign from the monetary values
CREATE TABLE ny_payroll(
    fiscal_year INTEGER,
    agency_name VARCHAR(255),
    last_name VARCHAR(255),
    first_name VARCHAR(255),
    mid_init CHAR(1),
    agency_start_date DATE,
    work_location_borough VARCHAR(255),
    title_description VARCHAR(255),
    leave_status_as_of_june_30 VARCHAR(255),
    base_salary DECIMAL(10, 2),
    pay_basis VARCHAR(255),
    regular_hours DECIMAL(10, 2),
    regular_gross_paid DECIMAL(10, 2),
    ot_hours DECIMAL(10, 2),
    total_ot_paid DECIMAL(10, 2),
    total_other_pay DECIMAL(10, 2)
);


INSERT INTO ny_payroll
SELECT
    fiscal_year::INTEGER,
    agency_name,
    last_name,
    first_name,
    NULLIF(mid_init, '')::CHAR(1),
    agency_start_date::DATE,
    work_location_borough,
    title_description,
    leave_status_as_of_june_30,
    REPLACE(base_salary, '$', '')::DECIMAL(10,2),
    pay_basis,
    regular_hours::DECIMAL(10,2),
    REPLACE(regular_gross_paid, '$', '')::DECIMAL(10,2),
    ot_hours::DECIMAL(10,2),
    REPLACE(total_ot_paid, '$', '')::DECIMAL(10,2),
    REPLACE(total_other_pay, '$', '')::DECIMAL(10,2)
FROM ny_payroll_raw;

CREATE INDEX idx_title ON ny_payroll(title_description);
CREATE INDEX idx_salary ON ny_payroll(base_salary);