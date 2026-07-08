# Python / pandas Learning Log

## Core Pattern

CSV → DataFrame → inspection → data quality checks → compare with SQL

Python is used to inspect and validate exported SQL results. The goal is not only to run code, but to check whether Python output matches expected SQL results.

---

## Commands I Know

- `pd.read_csv(...)`: reads a CSV file into a DataFrame.
- `df.head()`: shows the first rows.
- `df.shape`: shows the number of rows and columns.
- `df.columns.tolist()`: shows column names as a list.
- `df.isna().sum()`: counts missing values per column.
- `df["column"].value_counts(dropna=False)`: counts values in one column, including missing values.
- `df["column"].describe()`: summarizes numeric values.
- `df["column"].isna().sum()`: counts missing values in one specific column.
- `df[df["column"].isna()]`: filters records where a column is missing.
- `.to_string(index=False)`: prints a DataFrame without the pandas index.

---

## Important Insight

Python code belongs in the `.py` file. The terminal is used to run the script:

```bash
python src/profile_feature_table.py
```

`print()` is needed to show results in the terminal.

A Python script that runs without errors does not automatically prove that the data is correct. The output must be compared with expected SQL results.

---

## Debug Learning Point: `df.shape`

### Error

I wrote:

```python
df.shape()
```

### Error Message

```text
TypeError: 'tuple' object is not callable
```

### Cause

`df.shape` is not a function. It is a property. It directly returns a tuple, for example:

```python
(6, 18)
```

### Fix

Use:

```python
df.shape
```

without parentheses.

### General Pattern

Methods/actions often use parentheses:

```python
df.head()
```

Properties/information sometimes do not use parentheses:

```python
df.shape
```

### Professional Learning Point

When debugging, first check:

1. Where the script stops.
2. What the error message says.
3. What assumption was wrong.
4. What the smallest fix is.

---

## Python Validation Summary

A validation summary was added to the Python profiling script.

### Key Learning Points

- A Python function can be used to avoid repeated logic.
- `count_true()` counts how many values in a quality flag column are true.
- `count_false()` counts how many values in a quality flag column are false.
- `print_check()` compares an expected value with an actual value and prints PASS or FAIL.
- A function definition does not run automatically.
- A function only runs when it is called.
- `return` gives a value back, but does not print it.
- `print()` shows output in the terminal.
- For readability, intermediate variables can make code easier to understand than compact nested function calls.

### Why This Matters

The script can automatically check whether the exported CSV matches the expected SQL validation results. This makes the workflow more reliable and easier to review.

---

## Function Understanding

### Function Definition

A function definition prepares reusable logic:

```python
def count_true(dataframe, column_name):
    column_values = dataframe[column_name]
    column_as_text = column_values.astype(str)
    column_lowercase = column_as_text.str.lower()
    true_values = column_lowercase.eq("true")
    true_count = true_values.sum()

    return int(true_count)
```

This does not produce output by itself.

### Function Call

A function call executes the function:

```python
count_true(df, "has_cost_issue")
```

### Important Distinction

```text
def = define the function
function_name(...) = execute the function
return = give a value back
print = show output in the terminal
```

### Function Call Inside Another Function Call

This line:

```python
print_check("analysis-ready records", 1, count_true(df, "is_analysis_ready"))
```

is executed in steps:

1. Python first runs `count_true(df, "is_analysis_ready")`.
2. `count_true()` returns the actual count.
3. Python then passes that result into `print_check()`.
4. `print_check()` compares expected with actual and prints PASS or FAIL.

A more beginner-friendly version is:

```python
analysis_ready_count = count_true(df, "is_analysis_ready")

print_check("analysis-ready records", 1, analysis_ready_count)
```

This separates calculation from validation output.

---

## F-String Understanding

This line:

```python
print(f"{status}: {check_name} - expected {expected}, found {actual}")
```

uses an f-string.

Inside an f-string:

```text
Outside { } = normal text
Inside { } = Python variable or expression
```

Example:

```python
status = "PASS"
check_name = "row count"
expected = 6
actual = 6

print(f"{status}: {check_name} - expected {expected}, found {actual}")
```

Output:

```text
PASS: row count - expected 6, found 6
```

The words `expected` and `found` are not inside `{ }`, so they are printed as normal text.

---

## SQL to Python Validation Mapping

SQL expected values are compared with Python actual values from the exported CSV.

### Mapping

- SQL `COUNT(*)` maps to Python `len(df)`.
- SQL count of `is_analysis_ready = TRUE` maps to `count_true(df, "is_analysis_ready")`.
- SQL count of `is_analysis_ready = FALSE` maps to `count_false(df, "is_analysis_ready")`.
- SQL count of `has_missing_patient_features = TRUE` maps to `count_true(df, "has_missing_patient_features")`.
- SQL count of `has_length_of_stay_issue = TRUE` maps to `count_true(df, "has_length_of_stay_issue")`.
- SQL count of `has_cost_issue = TRUE` maps to `count_true(df, "has_cost_issue")`.

### Learning Point

The SQL query defines the expected validation result. Python checks whether the exported CSV still contains the same values.

A Python script that runs without errors does not automatically prove that the data is correct. The output must be compared with expected SQL results.

---

## Additional SQL/Python Check: Missing Department

### Data Question

How many records have a missing `department_standardized` value?

### SQL Count Check

```sql
SELECT
    COUNT(*) AS missing_department_count
FROM feature_admission_v2
WHERE department_standardized IS NULL;
```

### SQL Detail Check

```sql
SELECT
    admission_id,
    patient_id,
    department_standardized
FROM feature_admission_v2
WHERE department_standardized IS NULL;
```

### Python Count Check

```python
df["department_standardized"].isna().sum()
```

### Python Detail Check

```python
missing_department_records = df[df["department_standardized"].isna()]
```

A more readable version selects only relevant columns:

```python
missing_department_columns = [
    "admission_id",
    "patient_id",
    "department_standardized",
    "has_cost_issue",
    "is_analysis_ready",
]

print(missing_department_records[missing_department_columns].to_string(index=False))
```

### Result

- SQL result: 1 record
- Python result: 1 record
- Matching result: yes

### Interpretation

One record has a missing `department_standardized` value. SQL and Python both confirm the same missing value count, which means the exported CSV preserves this issue from the SQL feature table.

### Data Quality Risk

A missing department value can affect department-level reporting, filtering and later analysis. This value should not be filled automatically without checking the source admission record.

---

## Current Concepts to Repeat

- Pandas column names must be written as strings: `df["column_name"]`.
- A count check answers: how many records?
- A detail check answers: which records?
- SQL `IS NULL` maps to pandas `.isna()`.
- SQL `COUNT(*)` maps to Python `len(df)` or `.sum()` depending on the check.
- `def` defines a function, but does not run it.
- `return` gives a value back, but does not print it.
- `print()` is needed to show output in the terminal.
- Data quality interpretation should include: finding → risk → action.

---

## Daily Progress Notes

### Today’s Learning Points

- SQL and Python can answer the same data quality question.
- SQL `IS NULL` and pandas `.isna()` both detect missing values.
- A count check and a detail check serve different purposes.
- Python terminal output can be made clearer by selecting relevant columns and using `.to_string(index=False)`.
- Data quality interpretation should explain why the finding matters, not only what the count is.

### Concepts to Revisit

- Writing pandas column names correctly with quotes.
- Understanding when Python defines, calculates, returns or prints.
- Comparing SQL expected results with Python actual results.
- Writing clear data quality interpretations.

## Additional SQL/Python Checks: Gender and Cost

### Missing Gender

Data question:

How many records have a missing `gender_standardized` value?

SQL logic:

Use `gender_standardized IS NULL`.

Python logic:

Use `df["gender_standardized"].isna().sum()` for the count and filter the DataFrame to inspect the affected records.

Result:

- SQL result: 2 records
- Python result: 2 records
- Affected admission_ids: A003, A008
- Matching result: yes

Data quality risk:

Missing gender values can make demographic analysis incomplete. These records should not be used blindly in gender-based reporting or analysis. The source patient records should be checked before deciding whether to correct, exclude or keep these values with warning flags.

### Negative Total Cost

Data question:

How many records have a negative `total_cost`?

SQL logic:

Use `total_cost < 0`.

Python logic:

Use `(df["total_cost"] < 0).sum()` for the count and filter the DataFrame to inspect the affected records.

Result:

- SQL result: 1 record
- Python result: 1 record
- Affected admission_id: A006
- Matching result: yes

Data quality risk:

A negative cost value is likely invalid for financial analysis. It can distort totals, averages and cost-based reporting. The source record should be verified before deciding whether to correct, exclude or keep it with a warning flag.

### Cost Issue Records

Data question:

Which records have `has_cost_issue = TRUE`?

SQL logic:

Use `has_cost_issue = TRUE`.

Python logic:

Use a robust true-check with `.astype(str).str.lower().eq("true")`.

Result:

- SQL result: 2 records
- Python result: 2 records
- Affected admission_ids: A006, A007
- Matching result: yes

Data quality risk:

A count-only check shows how many records have a cost issue, but a detail-check shows which records are affected and which values caused the issue. This is needed for source verification and deciding how these records should be handled in cost analysis.

### Debugging Note

During this block, a pandas `KeyError` occurred because a Python variable name was used as a string column name. The issue was fixed by distinguishing between:

- `df["column_name"]` for selecting one real column
- `df[column_list_variable]` for selecting multiple columns stored in a Python variable

This reinforces the difference between column names, strings and Python variables.

### Missing Patient Features

Data question:

Which records have `has_missing_patient_features = TRUE`?

SQL logic:

Use `has_missing_patient_features = TRUE`.

Python logic:

Use a robust true-check with `.astype(str).str.lower().eq("true")`.

Result:

- SQL result: 2 records
- Python result: 2 records
- Affected admission_ids: A003, A008
- Matching result: yes

Data quality risk:

Records with missing patient features are not reliable for patient-level analysis because important patient attributes are unavailable. These records should be investigated at the source before deciding whether to enrich, exclude or keep them with warning flags.

Debugging note:

This check reinforced the difference between `.str.lower()` as a pandas string method and incorrect forms such as `str_lower`. It also reinforced that real pandas column names must be written as strings, such as `df["has_missing_patient_features"]`.

## Large Dataset SQL/Python Validation

Today, the small healthcare data quality pipeline was scaled to a larger synthetic healthcare dataset.

### Output Produced

- Created a large synthetic healthcare dataset design.
- Added an ERD with table relationships.
- Created five large raw/sandbox tables.
- Inserted synthetic data into the large tables.
- Ran SQL data quality checks on the large dataset.
- Exported a SQL data quality summary to CSV.
- Created `src/profile_large_dataset.py`.
- Validated SQL summary counts with Python.
- Result: 18 PASS, 0 FAIL.

### Python Concepts Practiced

- `Path` for file paths
- `pd.read_csv()` for loading CSV data
- DataFrame shape, columns and preview
- dictionary with expected values
- helper function `print_check()`
- loop over `expected_counts.items()`
- DataFrame filtering with `matching_rows`
- `.empty` to detect missing checks
- `.iloc[0]` to retrieve the first matching value
- expected vs actual validation

### Debugging / Learning Notes

The Python script was easier to understand after restructuring it in execution order:

1. imports
2. file paths
3. start header
4. data loading
5. basic inspection
6. expected values
7. helper functions
8. validation loop
9. PASS/FAIL output

This structure will be used for future Python validation scripts.