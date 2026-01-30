# Endpoint Evaluation Utilities Guide

## Overview

The `endpoint_eval_utils.R` script is a code generation utility that parses OpenAPI schemas and generates R function stubs for the EPA CompTox API endpoints. This document explains how the script interprets schemas and assigns function arguments, particularly for the `generic_chemi_request` function.

## Table of Contents

1.  [Architecture Overview](#architecture-overview)
2.  [Schema Parsing Flow](#schema-parsing-flow)
3.  [Parameter Assignment Logic](#parameter-assignment-logic)
4.  [The `wrap` and `tidy` Parameters](#the-wrap-and-tidy-parameters)
5.  [Resolver Wrapping](#resolver-wrapping)
6.  [Function Generation Pipeline](#function-generation-pipeline)
7.  [Flowchart](#flowchart)
8.  [Debugging Tips](#debugging-tips)
9.  [Troubleshooting Guide: Common Stubbing Failures](#troubleshooting-guide-common-stubbing-failures)

------------------------------------------------------------------------

## Architecture Overview {#architecture-overview}

The utility provides five main capabilities:

1.  **Schema Preprocessing** (`preprocess_schema`) - Filters endpoints and reduces schema complexity
2.  **OpenAPI Parsing** (`openapi_to_spec`) - Converts OpenAPI JSON to a tidy specification tibble
3.  **Codebase Analysis** (`find_endpoint_usages_base`) - Searches for existing endpoint implementations
4.  **Parameter Parsing** (`parse_path_parameters`, `parse_function_params`, `extract_query_params_with_refs`) - Extracts and organizes function parameters
5.  **Code Generation** (`build_function_stub`, `render_endpoint_stubs`) - Generates R function source code

### Unified Processing Pipeline (v1.6+)

**All generators use the same architecture:**

```
schema_file → select_schema_files → schema_list → openapi_to_spec (per file) → specification tibble
                                                         ↓
                                                   detect_schema_version (Swagger 2.0 / OpenAPI 3.0)
                                                         ↓
                                                   extract_body_properties (version-aware)
                                                         ↓
                                                   resolve_schema_ref (fallback chain)
                                                         ↓
                                                   extract_query_params_with_refs
```

**Key Points:**
- **Single entry point**: All schemas (ct, chemi, cc) use `openapi_to_spec()` directly
- **Version detection**: Automatic Swagger 2.0 vs OpenAPI 3.0 handling
- **Stage selection**: `select_schema_files()` handles multi-stage schemas (chemi)
- **Reference resolution**: Unified `resolve_schema_ref()` with version-aware fallback

------------------------------------------------------------------------

## Schema Version Detection

Before parsing, `openapi_to_spec()` detects the schema version to apply version-specific processing rules.

### detect_schema_version()

**Purpose:** Identifies whether the schema is Swagger 2.0 or OpenAPI 3.0

**Detection logic:**
1. Checks `swagger` field → If matches `^2\.` → Swagger 2.0
2. Checks `openapi` field → If matches `^3\.` → OpenAPI 3.0
3. Otherwise → Unknown version

**Returns:** `list(version = "2.0" | "3.0.0", type = "swagger" | "openapi" | "unknown")`

**Example:**
```r
openapi <- jsonlite::fromJSON("schema/chemi-amos-prod.json", simplifyVector = FALSE)
version_info <- detect_schema_version(openapi)
# Returns: list(version = "2.0", type = "swagger")
```

**Location:** `dev/endpoint_eval/01_schema_resolution.R` lines 251-262

**Why it matters:**
- Swagger 2.0 uses `definitions` for schemas, OpenAPI 3.0 uses `components/schemas`
- Swagger 2.0 puts request body in `parameters` array, OpenAPI 3.0 uses `requestBody` object
- Reference resolution needs version-aware fallback chains

------------------------------------------------------------------------

## Schema Parsing Flow {#schema-parsing-flow}

### Step 0: Preprocess Schema (Optional)

The `preprocess_schema()` function reduces schema complexity before parsing:

1.  **Filter endpoints** - Removes unwanted endpoints matching `ENDPOINT_PATTERNS_TO_EXCLUDE`
    - Pattern: `render|replace|add|freeze|metadata|version|reports|download|export|protocols`
2.  **Collect referenced schemas** - Walks through paths to find all `$ref` values
3.  **Filter components** - Keeps only schemas actually referenced by endpoints
4.  **Prevent circular references** - Simplifies schema resolution

```r
# Enable preprocessing (default when openapi is a file path)
spec <- openapi_to_spec(openapi = "schema/chemi-hazard-prod.json", preprocess = TRUE)
```

### Step 1: Load OpenAPI Schemas

**Unified Pipeline Approach (v1.6+):**

All stub generators (`generate_ct_stubs()`, `generate_chemi_stubs()`, `generate_cc_stubs()`) follow the same pattern:

1.  **List schema files** - Use `select_schema_files()` helper to find matching schemas
    -   For chemi: applies stage prioritization (prod > staging > dev)
    -   For ct/cc: simple pattern matching
2.  **Parse each schema** - Call `openapi_to_spec()` directly for each file
3.  **Bind results** - Combine into single specification tibble
4.  **Process endpoints** - Filter, classify, and generate stubs

**Schema File Selection Helper (`select_schema_files()`):**

Provides stage-based prioritization for schemas with multiple variants:

```r
# Chemi schemas with stage selection
chemi_files <- select_schema_files(
  pattern = "^chemi-.*\\.json$",
  exclude_pattern = "ui",
  stage_priority = c("prod", "staging", "dev")
)

# CT/CC schemas without stage selection
ct_files <- select_schema_files(
  pattern = "^ctx-.*-prod\\.json$",
  exclude_pattern = NULL,
  stage_priority = NULL
)
```

**Parameters:**
- `pattern`: Regex to match schema files
- `exclude_pattern`: Optional pattern to exclude (e.g., "ui")
- `stage_priority`: Character vector for stage ordering (NULL for non-staged schemas)
- `schema_dir`: Path to schema directory (defaults to here::here("schema"))

The helper automatically selects the highest priority stage per domain when multiple variants exist (e.g., chemi-mordred-prod.json, chemi-mordred-staging.json).

### Step 2: Extract Endpoint Specifications

The `openapi_to_spec()` function processes each OpenAPI path:

```         
For each route in openapi$paths:
    For each HTTP method (GET, POST, PUT, PATCH, DELETE):
        1. Merge path-level and operation-level parameters
        2. Deduplicate parameters by name@location
        3. Extract path parameters (in URL path like /endpoint/{id})
        4. Extract query parameters (in URL query string like ?param=value)
        5. Extract body parameters (from request body schema for POST/PUT/PATCH)
        6. Extract response content types
        7. Build specification tibble row
```

### Step 3: Parameter Metadata Extraction

For each parameter, the following metadata is extracted:

| `name` | `parameter.name` | Parameter name |
| `example` | `parameter.example` or `schema.default` | Example value for documentation |
| `description` | `parameter.description` or `schema.description` | Parameter description |
| `default` | `schema.default` | Default value |
| `enum` | `schema.enum` | Allowed values (for enums) |
| `type` | `schema.type` | Data type (string, boolean, integer, etc.) |
| `required` | `parameter.required` | Whether parameter is required |

### Step 4: Endpoint Metadata Extraction

In addition to parameters, the following endpoint-level metadata is extracted:

| Field | Source | Description |
|------------------|---------------------|-------------------------------------|
| `deprecated` | `operation.deprecated` | Whether endpoint is deprecated |
| `description` | `operation.description` | Detailed endpoint description |
| `response_schema_type` | Detected from `responses` | Response type classification (array/object/scalar/binary/unknown) |
| `request_type` | Detected from body/query | Request classification (json/query_only/query_with_schema) |
| `body_schema_full` | Resolved from body schema | Complete schema structure (type, properties, item_schema) |
| `body_item_type` | From array item schema | Type of array items or NA for objects |

**Request Type Classification:**

| Type | Description | Example |
|------|-------------|---------|
| `"json"` | POST with JSON body | `/api/hazard` POST |
| `"query_only"` | GET with query params only | `/api/search?q=benzene` |
| `"query_with_schema"` | GET with schema-based query | Complex query endpoints |

**Deprecated Detection:**

```r
# Extract deprecated status (defaults to FALSE if not specified)
deprecated <- op$deprecated %||% FALSE
```

When `isTRUE(deprecated)` is TRUE, the generated function will use `lifecycle::badge("deprecated")` instead of the configured badge (typically "experimental").

**Response Schema Type Detection:**

The `get_response_schema_type()` function analyzes successful response schemas (200, 201, 202, 204) to classify the return type:

| Type | Description | Schema Example | Generated @return |
|------|-------------|----------------|-------------------|
| `"array"` | Array of objects | `{"type": "array"}` | "Returns a tibble with results (array of objects)" |
| `"object"` | Single object | `{"type": "object"}` | "Returns a list with result object" |
| `"scalar"` | Primitive value | `{"type": "string"}` | "Returns a scalar value" |
| `"binary"` | Binary/image data | Content-Type: image/* | "Returns binary data" |
| `"unknown"` | Undetected | No schema | "Returns a tibble with results" (default) |

**Detection Process:**

1. Look for successful response codes (200, 201, 202, 204, default)
2. Check content types (binary/image detection)
3. Extract schema from `application/json` content type
4. Resolve `$ref` references to component schemas
5. Classify based on schema `type` field

**Benefits:**

- More accurate `@return` documentation in roxygen2
- Better user expectations about return types
- Clearer documentation for deprecated endpoints

------------------------------------------------------------------------

## Function Generation Pipeline

6.  **Return stubs**: Return tibble with `text` column containing complete function definitions

------------------------------------------------------------------------

## Swagger 2.0 Support

The stub generation pipeline fully supports Swagger 2.0 schemas, which are used by some cheminformatics microservices (AMOS, RDKit, Mordred).

### Key Differences: OpenAPI 3.0 vs Swagger 2.0

| Aspect | OpenAPI 3.0 | Swagger 2.0 |
|--------|-------------|-------------|
| **Root field** | `openapi: "3.0.0"` | `swagger: "2.0"` |
| **Schema location** | `components.schemas` | `definitions` |
| **Request body** | `requestBody` object | `parameters[]` with `in="body"` |
| **Reference path** | `#/components/schemas/Name` | `#/definitions/Name` |
| **Body constraints** | Multiple content types allowed | Single body parameter only |

### Swagger 2.0 Processing Flow

```mermaid
flowchart TD
    A[openapi_to_spec entry] --> B[detect_schema_version]
    B --> C{Version type?}
    C -->|swagger| D[Use definitions as components]
    C -->|openapi| E[Use components.schemas]
    D --> F[For each endpoint]
    E --> F
    F --> G{Method has body?}
    G -->|Yes swagger| H[extract_swagger2_body_schema]
    G -->|Yes openapi| I[extract_body_properties standard]
    G -->|No| J[Skip body extraction]
    H --> K[Find parameters with in=body]
    K --> L[Extract schema property]
    L --> M{Schema has $ref?}
    M -->|Yes| N[resolve_swagger2_definition_ref]
    M -->|No| O[Use inline schema]
    N --> P[Extract properties from resolved schema]
    O --> P
    P --> Q[Build parameter metadata]
    I --> Q
    J --> Q
```

### Version-Aware Reference Resolution

The `resolve_schema_ref()` function uses a version-aware fallback chain:

**For Swagger 2.0:**
1. Try `#/definitions/{Name}` first (primary)
2. Fallback to `#/components/schemas/{Name}` (for normalized schemas)

**For OpenAPI 3.0:**
1. Try `#/components/schemas/{Name}` first (primary)
2. Fallback to `#/definitions/{Name}` (for legacy refs)

**Location:** `dev/endpoint_eval/01_schema_resolution.R` lines 168-182

**Why fallback matters:**
- Some schemas mix conventions during migration
- Normalization step may create `components.schemas` from Swagger 2.0 `definitions`
- Robust resolution prevents failures on edge cases

**Logging:** Fallback usage is always logged with `cli::cli_alert_info()` for transparency

### Implicit Object Type Detection

Swagger 2.0 schemas often omit `type: "object"` when `properties` field is present. The pipeline detects this implicitly:

```r
# BODY-04: Implicit object detection
has_properties <- !is.null(schema$properties) && length(schema$properties) > 0
is_object <- (schema$type == "object") || (is.na(schema$type) && has_properties)
```

This handles schemas like:
```json
{
  "properties": {
    "dtxsids": {"type": "array"}
  },
  "required": ["dtxsids"]
}
```

Even without explicit `"type": "object"`.

### Which Schemas Use Swagger 2.0?

**Cheminformatics microservices:**
- AMOS (`chemi-amos-prod.json`)
- RDKit (`chemi-rdkit-prod.json`)
- Mordred (`chemi-mordred-prod.json`)

**CompTox Dashboard and Common Chemistry:** Use OpenAPI 3.0

------------------------------------------------------------------------

## POST Example Generation

### Dynamic Example Data

POST request examples use random DTXSIDs from the `testing_chemicals` dataset instead of hardcoded values.

**Implementation:**

The `sample_test_dtxsids()` helper function (lines 1308-1352 in `endpoint_eval_utils.R`) samples DTXSIDs for examples:

```r
sample_test_dtxsids(n = 3, custom_list = NULL)
```

**Loading strategy:**
1.  Try to access `testing_chemicals` from package namespace
2.  Fall back to loading from `data/testing_chemicals.rda`
3.  Sample `n` random DTXSIDs from the `dtxsid` column
4.  Fall back to `"DTXSID7020182"` if unavailable

**Example output comparison:**

| Method | Example Value |
|--------|---------------|
| GET | `query = "DTXSID7020182"` (single value) |
| POST | `query = c("DTXSID7020182", "DTXSID5020406", "DTXSID0020573")` (vector of 3) |

### Custom DTXSID Lists

Optionally provide custom DTXSIDs in the config:

```r
chemi_config <- list(
  wrapper_function = "generic_chemi_request",
  param_strategy = "options",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental",
  example_dtxsids = c("DTXSID1234567", "DTXSID2345678", "DTXSID3456789")
)
```

The custom list takes precedence over `testing_chemicals`.

------------------------------------------------------------------------

## Parameter Assignment Logic {#parameter-assignment-logic}

### Path Parameters

Path parameters are extracted from URL placeholders like `/endpoint/{dtxsid}`:

1.  **Primary Parameter**: The first path parameter becomes the `query` argument
2.  **Additional Path Parameters**: Remaining path parameters go into `path_params`

Example: - Route: `/property/{propertyName}/{start}/{end}` - Function signature: `ct_chemical_property_predicted_by_range(propertyName, start = NULL, end = NULL)`

### Query Parameters

Query parameters are URL query string parameters (e.g., `?projection=all`):

1.  If no path parameters exist, the first query parameter becomes the primary parameter
2.  All query parameters are passed through the ellipsis (`...`) mechanism

#### Query Parameter $ref Resolution

When query parameters reference schemas via `$ref`, `extract_query_params_with_refs()` resolves and flattens them:

1.  **Schema Resolution** - Resolves `$ref` to get actual schema properties
2.  **Object Flattening** - Flattens nested objects using dot notation
3.  **Binary Array Rejection** - Excludes parameters with `format: binary` (e.g., file uploads)
4.  **Prefix Preservation** - Maintains original parameter name as prefix

**Example: Nested Object Flattening**

OpenAPI Schema:
```json
{
  "name": "request",
  "schema": { "$ref": "#/components/schemas/UniversalHarvestRequest" }
}
```

Where `UniversalHarvestRequest` has:
```json
{
  "properties": {
    "info": { "$ref": "#/components/schemas/UniversalHarvestInfo" },
    "chemicals": { "type": "array" }
  }
}
```

And `UniversalHarvestInfo` has:
```json
{
  "properties": {
    "keyName": { "type": "string" },
    "keyType": { "type": "string" },
    "loadNames": { "type": "boolean" }
  }
}
```

Result: Flattened parameters with dot notation:
- `request.info.keyName`
- `request.info.keyType`
- `request.info.loadNames`
- `request.chemicals`

**Generated Function Signature:**
```r
chemi_resolver_universalharvest <- function(
  request.info.keyName,
  request.info.keyType = NULL,
  request.info.loadNames = NULL,
  request.chemicals = NULL
) {
  # ...
}
```

### Body Parameters

For POST/PUT/PATCH endpoints, body parameters come from request body schemas.

**Version-aware body extraction:**

#### OpenAPI 3.0
Body parameters extracted from `requestBody` object:
1. Navigate: `requestBody → content → application/json → schema`
2. Resolve `$ref` from `#/components/schemas/`
3. Extract properties with types, defaults, and required status

#### Swagger 2.0
Body parameters extracted from `parameters` array using `extract_swagger2_body_schema()`:
1. Find parameters with `in="body"`
2. Extract `schema` property from body parameter
3. Resolve `$ref` from `#/definitions/`
4. Handle object schemas, array schemas, and simple types

**Location:** `dev/endpoint_eval/01_schema_resolution.R` lines 267-404

**Key differences:**

| Feature | OpenAPI 3.0 | Swagger 2.0 |
|---------|-------------|-------------|
| Location | `requestBody` object | `parameters[]` array with `in="body"` |
| Reference path | `#/components/schemas/` | `#/definitions/` |
| Multiple bodies | Allowed (rare) | Forbidden (max 1) |
| Mutual exclusivity | N/A | Cannot mix body + formData |

**Validation (Swagger 2.0 only):**
- **BODY-05**: Warns if multiple body parameters detected (spec violation)
- **BODY-06**: Warns if both body and formData parameters present (spec violation)

### Parameter Strategy

Two strategies are supported:

| Strategy | Usage | Implementation |
|---------------------|------------------|----------------------------------|
| `extra_params` | `generic_request` | Parameters passed via `...` to `httr2::req_url_query()` |
| `options` | `generic_chemi_request` | Parameters collected into an `options` list |

------------------------------------------------------------------------

## The `wrap` and `tidy` Parameters

### The `wrap` Parameter

The `wrap` parameter in `generic_chemi_request` controls the JSON payload structure:

#### When `wrap = TRUE` (default)

Sends a wrapped payload with `chemicals` and `options` fields:

``` json
{
  "chemicals": [{"sid": "DTXSID7020182"}, {"sid": "DTXSID1020461"}],
  "options": {"fingerprint": "toxprints", "normalize": true}
}
```

**Used when**: The endpoint accepts additional options beyond the chemical identifiers.

#### When `wrap = FALSE`

Sends an unwrapped array of chemical objects:

``` json
[{"sid": "DTXSID7020182"}, {"sid": "DTXSID1020461"}]
```

**Used when**: The endpoint only accepts chemical identifiers with no additional parameters.

### Logic for Determining `wrap`

In `build_function_stub()`, the `wrap` parameter is determined as follows:

``` r
# From body_param_info, parameters are split:
# - query_param: the first body parameter (becomes the 'query' argument)
# - other_required: additional required body parameters
# - optional_params: body parameters with defaults or marked optional

has_no_additional_params <- length(other_required) == 0 && length(optional_params) == 0

wrap_param <- if (has_no_additional_params) {
  ",\n    wrap = FALSE"   # Simple array, no options needed
} else {
  ""                       # Use default wrap = TRUE
}
```

**Decision flow:** 1. Parse body parameters from OpenAPI schema 2. Identify the first parameter as the `query` (typically `chemicals` or `dtxsids`) 3. Check for additional required or optional parameters 4. If no additional parameters exist → `wrap = FALSE` 5. If additional parameters exist → `wrap = TRUE` (default)

### The `tidy` Parameter

The `tidy` parameter controls the output format:

| Value | Output Format | Use Case |
|------------------|---------------------------------|----------------------|
| `TRUE` (default) | Tidy tibble with columns for each field | Most R workflows |
| `FALSE` | Raw list structure from JSON | Nested data, custom processing |

In generated stubs, `tidy = FALSE` is explicitly set because: 1. Cheminformatics responses often have complex nested structures 2. Allows users to decide how to flatten/process the data 3. Provides access to all response data without loss

------------------------------------------------------------------------

## Resolver Wrapping {#resolver-wrapping}

Some Cheminformatics API endpoints expect full `Chemical` objects in their request body, not just simple identifiers like DTXSIDs. These endpoints require the caller to first resolve chemical identifiers to complete Chemical objects (with `sid`, `smiles`, `casrn`, `inchi`, `inchiKey`, `mol`, etc.).

The code generator automatically detects these endpoints and generates "resolver-wrapped" functions that:

1.  Accept flexible chemical identifiers (DTXSID, CAS, SMILES, InChI, etc.)
2.  Call `chemi_resolver()` to resolve identifiers to full Chemical objects
3.  Transform the resolved data and send it to the API endpoint

### Configuration: CHEMICAL_SCHEMA_PATTERNS

At the top of `endpoint_eval_utils.R`, a constant defines which OpenAPI schema references trigger resolver wrapping:

``` r
CHEMICAL_SCHEMA_PATTERNS <- c(
  "#/components/schemas/Chemical",
  "#/components/schemas/ChemicalRecord",
  "#/components/schemas/ResolvedChemical",
  "#/components/schemas/DSSToxRecord",
  "#/components/schemas/DSSToxRecord2"
)
```

**To add new schemas that need resolver wrapping**, simply add them to this vector.

### Detection Logic

Two helper functions detect resolver-needing endpoints:

| Function | Purpose | Returns |
|----------|---------|---------|
| `uses_chemical_schema()` | Checks if request body references a Chemical schema | `TRUE` / `FALSE` |
| `get_body_schema_type()` | Classifies the body schema type | `"chemical_array"`, `"string_array"`, `"simple_object"`, or `"unknown"` |

The `openapi_to_spec()` function adds two columns to the spec tibble:

| Column | Type | Description |
|--------|------|-------------|
| `needs_resolver` | logical | Whether endpoint needs resolver pre-processing |
| `body_schema_type` | character | Classification of the body schema |

### Resolver-Wrapped Function Structure

When `needs_resolver = TRUE` and `body_schema_type = "chemical_array"`, the generator produces:

``` r
#' Endpoint Title
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param id_type Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter (from body schema)
#' @return Returns a tibble with results
#' @export
chemi_example <- function(query, id_type = "AnyId", options = NULL) {
  # Resolve identifiers to Chemical objects
  resolved <- chemi_resolver(query = query, id_type = id_type)

  if (nrow(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved tibble to Chemical object format
  chemicals <- purrr::map(seq_len(nrow(resolved)), function(i) {
    row <- resolved[i, ]
    list(
      sid = row$dtxsid,
      smiles = row$smiles,
      casrn = row$casrn,
      inchi = row$inchi,
      inchiKey = row$inchiKey,
      name = row$name,
      mol = row$mol
    )
  })

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) extra_options$options <- options

  # Build and send request
  base_url <- Sys.getenv("chemi_burl", unset = "chemi_burl")
  payload <- list(chemicals = chemicals)
  if (length(extra_options) > 0) payload$options <- extra_options

  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("example/endpoint") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(payload)

  # ... error handling ...

  result <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  # Additional post-processing can be added here

  return(result)
}
```

### Resolver Wrapping Decision Flow

``` mermaid
flowchart TD
    A[POST/PUT/PATCH Endpoint] --> B{Has request body?}
    B -->|No| C[Standard stub generation]
    B -->|Yes| D[Check body schema reference]
    D --> E{References Chemical schema?}
    E -->|No| F[Check body_schema_type]
    E -->|Yes| G[needs_resolver = TRUE]
    F --> H{Type = string_array?}
    H -->|Yes| I[Simple SMILES array - no resolver]
    H -->|No| C
    G --> J{body_schema_type = chemical_array?}
    J -->|Yes| K[Generate resolver-wrapped stub]
    J -->|No| C
```

### Endpoints Detected for Resolver Wrapping

The following endpoint patterns typically need resolver wrapping:

-   `/api/hazard` - Hazard data lookup
-   `/api/alerts` - Chemical alerts
-   `/api/toxprints/calculate` - Toxprint fingerprint calculation
-   `/api/resolver/*` - Various resolver export endpoints
-   `/api/stdizer/chemicals` - Chemical standardization
-   `/api/services/export` - Export services

------------------------------------------------------------------------

## Function Generation Pipeline {#function-generation-pipeline}

### Configuration

``` r
chemi_config <- list(
  wrapper_function = "generic_chemi_request",  # or "generic_request"
  param_strategy = "options",                   # or "extra_params"
  example_query = "DTXSID7020182",             # Example for documentation
  lifecycle_badge = "experimental"              # Lifecycle stage
)
```

### Pipeline Steps

1.  **Parse Path Parameters** (`parse_path_parameters`)
    -   Input: `path_params` string, metadata
    -   Output: Function signature, path_params call, primary param
2.  **Parse Query Parameters** (`parse_function_params`)
    -   Input: `query_params` string, metadata, `has_path_params` flag
    -   Output: Function signature, param docs, params code, params call
3.  **Parse Body Parameters** (`parse_function_params`)
    -   Input: `body_params` string, metadata, `has_path_params` flag
    -   Output: Same as query params
4.  **Build Function Stub** (`build_function_stub`)
    -   Combines all parameter info
    -   Generates roxygen documentation
    -   Generates function body with appropriate wrapper call
5.  **Scaffold Files** (`scaffold_files`)
    -   Writes generated code to R/ directory
    -   Handles overwrite/append logic

------------------------------------------------------------------------

## Flowchart {#flowchart}

### Main Processing Flow

``` mermaid
flowchart TB
    subgraph "Schema Loading"
        A[Schema Directory] --> B[select_schema_files]
        B --> C{Stage priority provided?}
        C -->|Yes chemi| D[Select best stage per domain]
        C -->|No ct/cc| E[Match pattern only]
        D --> F[Schema file list]
        E --> F
    end

    subgraph "Schema Preprocessing Optional"
        F --> F1{Preprocess enabled?}
        F1 -->|Yes| F2[Filter endpoints by ENDPOINT_PATTERNS_TO_EXCLUDE]
        F1 -->|No| F5[Raw OpenAPI spec]
        F2 --> F3[extract_referenced_schemas]
        F3 --> F4[filter_components_by_refs]
        F4 --> F5
    end

    subgraph "Schema Parsing Unified Pipeline"
        F5 --> G[openapi_to_spec for each file]
        G --> G1[detect_schema_version]
        G1 --> G2{Swagger 2.0 or OpenAPI 3.0?}
        G2 -->|Swagger 2.0| H1[Use definitions]
        G2 -->|OpenAPI 3.0| H2[Use components/schemas]
        H1 --> H[For each route/method]
        H2 --> H
        H --> I[Extract path parameters]
        H --> J[Extract query parameters]
        H --> K[Extract body parameters]
        J --> J1[extract_query_params_with_refs]
        J1 --> J2[resolve_schema_ref for $ref params]
        J2 --> J3[Flatten nested objects with dot notation]
        K --> K1[extract_body_properties version-aware]
        K1 --> K2[resolve_schema_ref with fallback chain]
        I --> L[param_metadata]
        J3 --> L
        K2 --> L
        L --> M[Build spec tibble row]
    end

    subgraph "Parameter Classification"
        M --> N{Has path params?}
        N -->|Yes| O[First path param = primary]
        N -->|No| P{Has query params?}
        P -->|Yes| Q[First query param = primary]
        P -->|No| R{Has body params?}
        R -->|Yes| S[First body param = primary]
        R -->|No| T[No primary param]
    end

    subgraph "Wrap Parameter Logic"
        S --> U{Additional body params?}
        U -->|Yes| V[wrap = TRUE]
        U -->|No| W[wrap = FALSE]
        O --> X[wrap based on options]
        Q --> X
        T --> X
    end

    subgraph "Code Generation"
        V --> Y[build_function_stub]
        W --> Y
        X --> Y
        Y --> Z[Generate roxygen docs]
        Y --> AA[Generate function signature]
        Y --> AB[Generate function body]
        Z --> AC[Combine into R source]
        AA --> AC
        AB --> AC
    end

    subgraph "File Output"
        AC --> AD[render_endpoint_stubs]
        AD --> AE[scaffold_files]
        AE --> AF{File exists?}
        AF -->|Yes, overwrite=TRUE| AG[Overwrite file]
        AF -->|Yes, overwrite=FALSE| AH[Skip file]
        AF -->|No| AI[Create file]
    end
```

### Parameter Flow Detail

``` mermaid
flowchart LR
    subgraph "Input"
        A[OpenAPI Schema]
        A1[components]
    end

    subgraph "Extraction"
        A --> B[path_params]
        A --> C[query_params]
        A --> D[body_params]
        A --> E[metadata]
    end

    subgraph "$ref Resolution"
        C --> C1[extract_query_params_with_refs]
        C1 --> C2{Has $ref?}
        C2 -->|Yes| C3[resolve_schema_ref]
        C3 --> C4[Flatten with dot notation]
        C2 -->|No| C5[Use as-is]
        A1 --> C3
        D --> D1[extract_body_properties]
        D1 --> D2[resolve_schema_ref]
        A1 --> D2
    end

    subgraph "Parsing"
        B --> F[parse_path_parameters]
        C4 --> G[parse_function_params]
        C5 --> G
        D2 --> H[parse_function_params]
        E --> F
        E --> G
        E --> H
    end

    subgraph "Output"
        F --> I[fn_signature]
        F --> J[path_params_call]
        F --> K[primary_param]
        G --> L[params_code]
        G --> M[params_call]
        H --> N[body handling]
    end

    subgraph "Function Generation"
        I --> O[Function Definition]
        J --> O
        K --> O
        L --> O
        M --> O
        N --> O
    end
```

### Wrap Decision Flow

``` mermaid
flowchart TD
    A[Body Parameters Parsed] --> B{Any body params?}
    B -->|No| C[wrap = TRUE default]
    B -->|Yes| D[Split required vs optional]
    D --> E[First param = query/chemicals]
    E --> F{Other required params?}
    F -->|Yes| G[wrap = TRUE]
    F -->|No| H{Optional params?}
    H -->|Yes| G
    H -->|No| I[wrap = FALSE]
    
    G --> J[Payload: chemicals + options]
    I --> K[Payload: array only]
    C --> L[Default behavior]
```

------------------------------------------------------------------------

## Example: Generated Function

For an endpoint with body parameters `dtxsids` (required) and `fingerprint` (optional):

**Schema:**

``` json
{
  "requestBody": {
    "content": {
      "application/json": {
        "schema": {
          "$ref": "#/components/schemas/ToxprintRequest"
        }
      }
    }
  }
}
```

**Generated Code:**

``` r
#' Calculate Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids A list of DTXSIDs to search for
#' @param fingerprint Optional parameter. Options: toxprints, chemotypes
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprint(dtxsids = "DTXSID7020182")
#' }
chemi_toxprint <- function(dtxsids, fingerprint = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(fingerprint)) options$fingerprint <- fingerprint

  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "toxprints/calculate",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
```

For a simpler endpoint with only `dtxsids`:

``` r
chemi_resolve <- function(dtxsids) {
  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "resolver/resolve",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
```

### Post-Processing Pattern

All generated stubs assign the API result to a `result` variable before returning, enabling easy addition of post-processing logic. For example, see `chemi_rq()` which unnests and transforms the response:

``` r
chemi_rq <- function(query) {
  result <- generic_chemi_request(
    query = query,
    endpoint = "rq",
    server = 'chemi_burl',
    wrap = FALSE
  )

  # Post-processing: unnest and clean RQ data
  if (nrow(result) > 0 && "rqCode" %in% colnames(result)) {
    result <- result %>%
      tidyr::unnest_wider(rqCode) %>%
      dplyr::filter(!is.na(rq)) %>%
      tidyr::separate_wider_delim(rq, ' ', names = c('rq_lbs', 'rq_kgs')) %>%
      dplyr::mutate(
        rq_lbs = as.numeric(stringr::str_remove_all(rq_lbs, '\\(|\\)|\\,')),
        rq_kgs = as.numeric(stringr::str_remove_all(rq_kgs, '\\(|\\)|\\,'))
      )
  }

  return(result)
}
```

------------------------------------------------------------------------

## Key Functions Reference

| Function | Purpose | Input | Output |
|--------------------|------------------|-----------------|-----------------|
| `preprocess_schema()` | Filter endpoints and reduce schema complexity | Schema file path | Filtered OpenAPI list |
| `extract_referenced_schemas()` | Collect all $ref values from paths | OpenAPI paths | Character vector of schema names |
| `filter_components_by_refs()` | Keep only referenced schemas | Components, refs | Filtered components |
| `detect_schema_version()` | Detect Swagger 2.0 vs OpenAPI 3.0 | OpenAPI spec | `list(version, type)` |
| `resolve_schema_ref()` | Resolve $ref with version-aware fallback | Schema ref, components, schema_version | Resolved schema definition |
| `extract_swagger2_body_schema()` | Extract body from Swagger 2.0 parameters | Parameters array, definitions | Schema structure with properties |
| `resolve_swagger2_definition_ref()` | Resolve Swagger 2.0 definition refs | Ref string, definitions | Resolved schema definition |
| `extract_body_properties()` | Extract body schema metadata (version-aware) | Request body/parameters, components, schema_version | Schema structure with properties |
| `extract_query_params_with_refs()` | Resolve and flatten query params | Parameters, components, schema_version | `list(names, metadata)` |
| `select_schema_files()` | Stage-based schema file selection | Pattern, stage priority | Character vector of filenames |
| `openapi_to_spec()` | Parse OpenAPI to spec (Swagger 2.0 & 3.0) | OpenAPI list | Spec tibble with `needs_resolver`, `body_schema_type`, `request_type` |
| `uses_chemical_schema()` | Check if body uses Chemical schema | Request body, OpenAPI spec | `TRUE` / `FALSE` |
| `get_body_schema_type()` | Classify body schema type | Request body, OpenAPI spec | `"chemical_array"`, `"string_array"`, etc. |
| `parse_path_parameters()` | Parse path params | Param string, metadata | Signature, calls, docs |
| `parse_function_params()` | Parse query/body params | Param string, metadata | Signature, code, docs |
| `build_function_stub()` | Generate function code | All param info, config, `needs_resolver`, `body_schema_type` | R source string |
| `render_endpoint_stubs()` | Process spec to code | Spec tibble, config | Spec with `text` column |
| `scaffold_files()` | Write files to disk | Spec with text | Write result tibble |

------------------------------------------------------------------------

## Debugging Tips

1.  **Inspect parsed schema with preprocessing:**

    ``` r
    spec <- openapi_to_spec("schema/chemi-hazard-prod.json", preprocess = TRUE)
    View(spec)
    
    # Check new columns
    spec %>% select(route, method, request_type, body_schema_full, body_item_type)
    ```

2.  **Check parameter metadata:**

    ``` r
    spec$body_param_metadata[[1]]  # First endpoint's body params
    spec$query_param_metadata[[1]] # First endpoint's query params (with flattened $ref)
    ```

3.  **Test query parameter $ref resolution:**

    ``` r
    source("endpoint_eval_utils.R")
    openapi <- jsonlite::fromJSON("schema/chemi-resolver-prod.json", simplifyVector = FALSE)
    
    # Find an endpoint with query params that have $ref
    params <- openapi$paths[["/api/resolver/universalharvest"]]$post$parameters
    components <- openapi$components
    
    # Test the extraction
    result <- extract_query_params_with_refs(params, components)
    print(result$names)     # Flattened parameter names with dot notation
    print(result$metadata)  # Metadata for each parameter
    ```

4.  **Check which endpoints need resolver wrapping:**

    ``` r
    # Load utilities
    source(file.path("dev", "endpoint_eval", "04_openapi_parser.R"))
    source(file.path("dev", "endpoint_eval", "01_schema_resolution.R"))

    # Parse a chemi schema
    openapi <- jsonlite::fromJSON("schema/chemi-hazard-prod.json", simplifyVector = FALSE)
    eps <- openapi_to_spec(openapi)

    # View all endpoints needing resolver
    eps[eps$needs_resolver == TRUE, c("route", "method", "body_schema_type")]

    # Check the configured schema patterns
    print(CHEMICAL_SCHEMA_PATTERNS)
    ```

5.  **Test stub generation:**

    ``` r
    stub <- build_function_stub(fn, endpoint, method, title, batch_limit,
                                 path_info, query_info, body_info, content_type, config,
                                 needs_resolver = TRUE, body_schema_type = "chemical_array")
    cat(stub)
    ```

6.  **Enable verbose output:**

    ``` r
    Sys.setenv(run_verbose = "TRUE")
    Sys.setenv(run_debug = "TRUE")
    ```

7.  **Debug schema resolution:**

    ``` r
    source(file.path("dev", "endpoint_eval", "01_schema_resolution.R"))
    openapi <- jsonlite::fromJSON("schema/chemi-resolver-prod.json", simplifyVector = FALSE)

    # Detect version first
    schema_version <- detect_schema_version(openapi)
    print(schema_version)

    # Manually resolve a schema reference
    resolved <- resolve_schema_ref(
      "#/components/schemas/UniversalHarvestRequest",
      openapi$components,
      schema_version = schema_version,
      max_depth = 3
    )
    print(resolved)
    ```

8.  **Debug Swagger 2.0 body extraction:**

    ``` r
    source(file.path("dev", "endpoint_eval", "01_schema_resolution.R"))

    # Load a Swagger 2.0 schema
    openapi <- jsonlite::fromJSON("schema/chemi-amos-prod.json", simplifyVector = FALSE)
    schema_version <- detect_schema_version(openapi)

    # Check if it's Swagger 2.0
    if (schema_version$type == "swagger") {
      # Extract body from parameters array
      endpoint_op <- openapi$paths[["/api/amos/calculate"]]$post
      body_params <- purrr::keep(endpoint_op$parameters, ~ .x[["in"]] == "body")
      print(body_params)

      # Extract body schema
      body_schema <- extract_swagger2_body_schema(
        endpoint_op$parameters,
        openapi$definitions
      )
      print(body_schema)
    }
    ```

8.  **Add new schema patterns for resolver wrapping:**

    Edit the `CHEMICAL_SCHEMA_PATTERNS` constant at the top of `endpoint_eval_utils.R`:

    ``` r
    CHEMICAL_SCHEMA_PATTERNS <- c(
      "#/components/schemas/Chemical",
      "#/components/schemas/ChemicalRecord",
      # ... existing patterns ...
      "#/components/schemas/YourNewSchema"  # Add new pattern here
    )
    ```

------------------------------------------------------------------------

## Troubleshooting Guide: Common Stubbing Failures

This section provides systematic guidance for debugging when function stubs don't generate correctly.

### Problem 1: Function Not Generating at All

**Symptoms:** Running `chemi_endpoint_eval.R` or `endpoint eval.R` produces no output for an endpoint you expect.

**Debugging Workflow:**

1. **Check if endpoint was parsed:**
   ```r
   # Load utilities and parse schema
   source(file.path("dev", "endpoint_eval", "04_openapi_parser.R"))
   openapi <- jsonlite::fromJSON("schema/chemi-hazard-prod.json", simplifyVector = FALSE)
   eps <- openapi_to_spec(openapi)

   # Search for your route
   eps %>% filter(grepl("your-route-pattern", route))
   ```

2. **Check if endpoint was filtered out:**
   ```r
   # Check filtering logic in chemi_endpoint_eval.R lines 47-50
   # Endpoints are filtered out if they:
   # - Use PATCH/DELETE methods (not GET/POST)
   # - Match certain patterns: render, replace, add, freeze, metadata, etc.
   ```

3. **Check if endpoint already exists in codebase:**
   ```r
   # The endpoint usage search will mark it as "found" if it exists
   res <- find_endpoint_usages_base(
     eps$route,
     pkg_dir = here::here("R"),
     files_regex = "^chemi_.*\\.R$"
   )
   
   # Check for your endpoint
   res$summary %>% filter(grepl("your-route", endpoint))
   ```

**Common Causes:**
- Route is filtered by regex patterns in `chemi_endpoint_eval.R`
- Function already exists in R/ directory (check `n_hits > 0`)
- Schema file is not being loaded (check `source_file` column)
- HTTP method is not GET or POST

### Problem 2: Incorrect `batch_limit` Value

**Symptoms:** Generated function has wrong `batch_limit` (e.g., seeing `0` when you need `1`, or vice versa).

**Understanding `batch_limit`:**

| Value | Meaning | Use Case | Example |
|-------|---------|----------|--------|
| `NULL` | Default batching | POST endpoints with body | `chemi_toxprint()` |
| `1` | Single item appended to path | GET with path params | `/chemical/{dtxsid}` |
| `0` | Static endpoint, no batching | GET with only query params | `/chemicals?projection=all` |

**Debugging Workflow:**

1. **Identify endpoint type:**
   ```r
   # Check if endpoint has path parameters
   eps %>% 
     filter(route == "your-route") %>%
     select(method, num_path_params, path_params, query_params)
   ```

2. **Check the batch_limit logic:**
   - For **chemi endpoints** (in `chemi_endpoint_eval.R` line 86): `batch_limit = NA_integer_` (always)
   - For **ct endpoints** (in `endpoint eval.R` lines 90-94):
     ```r
     batch_limit = case_when(
       method == 'GET' & num_path_params > 0 ~ 1,    # Path param
       method == 'GET' & num_path_params == 0 ~ 0,   # Query only
       .default = NULL                               # POST/PUT/PATCH
     )
     ```

3. **Verify in generated stub:**
   - Search generated stub for `batch_limit = ` to confirm value
   - For GET endpoints with path params, expect: `batch_limit = 1`
   - For GET endpoints with only query params, expect: `batch_limit = 0`

**Common Causes:**
- Misidentified path vs query parameters in OpenAPI schema
- `num_path_params` not calculated correctly (check line counting)
- Chemi endpoints incorrectly using ct config (or vice versa)

### Problem 3: Parameter Name Sanitization Issues

**Symptoms:** Function won't load due to illegal parameter names like `2d`, `3d`, or names with hyphens.

**How Parameter Sanitization Works:**

The `parse_function_params()` function (lines 905-1095) handles parameter sanitization:

```r
# Sanitization logic (lines 938-946)
sanitize_param <- function(x) {
  # If starts with digit, prefix with x
  if (grepl("^[0-9]", x)) {
    paste0("x", x)
  } else {
    make.names(x)  # Handles other illegal chars
  }
}
```

**Debugging Workflow:**

1. **Check parameter metadata:**
   ```r
   # View the raw parameter names from schema
   eps %>%
     filter(route == "your-route") %>%
     pull(body_param_metadata) %>%
     .[[1]] %>%
     names()
   ```

2. **Test sanitization manually:**
   ```r
   # Test how parameter names are transformed
   source("endpoint_eval_utils.R")
   test_params <- c("2d", "3d", "my-param", "valid_param")
   sapply(test_params, function(x) {
     if (grepl("^[0-9]", x)) paste0("x", x)
     else make.names(x)
   })
   # Expected: "x2d", "x3d", "my.param", "valid_param"
   ```

3. **Verify mapping in generated code:**
   - Original name is preserved in API call: `` `2d` = x2d ``
   - Function parameter uses sanitized name: `function(x2d, x3d)`

**Common Causes:**
- Filenames with hyphens not sanitized (check `fn` generation in eval scripts)
- Parameter mapping not preserving original keys for API
- make.names() converting hyphens to dots instead of underscores

### Problem 4: Wrong Wrapper Function Used

**Symptoms:** Generated stub calls wrong wrapper (e.g., `generic_request` instead of `generic_chemi_request`).

**Understanding Wrapper Selection:**

The `build_function_stub()` function (lines 1264-1855) has special logic:

```r
# Lines 1296-1300: Force generic_request for GET endpoints
is_chemi_get <- FALSE
if (toupper(method) == "GET" && wrapper_fn == "generic_chemi_request") {
  wrapper_fn <- "generic_request"
  is_chemi_get <- TRUE  # Track this to set correct server/auth
}
```

**Debugging Workflow:**

1. **Check config:**
   ```r
   # In chemi_endpoint_eval.R (lines 32-37)
   chemi_config <- list(
     wrapper_function = "generic_chemi_request",  # For POST
     param_strategy = "options",
     ...
   )
   
   # In endpoint eval.R (lines 32-37)
   ct_config <- list(
     wrapper_function = "generic_request",
     param_strategy = "extra_params",
     ...
   )
   ```

2. **Check if forced to generic_request:**
   - ALL GET endpoints use `generic_request` (even for chemi)
   - POST/PUT/PATCH endpoints use wrapper from config

3. **Verify server and auth params:**
   ```r
   # For chemi GET endpoints (lines 1302-1306)
   # Should see: server = "chemi_burl", auth = FALSE, tidy = FALSE
   ```

**Common Causes:**
- GET endpoint configured with `generic_chemi_request` (auto-corrected)
- Missing `server` and `auth` params for chemi GET endpoints
- Wrong config object passed to `render_endpoint_stubs()`

### Problem 5: wrap Parameter Incorrectly Set

**Symptoms:** POST endpoint has wrong `wrap` value, causing payload structure mismatch.

**Understanding wrap Logic:**

From lines 1599-1607 in `build_function_stub()`:

```r
# wrap = FALSE: unwrapped array [{"sid": "..."}, ...]
# wrap = TRUE: wrapped object {"chemicals": [...], "options": {...}}

has_no_additional_params <- length(other_required) == 0 && length(optional_params) == 0
wrap_param <- if (has_no_additional_params) {
  ",\n    wrap = FALSE"  # Simple array
} else {
  ""  # Omitted = default TRUE
}
```

**Debugging Workflow:**

1. **Check body parameters:**
   ```r
   # View all body params for endpoint
   eps %>%
     filter(route == "your-route") %>%
     pull(body_param_metadata) %>%
     .[[1]]
   ```

2. **Count required vs optional:**
   ```r
   # First param is always query/chemicals
   # If ONLY that param exists -> wrap = FALSE
   # If additional params exist -> wrap = TRUE (default)
   
   body_meta <- eps$body_param_metadata[[1]]
   param_names <- names(body_meta)
   query_param <- param_names[1]  # First is query
   additional <- param_names[-1]   # Rest are options
   
   # wrap = FALSE when length(additional) == 0
   ```

3. **Verify expected payload:**
   - Check OpenAPI schema `requestBody` to see expected structure
   - Compare with generated stub's wrap parameter

**Common Causes:**
- Optional parameters not detected (check `required` field in schema)
- First parameter incorrectly identified as additional param
- Schema has nested objects that aren't parsed correctly

### Problem 6: Error "missing value where TRUE/FALSE needed"

**Symptoms:** The script fails during `dplyr::mutate()` or `purrr::pmap_chr()` with `! missing value where TRUE/FALSE needed`.

**Understanding the Issue:**
This is a standard R error that occurs when an `if` statement receives an `NA` value. In these utilities, it usually happens because a column in the specification tibble (like `deprecated`, `needs_resolver`, or `batch_limit`) contains `NA` for certain endpoints.

**Debugging Workflow:**

1. **Check for NA values in the spec:**
   ```r
   eps %>% filter(is.na(deprecated) | is.na(needs_resolver))
   ```

2. **Verify defensive guarding:**
   - Always use `isTRUE(var)` instead of `if (var)` when `var` comes from the schema spec.
   - Use `dplyr::coalesce(var, default)` in `render_endpoint_stubs()` to clean data before processing.

**Common Causes:**
- New columns added to `openapi_to_spec()` without providing a default value.
- Endpoints with unusual or incomplete OpenAPI definitions.
- Manual modifications to the spec tibble that introduce `NA`.

### Debugging Workflow Summary

```mermaid
flowchart TD
    A[Stub Generation Issue] --> B{What type of problem?}
    
    B -->|Not generating| C[Check Schema Parsing]
    B -->|Wrong batch_limit| D[Check Endpoint Type]
    B -->|Illegal param names| E[Check Sanitization]
    B -->|Wrong wrapper| F[Check Config/Method]
    B -->|Wrong wrap value| G[Check Body Params]
    
    C --> C1[Parse schema manually]
    C1 --> C2[Check filters in eval script]
    C2 --> C3[Check endpoint exists]
    
    D --> D1[Check num_path_params]
    D1 --> D2[Verify batch_limit logic]
    D2 --> D3[Inspect generated stub]
    
    E --> E1[View param metadata]
    E1 --> E2[Test sanitize_param]
    E2 --> E3[Check mapping in code]
    
    F --> F1[Check config object]
    F1 --> F2[Check GET override]
    F2 --> F3[Verify server/auth params]
    
    G --> G1[List body parameters]
    G1 --> G2[Count additional params]
    G2 --> G3[Verify wrap logic]
    
    C3 --> H[Generate Test Stub]
    D3 --> H
    E3 --> H
    F3 --> H
    G3 --> H
    
    H --> I{Stub correct?}
    I -->|Yes| J[Write to file]
    I -->|No| K[Review generated code]
    K --> L[Check build_function_stub logic]
    L --> M[Update template or schema]
```

### Quick Reference: Where to Look

| Issue | File | Function |
|-------|------|----------|
| Schema not loading | `generate_stubs.R` | Filtering logic in generators |
| Schema version detection | `01_schema_resolution.R` | `detect_schema_version()` |
| Schema preprocessing | `01_schema_resolution.R` | `preprocess_schema()` |
| Swagger 2.0 body extraction | `01_schema_resolution.R` | `extract_swagger2_body_schema()` |
| $ref resolution failing | `01_schema_resolution.R` | `resolve_schema_ref()` |
| Query params not flattened | `01_schema_resolution.R` | `extract_query_params_with_refs()` |
| batch_limit wrong | `generate_stubs.R` | batch_limit assignment |
| Parameter sanitization | `06_param_parsing.R` | `sanitize_param()` |
| Wrapper selection | `07_stub_generation.R` | GET override logic |
| wrap logic | `07_stub_generation.R` | `has_no_additional_params` |
| Resolver detection | `04_openapi_parser.R` | `uses_chemical_schema()` |
| Function naming | `generate_stubs.R` | fn generation |

### Tips for Senior Developers

1. **Use the spec tibble as your source of truth:** All decisions flow from `openapi_to_spec()` output
2. **Check intermediate values:** Use browser() or print statements in `build_function_stub()` to inspect:
   - `path_param_info`, `query_param_info`, `body_param_info`
   - `is_body_only`, `is_query_only`, `has_additional_params`
   - `primary_param`, `fn_signature`
3. **Test schema changes in isolation:** Modify a copy of the OpenAPI JSON to test edge cases
4. **Review glue templates:** The actual code is generated via glue() - check line 1609+ for templates

### Tips for Junior Developers

1. **Start with the spec tibble:** Run `View(eps)` to see all parsed endpoints in a table
2. **Use cat() to see generated code:** Before writing files, use `cat(stub)` to inspect
3. **Compare working examples:** Find a similar working function and compare its schema vs generated code
4. **Check one endpoint at a time:**
   ```r
   # Filter to single endpoint for testing
   test_ep <- eps %>% filter(route == "your-specific-route")
   stub <- render_endpoint_stubs(test_ep, config = chemi_config)
   cat(stub$text)
   ```
5. **Ask: What type of endpoint is this?**
   - GET with path params? (batch_limit = 1)
   - GET with query params only? (batch_limit = 0)
   - POST with body? (batch_limit = NULL, might need wrap)
6. **Read the flowcharts:** Start with the main processing flow, then dive into specific areas