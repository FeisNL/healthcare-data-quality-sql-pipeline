# 1. Import the required libraries
from pathlib import Path
import pandas as pd


# 2. Define the path to the CSV file we want to load
SUMMARY_PATH = Path("Data/Processed/large_dq_summary.csv")


# 3. Print a header to indicate the validation process is starting
print("\n=== LARGE DATASET VALIDATION ===")


# 4. Load the CSV file into a pandas DataFrame
#    From this point on, 'summary_df' contains the entire SQL summary table
summary_df = pd.read_csv(SUMMARY_PATH)


# 5. Print basic information about the DataFrame
print("\nSummary shape:")
print(summary_df.shape)  # number of rows and columns

print("\nSummary columns:")
print(summary_df.columns.tolist())  # list of column names

print("\nSummary preview:")
print(summary_df.to_string(index=False))  # print the full table without truncation


# 6. Define the expected values for each check
#    These represent the correct values we expect from the SQL export
expected_counts = {
    "departments_row_count": 8,
    "providers_row_count": 50,
    "patients_row_count": 1000,
    "admissions_row_count": 2000,
    "lab_results_row_count": 5000,
    "duplicate_patient_id_rows": 2,
    "missing_patient_id": 1,
    "unknown_patient_id_admissions": 12,
    "invalid_admission_dates": 10,
    "negative_total_cost": 11,
    "extreme_total_cost": 9,
    "unknown_department_id_admissions": 6,
    "unknown_provider_id_admissions": 7,
    "unknown_admission_id_lab_results": 15,
    "unknown_patient_id_lab_results": 25,
    "negative_lab_values": 20,
    "extreme_lab_values": 7,
    "future_lab_dates": 10,
}


# 7. Print a header for the validation section
print("\n=== EXPECTED VS ACTUAL CHECKS ===")


# 8. Define a helper function that compares expected vs actual values
#    and prints PASS or FAIL for each check
def print_check(check_name, expected, actual):
    # Compare expected and actual values
    status = "PASS" if expected == actual else "FAIL"

    # Print the result of this validation check
    print(f"{status}: {check_name} - expected {expected}, found {actual}")


# 9. Loop through all checks defined in expected_counts
#    The loop iterates over the dictionary, NOT over the DataFrame
for check_name, expected_count in expected_counts.items():

    # 9a. Filter the DataFrame to find the row matching this check_name
    #     This creates a small DataFrame (matching_rows) with either:
    #     - exactly one row (normal case)
    #     - zero rows (SQL export is missing this check)
    matching_rows = summary_df[summary_df["check_name"] == check_name]

    # 9b. If no row is found, the SQL export is incomplete → FAIL
    if matching_rows.empty:
        print(f"FAIL: {check_name} - missing from SQL summary export")
        continue  # skip to the next check in the dictionary

    # 9c. Extract the actual_count value from the matching row
    #     matching_rows contains exactly one row, so .iloc[0] safely retrieves it
    actual_count = int(matching_rows["actual_count"].iloc[0])

    # 9d. Call the helper function to compare expected vs actual
    print_check(
        check_name=check_name,
        expected=expected_count,
        actual=actual_count,
    )