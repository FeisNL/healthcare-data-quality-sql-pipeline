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