---
phase: 31-standalone-validation
reviewed: 2026-04-20T18:07:59Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - dev/lifestage/validate_lifestage.R
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-04-20T18:07:59Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `dev/lifestage/validate_lifestage.R`, a standalone validation script that defines a 5-column lifestage dictionary, a keyword classifier function, and an 18-assertion test battery run against a DuckDB database. The script is well-structured with clear separation of concerns (dictionary, classifier, database connection, assertions, diff reporting). Database access is read-only with proper cleanup via `on.exit()`. The assertion framework is sound and covers dictionary structure, classifier behavior, and misclassification fixes.

Two warnings are raised for dictionary-vs-classifier classification inconsistencies that represent real disagreements between the two classification mechanisms. These will matter when the classifier is used as a fallback for novel terms in production (Phase 32). Two informational items are noted regarding edge-case regex behavior and the use of `quit()` in a sourceable script.

## Warnings

### WR-01: Dictionary-Classifier Inconsistency for "Alevin"

**File:** `dev/lifestage/validate_lifestage.R:39,91`
**Issue:** The dictionary (line 91) maps "Alevin" to "Larva", but the keyword classifier (line 39, rule 3) includes `alevin` in the Juvenile pattern. When this classifier is used as a fallback for novel terms in production, any description containing "alevin" will be classified as Juvenile, contradicting the dictionary's Larva classification. Alevin is a newly-hatched salmonid still carrying its yolk sac -- biologically, "Larva" is the correct category.
**Fix:** Move `alevin` from the Juvenile pattern (rule 3, line 39) to the Larva pattern (rule 2, line 38):
```r
# Line 38 -- add alevin to Larva pattern:
2L, "(?i)larva|fry|naupli|nymph|tadpole|veliger|zoea|instar|pupa|prepupal|protozoea|mysis|glochidia|trochophore|caterpillar|maggot|megalopa|newborn|naiad|neonate|hatch|trophozoite|alevin", "Larva",

# Line 39 -- remove alevin from Juvenile pattern:
3L, "(?i)fingerling|froglet|smolt|parr|seedling|elver|juvenile|weanling|yearling|pullet|young(?!.*adult)|post-larva|post-smolt|copepodid|copepodite|swim-up|underyearling|spat|sapling|sporeling", "Juvenile",
```

### WR-02: Multiple Dictionary-Classifier Disagreements on Known Terms

**File:** `dev/lifestage/validate_lifestage.R:38-43,92,162,167,183,213,216`
**Issue:** At least 6 dictionary terms produce a different classification when passed through the keyword classifier. The dictionary is authoritative, but the classifier contradicts it for these terms:

| Term | Dictionary | Classifier | Classifier Pattern |
|------|-----------|------------|-------------------|
| Trophozoite (line 213) | Other/Unknown | Larva | `trophozoite` in rule 2 |
| Bud or Budding (line 92) | Other/Unknown | Adult | `\bbud\b` in rule 5 |
| Pre-hatch (line 162) | Other/Unknown | Larva | `hatch` in rule 2 |
| Post-hatch (line 167) | Other/Unknown | Larva | `hatch` in rule 2 |
| Post-embryo (line 183) | Other/Unknown | Egg/Embryo | `embryo` in rule 1 |
| Mature vegetative (line 216) | Other/Unknown | Adult | `mature(?!.*dormant)` in rule 5 |

These disagreements are hidden by assertion A17, which only requires >= 125/139 non-Other/Unknown matches (allowing up to 14 mismatches). This is a design choice, but it means the classifier's accuracy on novel terms containing these keywords will diverge from dictionary intent. For example, a novel "Post-embryo stage" would be classified as Egg/Embryo by the classifier, but the dictionary considers "Post-embryo" to be Other/Unknown.

**Fix:** Either (a) align the classifier patterns with dictionary intent by adding negative lookaheads or exclusions for these compound terms (e.g., `(?<!post-)hatch`, `(?<!post-)embryo`), or (b) add a documented acknowledgment in the comments that the classifier intentionally disagrees with the dictionary on these terms and explain why the simpler regex is preferred for the fallback role. Option (b) is reasonable if the dictionary is always consulted first and the classifier only handles truly novel terms.

## Info

### IN-01: Edge Case in Egg Negative Lookahead

**File:** `dev/lifestage/validate_lifestage.R:37`
**Issue:** The pattern `egg(?!.?laying)` uses `.?` (0 or 1 of any character) to bridge "egg" and "laying". This correctly handles "egg-laying", "egglaying", and "egg laying" (single space). However, it would fail on "egg  laying" (two spaces) or "egg - laying" (space-hyphen-space), which would be incorrectly classified as Egg/Embryo instead of falling through to the Adult rule. This is unlikely to occur in the ECOTOX database vocabulary, but worth noting for robustness.
**Fix:** If broader coverage is desired, use `.{0,3}` instead of `.?`:
```r
"(?i)egg(?!.{0,3}laying)|embryo|blastula|..."
```

### IN-02: Script Uses `quit()` Which Terminates Interactive Sessions

**File:** `dev/lifestage/validate_lifestage.R:584,587`
**Issue:** The script calls `quit(status = 0)` and `quit(status = 1)` at the end. This is correct for a standalone `Rscript` invocation (as documented in the header), but if someone accidentally `source()`s this file in an interactive R session, it will terminate their session without warning. This is a minor usability concern given the script's stated purpose.
**Fix:** No change needed if this is strictly a CLI script. If it may be sourced interactively, wrap the exit logic:
```r
if (!interactive()) {
  quit(status = if (n_fail > 0) 1 else 0)
}
```

---

_Reviewed: 2026-04-20T18:07:59Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
