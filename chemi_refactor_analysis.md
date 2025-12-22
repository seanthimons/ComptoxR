# Cheminformatics Refactor Analysis

This document analyzes the amenability of the `chemi_*` function family to refactoring using standardized request templates (`generic_request` and `generic_chemi_request`).

## Refactor Summary

| Function | Template Used | Status | Notes |
| :--- | :--- | :--- | :--- |
| `chemi_toxprint` | `generic_chemi_request` | Refactored | Perfect fit for nested payload structure. |
| `chemi_classyfire`| `generic_request` | Refactored | No auth required; uses path-based GET. |
| `chemi_rq` | `generic_request` | Refactored | Simple POST with list body. |
| `chemi_safety` | `generic_request` | Refactored | Post-processing kept internal; request standardized. |
| `chemi_search` | N/A | **Not Amenable** | Complex body with `inputType`, `searchType`, and raw MOL strings. Requires custom parameters. |
| `chemi_hazard` | Partial | **Complex** | Request standardized, but includes ~400 lines of coercion logic. |
| `chemi_resolver`| N/A | **Not Amenable** | Custom pagination (batch of 200) and highly specific payload keys (`ids`, `idsType`, `fuzzy`). |
| `chemi_predict` | N/A | **Not Amenable** | Performs internal `chemi_resolver` call before request; custom payload structure. |
| `chemi_cluster` | `generic_chemi_request` | Possible | Requires `chemi_resolver` call first; secondary parsing of `order` and `similarity` keys. |

## Detailed Analysis of Non-Amenable Functions

### `chemi_search.R`
- **Complexity:** The function builds a highly dynamic `params` list based on 10+ arguments.
- **Payload:** Uses `inputType = "MOL"` and `query = MOL_STRING`. Most standardized templates expect JSON-serializable lists or IDs.
- **Recommendation:** Keep as a standalone function due to its unique role as a multi-parameter chemical search engine.

### `chemi_resolver.R`
- **Pagination:** Uses a hardcoded batch limit of 200, whereas others use 1000.
- **Payload:** The body is a flat dictionary with specific flags (`fuzzy`, `ids`, `idsType`, `mol`) rather than the standardized `chemicals`/`options` pattern.
- **Recommendation:** Maintain as a core utility function as it is a dependency for other `chemi_*` functions.

### `chemi_hazard.R`
- **Logic Density:** While the HTTP request fits the `generic_chemi_request` pattern, the data processing (coercing letters to numbers, GHS code mapping, authority penalties) is the primary value of the function.
- **Recommendation:** Refactor only the `POST` request section to reduce boilerplate, while keeping the logic switches internal.
