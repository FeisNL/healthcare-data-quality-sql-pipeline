# Python / pandas learning log

## Basispatroon

CSV → DataFrame → inspectie → data quality checks → vergelijken met SQL

## Commands die ik nu ken

- `pd.read_csv(...)`: leest een CSV-bestand in als tabel.
- `df.head()`: toont de eerste rijen.
- `df.shape`: toont aantal rijen en kolommen.
- `df.columns.tolist()`: toont kolomnamen als lijst.
- `df.isna().sum()`: telt missende waarden per kolom.
- `df["kolom"].value_counts(dropna=False)`: telt waarden in één kolom.

## Belangrijk inzicht

Python-code hoort in het `.py`-bestand.
De terminal gebruik ik om het script uit te voeren.
`print()` is nodig om resultaat te tonen.

## Debug-leerpunt: df.shape()

Fout:
Ik schreef `df.shape()`.

Foutmelding:
`TypeError: 'tuple' object is not callable`

Oorzaak:
`df.shape` is geen functie, maar een eigenschap. Het geeft direct een tuple terug, bijvoorbeeld `(6, 18)`.

Fix:
Gebruik `df.shape` zonder haakjes.

Algemeen patroon:
- Methoden/acties gebruiken vaak haakjes: `df.head()`
- Eigenschappen/informatie gebruiken soms geen haakjes: `df.shape`

Professioneel leerpunt:
Bij een fout kijk ik eerst naar de regel waar het script stopt, daarna naar de foutmelding, daarna naar mijn aanname.

## Python Validation Summary

Today I added a validation summary to the Python profiling script.

Key learning points:

- A Python function can be used to avoid repeated logic.
- `count_true()` counts how many values in a quality flag column are true.
- `count_false()` counts how many values in a quality flag column are false.
- `print_check()` compares an expected value with an actual value and prints PASS or FAIL.
- A function can be called first, and its return value can then be passed into another function.
- For readability, intermediate variables can make code easier to understand than compact nested function calls.

Why this matters:

The script can now automatically check whether the exported CSV matches the expected SQL validation results. This makes the workflow more reliable and easier to review.