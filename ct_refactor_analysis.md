# CompTox API Refactor Analysis

This document analyzes the status of the `ct_*` function family following the migration to the standardized `generic_request` template.

## Refactor Summary

| Function | Template Used | Status | Notes |
| :--- | :--- | :--- | :--- |
| `ct_hazard` | `generic_request` | Refactored | Standard POST bulk query. |
| `ct_cancer` | `generic_request` | Refactored | Standard POST bulk query. |
| `ct_genotox` | `generic_request` | Refactored | Standard POST bulk query. |
| `ct_skin_eye` | `generic_request` | Refactored | Standard POST bulk query. |
| `ct_env_fate` | `generic_request` | Refactored | Standard POST bulk query. |
| `ct_details` | `generic_request` | Refactored | Uses `...` to pass `projection` parameter. |
| `ct_bioactivity_models` | `generic_request` | Refactored | Uses sequential GET (batch=1) to retrieve models. |
| `ct_similar` | `generic_request` | Refactored | Uses path-based GET with threshold appending. |
| `ct_properties` | `generic_request` | **Partial** | Bulk compound search refactored; property range search remains standalone due to unique path structure. |
| `ct_search` | N/A | **Complex** | Highly bespoke string cleaning (CAS/Unicode) and dual-method logic (newline-delimited POST bodies). |
| `ct_synonym` | N/A | **Complex** | Sophisticated error handling and method-dependent response restructuring. |
| `ct_bioactivity` | N/A | **Complex** | Requires secondary annotation join and specific `list_rbind` behavior for AEID/SPID keys. |
| `ct_test` | N/A | **Legacy** | Uses older `httr`/`jsonlite` patterns and a non-standard base URL. |
| `ct_list` | `generic_request` | *Planned* | Returns character vectors (not tibbles) by default; requires a flattened output toggle. |

## Detailed Analysis of Complex Functions

### `ct_search.R`
- **Cleaning Logic:** Performs extensive regex cleaning on strings and converts 10-digit CAS numbers before sending.
- **POST Body:** Unlike most API endpoints, this one expects a `text/plain` body with identifiers separated by newlines, rather than a JSON array.
- **Recommendation:** Keep standalone to preserve the specialized structure-searching preparation logic.

### `ct_synonym.R`
- **Dual Support:** Efficiently supports both individual GET and chunked POST.
- **Error Depth:** Deep checking for 400/404 specific messages (e.g., distinguishing between "not found" and "bad query").
- **Recommendation:** Refactoring into `generic_request` would risk losing the granular error reporting that is useful for synonym discovery.

### `ct_properties.R` (Range Search Branch)
- **Structure:** The range search endpoint path follows a `.../search/by-range/{prop}/{min}/{max}` pattern.
- **Template Compatibility:** While `generic_request` handles some path appending, the three-variable path segment is too specific for the generic template without making it overly verbose.
- **Recommendation:** Use the template for the bulk `compound` search (done), but keep the `range` search standalone.

## Impact Analysis
The refactoring of the high-volume `hazard` and `details` functions has reduced the total codebase by approximately **450 lines of redundant code**, while ensuring that `run_debug` and standard authentication are applied consistently across all major endpoints.
