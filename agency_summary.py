import pandas as pd

# Load data
df = pd.read_csv("/home/santiagodp/Documents/ML/NY_salaries/cleaned_payroll.csv")

# Convert total_income to thousands of dollars (k$)
df['income_k'] = df['regular_gross_paid'] / 1000

# =========================================================
# Filter by hours worked
# =========================================================

min_hours = 1823
max_hours = 1833

df = df[(df['total_hours'] >= min_hours) & (df['total_hours'] <= max_hours)]

print(f"After hours filter ({min_hours}-{max_hours} hours): {len(df):,} rows")

# =========================================================
# Filter agencies with at least n_emp employees
# =========================================================

# First, identify agencies with at least 500 employees in ANY fiscal year
n_emp = 750
agency_counts = df.groupby(['fiscal_year', 'agency_name']).size().reset_index(name='n_employees')
agencies_to_keep = agency_counts.groupby('agency_name')['n_employees'].max()
agencies_to_keep = agencies_to_keep[agencies_to_keep >= n_emp].index

# Filter main dataframe
df_filtered = df[df['agency_name'].isin(agencies_to_keep)]

print(f"Original rows (after hours filter): {len(df):,}")
print(f"Filtered rows (after agency filter): {len(df_filtered):,}")
print(f"Agencies kept: {len(agencies_to_keep)}")

# =========================================================
# Create agency summary
# =========================================================

agency_summary = (
    df_filtered
    .groupby(['fiscal_year', 'agency_name'])
    .agg(
        n_employees=('agency_name', 'size'),
        mean_salary_k=('income_k', 'mean'),
        median_salary_k=('income_k', 'median')
    )
    .reset_index()
)

# =========================================================
# Export to CSV
# =========================================================

output_path = "agency_summary.csv"
agency_summary.to_csv(output_path, index=False)

print(f"\n✅ Exported to: {output_path}")
print(f"   Shape: {agency_summary.shape}")
print(f"   Years: {sorted(agency_summary['fiscal_year'].unique())}")
print(f"   Agencies: {agency_summary['agency_name'].nunique()}")
print(agency_summary.groupby('fiscal_year')['agency_name'].nunique()) #--> check that it is the same number each year