import pandas as pd

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

print("\nNummeric summary column total_cost:")
print(df["total_cost"].describe())

print("\n=== NUMERIC PROFILING ===")

print("\nLength of stay day days summary:")
print(df["length_of_stay_days"].describe())

print("\nTotal cost summary:")
print(df["total_cost"].describe())

print("\nAge at admission summary:")
print(df["age_at_admission"].describe())

print("\n === CATEGORICAL PROFILING ===")

print("\n department standardized distributution:")
print(df["department_standardized"].value_counts(dropna=False))

print("\nGender standardized distribution:")
print(df["gender_standardized"].value_counts(dropna=False))

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
