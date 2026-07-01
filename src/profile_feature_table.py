# Load exported feature table
import pandas as pd

# Read CSV file
df = pd.read_csv("Data/Processed/feature_admission_v2.csv")

print("\n=== BASIC DATA CHECKS ===")

print("\nEerste rijen:")
print(df.head())

print("\nAantal rijen en kolommen:")
print(df.shape)

print("\nKolomnamen:")
print(df.columns.tolist())

print("\nMissende waarden per kolom:")
print(df.isna().sum())

print("\nVerdeling is analysis ready:")
print(df["is_analysis_ready"].value_counts(dropna=False))

print("\nhas missing patient features:")
print(df["has_missing_patient_features"].value_counts(dropna=False))

print("\nhas length of stay issue:")
print(df["has_length_of_stay_issue"].value_counts(dropna=False))

print("\ndistribution has cost issue:")
print(df["has_cost_issue"].value_counts(dropna=False))

# Validate Python output against SQL expectations
print("\n=== NUMERIC DATA PREVIEW ===")

preview_columns = [
    "admission_id",
    "patient_id",
    "length_of_stay_days",
    "total_cost",
    "age_at_admission",
    "has_length_of_stay_issue",
    "has_cost_issue",
    "is_analysis_ready"
]

print(df[preview_columns].to_string(index=False))

# Profile numeric columns
print("\n=== NUMERIC PROFILING ===")

print("\nLength of stay day days summary:")
print(df["length_of_stay_days"].describe())

print("\nTotal cost summary:")
print(df["total_cost"].describe())

print("\nAge at admission summary:")
print(df["age_at_admission"].describe())

# Profile categorical columns
print("\n === CATEGORICAL PROFILING ===")

print("\n department standardized distributution:")
print(df["department_standardized"].value_counts(dropna=False))

print("\nGender standardized distribution:")
print(df["gender_standardized"].value_counts(dropna=False))

# Inspect rejected records
print("\n=== REJECTED RECORDS INSPECTION ===")

rejected_records = df[df["is_analysis_ready"] == False]

rejected_columns = [
    "admission_id",
    "patient_id",
    "has_missing_patient_features",
    "has_length_of_stay_issue",
    "has_cost_issue",
    "is_analysis_ready"
]

print(rejected_records[rejected_columns].to_string(index = False))


print("\n=== VALIDATION SUMMARY ===")


def count_true(dataframe, column_name):
    column_values = dataframe[column_name]
    column_as_text = column_values.astype(str)
    column_lowercase = column_as_text.str.lower()
    true_values = column_lowercase.eq("true")
    true_count = true_values.sum()

    return int(true_count)


def count_false(dataframe, column_name):
    column_values = dataframe[column_name]
    column_as_text = column_values.astype(str)
    column_lowercase = column_as_text.str.lower()
    false_values = column_lowercase.eq("false")
    false_count = false_values.sum()

    return int(false_count)


def print_check(check_name, expected, actual):
    status = "PASS" if expected == actual else "FAIL"
    print(f"{status}: {check_name} - expected {expected}, found {actual}")


print_check("row count", 6, len(df))
print_check("analysis-ready records", 1, count_true(df, "is_analysis_ready"))
print_check("rejected records", 5, count_false(df, "is_analysis_ready"))
print_check("missing patient features", 2, count_true(df, "has_missing_patient_features"))
print_check("length-of-stay issues", 1, count_true(df, "has_length_of_stay_issue"))
print_check("cost issues", 2, count_true(df, "has_cost_issue"))