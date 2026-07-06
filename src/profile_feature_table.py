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

print("\nMissing department count")
print(df[df["department_standardized"].isna()])

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

print("\n=== MISSING DEPARTMENT CHECK ===")

missing_department_count = df["department_standardized"].isna().sum()

print("Missing department count")
print(missing_department_count)

missing_department_records = df[df["department_standardized"].isna()]

print("\nMissing department records")

missing_department_columns = [
                             "admission_id",
                             "patient_id",
                             "department_standardized",
                             "has_cost_issue",
                             "is_analysis_ready",
                             ]

print(missing_department_records[missing_department_columns].to_string(index=False))


print("\n=== ADDITIONAL DATA QUALITY CHECKS ===")

print(df["gender_standardized"].isna().sum())

print("\n***Overview records missing gender standardized***")

missing_gender_standardized_records = df[df["gender_standardized"].isna()]

missing_gender_standardized_records_columns = [
                                        "admission_id",
                                        "patient_id",
                                        "gender_standardized",
                                        ]

print(missing_gender_standardized_records[missing_gender_standardized_records_columns].to_string(index=False))


print("\n***Counting records total cost < 0***")

print((df["total_cost"] < 0).sum())


print("\n***Overview records total cost < 0***")

totalcostunderzero_records = df[df["total_cost"] < 0]

totalcostunderzero_records_columns = [
                                    "admission_id",
                                    "patient_id",
                                    "total_cost",
                                    ]

print(totalcostunderzero_records[totalcostunderzero_records_columns].to_string(index=False))

print("\n***Overview has cost issue is true***")

has_cost_issue_true_records = df[
                                df["has_cost_issue"].astype(str).str.lower().eq("true")
                                ]

has_cost_issue_true_columns = [
                                "admission_id",
                                "patient_id",
                                "total_cost",
                                "has_cost_issue",
                                ]

print(has_cost_issue_true_records[has_cost_issue_true_columns].to_string(index=False))


print("\n***Records with missing patient features***")

has_missing_patient_features_records = df[df["has_missing_patient_features"].astype(str).str.lower().eq('true')]

has_missing_patient_features_columns = [
					"admission_id",
					"patient_id",
					"has_missing_patient_features",
					]

print(has_missing_patient_features_records[has_missing_patient_features_columns].to_string(index=False))


print("\n***beginner friendly version of the code above***")

missing_patient_features_mask = (
    df["has_missing_patient_features"].astype(str).str.lower().eq("true")
)

missing_patient_features_count = missing_patient_features_mask.sum()

print("\n***Missing patient features count:***")
print(missing_patient_features_count)

missing_patient_features_records = df[missing_patient_features_mask]

missing_patient_features_columns = [
    "admission_id",
    "patient_id",
    "has_missing_patient_features",
]

print("\nMissing patient features records:")
print(missing_patient_features_records[missing_patient_features_columns].to_string(index=False))