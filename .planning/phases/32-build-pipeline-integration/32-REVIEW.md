---
phase: 32-build-pipeline-integration
reviewed: 2026-04-20T14:32:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - inst/ecotox/ecotox_build.R
  - data-raw/ecotox.R
  - R/eco_functions.R
findings:
  critical: 1
  warning: 0
  info: 1
  total: 2
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-04-20T14:32:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the lifestage dictionary (section 16) in both build scripts, the keyword classifier function, the build-gate logic, and the `eco_functions.R` query layer. The lifestage dictionaries are identical across both scripts and the classifier is well-structured with prioritized rules. The relocate call and @return roxygen in `eco_functions.R` are correct. One critical bug was found in `inst/ecotox/ecotox_build.R` where the year-to-hours conversion factor is missing from the duration conversion section (section 12), which would cause year-based durations to silently default to 1 hour instead of 8765.82 hours. The `data-raw/ecotox.R` copy has the correct fix.

## Critical Issues

### CR-01: Missing year conversion factor in inst/ecotox/ecotox_build.R (section 12)

**File:** `inst/ecotox/ecotox_build.R:567`
**Issue:** The `conversion_factor_duration` case_when block handles minute, second, hour, day, week, and month but falls through to `.default = 1` for year-based durations. This means any test with a "year" duration unit code gets a conversion factor of 1 (i.e., treated as 1 hour) instead of `24 * 365.2425 = 8765.82` hours. The `data-raw/ecotox.R` version correctly includes this case at line 567. This is a data-corruption bug that would silently produce wildly incorrect `final_obs_duration` values for chronic/long-term studies measured in years.

**Fix:**
```r
# In inst/ecotox/ecotox_build.R, section 12 (line ~566-567), add the year case:
      conversion_factor_duration = dplyr::case_when(
        stringr::str_detect(tolower(description), "minute") ~ 1 / 60,
        stringr::str_detect(tolower(description), "second") ~ 1 / 3600,
        stringr::str_detect(tolower(description), "hour") ~ 1,
        stringr::str_detect(tolower(description), "day") ~ 24,
        stringr::str_detect(tolower(description), "week") ~ 24 * 7,
        stringr::str_detect(tolower(description), "month") ~ 24 * 30.43685,
        stringr::str_detect(tolower(description), "year") ~ 24 * 365.2425,
        .default = 1
      ),
```

## Info

### IN-01: Classifier regex for "Post-hatch" and "Post-embryo" may surprise users

**File:** `inst/ecotox/ecotox_build.R:982`
**Issue:** The Larva pattern (priority 2) contains `(?<!pre-)(?<!post-)hatch`, which means "Post-hatch" is intentionally excluded from matching Larva. The dictionary correctly maps "Post-hatch" to "Other/Unknown" (line 1096), and "Post-embryo" similarly maps to "Other/Unknown" (line 1111). These are intentional choices (the lookbehinds are explicitly designed for this), but worth noting that if new ECOTOX terms like "post-hatch fry" appear in the future, they would also be excluded from Larva classification by the keyword fallback. The build gate would catch truly unknown terms, so this is low risk. No action needed.

**Fix:** No fix required -- this is informational. The build gate at lines 1162-1183 ensures any new terms that cannot be classified will halt the build, providing a safety net.

---

_Reviewed: 2026-04-20T14:32:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
