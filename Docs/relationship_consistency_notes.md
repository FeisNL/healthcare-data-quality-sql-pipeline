# Relationship Consistency Notes

## Purpose

This note documents an additional relationship consistency check for the curated healthcare layer.

The curated layer already validates that admissions link to curated patients, departments and providers. This check goes one step further by testing whether the provider assigned to an admission belongs to the same department as the admission.

## Check Logic

The check compares:

```text
curated_admissions_large.department_id
```

with:

```text
curated_providers_large.department_id
```

A mismatch is found when:

```text
admission.department_id <> provider.department_id
```

This is not a parent-link validation check. Parent-link validation checks whether a related record exists. Relationship consistency checks whether existing related records are logically consistent with each other.

## Result

The check found:

| Metric | Value |
|---|---:|
| Total curated admissions | 1,635 |
| Provider-to-department mismatches | 1,232 |
| Mismatch percentage | 75.35% |

## Interpretation

The provider-to-department relationship check found 1,232 mismatches out of 1,635 curated admissions, which is 75.35%.

This is a high mismatch rate and should be investigated further. The records are technically valid because the admissions still link to curated providers and curated departments. However, the provider department does not always match the admission department.

This may indicate that the synthetic data generation does not enforce provider-to-department consistency. It may also mean that admission department and provider department represent different business concepts.

## Decision

This check is treated as a warning for now, not as a blocking exclusion rule.

Applying this rule as a blocking exclusion rule would remove most curated admissions and could strongly affect downstream analysis. The business meaning of admission department and provider department needs confirmation before this rule can be used to exclude records.

## Why This Matters

This check is important for later warehouse modeling, feature tables and analysis.

If admissions are analyzed by department, inconsistent provider-department relationships could affect:

- department-level admission counts
- provider-level analysis
- cost analysis by department
- feature engineering for machine learning
- interpretation of provider and department dimensions

## Next Improvement

A future improvement is to review the data generation logic and decide whether providers should be assigned only to admissions within their own department.

If this rule is confirmed by the business context, the pipeline can later treat provider-to-department mismatches as a blocking quality issue. Until then, it remains a warning.