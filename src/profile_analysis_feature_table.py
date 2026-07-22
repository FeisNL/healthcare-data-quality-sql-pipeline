# ============================================================
# Script: profile_analysis_feature_table.py
# Purpose:
#   Profile and validate the exported physical analysis feature table
#   before using it for further analysis.
#
# Input file:
#   Data/Processed/analysis_feature_admission_large_v2.csv
#
# Original SQL source:
#   PostgreSQL table: analysis_feature_admission_large_v2
#
# Why this script exists:
#   We already validated the physical table in SQL.
#   However, after exporting the table to CSV, we also need to check
#   whether the exported file still contains the expected data.
#
#   This script checks:
#   - whether the CSV has the expected number of rows
#   - whether each admission still appears once
#   - whether required IDs are complete
#   - whether lab result totals are preserved
#   - whether numeric columns have logical ranges
#   - whether category columns have understandable distributions
#   - which columns may be leakage risks before future ML work
#
# Job-ready relevance:
#   This shows that we do not blindly trust an exported dataset.
#   We validate the dataset again before using it for analysis or ML.
# ============================================================


# ============================================================
# 1. Imports
# ============================================================

# pathlib is used to build file paths in a safer way.
# This avoids hardcoding Windows-only paths such as:
# C:\Users\fbent\...
#
# Path(__file__) means: the location of this Python script.
# From there, we navigate to the project root.
from pathlib import Path

# pandas is the main Python library we use here for data analysis.
# We use it to load the CSV into a DataFrame and inspect the data.
#
# A DataFrame is basically a table in Python:
# - rows
# - columns
# - values
import pandas as pd


# ============================================================
# 2. Configuration
# ============================================================
# This section stores values that we expect to be true.
#
# Why do we put them at the top?
# Because expected values should be easy to find and change.
# This makes the script more maintainable.


# PROJECT_ROOT points to the main project folder.
#
# __file__ = this script file:
#   src/profile_analysis_feature_table.py
#
# Path(__file__).resolve() gives the full absolute path to this script.
#
# .parents[1] means:
#   go two levels up from this file:
#
#   src/profile_analysis_feature_table.py
#   parent 0 = src/
#   parent 1 = project root/
PROJECT_ROOT = Path(__file__).resolve().parents[1]


# DATA_PATH points to the CSV file that was exported from DBeaver.
#
# We build the path step by step:
# project root → Data → Processed → file name
#
# This is better than typing one long hardcoded path.
DATA_PATH = (
    PROJECT_ROOT
    / "Data"
    / "Processed"
    / "analysis_feature_admission_large_v2.csv"
)


# These expected values come from the SQL validation.
#
# If the CSV export worked correctly, pandas should see the same values.
EXPECTED_ROW_COUNT = 1635
EXPECTED_LAB_RESULT_TOTAL = 4079


# These ID columns are required.
#
# If one of these is missing, the row becomes hard to trust:
# - admission_id identifies the admission
# - patient_id identifies the patient
# - department_id identifies the department
# - provider_id identifies the provider
REQUIRED_ID_COLUMNS = [
    "admission_id",
    "patient_id",
    "department_id",
    "provider_id",
]


# These numeric columns will be checked for min, max, mean and median.
#
# Numeric range checks help detect suspicious values.
# Example:
# - negative age would be impossible
# - lab_result_count below 0 would be impossible
# - very high values may need further investigation
NUMERIC_COLUMNS = [
    "age_at_admission",
    "lab_result_count",
    "distinct_test_name_count",
]


# These categorical columns will be checked with value_counts().
#
# Category distribution checks help us understand the dataset.
# Example:
# - Are some categories dominant?
# - Are there unexpected categories?
# - Are there missing values?
CATEGORY_COLUMNS = [
    "gender",
    "admission_type",
    "diagnosis_group",
    "department_name",
]


# These columns are flags or warning-like columns.
#
# We inspect them separately because they tell us about data quality or
# business rule warnings.
WARNING_COLUMNS = [
    "provider_department_mismatch_warning",
    "has_lab_results",
]


# These columns are not automatically wrong.
#
# However, they may become leakage risks depending on the ML target and
# prediction moment.
#
# Example:
# If we want to predict something at admission start, then lab results
# collected later during the admission may leak future information.
LEAKAGE_RISK_COLUMNS = [
    "lab_result_count",
    "distinct_test_name_count",
    "first_lab_result_date",
    "latest_lab_result_date",
    "has_lab_results",
    "diagnosis_group",
]


# ============================================================
# 3. Helper functions
# ============================================================
# Helper functions prevent repeated code.
#
# Instead of writing the same logic many times, we define it once and reuse it.


def print_section(title: str) -> None:
    """
    Print a clear section header in the terminal output.

    Input:
        title: text that describes the current section

    Output:
        Nothing is returned.
        The function only prints text to the terminal.

    Why this is useful:
        The script output becomes easier to read.
    """
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)


def missing_count(series: pd.Series) -> int:
    """
    Count missing values in one pandas column.

    Input:
        series: one pandas column

    Output:
        an integer with the number of missing values

    Why not only use series.isna().sum()?
        Because CSV files can contain different types of missing values:
        - real pandas NaN values
        - empty strings: ""
        - strings with only spaces: "   "

    This function counts both real missing values and empty text values.
    """

    # series.isna() returns True for real pandas missing values.
    #
    # series.astype(str) converts all values to text.
    # This allows us to use string operations safely.
    #
    # .str.strip() removes spaces from the beginning and end.
    #
    # .eq("") checks whether the cleaned text is empty.
    #
    # The | symbol means OR.
    # So we count a value as missing if:
    # - it is NaN
    # OR
    # - it is empty text after removing spaces.
    missing_mask = series.isna() | series.astype(str).str.strip().eq("")

    # .sum() counts True values because pandas treats True as 1 and False as 0.
    #
    # int(...) converts the result to a normal Python integer.
    return int(missing_mask.sum())


def add_check(
    results: list[dict],
    check_name: str,
    actual_value,
    expected_value,
    passed: bool,
) -> None:
    """
    Add one validation check to the validation summary.

    Input:
        results:
            a list where every validation result is stored

        check_name:
            name of the validation check

        actual_value:
            value found in the data

        expected_value:
            value we expected based on SQL validation or business rules

        passed:
            True if the check passed, False if it failed

    Output:
        Nothing is returned.
        The function updates the results list.

    Why this is useful:
        At the end of the script we can convert all checks into one
        clean PASS/FAIL summary table.
    """

    # A dictionary stores one validation result.
    # Each key becomes a column in the final summary DataFrame.
    results.append(
        {
            "check_name": check_name,
            "actual_value": actual_value,
            "expected_value": expected_value,
            "status": "PASS" if passed else "FAIL",
        }
    )


# ============================================================
# 4. Load data
# ============================================================

print_section("1. Load CSV")

# Print the file path so we can visually confirm that Python reads the
# correct file.
print(f"Reading file: {DATA_PATH}")

# pd.read_csv() loads the CSV file into a pandas DataFrame.
#
# df is short for DataFrame.
# From now on, df represents our exported analysis table in Python.
df = pd.read_csv(DATA_PATH)

print("CSV loaded successfully.")


# If pandas detects only one column, this often means the separator is wrong.
#
# Example:
# - file uses semicolon ;
# - pandas expects comma ,
#
# In that case pandas may read the entire row as one big text column.
if len(df.columns) == 1:
    print(
        "\nWARNING: Only one column was detected. "
        "This may mean the CSV separator is wrong. "
        "Check whether the file uses comma or semicolon separators."
    )


# ============================================================
# 5. Basic structure
# ============================================================

print_section("2. Basic structure")

# df.shape returns a tuple:
#   df.shape[0] = number of rows
#   df.shape[1] = number of columns
#
# Important:
#   shape is a property, not a function.
#   Correct: df.shape
#   Wrong:   df.shape()
print(f"Rows: {df.shape[0]}")
print(f"Columns: {df.shape[1]}")


# Print all column names.
# This helps confirm that the CSV export contains the expected columns.
print("\nColumn names:")
for column in df.columns:
    print(f"- {column}")


# df.dtypes shows the data type pandas assigned to every column.
#
# Common pandas dtypes:
# - object: usually text
# - int64: integer number
# - float64: decimal number
# - bool: True/False
#
# Date columns are often read as object first.
# We convert date columns later when needed.
print("\nData types:")
print(df.dtypes)


# ============================================================
# 6. Validation checks
# ============================================================

print_section("3. Validation checks")

# This list will store all validation check results.
# At the end, we convert it into a DataFrame.
validation_results = []


# ------------------------------------------------------------
# 6.1 Row count check
# ------------------------------------------------------------
# Goal:
#   Confirm that the CSV has the same number of rows as the SQL table.
#
# Expected:
#   1,635 rows.
#
# Why important:
#   If this fails, the export may be incomplete or incorrect.

actual_row_count = len(df)

add_check(
    results=validation_results,
    check_name="row_count_matches_sql_table",
    actual_value=actual_row_count,
    expected_value=EXPECTED_ROW_COUNT,
    passed=actual_row_count == EXPECTED_ROW_COUNT,
)

print(f"Row count: {actual_row_count}")


# ------------------------------------------------------------
# 6.2 Grain / duplicate admission_id check
# ------------------------------------------------------------
# Goal:
#   Confirm that each admission appears only once.
#
# Grain:
#   1 row = 1 admission
#
# Expected:
#   duplicate admission_id count = 0
#
# Why important:
#   If duplicates exist, aggregations and ML rows may become unreliable.

duplicate_admission_count = int(df["admission_id"].duplicated().sum())

add_check(
    results=validation_results,
    check_name="one_row_per_admission_id",
    actual_value=duplicate_admission_count,
    expected_value=0,
    passed=duplicate_admission_count == 0,
)

print(f"Duplicate admission_id count: {duplicate_admission_count}")


# ------------------------------------------------------------
# 6.3 Required ID completeness check
# ------------------------------------------------------------
# Goal:
#   Confirm that required ID columns are not missing.
#
# Expected:
#   missing required IDs total = 0
#
# Why important:
#   Required IDs are needed for traceability and joins.
#   Missing IDs make rows harder to trust.

missing_required_id_total = 0

print("\nMissing required IDs:")

for column in REQUIRED_ID_COLUMNS:
    # Count missing values in the current required ID column.
    column_missing_count = missing_count(df[column])

    # Add this column's missing count to the total.
    missing_required_id_total += column_missing_count

    # Print the result so we can inspect each ID column separately.
    print(f"- {column}: {column_missing_count}")

add_check(
    results=validation_results,
    check_name="required_ids_complete",
    actual_value=missing_required_id_total,
    expected_value=0,
    passed=missing_required_id_total == 0,
)


# ------------------------------------------------------------
# 6.4 Lab result total check
# ------------------------------------------------------------
# Goal:
#   Confirm that all curated lab results are still represented through
#   lab_result_count.
#
# Expected:
#   SUM(lab_result_count) = 4,079
#
# Why important:
#   The feature table has one row per admission.
#   Lab results are aggregated into lab_result_count.
#   This check confirms that lab aggregation was preserved in the CSV.

# pd.to_numeric(..., errors="coerce") tries to convert values to numbers.
#
# If a value cannot be converted, pandas turns it into NaN.
# This prevents the script from crashing on unexpected text values.
lab_result_total = int(pd.to_numeric(df["lab_result_count"], errors="coerce").sum())

add_check(
    results=validation_results,
    check_name="lab_result_total_preserved",
    actual_value=lab_result_total,
    expected_value=EXPECTED_LAB_RESULT_TOTAL,
    passed=lab_result_total == EXPECTED_LAB_RESULT_TOTAL,
)

print(f"\nTotal lab results from lab_result_count: {lab_result_total}")


# ------------------------------------------------------------
# 6.5 Lab feature consistency checks
# ------------------------------------------------------------
# Goal:
#   Confirm that lab-related numeric features are logically consistent.
#
# Checks:
#   - lab_result_count should not be negative
#   - distinct_test_name_count should not be greater than lab_result_count
#
# Why important:
#   You cannot have more distinct test names than total lab results.
#   You also cannot have a negative number of lab results.

lab_result_count_numeric = pd.to_numeric(df["lab_result_count"], errors="coerce")

distinct_test_count_numeric = pd.to_numeric(df["distinct_test_name_count"],errors="coerce",)

negative_lab_count = int((lab_result_count_numeric < 0).sum())

distinct_test_count_greater_than_lab_count = int(
    (distinct_test_count_numeric > lab_result_count_numeric).sum()
)

add_check(
    results=validation_results,
    check_name="lab_result_count_not_negative",
    actual_value=negative_lab_count,
    expected_value=0,
    passed=negative_lab_count == 0,
)

add_check(
    results=validation_results,
    check_name="distinct_test_count_not_greater_than_lab_count",
    actual_value=distinct_test_count_greater_than_lab_count,
    expected_value=0,
    passed=distinct_test_count_greater_than_lab_count == 0,
)

print(f"Negative lab_result_count rows: {negative_lab_count}")
print(
    "Rows where distinct_test_name_count > lab_result_count: "
    f"{distinct_test_count_greater_than_lab_count}"
)


# ------------------------------------------------------------
# 6.6 Lab date order check
# ------------------------------------------------------------
# Goal:
#   Confirm that first_lab_result_date is not after latest_lab_result_date.
#
# Expected:
#   invalid lab date order count = 0
#
# Why important:
#   The first lab result date should be earlier than or equal to the latest
#   lab result date.

# Convert date columns from text/object to datetime.
#
# errors="coerce" means:
#   invalid dates become NaT
#
# NaT means "Not a Time", pandas' missing value for dates.
first_lab_date = pd.to_datetime(df["first_lab_result_date"], errors="coerce")
latest_lab_date = pd.to_datetime(df["latest_lab_result_date"], errors="coerce")

# We only compare rows where both dates are present.
#
# first_lab_date.notna() means first date exists.
# latest_lab_date.notna() means latest date exists.
# first_lab_date > latest_lab_date catches invalid date order.
invalid_lab_date_order_count = int(
    (
        first_lab_date.notna()
        & latest_lab_date.notna()
        & (first_lab_date > latest_lab_date)
    ).sum()
)

add_check(
    results=validation_results,
    check_name="lab_date_order_valid",
    actual_value=invalid_lab_date_order_count,
    expected_value=0,
    passed=invalid_lab_date_order_count == 0,
)

print(f"Invalid lab date order count: {invalid_lab_date_order_count}")


# ============================================================
# 7. Missing values per column
# ============================================================
# Goal:
#   Show missing values for every column.
#
# Important:
#   Missing values are not always wrong.
#   The question is:
#   - Which column is missing?
#   - How many values are missing?
#   - Is that acceptable for the purpose of analysis?

print_section("4. Missing values per column")

# We create a new DataFrame with one row per column.
#
# For every column, we calculate:
# - missing_count
# - missing_percentage
missing_profile = pd.DataFrame(
    {
        "column_name": df.columns,
        "missing_count": [missing_count(df[column]) for column in df.columns],
    }
)

# Calculate missing percentage:
# missing_count / total rows * 100
missing_profile["missing_percentage"] = (
    missing_profile["missing_count"] / len(df) * 100
).round(2)

# Sort columns with the most missing values first.
missing_profile = missing_profile.sort_values(
    by=["missing_count", "column_name"],
    ascending=[False, True],
)

print(missing_profile.to_string(index=False))


# ============================================================
# 8. Numeric ranges
# ============================================================
# Goal:
#   Inspect numeric columns with min, max, mean and median.
#
# Why:
#   Numeric ranges help detect impossible or suspicious values.

print_section("5. Numeric ranges")

for column in NUMERIC_COLUMNS:
    # Convert the column to numeric values.
    # If conversion fails, invalid values become NaN.
    numeric_series = pd.to_numeric(df[column], errors="coerce")

    print(f"\nColumn: {column}")
    print(f"- missing after numeric conversion: {int(numeric_series.isna().sum())}")
    print(f"- min: {numeric_series.min()}")
    print(f"- max: {numeric_series.max()}")
    print(f"- mean: {round(numeric_series.mean(), 2)}")
    print(f"- median: {numeric_series.median()}")


# ============================================================
# 9. Category distributions
# ============================================================
# Goal:
#   Inspect the most common values for categorical columns.
#
# Why:
#   This helps detect:
#   - unexpected categories
#   - dominant categories
#   - missing values
#   - data imbalance

print_section("6. Category distributions")

for column in CATEGORY_COLUMNS:
    print(f"\nColumn: {column}")

    # value_counts(dropna=False) counts each unique value.
    #
    # dropna=False means:
    #   include missing values in the count.
    #
    # head(20) means:
    #   show only the top 20 values.
    print(df[column].value_counts(dropna=False).head(20).to_string())


# ============================================================
# 10. Warning column distributions
# ============================================================
# Goal:
#   Inspect warning/flag columns.
#
# Why:
#   Warning columns are not always blockers.
#   They help us understand data risks.

print_section("7. Warning column distributions")

for column in WARNING_COLUMNS:
    print(f"\nColumn: {column}")
    print(df[column].value_counts(dropna=False).to_string())


# ============================================================
# 11. Leakage-risk columns
# ============================================================
# Goal:
#   List columns that may become leakage risks later.
#
# Important:
#   Leakage depends on:
#   - the ML target
#   - the prediction moment
#   - what information would realistically be available at that time.
#
# Example:
#   If we predict at admission start, lab results collected later may leak
#   future information.

print_section("8. Leakage-risk columns")

print(
    "These columns are not automatically wrong, but they require review "
    "before machine learning because their safety depends on the target "
    "and prediction moment.\n"
)

for column in LEAKAGE_RISK_COLUMNS:
    if column in df.columns:
        print(f"- {column}: present")
    else:
        print(f"- {column}: missing from dataset")

print(
    "\nLeakage note:\n"
    "- Lab-related features may be leakage if the prediction is made at "
    "admission start and the lab information becomes available later.\n"
    "- diagnosis_group may be leakage if it is used to predict diagnosis "
    "or if it is not known at prediction time.\n"
    "- These columns should be reviewed again after the ML target is defined."
)


# ============================================================
# 12. Validation summary
# ============================================================
# Goal:
#   Print one compact PASS/FAIL overview.
#
# Why:
#   This is easier to document than reading the full script output.

print_section("9. PASS / FAIL summary")

# Convert the list of dictionaries into a DataFrame.
#
# Each dictionary becomes one row.
# Each dictionary key becomes one column.
validation_summary = pd.DataFrame(validation_results)

print(validation_summary.to_string(index=False))

# Count how many checks passed and failed.
pass_count = int((validation_summary["status"] == "PASS").sum())
fail_count = int((validation_summary["status"] == "FAIL").sum())

print(f"\nPASS count: {pass_count}")
print(f"FAIL count: {fail_count}")

# Final decision:
# - If there are no failed checks, the exported dataset is valid for profiling.
# - If there are failed checks, we should investigate before using the dataset.
if fail_count == 0:
    print(
        "\nFinal decision: PASS. "
        "The exported analysis feature table is valid for Python/pandas profiling."
    )
else:
    print(
        "\nFinal decision: FAIL. "
        "Investigate failed checks before using this dataset for analysis."
    )