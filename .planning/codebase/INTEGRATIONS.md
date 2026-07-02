# External Integrations

**Analysis Date:** 2026-02-12

## APIs & External Services

**CompTox Chemistry Dashboard:**
- USEPA's primary chemical hazard and property database
- SDK/Client: Built-in via httr2 + generic_request() template
- Auth: `ctx_api_key` environment variable (x-api-key header)
- Base URL: Configurable via `ctx_server()` (Production/Staging/Development/Scraping)
- Functions: All `ct_*` functions (e.g., `ct_hazard()`, `ct_cancer()`, `ct_env_fate()`)

**Cheminformatics Microservices:**
- Multiple specialized EPA chemical analysis services
- SDK/Client: Built-in via httr2 + generic_chemi_request() template
- Auth: No API key required (most endpoints)
- Base URL: Configurable via `chemi_server()` (Production/Staging/Development)
- Endpoints include:
  - ToxPrints: Chemical fingerprinting (`chemi_toxprint()`)
  - Safety profiles (`chemi_safety()`)
  - Hazard profiling (`chemi_hazard()`)
  - ClassyFire classification (`chemi_classyfire()`)
  - Resolver: Chemical identifier resolution (`chemi_resolver()`)
  - RQ Codes (`chemi_rq()`)
  - AMOS database searches (`chemi_amos*()`)
  - Alerts module (`chemi_alerts*()`)
- Location: `R/z_generic_request.R` - `generic_chemi_request()` function
- Payload structure: Nested JSON with chemicals array and options object

**EPI Suite API:**
- USEPA Estimation Programs Interface Suite
- SDK/Client: httr2 via `epi_suite_search()` and `epi_suite_analysis()`
- Auth: None required
- Base URL: Configurable via `epi_server()` (Production only)
- Endpoints:
  - `/search` - Search by CASRN
  - `/submit` - Analysis submission
- Implementation: `R/epi_suite.R`
- Sequential request execution with progress tracking

**ECOTOX Database:**
- EPA's ecological toxicity database
- SDK/Client: httr2 via `eco_server()` configuration
- Auth: None required
- Base URL: Configurable via `eco_server()` (Dashboard/Production/Local)
- Purpose: Bioactivity and environmental toxicity data
- Multiple endpoints via CompTox Dashboard integration

**CAS Common Chemistry API:**
- CAS Registry chemical identifier and property database
- SDK/Client: Built-in via httr2 + generic_cc_request() template
- Auth: `cc_api_key` environment variable (required for some endpoints)
- Base URL: Configurable via `cc_server()` (Production)
- URL: `https://commonchemistry.cas.org/api/`
- Functions:
  - `cc_search()` - Search by CAS RN, SMILES, InChI, InChIKey, name (with wildcard support)
  - `cc_detail()` - Get detailed substance information
  - `cc_export()` - Export substance data
- Implementation: `R/cc_api_key.R`, `R/cc_search.R`, `R/cc_detail.R`, `R/cc_export.R`

**Natural Products Database:**
- Natural products chemical database
- SDK/Client: httr2 via `np_server()` configuration
- Auth: None required
- Base URL: Configurable via `np_server()` (Production)
- URL: `https://api.naturalproducts.net/latest/`
- Currently not fully integrated (commented out in setup)

## Data Storage

**Databases:**
- None - this is a client-side wrapper package

**Caching:**
- Session-level caching in `.ComptoxREnv` (internal R environment)
  - Location: `R/zzz.R` - `.onLoad()` function
  - Cached objects:
    - `.ComptoxREnv$extractor` - Formula extraction regex compiled once per session
    - `.ComptoxREnv$classifier` - Compound classification function compiled once per session
  - Access: Used by formula/mixture extraction functions to avoid recompilation

**File Storage:**
- API schemas stored locally: `schema/` directory
  - Production, staging, development schemas for each API
  - OpenAPI 3.1.0 and Swagger 2.0 formats
  - Auto-downloaded via `ct_schema()` function

## Testing & Mocking

**HTTP Mocking Framework:**
- vcr - Records/replays HTTP interactions as YAML cassettes
- Configuration: `tests/testthat/helper-vcr.R`
- Cassette directory: `tests/testthat/fixtures/`
- API key sanitization: All `ctx_api_key` values replaced with `<<<API_KEY>>>` before committing
- First run: Requires valid API keys; hits production and records responses
- Subsequent runs: Uses recorded cassettes (no API key needed)

**Test Data:**
- Fixtures stored in `tests/testthat/fixtures/` directory
- Test helper functions in `tests/testthat/helper-*.R`

## Authentication & Identity

**CompTox Dashboard:**
- API Key Authentication via `x-api-key` HTTP header
- Environment variable: `ctx_api_key`
- Setter: `ct_api_key()` function validates key is set
- Location: `R/ct_api_key.R`
- Request from: ccte_api@epa.gov

**CAS Common Chemistry:**
- API Key Authentication
- Environment variable: `cc_api_key`
- Setter: `cc_api_key()` function validates key is set
- Location: `R/cc_api_key.R`

**Cheminformatics:**
- Most endpoints public (no authentication)
- Some specialized endpoints may require authentication (future)

## Monitoring & Observability

**Health Checks:**
- `run_setup()` function performs endpoint health checks on package attach
- Ping endpoints for all configured APIs with latency measurement
- Status: OK/WARN/ERROR with color-coded output
- Latency thresholds: <300ms (green), <1000ms (yellow), >1000ms (red)
- Cheminformatics endpoint availability reported (active/total endpoints)

**Logging:**
- `cli` package for formatted console output
- No external logging service integrated
- Debug mode: `run_debug(TRUE)` for dry-run without actual requests
- Verbose mode: `run_verbose(TRUE)` for detailed logging

**Error Handling:**
- HTTP errors (4xx/5xx) trigger warnings, return NULL/empty for batch
- Connection errors caught in health checks
- Timeout handling: 5-second timeout on health check requests
- Smart error messages via cli package

## Environment Configuration

**Required env vars for authenticated endpoints:**
- `ctx_api_key` - CompTox Dashboard API key
- `cc_api_key` - CAS Common Chemistry API key

**Optional env vars:**
- `ctx_burl` - CompTox Dashboard URL (auto-set by `ctx_server()`)
- `chemi_burl` - Cheminformatics URL (auto-set by `chemi_server()`)
- `epi_burl` - EPI Suite URL (auto-set by `epi_server()`)
- `eco_burl` - ECOTOX URL (auto-set by `eco_server()`)
- `cc_burl` - Common Chemistry URL (auto-set by `cc_server()`)
- `np_burl` - Natural Products URL (auto-set by `np_server()`)
- `run_debug` - Debug flag (auto-set by `run_debug()`)
- `run_verbose` - Verbose flag (auto-set by `run_verbose()`)
- `batch_limit` - Batch size (auto-set by `batch_limit()`, default 200)

**Development vs Production:**
- DEV version (no package date) defaults to Staging/Dev environments
- Production version defaults to Production environments
- Can be overridden via `*_server()` functions

## Request Patterns

**Generic Request Template:**
- Location: `R/z_generic_request.R` - `generic_request()` function
- Used by: All `ct_*` functions (9+ functions)
- Features:
  - Automatic batching (default 200 items per request)
  - Support for both POST and GET methods
  - Multiple path parameters support
  - Query normalization and deduplication
  - Tidy tibble or raw list output
  - Custom content-type support (JSON, text, image)

**Generic Cheminformatics Request Template:**
- Location: `R/z_generic_request.R` - `generic_chemi_request()` function
- Used by: All `chemi_*` functions (5+ functions)
- Features:
  - Nested JSON payload structure (chemicals + options)
  - Configurable identifier label (usually "sid")
  - Response field extraction
  - Tidy tibble or raw list output

**Generic Common Chemistry Request Template:**
- Location: `R/z_generic_request.R` - `generic_cc_request()` function (assumed)
- Used by: `cc_search()`, `cc_detail()`, `cc_export()`
- Features:
  - GET method queries with pagination support
  - Result filtering and post-processing

## Response Handling

**JSON Responses:**
- Parsed via jsonlite::fromJSON()
- Converted to tidy tibbles by default
- Unicode normalization via `clean_unicode()` when needed
- Sensitive data (formula extraction, molecular properties) post-processed

**Text Responses:**
- Returned as character strings for text/plain content type

**Image Responses:**
- Returned as raw bytes or magick image objects if package available
- Support for PNG, SVG+XML, and other image formats

## Batch Processing

**Default Behavior:**
- All requests automatically batched at 200 items per POST
- Configurable via `batch_limit()` function (stored in env var)
- Prevents API rate limits and request size exceeded errors
- Example: Query with 500 DTXSIDs splits into 3 requests (200+200+100)

**Constraints:**
- Path parameters cannot be used with batching
- Static endpoints (batch_limit=0) require no query
- Single-item queries (batch_limit=1) append to URL path

---

*Integration audit: 2026-02-12*
