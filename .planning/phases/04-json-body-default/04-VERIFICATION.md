---
phase: 04-json-body-default
verified: 2026-01-28T17:17:23Z
status: passed
score: 4/4 must-haves verified
---

# Phase 4: JSON Body Default Verification Report

**Phase Goal:** Fix stub generation to send JSON arrays for bulk POST endpoints, preserving raw text only for `/chemical/search/equal/`

**Verified:** 2026-01-28T17:17:23Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `ct_hazard_skin_eye_search_bulk()` sends JSON array body (not newline-delimited text) | ✓ VERIFIED | Function passes `query = query` directly to `generic_request()` (line 16). No `paste(query, collapse = "\n")` pattern found. `generic_request()` uses `req_body_json()` for POST requests (z_generic_request.R:155) |
| 2 | `ct_chemical_search_equal_bulk()` still sends raw text body (preserved from v1.1) | ✓ VERIFIED | Function includes `body_type = "raw_text"` parameter (ct_chemical_search_equal.R:20). Stub generation logic correctly detects endpoint (07_stub_generation.R:390) |
| 3 | All bulk stubs regenerated without the `paste(query, collapse = "\n")` pattern | ✓ VERIFIED | Pattern search across entire codebase returns 0 matches. All 27 bulk POST functions verified with correct structure |
| 4 | At least one regenerated function returns valid data from live API (user verified) | ✓ VERIFIED | User confirmed live API test of `ct_hazard_skin_eye_search_bulk()` passed. VCR test file created (test-ct_hazard_skin_eye_search.R). Code path traced: function → generic_request → req_body_json → JSON array body |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `dev/endpoint_eval/07_stub_generation.R` | Fixed string_array handling, endpoint-specific raw text detection | ✓ VERIFIED | Lines 472-486: string_array passes query directly. Lines 386-391: endpoint check for `/chemical/search/equal/` |
| `R/ct_hazard_skin_eye_search.R` | Bulk function uses JSON encoding | ✓ VERIFIED | Line 16: `query = query` (direct pass). No paste/collapse pattern. 51 lines (substantive) |
| `R/ct_chemical_search_equal.R` | Preserves `body_type = "raw_text"` | ✓ VERIFIED | Line 20: `body_type = "raw_text"` parameter present. Exception correctly maintained |
| `R/z_generic_request.R` | Uses req_body_json for POST | ✓ VERIFIED | Lines 154-156: Default POST behavior uses `req_body_json(query_part, auto_unbox = FALSE)` |
| 26 regenerated bulk functions | All use correct JSON encoding | ✓ VERIFIED | All 27 bulk POST functions checked (26 fixed + 1 exception). Pattern: `query = query` with `method = "POST"`. No paste patterns found |
| `tests/testthat/test-ct_hazard_skin_eye_search.R` | VCR tests for verification | ✓ VERIFIED | 40 lines with 3 test cases. Tests single and bulk scenarios. Created in commit eec87ce |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Bulk functions | generic_request | Direct function call | ✓ WIRED | All 27 bulk functions call `generic_request(query = query, ...)` |
| generic_request | httr2::req_body_json | Conditional POST logic | ✓ WIRED | Line 155 of z_generic_request.R applies JSON encoding when body_type != "raw_text" |
| Stub generation | Endpoint-specific detection | is_raw_text_body check | ✓ WIRED | Lines 386-391 check endpoint == "chemical/search/equal/" |
| Stub generation | string_array handling | Body schema type conditional | ✓ WIRED | Lines 472-486 handle string_array with direct query pass |
| ct_chemical_search_equal_bulk | raw_text body | body_type parameter | ✓ WIRED | Line 20 explicitly sets `body_type = "raw_text"` |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| STUB-01: Bulk POST endpoints with string_array body send JSON arrays | ✓ SATISFIED | Stub generation fixed (07_stub_generation.R:472-486). All 27 bulk functions regenerated. No paste patterns remain |
| STUB-02: Only `/chemical/search/equal/` endpoint uses raw text body | ✓ SATISFIED | Endpoint-specific check implemented (07_stub_generation.R:386-391). ct_chemical_search_equal_bulk preserved with body_type = "raw_text" |
| STUB-03: All affected bulk stubs regenerated with correct body handling | ✓ SATISFIED | 26 bulk functions regenerated in commit adaef92. All use `query = query` pattern. Documentation regenerated |
| VAL-01: At least one regenerated bulk function verified against live API | ✓ SATISFIED | User verified ct_hazard_skin_eye_search_bulk returns valid data. VCR tests created. Code path traced and confirmed |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | - | - | No anti-patterns detected |

**Anti-pattern scan results:**
- Searched for `paste(query, collapse`: 0 matches
- Searched for TODO/FIXME in modified files: Only documentation TODOs (acceptable)
- Searched for placeholder content: None found in function implementations
- Searched for empty returns: None found in bulk functions

### Verification Method

**Level 1 (Existence):** All 6 key artifacts exist and are substantive
- Stub generation file: 1,258 lines
- Example bulk function: 51 lines
- Generic request template: 506 lines
- Test file: 40 lines

**Level 2 (Substantive):** All artifacts have real implementations
- No stub patterns (TODO, placeholder, console.log only)
- All functions have proper exports
- Documentation complete and regenerated

**Level 3 (Wired):** All connections verified
- 27 bulk functions import and use generic_request
- generic_request uses httr2::req_body_json (traced)
- Exception case properly wired with body_type parameter
- Stub generation logic produces correct output

### Commit Trace

| Commit | Phase Plan | Description |
|--------|------------|-------------|
| 15cde53 | 04-01 | fix(04-01): correct string_array body type handling in stub generation |
| adaef92 | 04-02 | fix(04-02): correct JSON body encoding in 26 bulk stub functions |
| eec87ce | 04-03 | test(04-03): add VCR tests for ct_hazard_skin_eye_search_bulk |

All commits properly tagged, atomic, and traceable to phase plans.

---

## Verification Summary

**Phase 4 Goal Achieved:** ✓

The stub generation logic was successfully fixed to use JSON array encoding for bulk POST endpoints. All 26 affected bulk functions were regenerated with correct body handling. The special case for `/chemical/search/equal/` was preserved with raw text encoding. Live API testing confirmed the fix works correctly.

**Key Findings:**
1. **Stub generation corrected**: Lines 472-486 of 07_stub_generation.R now pass query directly
2. **Endpoint-specific detection**: Lines 386-391 correctly identify `/chemical/search/equal/` for raw text
3. **Complete regeneration**: All 27 bulk POST functions verified (26 with JSON, 1 with raw text)
4. **Zero old patterns**: No `paste(query, collapse = "\n")` found anywhere in codebase
5. **Live API verified**: User confirmed ct_hazard_skin_eye_search_bulk returns valid data

**Architecture Impact:**
- generic_request template correctly handles JSON encoding by default (req_body_json)
- Exception handling mechanism works correctly (body_type parameter)
- Future stub generation will produce correct code for new endpoints

**Testing Coverage:**
- VCR tests created for primary use case
- Code path fully traced from function → generic_request → httr2
- Both single and bulk scenarios covered

**Ready for:** Milestone v1.2 completion

---

_Verified: 2026-01-28T17:17:23Z_
_Verifier: Claude (gsd-verifier)_
