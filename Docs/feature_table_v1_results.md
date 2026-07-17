# Feature Table V1 Results

## Purpose

This document summarizes the validation results for `feature_admission_large_v1`.

The goal of the validation was to confirm that the first large admission-level feature table preserves the intended grain and is reliable enough to use as a foundation for initial descriptive analysis.

## Feature Table

Feature view:

`feature_admission_large_v1`

Grain:

`1 row = 1 curated admission`

## Validation Results

| Check | Result |
|---|---:|
| Curated admissions row count | 1,635 |
| Feature table row count | 1,635 |
| Duplicate admission count | 0 |
| Missing required IDs | 0 |
| Minimum age at admission | 16 |
| Maximum age at admission | 84 |
| Negative age count | 0 |
| Very high age count above 110 | 0 |
| PASS checks in summary | 6 |
| WARNING checks in summary | 0 |
| FAIL checks in summary | 0 |

## Provider-Department Warning Distribution

The provider-to-department relationship warning remains visible in the feature table.

| provider_department_mismatch_warning | Row count |
|---|---:|
| FALSE | 403 |
| TRUE | 1,232 |

This matches the earlier relationship consistency result. The warning is included in the feature table, but it is not used as a blocking exclusion rule.

## Interpretation

The feature table preserves the admission-level grain.

The row count of `feature_admission_large_v1` matches `curated_admissions_large`, with 1,635 rows in both views. The duplicate admission count is 0, which confirms that each admission appears only once.

Required IDs are complete. This supports traceability and makes the feature table suitable as a foundation for later analysis.

The age range is realistic, with a minimum age of 16 and a maximum age of 84. No negative ages or very high ages above 110 were found.

The known provider-to-department relationship issue remains visible through `provider_department_mismatch_warning`. This is important because the issue is documented and can be reviewed in downstream analysis without removing records.

## Decision

`feature_admission_large_v1` is considered valid for initial descriptive analysis.

The feature table should not yet be treated as fully ML-ready for all use cases. Fields such as `total_cost`, `discharge_date` and `length_of_stay_days` require careful handling because they may cause leakage in early prediction scenarios.

## Limitations

The current feature table does not include lab result aggregations. Lab results are deferred to a later version because they have a different grain and must first be aggregated to admission level.

The provider-to-department mismatch is still a warning, not a confirmed data error. The business meaning of admission department and provider department still needs confirmation.

The current feature table is suitable for analysis preparation, but additional target definition, leakage review and model-specific validation are needed before machine learning experiments.

## Next Steps

- review `SQL/25_feature_admission_large_v1_quality_checks.sql`
- add lab result aggregations in a later feature table version
- define a clear analysis or machine learning target
- document leakage decisions for any future ML use case