# Architecture

**Analysis Date:** 2026-02-12

## Pattern Overview

**Overall:** Template-based API wrapper pattern with centralized request handling

**Key Characteristics:**
- All API interactions flow through two centralized template functions (`generic_request` and `generic_chemi_request`)
- Session-level environment management for configuration and caching
- Lazy-loaded data objects bundled with the package
- Factory pattern for expensive computations (formula extractors, classifiers)
- VCR cassette-based testing with sanitized sensitive data

## Layers

**API Wrapper Layer:**
- Purpose: Provide high-level, user-facing functions for specific EPA databases (CompTox Dashboard, Cheminformatics, EPI Suite, ECOTOX)
- Location: `R/ct_*.R`, `R/chemi_*.R`, `R/epi_*.R`, `R/eco_*.R`, `R/cc_*.R`
- Contains: 300+ wrapper functions following naming convention
- Depends on: Request template functions, resolver utilities, server configuration
- Used by: End users and downstream analysis code

**Request Template Layer:**
- Purpose: Centralize HTTP request construction, batching, authentication, and response handling
- Location: `R/z_generic_request.R`
- Contains: `generic_request()` (CompTox/EPI/ECOTOX), `generic_chemi_request()` (Cheminformatics), `generic_cc_request()` (Common Chemistry)
- Depends on: httr2 for HTTP, cli for messaging, dplyr/tidyr for data manipulation
- Used by: All API wrapper functions

**Configuration & State Layer:**
- Purpose: Manage server endpoints, API authentication, debugging flags, and session-level caching
- Location: `R/zzz.R`
- Contains: Server setup functions (`ctx_server()`, `chemi_server()`, etc.), debug/verbose modes, batch limits, `.ComptoxREnv` cache
- Depends on: base R environment system
- Used by: Request templates and initialization hooks

**Utility & Helper Layer:**
- Purpose: Provide domain-specific utilities (CASRN validation, identifier resolution, scoring matrices, data extraction)
- Location: `R/util_*.R`, `R/chemi_resolver_*.R`, `R/extract_*.R`, `R/misc_functions.R`
- Contains: CAS validation, ClassyFire resolver, molecular formula extraction, mixture extraction
- Depends on: stringr, stringi, regex patterns
- Used by: Wrapper functions for data transformation and validation

**Data Layer:**
- Purpose: Bundle reference data and lookup tables as package data
- Location: `data/*.rda`, `R/data.R`
- Contains: Periodic table, property IDs, toxprint dictionaries, species lookups, ToxValDB source rankings
- Depends on: None (static data)
- Used by: Resolver functions, visualization functions, data enrichment

## Data Flow

**Standard API Query Flow:**

1. User calls wrapper function (e.g., `ct_hazard("DTXSID7020182")`)
2. Wrapper constructs parameters and calls `generic_request()` or `generic_chemi_request()`
3. Template function:
   - Resolves server URL from environment variable or direct URL
   - Normalizes and deduplicates query input
   - Batches query if exceeds batch limit (default 200)
   - Constructs httr2 request(s) with authentication headers
   - Executes sequentially if multiple batches (to respect rate limits)
4. Response processing:
   - Extracts HTTP body (JSON, text, or image)
   - Filters sensitive data via VCR (in tests)
   - Converts to tidy tibble format (optional)
   - Returns data or empty tibble

**Resolver/Identifier Lookup Flow:**

1. User provides chemical identifiers (DTXSID, CAS, SMILES, InChI, etc.)
2. `chemi_resolver_lookup_bulk()` or similar resolver function called
3. Resolver sends identifiers to Cheminformatics API
4. API returns standardized Chemical objects with fields: dtxsid, smiles, casrn, inchi, inchikey
5. Downstream wrapper functions (e.g., `chemi_hazard_bulk()`) extract needed fields and pass to API

**State Management:**

- `.ComptoxREnv` internal environment stores:
  - `.ComptoxREnv$extractor` - Pre-compiled formula extractor function (created in `.onLoad()`)
  - `.ComptoxREnv$classifier` - Pre-compiled compound classifier (created in `.onLoad()`)
- System environment variables store:
  - API endpoints (ctx_burl, chemi_burl, epi_burl, eco_burl, cc_burl)
  - API keys (ctx_api_key, cc_api_key)
  - Behavior flags (run_debug, run_verbose, batch_limit)

## Key Abstractions

**Request Template Abstraction:**
- Purpose: Eliminate code duplication across 300+ wrapper functions
- Examples: `R/z_generic_request.R` contains `generic_request()` and `generic_chemi_request()`
- Pattern: Wrapper functions pass endpoint, query, method, and options to template; template handles all HTTP mechanics

**Batch Processing Abstraction:**
- Purpose: Transparently split large queries into smaller batches
- Examples: `ct_hazard(list_of_1000_dtxsids)` automatically batches into 5 requests of 200
- Pattern: Template splits query via `split()` and maps httr2 request construction

**Server/Environment Abstraction:**
- Purpose: Support multiple API environments (production, staging, development) without code changes
- Examples: `ctx_server(1)` sets production, `ctx_server(2)` sets staging
- Pattern: Functions read from `Sys.getenv()` via variable name indirection

**Resolver Abstraction:**
- Purpose: Normalize heterogeneous chemical identifiers to standardized Chemical objects
- Examples: `chemi_resolver_lookup_bulk(c("50-00-0", "DTXSID7020182", "benzene"))`
- Pattern: Resolver accepts multiple ID types, returns standardized format for downstream use

## Entry Points

**Package Initialization (.onAttach / .onLoad):**
- Location: `R/zzz.R` lines 528-602
- Triggers: When package is loaded via `library(ComptoxR)` or `devtools::load_all()`
- Responsibilities:
  - Set default server URLs based on package version (dev vs production)
  - Initialize batch limits, debug, and verbose modes
  - Pre-compile expensive functions (formula extractor, classifier)
  - Display startup header with endpoint health checks

**User-Facing Wrapper Functions:**
- Location: 300+ files in `R/ct_*.R`, `R/chemi_*.R`, `R/epi_*.R`, etc.
- Triggers: Direct function calls in user code
- Responsibilities: Accept domain-specific parameters, validate inputs, call appropriate request template

**Server Configuration Functions:**
- Location: `R/zzz.R` lines 213-406
- Triggers: User calls `ctx_server(1)`, `chemi_server(2)`, etc.
- Responsibilities: Switch API endpoint URLs

**Debug/Verbose Mode Functions:**
- Location: `R/zzz.R` lines 408-507
- Triggers: User calls `run_debug(TRUE)`, `run_verbose(TRUE)`
- Responsibilities: Toggle dry-run mode and logging behavior

## Error Handling

**Strategy:** Graceful degradation with informative messaging via `cli` package

**Patterns:**

1. **Input Validation (Pre-Request):**
   - `generic_request()` validates query is non-empty after normalization
   - Wrapper functions validate domain-specific constraints (e.g., similarity 0-1 for `ct_similar()`)
   - Uses `cli::cli_abort()` for user-facing errors with formatted messages

2. **HTTP Error Handling (Response Processing):**
   - Template functions check HTTP status codes (200-299 range)
   - Status >= 300 triggers `cli::cli_warn()` and returns NULL for that batch
   - Multiple batches continue processing even if some fail (via `httr2::req_perform_sequential(..., on_error = 'continue')`)

3. **Empty Result Handling:**
   - Empty API responses return empty tibble (if `tidy=TRUE`) or empty list (if `tidy=FALSE`)
   - Resolver functions return NULL with warning if no identifiers resolve

4. **Authentication Failures:**
   - `ct_api_key()` helper checks API key presence and aborts with instructions if missing
   - API endpoints that require authentication fail with HTTP 401/403 (caught by HTTP error handling)

## Cross-Cutting Concerns

**Logging:**
- Framework: `cli` package for user-facing messages
- Patterns:
  - `run_verbose(TRUE)` enables `cli::cli_rule()`, `cli::cli_dl()`, and progress bars
  - Request templates display batch info and endpoint health
  - `cli::cli_alert_*()` for warnings, errors, info messages

**Validation:**
- Functions validate:
  - Query vectors: non-empty, no NAs, unique values
  - Path parameters: cannot be used with batching
  - Domain-specific ranges: e.g., similarity 0-1, batch_limit > 0
  - HTTP status codes: 200-299 success, others trigger warnings

**Authentication:**
- CompTox Dashboard and Common Chemistry endpoints require API keys in `x-api-key` header
- Keys sourced from environment variables: `ctx_api_key`, `cc_api_key`
- Cheminformatics and ECOTOX endpoints typically don't require authentication

**Batching:**
- Global batch limit configurable via `batch_limit()` function (default 200)
- Per-endpoint override via `batch_limit` parameter to request templates
- POST endpoints support larger batches (e.g., 1000 items)
- GET path-based endpoints use `batch_limit=1` (one item per request)

**Response Tidying:**
- JSON responses converted to tibbles via `purrr::list_rbind()` + `tibble::as_tibble()`
- Nested lists preserved as list columns
- NULL values replaced with NA in tibble conversion
- Image/text responses bypass tidying and return raw bytes or strings

---

*Architecture analysis: 2026-02-12*
