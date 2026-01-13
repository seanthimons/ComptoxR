# ==============================================================================
# Endpoint Evaluation Utilities
# ==============================================================================
#
# Shared utility functions for OpenAPI schema-driven code generation.
# Used by endpoint eval.R and chemi_endpoint_eval.R to generate R function
# stubs from EPA CompTox API specifications.
#
# Purpose:
#   - Parse OpenAPI schemas into tidy dataframes
#   - Search codebase for existing endpoint implementations
#   - Generate roxygen-documented R function stubs
#   - Write generated files to disk with safety checks
#
# Usage:
#   source("endpoint_eval_utils.R")
#
# Dependencies:
#   - tidyverse (dplyr, purrr, stringr, tibble)
#   - jsonlite
#   - fs, readr (for file operations)
#   - glue (for template rendering)
#
# ==============================================================================

# Load required packages
library(jsonlite)
library(tidyverse)

# ==============================================================================
# Configuration: Schema Patterns that Require Resolver Wrapping
# ==============================================================================
#
# These OpenAPI schema references indicate endpoints that accept full Chemical
# objects. Functions for these endpoints will first call chemi_resolver() to
# convert identifiers (DTXSID, CAS, SMILES, etc.) to complete Chemical objects.
#
# To add new schemas that need resolver wrapping, add them to this vector.
# Format: "#/components/schemas/SchemaName"
#
CHEMICAL_SCHEMA_PATTERNS <- c(
  "#/components/schemas/Chemical",
  "#/components/schemas/ChemicalRecord",
  "#/components/schemas/ResolvedChemical",
  "#/components/schemas/DSSToxRecord",
  "#/components/schemas/DSSToxRecord2"
)

# Helper: NULL-coalesce
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  if (length(x) == 1 && is.na(x)) return(y)
  x
}

# Helper: ensure columns exist in data frame
ensure_cols <- function(df, cols_with_defaults) {
  nr <- nrow(df)
  for (col in names(cols_with_defaults)) {
    if (!(col %in% names(df))) {
      val <- cols_with_defaults[[col]]
      if (is.list(val) && length(val) == 1) {
        # Handle list-column defaults
        df[[col]] <- replicate(nr, val[[1]], simplify = FALSE)
      } else {
        df[[col]] <- rep(val, length.out = nr)
      }
    }
  }
  df
}

# ==============================================================================
# Path Manipulation
# ==============================================================================

#' Strip curly parameter placeholders from endpoint paths
#'
#' This utility removes `{}` parameter tokens from endpoint strings and optionally
#' normalises leading and trailing slashes.
#' @param paths Character vector of endpoint paths that may contain tokens such as `{id}`.
#' @param keep_trailing_slash Logical; if FALSE the trailing slash is removed.
#' @param leading_slash Character, one of "keep", "ensure", "remove" to control the leading slash.
#' @return A character vector of cleaned endpoint paths.
#' @examples
#' strip_curly_params(c("/hazard/{id}/"))
#' @export
strip_curly_params <- function(paths, keep_trailing_slash = TRUE, leading_slash = c("keep", "ensure", "remove")) {
  leading_slash <- match.arg(leading_slash)

  # 1) Remove {param} tokens
  out <- str_replace_all(paths, "\\{[^}]+\\}", "")

  # 2) Collapse duplicate slashes
  out <- str_replace_all(out, "/{2,}", "/")

  # 3) Trailing slash handling
  if (!keep_trailing_slash) {
    out <- str_remove(out, "/$")
  }

  # 4) Leading slash handling
  if (leading_slash == "ensure") {
    out <- ifelse(str_starts(out, "/"), out, paste0("/", out))
  } else if (leading_slash == "remove") {
    # Remove any leading slash(es)
    out <- str_remove(out, "^/+")
  } # "keep" leaves as-is

  out
}

# ==============================================================================
# Codebase Analysis
# ==============================================================================

#' Find usages of API endpoints in the package source
#'
#' Scans R source files for occurrences of given endpoint paths.
#' @param endpoints Character vector of endpoint strings (may contain `{}` placeholders).
#' @param pkg_dir Directory of the package to scan; defaults to current directory.
#' @param ignore_case Logical, whether the search is case‑insensitive.
#' @param files_regex Regex for file extensions to include (e.g., "\\.(R|Rmd|qmd|Rnw|Rd|md)$").
#' @param include_no_leading_slash Logical, also search for paths without a leading slash.
#' @param keep_trailing_slash Logical, retain trailing slash in base paths.
#' @return A list with two elements:
#'   \describe{\item{hits}{data.frame of each match with file, line, text, etc.}\item{summary}{summary data.frame per endpoint.}}
#' @export
find_endpoint_usages_base <- function(
  endpoints,
  pkg_dir = ".",
  ignore_case = TRUE,
  files_regex = "\\.(R|Rmd|qmd|Rnw|Rd|md)$",
  include_no_leading_slash = TRUE,
  keep_trailing_slash = TRUE
) {
  base_paths <- strip_curly_params(endpoints, keep_trailing_slash = keep_trailing_slash, leading_slash = 'remove')

  # Include variants without a leading slash to catch code that stores paths "bare"
  patterns <- unique(c(base_paths, if (include_no_leading_slash) str_remove(base_paths, "^/")))

  files <- list.files(pkg_dir, pattern = files_regex, recursive = TRUE, full.names = TRUE)

  scan_file <- function(f, pat) {
    lines <- tryCatch(readLines(f, warn = FALSE), error = function(e) character())
    if (!length(lines)) {
      return(NULL)
    }
    # fixed() does literal matching with optional ignore_case
    hits <- which(str_detect(lines, fixed(pat, ignore_case = ignore_case)))
    if (!length(hits)) {
      return(NULL)
    }
    data.frame(
      file = f,
      line = hits,
      text = substr(lines[hits], 1, 240),
      stringsAsFactors = FALSE
    )
  }

  hits_list <- list()
  for (i in seq_along(endpoints)) {
    ep <- endpoints[i]
    bp <- base_paths[i]
    pat_set <- unique(c(bp, if (include_no_leading_slash) str_remove(bp, "^/")))
    for (pat in pat_set) {
      for (f in files) {
        h <- scan_file(f, pat)
        if (!is.null(h)) {
          h$endpoint <- ep
          h$base_path <- bp
          h$pattern <- pat
          hits_list[[length(hits_list) + 1]] <- h
        }
      }
    }
  }

  hits <- if (length(hits_list)) {
    do.call(rbind, hits_list)
  } else {
    data.frame(
      file = character(),
      line = integer(),
      text = character(),
      endpoint = character(),
      base_path = character(),
      pattern = character(),
      stringsAsFactors = FALSE
    )
  }

  summarize_ep <- function(ep_df) {
    ep_df <- ep_df[order(ep_df$file, ep_df$line), , drop = FALSE]
    first <- ep_df[1, , drop = FALSE]
    data.frame(
      endpoint = first$endpoint,
      base_path = first$base_path,
      n_hits = nrow(ep_df),
      n_files = length(unique(ep_df$file)),
      first_file = first$file,
      first_line = first$line,
      first_snippet = first$text,
      stringsAsFactors = FALSE
    )
  }

  if (nrow(hits)) {
    by_ep <- split(hits, hits$endpoint, drop = TRUE)
    summary_found <- do.call(rbind, lapply(by_ep, summarize_ep))
  } else {
    summary_found <- data.frame(
      endpoint = character(),
      base_path = character(),
      n_hits = integer(),
      n_files = integer(),
      first_file = character(),
      first_line = integer(),
      first_snippet = character(),
      stringsAsFactors = FALSE
    )
  }

  missing_eps <- setdiff(endpoints, summary_found$endpoint)
  if (length(missing_eps)) {
    summary_missing <- data.frame(
      endpoint = missing_eps,
      base_path = strip_curly_params(
        missing_eps,
        keep_trailing_slash = keep_trailing_slash,
        leading_slash = 'remove'
      ),
      n_hits = 0L,
      n_files = 0L,
      first_file = NA_character_,
      first_line = NA_integer_,
      first_snippet = NA_character_,
      stringsAsFactors = FALSE
    )
    summary <- rbind(summary_found, summary_missing)
  } else {
    summary <- summary_found
  }

  # Keep original order
  summary <- summary[match(endpoints, summary$endpoint), , drop = FALSE]

  list(hits = hits, summary = summary)
}

# ==============================================================================
# OpenAPI Parsing
# ==============================================================================

#' Convert an OpenAPI specification to a tidy data.frame of endpoint specs
#'
#' Parses the OpenAPI JSON object and extracts routes, HTTP methods, and parameter information.
#' @param openapi List parsed from an OpenAPI JSON file (as produced by `jsonlite::fromJSON`).
#' @param default_base_url Optional base URL to use if the OpenAPI document does not specify one.
#' @param name_strategy Strategy for naming generated functions: "operationId" (uses the operationId field) or "method_path" (constructs a name from HTTP method and path).
#' @return A tibble with columns: route, method, summary, has_body, params (list of parameter names).
#' @export
openapi_to_spec <- function(
  openapi,
  default_base_url = NULL,
  name_strategy = c("operationId", "method_path")
) {
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")
  if (!requireNamespace("tibble", quietly = TRUE)) stop("Package 'tibble' is required.")
  if (!requireNamespace("stringr", quietly = TRUE)) stop("Package 'stringr' is required.")

  name_strategy <- match.arg(name_strategy)

  sanitize_name <- function(x) {
    x <- stringr::str_replace_all(x, "[^A-Za-z0-9_]", "_")
    x <- stringr::str_replace_all(x, "_+", "_")
    x <- stringr::str_trim(x)
    x
  }
  method_path_name <- function(route, method) {
    p <- gsub("^/|/$", "", route)
    p <- gsub("\\{([^}]+)\\}", "by_\\1", p)
    p <- gsub("[^A-Za-z0-9]+", "_", p)
    p <- gsub("_+", "_", p)
    tolower(paste0(method, "_", p))
  }
  dedup_params <- function(params) {
    if (!length(params)) return(list())
    keys <- purrr::map_chr(params, ~ paste(.x[["name"]] %||% "", .x[["in"]] %||% "", sep = "@"))
    params[!duplicated(keys)]
  }
  param_names <- function(params, where, exclude_pattern = "^files\\[\\]$") {
    purrr::map_chr(
      purrr::keep(params, ~ identical(.x[["in"]], where) &&
                           !grepl(exclude_pattern, .x[["name"]] %||% "")),
      ~ .x[["name"]] %||% ""
    ) -> nm
    nm[nzchar(nm)]
  }

  # Extract parameter metadata (examples, descriptions, defaults, enums, types, required status)
  param_metadata <- function(params, where, exclude_pattern = "^files\\[\\]$") {
    relevant_params <- purrr::keep(params, ~ identical(.x[["in"]], where) &&
                                              !grepl(exclude_pattern, .x[["name"]] %||% ""))
    if (length(relevant_params) == 0) return(list())

    metadata <- purrr::map(relevant_params, function(p) {
      schema <- p[["schema"]] %||% list()

      list(
        name = p[["name"]] %||% "",
        example = p[["example"]] %||% schema[["default"]] %||% NA,  # Fallback to default
        description = p[["description"]] %||% schema[["description"]] %||% "",  # Check schema too
        default = schema[["default"]] %||% NA,  # Explicit default field
        enum = schema[["enum"]] %||% NULL,  # Allowed values
        type = schema[["type"]] %||% NA,  # Data type
        required = p[["required"]] %||% FALSE  # Required status
      )
    })

    # Filter out params with no name
    metadata <- purrr::keep(metadata, ~ nzchar(.x$name))

    # Convert to named list for easier lookup
    names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
    metadata
  }

  # Check if a request body uses the Chemical schema pattern
  # Returns TRUE if the request body contains Chemical objects that should be resolved first
  uses_chemical_schema <- function(request_body, openapi_spec) {
    if (is.null(request_body) || !is.list(request_body)) return(FALSE)

    # Navigate: requestBody -> content -> application/json -> schema -> $ref
    content <- request_body[["content"]] %||% list()
    json_schema <- content[["application/json"]][["schema"]] %||% list()

    # Get the schema reference
    ref <- json_schema[["$ref"]]
    if (is.null(ref) || !nzchar(ref)) return(FALSE)

    # Parse the reference
    ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
    if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
      return(FALSE)
    }

    schema_name <- ref_parts[4]

    # Resolve the schema from components
    components <- openapi_spec[["components"]] %||% list()
    schemas <- components[["schemas"]] %||% list()
    schema_def <- schemas[[schema_name]]

    if (is.null(schema_def) || !is.list(schema_def)) return(FALSE)

    # Check if the schema has a 'chemicals' property that references Chemical, ChemicalRecord, or ResolvedChemical
    properties <- schema_def[["properties"]] %||% list()

    # Check 'chemicals' property specifically
    chemicals_prop <- properties[["chemicals"]]
    if (!is.null(chemicals_prop)) {
      # Check if it's an array of Chemical-like objects
      items <- chemicals_prop[["items"]] %||% list()
      item_ref <- items[["$ref"]] %||% ""

      # Check if the array items reference a Chemical-like schema
      # Uses the CHEMICAL_SCHEMA_PATTERNS constant defined at module level
      if (any(item_ref %in% CHEMICAL_SCHEMA_PATTERNS)) {
        return(TRUE)
      }
    }

    # Also check for 'main', 'selectedForSimilarity' or other single Chemical references
    for (prop_name in c("main", "selectedForSimilarity", "chemical")) {
      prop <- properties[[prop_name]]
      if (!is.null(prop)) {
        prop_ref <- prop[["$ref"]] %||% ""
        if (grepl("#/components/schemas/Chemical", prop_ref, fixed = TRUE)) {
          return(TRUE)
        }
      }
    }

    return(FALSE)
  }

  # Determine the body schema type for code generation
  # Returns: "chemical_array" (needs resolver), "string_array" (SMILES), "simple_object", or "unknown"
  get_body_schema_type <- function(request_body, openapi_spec) {
    if (is.null(request_body) || !is.list(request_body)) return("unknown")

    # Navigate: requestBody -> content -> application/json -> schema -> $ref
    content <- request_body[["content"]] %||% list()
    json_schema <- content[["application/json"]][["schema"]] %||% list()

    # Get the schema reference
    ref <- json_schema[["$ref"]]
    if (is.null(ref) || !nzchar(ref)) return("unknown")

    # Parse the reference
    ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
    if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
      return("unknown")
    }

    schema_name <- ref_parts[4]

    # Resolve the schema from components
    components <- openapi_spec[["components"]] %||% list()
    schemas <- components[["schemas"]] %||% list()
    schema_def <- schemas[[schema_name]]

    if (is.null(schema_def) || !is.list(schema_def)) return("unknown")

    # Check 'chemicals' property
    properties <- schema_def[["properties"]] %||% list()
    chemicals_prop <- properties[["chemicals"]]

    if (!is.null(chemicals_prop)) {
      items <- chemicals_prop[["items"]] %||% list()
      item_ref <- items[["$ref"]] %||% ""
      item_type <- items[["type"]] %||% ""

      # Check if the array items reference a Chemical-like schema
      # Uses the CHEMICAL_SCHEMA_PATTERNS constant defined at module level
      if (any(item_ref %in% CHEMICAL_SCHEMA_PATTERNS)) {
        return("chemical_array")
      }

      # String array (SMILES) - doesn't need resolver
      if (item_type == "string") {
        return("string_array")
      }
    }

    return("simple_object")
  }

  # Determine the response schema type for code generation
  # Returns: "array", "object", "scalar", "binary", or "unknown"
  get_response_schema_type <- function(responses, openapi_spec) {
    if (is.null(responses) || !is.list(responses)) return("unknown")
    
    # Look for successful response codes
    success_codes <- intersect(names(responses), c("200", "201", "202", "204", "default"))
    if (length(success_codes) == 0) return("unknown")
    
    # Check first successful response
    resp <- responses[[success_codes[1]]]
    content <- resp$content %||% list()
    
    # Check for binary/image content types first
    if (any(grepl("^image/", names(content))) || any(grepl("octet-stream", names(content)))) {
      return("binary")
    }
    
    # Check application/json response
    json_schema <- content[["application/json"]]$schema %||% list()
    
    # If no JSON schema, return unknown
    if (length(json_schema) == 0) return("unknown")
    
    # Check for $ref - need to resolve it
    if (!is.null(json_schema[["$ref"]])) {
      ref <- json_schema[["$ref"]]
      ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
      if (length(ref_parts) >= 4 && ref_parts[2] == "components" && ref_parts[3] == "schemas") {
        schema_name <- ref_parts[4]
        components <- openapi_spec[["components"]] %||% list()
        schemas <- components[["schemas"]] %||% list()
        json_schema <- schemas[[schema_name]] %||% list()
      }
    }
    
    # Determine type from schema
    schema_type <- json_schema[["type"]] %||% ""
    
    if (schema_type == "array") return("array")
    if (schema_type == "object") return("object")
    if (schema_type %in% c("string", "number", "integer", "boolean")) return("scalar")
    
    # Default to unknown
    return("unknown")
  }

  # Extract metadata from request body schema reference
  # Parses POST endpoint request bodies that reference schemas in #/components/schemas
  extract_body_schema_metadata <- function(request_body, openapi_spec) {
    if (is.null(request_body) || !is.list(request_body)) return(list())

    # Navigate: requestBody -> content -> application/json -> schema -> $ref
    content <- request_body[["content"]] %||% list()
    json_schema <- content[["application/json"]][["schema"]] %||% list()

    # Check if this is a schema reference
    ref <- json_schema[["$ref"]]
    if (is.null(ref) || !nzchar(ref)) return(list())

    # Parse the reference (e.g., "#/components/schemas/LookupRequest")
    # Format: #/components/schemas/{SchemaName}
    ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
    if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
      return(list())
    }

    schema_name <- ref_parts[4]

    # Resolve the schema from components
    components <- openapi_spec[["components"]] %||% list()
    schemas <- components[["schemas"]] %||% list()
    schema_def <- schemas[[schema_name]]

    if (is.null(schema_def) || !is.list(schema_def)) return(list())

    # Extract properties
    properties <- schema_def[["properties"]] %||% list()
    required_fields <- schema_def[["required"]] %||% character(0)

    # Build metadata for each property
    metadata <- purrr::imap(properties, function(prop, prop_name) {
      list(
        name = prop_name,
        description = prop[["description"]] %||% "",
        type = prop[["type"]] %||% NA,
        enum = prop[["enum"]] %||% NULL,
        default = prop[["default"]] %||% NA,
        required = prop_name %in% required_fields,
        example = prop[["example"]] %||% prop[["default"]] %||% NA
      )
    })

    # Filter and return as named list
    metadata <- purrr::keep(metadata, ~ nzchar(.x$name))
    names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
    metadata
  }

  order_path_by_route <- function(path_names, route) {
    if (!length(path_names)) return(character(0))
    m <- stringr::str_match_all(route, "\\{([^}]+)\\}")
    if (length(m) >= 1 && length(m[[1]]) && nrow(m[[1]]) > 0) {
      in_route <- m[[1]][, 2]
      unique(c(in_route[in_route %in% path_names], setdiff(path_names, in_route)))
    } else {
      unique(path_names)
    }
  }

  base_url <- default_base_url %||% {
    srv <- openapi$servers
    if (is.list(srv) && length(srv) && !is.null(srv[[1]]$url)) srv[[1]]$url else "https://example.com"
  }

  paths <- openapi$paths
  if (!is.list(paths) || !length(paths)) stop("OpenAPI object has no 'paths'.")

  purrr::imap_dfr(paths, function(path_item, route) {
    path_level_params <- path_item$parameters %||% list()
    meths <- intersect(names(path_item), c("get", "post", "put", "patch", "delete", "head", "options", "trace"))

    purrr::map_dfr(meths, function(method) {
      op <- path_item[[method]]
      op_params <- op$parameters %||% list()
      parameters <- dedup_params(c(path_level_params, op_params))

      path_names  <- order_path_by_route(param_names(parameters, "path"), route)
      query_names <- param_names(parameters, "query")  # keep declared order

      # Extract parameter metadata (examples and descriptions)
      path_meta  <- param_metadata(parameters, "path")
      query_meta <- param_metadata(parameters, "query")

      # Extract request body schema metadata for POST/PUT/PATCH
      body_meta <- if (method %in% c("post", "put", "patch")) {
        extract_body_schema_metadata(op$requestBody, openapi)
      } else {
        list()
      }

      # Extract body parameter names (ordered by required first, then alphabetically)
      body_names <- if (length(body_meta) > 0) {
        # Split into required and optional
        required_names <- names(purrr::keep(body_meta, ~ .x$required))
        optional_names <- names(purrr::keep(body_meta, ~ !.x$required))
        c(required_names, optional_names)
      } else {
        character(0)
      }

      # Combine all parameters (path parameters first, then query parameters)
      combined <- c(path_names, query_names)

      has_body <- !is.null(op$requestBody)
      operationId <- op$operationId %||% paste(method, route)
      summary <- op$summary %||% ""
      
      # Extract deprecated status
      deprecated <- op$deprecated %||% FALSE
      
      # Extract description for enhanced documentation
      description <- op$description %||% ""

      # Detect if the request body uses the Chemical schema (needs resolver)
      needs_resolver <- if (method %in% c("post", "put", "patch") && has_body) {
        uses_chemical_schema(op$requestBody, openapi)
      } else {
        FALSE
      }

      # Get body schema type for more specific code generation
      body_schema_type <- if (method %in% c("post", "put", "patch") && has_body) {
        get_body_schema_type(op$requestBody, openapi)
      } else {
        "unknown"
      }
      
      # Detect response schema type for enhanced documentation
      response_schema_type <- get_response_schema_type(op$responses, openapi)

      # Extract response content types
      response_content_types <- character(0)
      if (!is.null(op$responses)) {
        # Look for successful responses (200, 201, etc.)
        success_codes <- intersect(names(op$responses), c("200", "201", "202", "204", "default"))
        for (code in success_codes) {
          resp <- op$responses[[code]]
          if (!is.null(resp$content) && is.list(resp$content)) {
            response_content_types <- c(response_content_types, names(resp$content))
          }
        }
      }
      response_content_types <- unique(response_content_types)
      content_type <- if (length(response_content_types) > 0) {
        paste(response_content_types, collapse = ", ")
      } else {
        ""
      }

      fn <- if (name_strategy == "operationId") sanitize_name(operationId) else sanitize_name(method_path_name(route, method))

      tibble::tibble(
        route = route,
        method = toupper(method),
        summary = summary,
        has_body = has_body,
        params = if (length(combined) > 0) paste(combined, collapse = ",") else "",
        # Separate path and query parameters for flexible stub generation
        path_params = if (length(path_names) > 0) paste(path_names, collapse = ",") else "",
        query_params = if (length(query_names) > 0) paste(query_names, collapse = ",") else "",
        body_params = if (length(body_names) > 0) paste(body_names, collapse = ",") else "",
        num_path_params = length(path_names),
        num_body_params = length(body_names),
        # NEW: Parameter metadata with examples and descriptions
        path_param_metadata = list(path_meta),
        query_param_metadata = list(query_meta),
        body_param_metadata = list(body_meta),
        # NEW: Response content type(s)
        content_type = content_type,
        # NEW: Chemical schema detection for resolver wrapping
        needs_resolver = needs_resolver,
        body_schema_type = body_schema_type,
        # NEW: Deprecated status and description
        deprecated = deprecated,
        description = description,
        # NEW: Response schema type for enhanced documentation
        response_schema_type = response_schema_type
      )
    })
  })
}

#' Parse and merge chemi schema files into a unified super schema
#'
#' Reads all chemi-*.json schema files from the specified directory, selects the
#' best available version for each endpoint domain (prioritizing prod > staging > dev),
#' parses each selected schema using `openapi_to_spec()`, and merges them into a
#' single tibble.
#'
#' @param schema_dir Path to the directory containing schema files. Defaults to
#'   the 'schema' directory at the project root (using `here::here('schema')`).
#' @param pattern Regex pattern for matching schema files. Defaults to "^chemi-.*\\.json$".
#' @param exclude_pattern Regex pattern for excluding schema files (e.g., UI schemas).
#'   Defaults to "ui" (case-insensitive).
#' @param stage_order Character vector specifying the priority order for stages.
#'   Defaults to c("prod", "staging", "dev").
#' @return A tibble containing all parsed endpoint specifications from the selected
#'   schema files, with columns from `openapi_to_spec()` plus a `source_file` column
#'   indicating which schema file each row came from.
#'
#' @details
#' The function works by:
#' 1. Listing all files matching the pattern in the schema directory
#' 2. Filtering out files matching the exclude pattern
#' 3. Parsing filenames to extract origin, domain, and stage
#' 4. For each domain, selecting the first available stage based on stage_order
#' 5. Parsing each selected schema file with `openapi_to_spec()`
#' 6. Combining all parsed schemas into a single tibble
#'
#' @examples
#' \dontrun{
#' # Parse all chemi schemas using defaults
#' super_schema <- parse_chemi_schemas()
#'
#' # Parse with custom schema directory
#' super_schema <- parse_chemi_schemas(schema_dir = "my/schema/path")
#'
#' # View domains represented in the super schema
#' table(super_schema$source_file)
#' }
#' @export
parse_chemi_schemas <- function(
  schema_dir = NULL,
  pattern = "^chemi-.*\\.json$",
  exclude_pattern = "ui",
  stage_order = c("prod", "staging", "dev")
) {
  if (!requireNamespace("here", quietly = TRUE)) stop("Package 'here' is required.")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.")
  if (!requireNamespace("tidyr", quietly = TRUE)) stop("Package 'tidyr' is required.")
  if (!requireNamespace("stringr", quietly = TRUE)) stop("Package 'stringr' is required.")
  if (!requireNamespace("tibble", quietly = TRUE)) stop("Package 'tibble' is required.")

  # Default to here::here('schema') if not specified
  if (is.null(schema_dir)) {
    schema_dir <- here::here("schema")
  }

  # Verify schema directory exists
  if (!dir.exists(schema_dir)) {
    stop("Schema directory does not exist: ", schema_dir)
  }

  # List all matching schema files
  all_files <- list.files(
    path = schema_dir,
    pattern = pattern,
    full.names = FALSE
  )

  if (length(all_files) == 0) {
    warning("No schema files found matching pattern '", pattern, "' in ", schema_dir)
    return(tibble::tibble())
  }

  # Filter out excluded files (e.g., UI schemas)
  if (!is.null(exclude_pattern) && nzchar(exclude_pattern)) {
    files_filtered <- all_files[!grepl(exclude_pattern, all_files, ignore.case = TRUE)]
  } else {
    files_filtered <- all_files
  }

  if (length(files_filtered) == 0) {
    warning("All schema files were excluded by pattern '", exclude_pattern, "'")
    return(tibble::tibble())
  }

  # Parse filenames to extract origin, domain, and stage
  # Expected format: chemi-{domain}-{stage}.json
  schema_meta <- tibble::tibble(file = files_filtered) %>%
    tidyr::separate_wider_delim(
      cols = file,
      delim = "-",
      names = c("origin", "domain", "stage"),
      cols_remove = FALSE
    ) %>%
    dplyr::mutate(
      # Remove .json extension from stage
      stage = stringr::str_remove(stage, pattern = "\\.json$"),
      # Convert stage to factor with specified priority order
      stage = factor(stage, levels = stage_order)
    )

  # For each domain, select the best available stage (first in order)
  selected_files <- schema_meta %>%
    dplyr::group_by(domain) %>%
    dplyr::arrange(stage, .by_group = TRUE) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::pull(file)

  if (length(selected_files) == 0) {
    warning("No schema files selected after filtering by stage")
    return(tibble::tibble())
  }

  # Parse each selected schema file and combine
  super_schema <- purrr::map(
    selected_files,
    function(schema_file) {
      schema_path <- file.path(schema_dir, schema_file)
      openapi <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
      spec <- openapi_to_spec(openapi)
      # Add source file column for traceability
      spec$source_file <- schema_file
      spec
    }
  ) %>%
    purrr::list_rbind()

  super_schema
}

# ==============================================================================
# File Scaffolding
# ==============================================================================

#' Write generated files to disk based on a specification tibble
#'
#' Creates or updates files according to a data frame describing file paths and their content.
#' The result tibble is returned invisibly, allowing you to capture it for inspection.
#'
#' @param data Data frame or tibble with at least columns for file paths and text.
#' @param path_col Name of the column containing file paths; default "file".
#' @param text_col Name of the column containing the file content; default "text".
#' @param base_dir Base directory to prepend to relative paths.
#' @param overwrite If TRUE, existing files will be overwritten; otherwise they are skipped.
#' @param append If TRUE, text is appended to existing files.
#' @param quiet If FALSE, progress messages are printed.
#' @return A tibble summarising each write operation with columns:
#'   - path: Full file path
#'   - action: What happened (created, skipped, overwritten, appended, error)
#'   - existed: Whether file existed before operation
#'   - written: Whether write succeeded
#'   - size_bytes: File size after operation
#'
#' @examples
#' \dontrun{
#' # Capture result to inspect which files weren't created
#' result <- scaffold_files(spec_with_text, base_dir = "R", overwrite = FALSE)
#'
#' # Check for skipped or failed files
#' result %>% filter(action %in% c("skipped", "error"))
#' }
#' @export
scaffold_files <- function(
  data,
  path_col = "file",
  text_col = "text",
  base_dir = ".",
  overwrite = FALSE,
  append = FALSE,
  quiet = FALSE
) {
  stopifnot(is.data.frame(data))
  if (!requireNamespace("fs", quietly = TRUE)) stop("Package 'fs' is required.")
  if (!requireNamespace("readr", quietly = TRUE)) stop("Package 'readr' is required.")
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.")
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")

  if (!path_col %in% names(data)) stop(sprintf("Column '%s' not found in data.", path_col))
  if (!text_col %in% names(data)) stop(sprintf("Column '%s' not found in data.", text_col))

  # Normalize and join paths with base_dir (if relative)
  paths <- purrr::map_chr(data[[path_col]], function(p) {
    if (fs::is_absolute_path(p)) fs::path_norm(p) else fs::path(base_dir, p)
  })

  jobs <- dplyr::tibble(
    index = seq_len(nrow(data)),
    path  = paths,
    text  = data[[text_col]]
  )

  write_one <- function(index, path, text) {
    # Allow text to be either a scalar string or a list-column of character lines
    if (is.list(text)) {
      text <- unlist(text, recursive = FALSE, use.names = FALSE)
    }

    # Ensure directory exists
    dir_path <- fs::path_dir(path)
    if (!fs::dir_exists(dir_path)) fs::dir_create(dir_path, recurse = TRUE)

    existed <- fs::file_exists(path)

    # Decide whether to skip, append, or write fresh/overwrite
    if (existed && !overwrite && !append) {
      if (!quiet) message(sprintf("Skipping (exists): %s", path))
      return(dplyr::tibble(
        index = index, path = path, action = "skipped_exists",
        existed = TRUE, written = FALSE, size_bytes = if (existed) file.size(path) else NA_real_
      ))
    }

    action <- if (append && existed) "appended" else if (existed) "overwritten" else "created"

    out <- tryCatch({
      if (length(text) > 1) {
        readr::write_lines(text, path, append = append)
      } else {
        readr::write_file(as.character(text %||% ""), path, append = append)
      }
      TRUE
    }, error = function(e) e)

    if (isTRUE(out)) {
      if (!quiet) message(sprintf("%s: %s", action, path))
      dplyr::tibble(
        index = index, path = path, action = action,
        existed = existed, written = TRUE, size_bytes = file.size(path)
      )
    } else {
      if (!quiet) message(sprintf("Error writing %s: %s", path, out$message))
      dplyr::tibble(
        index = index, path = path, action = "error",
        existed = existed, written = FALSE,
        size_bytes = if (fs::file_exists(path)) file.size(path) else NA_real_
      )
    }
  }

  if (nrow(jobs) == 0) {
    return(dplyr::tibble(
      index = integer(), path = character(), action = character(),
      existed = logical(), written = logical(), size_bytes = numeric()
    ))
  }

  result <- purrr::pmap_dfr(jobs, write_one)
  print(result, n = Inf)

  # Return result invisibly so users can inspect which files were/weren't created
  invisible(result)
}

# ==============================================================================
# Parameter Parsing and Code Generation
# ==============================================================================

#' Parse function parameters from comma-separated string
#'
#' Extracts parameter information and generates code components for function signatures,
#' documentation, and parameter handling.
#' @param params_str Comma-separated string of parameter names, or empty/NA.
#' @param strategy Parameter handling strategy: "extra_params" (for do.call with generic_request)
#'   or "options" (for options list with generic_chemi_request).
#' @param metadata Named list mapping parameter names to list(example, description).
#' @param has_path_params Logical; whether the endpoint has path parameters. If FALSE and
#'   query params exist, the first query param becomes the primary parameter.
#' @return A list with: fn_signature, param_docs, params_code, params_call, has_params,
#'   primary_param (when query params are used as primary).
#' @export

# Helper function to build parameter default value based on schema metadata
build_param_default <- function(param_name, metadata, is_primary = FALSE) {
  # If parameter is primary (required), no default
  if (isTRUE(is_primary)) {
    return("")
  }

  # If no metadata, fall back to NULL
  if (is.null(metadata) || is.na(param_name) || is.null(metadata[[param_name]])) {
    return("= NULL")
  }

  metadata_entry <- metadata[[param_name]]
  if (!is.list(metadata_entry)) return("= NULL")

  # Check if parameter is required
  if (isTRUE(metadata_entry$required)) {
    return("")  # No default for required params
  }

  # Check for default value in schema
  default_val <- metadata_entry$default
  if (is.null(default_val) || (length(default_val) == 1 && is.na(default_val))) {
    return("= NULL")
  }

  # Format based on type
  param_type <- metadata_entry$type %||% NA

  if (!is.na(param_type)) {
    if (param_type == "string") {
      return(paste0('= "', default_val, '"'))
    } else if (param_type == "boolean") {
      return(paste0("= ", toupper(as.character(default_val))))
    } else if (param_type %in% c("integer", "number")) {
      return(paste0("= ", default_val))
    }
  }

  # Safe fallback using deparse
  return(paste0("= ", deparse(default_val)))
}

parse_function_params <- function(params_str, strategy = c("extra_params", "options"), metadata = list(), has_path_params = TRUE) {
  strategy <- match.arg(strategy)

  # Handle empty/NA params
  if (is.null(params_str) || length(params_str) == 0 || is.na(params_str[1]) || !nzchar(trimws(params_str[1]))) {
    return(list(
      fn_signature = "",
      param_docs = "",
      params_code = "",
      params_call = "",
      has_params = FALSE,
      primary_param = NULL,
      primary_example = NA
    ))
  }

  # Split and clean parameter names
  param_vec_orig <- strsplit(params_str, ",")[[1]]
  param_vec_orig <- trimws(param_vec_orig)
  param_vec_orig <- param_vec_orig[nzchar(param_vec_orig) & !is.na(param_vec_orig)]

  if (length(param_vec_orig) == 0) {
    return(list(
      fn_signature = "",
      param_docs = "",
      params_code = "",
      params_call = "",
      has_params = FALSE,
      primary_param = NULL,
      primary_example = NA
    ))
  }

  # Helper to sanitize parameter names
  sanitize_param <- function(x) {
    if (is.na(x) || !nzchar(x)) return("param")
    if (grepl("^[0-9]", x)) {
      paste0("x", x)
    } else {
      make.names(x)
    }
  }

  param_vec_sanitized <- vapply(param_vec_orig, sanitize_param, character(1))
  names(param_vec_sanitized) <- param_vec_orig
  
  # Identify required vs optional parameters
  required_params <- character(0)
  optional_params <- character(0)
  primary_param <- NULL
  
  if (!isTRUE(has_path_params)) {
    primary_param <- param_vec_sanitized[1]
  }

  for (i in seq_along(param_vec_orig)) {
    p_orig <- param_vec_orig[i]
    p_san <- param_vec_sanitized[i]
    entry <- if (!is.null(metadata) && !is.na(p_orig)) metadata[[p_orig]] else NULL
    
    is_required <- FALSE
    if (is.list(entry) && isTRUE(entry$required)) {
      is_required <- TRUE
    }
    
    if (!is.null(primary_param) && p_san == primary_param) {
      is_required <- TRUE
    }
    
    if (is_required) {
      required_params <- c(required_params, p_san)
    } else {
      optional_params <- c(optional_params, p_san)
    }
  }
  
  # Build function signature
  sig_parts <- character(0)
  if (length(required_params) > 0) {
    sig_parts <- c(sig_parts, paste(required_params, collapse = ", "))
  }
  
  if (length(optional_params) > 0) {
    optional_defaults <- vapply(optional_params, function(p_san) {
      p_orig <- param_vec_orig[which(param_vec_sanitized == p_san)[1]]
      entry <- if (!is.null(metadata) && !is.na(p_orig)) metadata[[p_orig]] else NULL
      build_param_default(p_orig, metadata, is_primary = FALSE)
    }, character(1))
    sig_parts <- c(sig_parts, paste(optional_params, optional_defaults, collapse = ", "))
  }
  
  fn_signature <- paste(sig_parts, collapse = ", ")
  
  # Extract primary example safely
  primary_example <- NA
  if (!is.null(primary_param)) {
    primary_orig <- param_vec_orig[which(param_vec_sanitized == primary_param)[1]]
    entry <- if (!is.null(metadata) && !is.na(primary_orig)) metadata[[primary_orig]] else NULL
    if (is.list(entry)) {
      primary_example <- entry$example %||% NA
    }
  }

  # Generate @param documentation
  doc_lines <- character(0)
  for (i in seq_along(param_vec_orig)) {
    p_orig <- param_vec_orig[i]
    p_san <- param_vec_sanitized[i]
    entry <- if (!is.null(metadata) && !is.na(p_orig)) metadata[[p_orig]] else NULL
    
    if (is.list(entry)) {
      desc <- entry$description %||% ""
      enum_vals <- entry$enum %||% NULL
      default_val <- entry$default %||% NA
      is_req <- p_san %in% required_params

      if (nzchar(desc)) {
        param_desc <- desc
      } else if (is_req) {
        param_desc <- "Required parameter"
      } else {
        param_desc <- "Optional parameter"
      }

      if (length(enum_vals) > 0) {
        param_desc <- paste0(param_desc, ". Options: ", paste(enum_vals, collapse = ", "))
      }

      if (!is.na(default_val)) {
        param_desc <- paste0(param_desc, " (default: ", default_val, ")")
      }

      doc_lines <- c(doc_lines, paste0("#' @param ", p_san, " ", param_desc))
    } else {
       doc_lines <- c(doc_lines, paste0("#' @param ", p_san, if (p_san %in% required_params) " Required parameter" else " Optional parameter"))
    }
  }
  param_docs <- paste0(paste(doc_lines, collapse = "\n"), "\n")

  # Strategy-specific code generation
  if (strategy == "extra_params") {
    args_list <- paste(paste0("`", param_vec_orig, "` = ", param_vec_sanitized), collapse = ",\n    ")
    params_call <- paste0(",\n    ", args_list)
    params_code <- ""
  } else {
    lines <- c("  # Collect optional parameters", "  options <- list()")
    for (i in seq_along(param_vec_orig)) {
      p_orig <- param_vec_orig[i]
      p_san <- param_vec_sanitized[i]
      lines <- c(lines, paste0("  if (!is.null(", p_san, ")) options[['", p_orig, "']] <- ", p_san))
    }
    params_code <- paste0(paste(lines, collapse = "\n"), "\n  ")
    params_call <- ",\n    options = options"
  }

  list(
    fn_signature = fn_signature,
    param_docs = param_docs,
    params_code = params_code,
    params_call = params_call,
    has_params = TRUE,
    primary_param = primary_param,
    primary_example = primary_example
  )
}

#' Parse path parameters distinguishing primary from additional
#'
#' This function handles path parameters from OpenAPI specifications, treating
#' the first path parameter as the primary parameter (mapped to 'query' in
#' generic_request) and any additional path parameters as the path_params argument.
#'
#' @param path_params_str Comma-separated path parameter names from OpenAPI spec.
#' @param strategy Parameter strategy ("extra_params" or "options").
#' @param metadata Named list mapping parameter names to list(example, description).
#' @return List with function signature and path_params call components:
#'   \itemize{
#'     \item fn_signature: Function parameters string (e.g., "propertyName, start = NULL, end = NULL")
#'     \item path_params_call: Code string for path_params argument (e.g., ",\n    path_params = c(start = start, end = end)")
#'     \item has_path_params: Boolean indicating if additional path params exist
#'     \item param_docs: Roxygen @param documentation strings
#'     \item primary_param: Name of the primary parameter
#'     \item primary_example: Example value for primary parameter (or NA)
#'   }
#' @export
parse_path_parameters <- function(path_params_str, strategy = c("extra_params", "options"), metadata = list()) {
  strategy <- match.arg(strategy)

  # Handle empty/NA path params
  if (is.null(path_params_str) || length(path_params_str) == 0 || is.na(path_params_str[1]) || !nzchar(trimws(path_params_str[1]))) {
    return(list(
      fn_signature = "",
      path_params_call = "",
      has_path_params = FALSE,
      param_docs = "",
      primary_param = NULL,
      primary_example = NA,
      has_any_path_params = FALSE
    ))
  }

  # Split into individual parameters
  param_vec <- strsplit(path_params_str, ",")[[1]]
  param_vec <- trimws(param_vec)
  param_vec <- param_vec[nzchar(param_vec) & !is.na(param_vec)]

  if (length(param_vec) == 0) {
    return(list(
      fn_signature = "query",
      path_params_call = "",
      has_path_params = FALSE,
      param_docs = "",
      primary_param = "query",
      primary_example = NA,
      has_any_path_params = FALSE
    ))
  }

  # First parameter becomes 'query', rest are path_params
  primary_param <- param_vec[1]
  additional_params <- if (length(param_vec) > 1) param_vec[-1] else character(0)

  # Build function signature
  if (length(additional_params) > 0) {
    fn_signature <- paste0(
      primary_param, ", ",
      paste(additional_params, "= NULL", collapse = ", ")
    )
  } else {
    fn_signature <- primary_param
  }

  # Extract primary parameter example safely
  primary_example <- NA
  if (!is.null(metadata) && !is.na(primary_param) && !is.null(metadata[[primary_param]])) {
    entry <- metadata[[primary_param]]
    if (is.list(entry)) {
      primary_example <- entry$example %||% NA
    }
  }

  # Build param_docs from metadata with enhanced information
  param_docs <- ""
  all_params <- c(primary_param, additional_params)
  doc_lines <- character(0)
  for (p in all_params) {
    entry <- if (!is.null(metadata) && !is.na(p)) metadata[[p]] else NULL
    
    if (is.list(entry)) {
      desc <- entry$description %||% ""
      enum_vals <- entry$enum %||% NULL
      default_val <- entry$default %||% NA

      # Start with description or generic fallback
      if (nzchar(desc)) {
        param_desc <- desc
      } else if (p == primary_param) {
        param_desc <- "Primary query parameter"
      } else {
        param_desc <- "Optional parameter"
      }

      # Append enum values if available
      if (length(enum_vals) > 0) {
        enum_str <- paste(enum_vals, collapse = ", ")
        param_desc <- paste0(param_desc, ". Options: ", enum_str)
      }

      # Append default value if available
      if (!is.na(default_val)) {
        param_desc <- paste0(param_desc, " (default: ", default_val, ")")
      }

      doc_lines <- c(doc_lines, paste0("#' @param ", p, " ", param_desc))
    } else {
      # Generic description if none provided
      if (p == primary_param) {
        doc_lines <- c(doc_lines, paste0("#' @param ", p, " Primary query parameter"))
      } else {
        doc_lines <- c(doc_lines, paste0("#' @param ", p, " Optional parameter"))
      }
    }
  }
  if (length(doc_lines) > 0) {
    param_docs <- paste0(paste(doc_lines, collapse = "\n"), "\n")
  }

  # Build path_params call
  if (length(additional_params) > 0) {
    path_params_call <- paste0(
      ",\n    path_params = c(",
      paste(additional_params, "=", additional_params, collapse = ", "),
      ")"
    )
  } else {
    path_params_call <- ""
  }

  list(
    fn_signature = fn_signature,
    path_params_call = path_params_call,
    has_path_params = length(additional_params) > 0,
    param_docs = param_docs,
    primary_param = primary_param,
    primary_example = primary_example,
    has_any_path_params = length(param_vec) > 0
  )
}


#' Sample random DTXSIDs for examples
#' 
#' Samples random DTXSIDs from the testing_chemicals dataset for use in
#' example code generation. Falls back to a default DTXSID if the dataset
#' is unavailable.
#' 
#' @param n Number of DTXSIDs to sample (default 3)
#' @param custom_list Optional custom vector of DTXSIDs to sample from
#' @return Character vector of DTXSIDs
sample_test_dtxsids <- function(n = 3, custom_list = NULL) {
  # If custom list provided, use it
  if (!is.null(custom_list) && length(custom_list) >= n) {
    return(sample(custom_list, size = n))
  }
  
  default_dtxsid <- "DTXSID7020182"
  
  tryCatch({
    # Try to load testing_chemicals from package data
    chems <- NULL
    if (requireNamespace("ComptoxR", quietly = TRUE)) {
      if (exists("testing_chemicals", envir = asNamespace("ComptoxR"))) {
        chems <- get("testing_chemicals", envir = asNamespace("ComptoxR"))
      }
    }
    
    # Fallback: try to load from data/ directory
    if (is.null(chems)) {
      data_path <- "data/testing_chemicals.rda"
      if (file.exists(data_path)) {
        load(data_path)
      }
    }
    
    if (!is.null(chems) && "dtxsid" %in% names(chems) && nrow(chems) >= n) {
      sample(chems$dtxsid, size = n)
    } else {
      default_dtxsid
    }
  }, error = function(e) {
    default_dtxsid  # fallback to default
  })
}

#' Build a single function stub from components
#'
#' Generates R function source code with roxygen documentation using configuration.
#' @param fn Function name.
#' @param endpoint API endpoint path.
#' @param method HTTP method (GET, POST, etc.).
#' @param title Function title for documentation.
#' @param batch_limit Batching configuration (NULL, 0, 1, or integer).
#' @param path_param_info List from parse_path_parameters() containing primary and additional path params.
#' @param query_param_info List from parse_function_params() containing query string parameters.
#' @param body_param_info List from parse_function_params() containing request body parameters.
#' @param content_type Response content type(s) from OpenAPI spec (e.g., "application/json", "image/png").
#' @param config Configuration list specifying template behavior.
#' @param needs_resolver Boolean; whether this endpoint needs resolver pre-processing.
#' @param body_schema_type Character; type of body schema ("chemical_array", "string_array", "simple_object", "unknown").
#' @param deprecated Boolean; whether endpoint is deprecated in OpenAPI spec.
#' @param response_schema_type Character; type of response schema ("array", "object", "scalar", "binary", "unknown").
#' @return Character string containing complete function definition.
#' @export
build_function_stub <- function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, body_param_info, content_type, config, needs_resolver = FALSE, body_schema_type = "unknown", deprecated = FALSE, response_schema_type = "unknown") {
  if (!requireNamespace("glue", quietly = TRUE)) stop("Package 'glue' is required.")

  # Format batch_limit for code
  batch_limit_code <- if (is.null(batch_limit) || is.na(batch_limit)) "NULL" else as.character(batch_limit)

  # Determine response type and return documentation based on content_type
  content_type <- content_type %||% ""
  is_image <- grepl("image/", content_type, fixed = TRUE)
  is_text <- grepl("text/plain", content_type, fixed = TRUE)
  is_json <- content_type == "" || grepl("application/json", content_type, fixed = TRUE)

  # Set return type documentation based on response schema
  if (is_image) {
    return_doc <- "Returns image data (raw bytes or magick image object)"
    content_type_call <- paste0(',\n    content_type = "', content_type, '"')
  } else if (is_text) {
    return_doc <- "Returns a character string"
    content_type_call <- ',\n    content_type = "text/plain"'
  } else {
    # Enhance based on response_schema_type
    return_doc <- switch(response_schema_type,
      "array" = "Returns a tibble with results (array of objects)",
      "object" = "Returns a list with result object",
      "scalar" = "Returns a scalar value",
      "binary" = "Returns binary data",
      "Returns a tibble with results"  # default
    )
    content_type_call <- ""
  }

  # Extract config values
  wrapper_fn <- config$wrapper_function
  example_query <- config$example_query %||% "DTXSID7020182"
  # Use deprecated badge if endpoint is deprecated, otherwise use config badge
  lifecycle_badge <- if (isTRUE(deprecated)) {
    "deprecated"
  } else {
    config$lifecycle_badge %||% "experimental"
  }
  default_query_doc <- config$default_query_doc %||% "#' @param query A list of DTXSIDs to search for\n"

  # For GET endpoints, use generic_request even if config specifies generic_chemi_request
  # generic_chemi_request is designed for POST with JSON payloads only
  is_chemi_get <- FALSE
  if (isTRUE(toupper(method) == "GET") && wrapper_fn == "generic_chemi_request") {
    wrapper_fn <- "generic_request"
    is_chemi_get <- TRUE  # Track this to set correct server/auth
  }

  # Build server and auth params for chemi GET endpoints
  chemi_server_params <- if (is_chemi_get) ',\n    server = "chemi_burl",\n    auth = FALSE' else ""

  # Build tidy param for chemi GET endpoints (return raw list instead of tibble)
  chemi_tidy_param <- if (is_chemi_get) ',\n    tidy = FALSE' else ""

  # Check endpoint type
  is_query_only <- (!is.null(batch_limit) && !is.na(batch_limit) && batch_limit == 0 &&
                    isTRUE(query_param_info$has_params) &&
                    !is.null(query_param_info$primary_param))

  is_body_only <- (isTRUE(body_param_info$has_params) &&
                   !isTRUE(path_param_info$has_path_params) &&
                   nchar(path_param_info$fn_signature) == 0)

  if (isTRUE(is_body_only)) {
    # Body-only endpoint (POST/PUT/PATCH with no path params): primary param from body
    primary_param <- body_param_info$primary_param %||% "data"
    fn_signature <- body_param_info$fn_signature
    combined_calls <- ""  # Body params handled differently
    param_docs <- body_param_info$param_docs

    # Example value from body param metadata
    example_value <- example_query
    if (!is.null(body_param_info$primary_example) && !is.na(body_param_info$primary_example)) {
      example_value <- as.character(body_param_info$primary_example)
    }
    
    # Build example_value_vec for example call generation
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 3, custom_list = config$example_dtxsids %||% NULL)
      if (length(dtxsids) > 1) {
        example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
      } else {
        example_value_vec <- paste0('"', dtxsids, '"')
      }
    } else {
      example_value_vec <- paste0('"', example_value, '"')
    }
  } else if (isTRUE(is_query_only)) {
    # Query-only endpoint: primary param comes from query params
    primary_param <- query_param_info$primary_param
    fn_signature <- query_param_info$fn_signature
    combined_calls <- query_param_info$params_call
    param_docs <- query_param_info$param_docs

    # Example value from query param metadata
    example_value <- example_query
    if (!is.null(query_param_info$primary_example) && !is.na(query_param_info$primary_example)) {
      example_value <- as.character(query_param_info$primary_example)
    }
    
    # Build example_value_vec for example call generation
    example_value_vec <- paste0('"', example_value, '"')
  } else {
    # Standard case: primary param comes from path params
    primary_param <- "NULL"
    if (nzchar(path_param_info$fn_signature)) {
      primary_param <- strsplit(path_param_info$fn_signature, ",")[[1]][1]
    } else if (isTRUE(query_param_info$has_params)) {
      primary_param <- query_param_info$primary_param
    }
    primary_param <- trimws(primary_param)

    # Build combined function signature
    # Start with path parameters (which includes the primary param)
    fn_signature <- path_param_info$fn_signature

    # Add query parameters if they exist
    if (isTRUE(query_param_info$has_params)) {
      query_sig <- query_param_info$fn_signature
      if (nzchar(query_sig)) {
        if (nzchar(fn_signature)) {
          fn_signature <- paste0(fn_signature, ", ", query_sig)
        } else {
          fn_signature <- query_sig
        }
      }
    }

    # For generic_chemi_request endpoints without any params, add a 'query' parameter
    # since generic_chemi_request requires a query to send to the API
    if (primary_param == "NULL" && wrapper_fn == "generic_chemi_request") {
      primary_param <- "query"
      fn_signature <- "query"
      param_docs <- default_query_doc
    } else {
      param_docs <- paste0(path_param_info$param_docs, query_param_info$param_docs)
    }

    # Build combined parameter calls
    combined_calls <- ""
    if (isTRUE(path_param_info$has_path_params)) {
      combined_calls <- paste0(combined_calls, path_param_info$path_params_call)
    }
    if (isTRUE(query_param_info$has_params)) {
      combined_calls <- paste0(combined_calls, query_param_info$params_call)
    }


    # Determine example value from path param metadata
    example_value <- example_query
    if (!is.null(path_param_info$primary_example) && !is.na(path_param_info$primary_example)) {
      example_value <- as.character(path_param_info$primary_example)
    }
    
    # For POST requests, use sample from testing_chemicals
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 3, custom_list = config$example_dtxsids %||% NULL)
      if (length(dtxsids) > 1) {
        example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
      } else {
        example_value_vec <- paste0('"', dtxsids, '"')
      }
    } else {
      example_value_vec <- paste0('"', example_value, '"')
    }
  }

  # Build example call string - handle case where there are no parameters
  example_call <- if (primary_param == "NULL" || primary_param == "" || nchar(fn_signature) == 0) {
    paste0(fn, "()")
  } else {
    paste0(fn, "(", primary_param, ' = ', example_value_vec, ')')
  }

  # Build roxygen header with parameter descriptions from metadata
  roxygen_header <- glue::glue('
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
{param_docs}#\' @return {return_doc}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {example_call}
#\' }}')

  # Build function body based on endpoint type
  has_additional_params <- isTRUE(path_param_info$has_path_params) || isTRUE(query_param_info$has_params)

  # Special handling for endpoints that need resolver pre-processing
  if (isTRUE(needs_resolver) && body_schema_type == "chemical_array") {
    # Generate resolver-wrapped stub
    # These endpoints expect full Chemical objects (with sid, smiles, casrn, inchi, etc.)
    # We first resolve identifiers via chemi_resolver, then send to the endpoint

    # Build additional parameters from body_param_info (excluding 'chemicals')
    body_params_vec <- if (isTRUE(body_param_info$has_params)) {
      params <- strsplit(body_param_info$fn_signature, ",")[[1]]
      params <- trimws(params)
      params <- gsub("\\s*=\\s*NULL$", "", params)
      # Filter out 'chemicals' as we'll handle that via resolver
      params[!params %in% c("chemicals")]
    } else {
      character(0)
    }

    # Build function signature: query, id_type, plus any additional body params
    additional_sig <- if (length(body_params_vec) > 0) {
      paste0(", ", paste(body_params_vec, "= NULL", collapse = ", "))
    } else {
      ""
    }

    fn_signature_resolver <- paste0('query, id_type = "AnyId"', additional_sig)

    # Build options list from additional body params
    options_assembly <- if (length(body_params_vec) > 0) {
      lines <- c("  # Build options from additional parameters", "  extra_options <- list()")
      for (p in body_params_vec) {
        lines <- c(lines, paste0("  if (!is.null(", p, ")) extra_options$", p, " <- ", p))
      }
      paste(lines, collapse = "\n")
    } else {
      "  extra_options <- list()"
    }

    # Build the param docs for resolver wrapper
    resolver_param_docs <- paste0(
      "#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)\n",
      "#' @param id_type Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)\n"
    )
    if (length(body_params_vec) > 0) {
      for (p in body_params_vec) {
        resolver_param_docs <- paste0(resolver_param_docs, "#' @param ", p, " Optional parameter\n")
      }
    }

    # Update roxygen header with resolver-specific docs
    roxygen_header <- glue::glue('
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
#\' This function first resolves chemical identifiers using `chemi_resolver`,
#\' then sends the resolved Chemical objects to the API endpoint.
#\'
{resolver_param_docs}#\' @return {return_doc}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = c("50-00-0", "DTXSID7020182"))
#\' }}')

    # Generate resolver-wrapped function body
    fn_body <- glue::glue('
{fn} <- function({fn_signature_resolver}) {{
  # Resolve identifiers to Chemical objects
  resolved <- chemi_resolver(query = query, id_type = id_type)

  if (nrow(resolved) == 0) {{
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }}

  # Transform resolved tibble to Chemical object format
  # Map column names: dtxsid -> sid, etc.
  chemicals <- purrr::map(seq_len(nrow(resolved)), function(i) {{
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
  }})

{options_assembly}

  # Build and send request
  base_url <- Sys.getenv("chemi_burl", unset = "chemi_burl")
  if (base_url == "") base_url <- "chemi_burl"

  payload <- list(chemicals = chemicals)
  if (length(extra_options) > 0) payload$options <- extra_options

  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("{endpoint}") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(payload) |>
    httr2::req_headers(Accept = "application/json")

  if (as.logical(Sys.getenv("run_debug", "FALSE"))) {{
    return(httr2::req_dry_run(req))
  }}

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) < 200 || httr2::resp_status(resp) >= 300) {{
    cli::cli_abort("API request to {{.val {endpoint}}} failed with status {{httr2::resp_status(resp)}}")
  }}

  result <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  # Additional post-processing can be added here

  return(result)
}}

')

    # Combine header and body and return
    return(paste0(roxygen_header, "\n", fn_body, "\n\n"))
  }

  if (is_body_only) {
    # Body-only endpoint (POST/PUT/PATCH with body params): build request body
    if (wrapper_fn == "generic_chemi_request") {
      # Extract parameter info from body_param_info
      param_vec <- strsplit(body_param_info$fn_signature, ",")[[1]]
      param_vec <- trimws(param_vec)
      param_vec <- gsub("\\s*=\\s*NULL$", "", param_vec)  # Remove " = NULL" suffix

      # Identify required params (no "= NULL" in signature)
      sig_parts <- strsplit(body_param_info$fn_signature, ",")[[1]]
      sig_parts <- trimws(sig_parts)
      required_params <- sig_parts[!grepl("=", sig_parts)]
      optional_params <- param_vec[!param_vec %in% required_params]

      # For generic_chemi_request, the first parameter is the 'query' (DTXSIDs)
      # and all other parameters go into the 'options' list
      if (length(required_params) > 0) {
        query_param <- required_params[1]
        other_required <- if (length(required_params) > 1) required_params[-1] else character(0)
      } else if (length(optional_params) > 0) {
        query_param <- optional_params[1]
        optional_params <- optional_params[-1]
        other_required <- character(0)
      } else {
        stop("Body-only endpoint must have at least one parameter")
      }

      # Build options assembly code
      if (length(other_required) > 0 || length(optional_params) > 0) {
        options_code_lines <- c(
          "  # Build options list for additional parameters",
          "  options <- list()"
        )

        # Add other required params to options
        for (p in other_required) {
          options_code_lines <- c(options_code_lines, paste0("  options$", p, " <- ", p))
        }

        # Add optional params with NULL checks
        for (p in optional_params) {
          options_code_lines <- c(options_code_lines, paste0("  if (!is.null(", p, ")) options$", p, " <- ", p))
        }

        options_assembly <- paste(options_code_lines, collapse = "\n")
        options_call <- ",\n    options = options"
      } else {
        options_assembly <- ""
        options_call <- ""
      }

      # Determine wrap parameter based on presence of additional parameters beyond query
      # - No additional params: use wrap = FALSE to send unwrapped array [{"sid": "..."}, ...]
      # - Has additional params: use wrap = TRUE (default) to send {"chemicals": [...], "options": {...}}
      has_no_additional_params <- length(other_required) == 0 && length(optional_params) == 0
      wrap_param <- if (has_no_additional_params) {
        ",\n    wrap = FALSE"
      } else {
        ""
      }

      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{options_assembly}
  result <- generic_chemi_request(
    query = {query_param},
    endpoint = "{endpoint}"{options_call}{wrap_param},
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else if (wrapper_fn == "generic_request") {
      # Similar logic for generic_request
      param_vec <- strsplit(body_param_info$fn_signature, ",")[[1]]
      param_vec <- trimws(param_vec)
      param_vec <- gsub("\\s*=\\s*NULL$", "", param_vec)

      sig_parts <- strsplit(body_param_info$fn_signature, ",")[[1]]
      sig_parts <- trimws(sig_parts)
      required_params <- sig_parts[!grepl("=", sig_parts)]
      optional_params <- param_vec[!param_vec %in% required_params]

      body_code_lines <- c(
        "  # Build request body",
        "  body <- list()"
      )

      for (p in required_params) {
        body_code_lines <- c(body_code_lines, paste0("  body$", p, " <- ", p))
      }

      for (p in optional_params) {
        body_code_lines <- c(body_code_lines, paste0("  if (!is.null(", p, ")) body$", p, " <- ", p))
      }

      body_assembly <- paste(body_code_lines, collapse = "\n")

      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{body_assembly}

  result <- generic_request(
    query = NULL,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code},
    body = body{content_type_call}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  } else if (is_query_only) {
    # Query-only endpoint: pass query = NULL, all params via ellipsis
    if (wrapper_fn == "generic_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_request(
    query = NULL,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code}{chemi_server_params}{chemi_tidy_param}{content_type_call}{combined_calls}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_chemi_request(
    query = NULL,
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  } else if (isTRUE(has_additional_params)) {
    # Standard endpoint with path params and optional query params
    if (wrapper_fn == "generic_request") {
      # For chemi GET endpoints, determine batch_limit based on path params
      if (isTRUE(is_chemi_get)) {
        # Only use batch_limit = 1 for endpoints with PATH parameters
        if (isTRUE(path_param_info$has_any_path_params)) {
          # Has path params: append to URL path
          effective_batch_limit <- "1"
          effective_query <- primary_param
        } else {
          # Query-only or static endpoints: batch_limit = 0, query = NULL
          effective_batch_limit <- "0"
          effective_query <- "NULL"
        }
      } else {
        effective_batch_limit <- batch_limit_code
        effective_query <- primary_param
      }

      # Special handling for chemi GET query-only endpoints
      if (isTRUE(is_chemi_get) && !isTRUE(path_param_info$has_any_path_params) && isTRUE(query_param_info$has_params)) {
        # Query-only chemi GET: pass parameters directly without options pattern
        # Extract parameter names from function signature
        sig_parts <- strsplit(fn_signature, ",")[[1]]
        param_names <- gsub("\\s*=.*$", "", trimws(sig_parts))

        # Build direct parameter passing
        direct_params <- paste0(
          ",\n    ",
          paste(param_names, "=", param_names, collapse = ",\n    ")
        )

        # For query-only endpoints, don't include query as formal param - all params via ellipsis
        fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
  result <- generic_request(
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{direct_params}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
      } else {
        # Standard generation with existing logic
        fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_request(
    query = {effective_query},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{combined_calls}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
      }
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  } else {
    # No extra params: simple call with just primary param
    fn_arg <- if (primary_param == "NULL") "" else primary_param
    
    if (wrapper_fn == "generic_request") {
      # For chemi GET endpoints, determine batch_limit based on path params
      if (isTRUE(is_chemi_get)) {
        # Only use batch_limit = 1 for endpoints with PATH parameters
        if (isTRUE(path_param_info$has_any_path_params)) {
          # Has path params: append to URL path
          effective_batch_limit <- "1"
          effective_query <- primary_param
          extra_params <- ""
        } else {
          # Query-only or static endpoints: batch_limit = 0, query = NULL
          effective_batch_limit <- "0"
          effective_query <- "NULL"
          extra_params <- ""
        }
      } else {
        effective_batch_limit <- batch_limit_code
        effective_query <- primary_param
        extra_params <- ""
      }

      fn_body <- glue::glue('
{fn} <- function({fn_arg}) {{
  result <- generic_request(
    query = {effective_query},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{extra_params}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_arg}) {{
  result <- generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  }

  # Combine header and body
  paste0(roxygen_header,"\n", fn_body, "\n\n")
}

#' Render R function stubs from endpoint specification
#'
#' Takes a tibble of endpoint specifications and generates R source code strings using configuration.
#' @param spec Data frame produced by openapi_to_spec() containing endpoint metadata.
#' @param config Configuration list specifying:
#'   - wrapper_function: "generic_request" or "generic_chemi_request"
#'   - param_strategy: "extra_params" or "options"
#'   - example_query: Example value for documentation
#'   - lifecycle_badge: Badge type (default "experimental")
#' @param fn_transform Function to derive R function name from file name (default sanitizes basename).
#' @return The spec tibble with additional columns: fn, endpoint, title, text (rendered R code).
#' @export
render_endpoint_stubs <- function(spec,
                                   config,
                                   fn_transform = function(x) {
                                     nm <- tools::file_path_sans_ext(basename(x))
                                     nm <- gsub("-", "_", nm, fixed = TRUE)
                                     nm
                                   }) {
  stopifnot(is.data.frame(spec))
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.")
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")

  # Extract strategy from config
  param_strategy <- config$param_strategy %||% "extra_params"

  # Ensure all necessary columns exist with defaults
  spec <- ensure_cols(spec, list(
    fn = NA_character_,
    file = "unknown.R",
    route = "/unknown",
    summary = "",
    method = "GET",
    batch_limit = NA_integer_,
    path_params = "",
    query_params = "",
    body_params = "",
    num_path_params = 0L,
    num_body_params = 0L,
    path_param_metadata = list(NULL),
    query_param_metadata = list(NULL),
    body_param_metadata = list(NULL),
    content_type = "",
    needs_resolver = FALSE,
    body_schema_type = "unknown",
    deprecated = FALSE,
    response_schema_type = "unknown"
  ))

  # Pre-process some columns
  spec <- spec %>%
    dplyr::mutate(
      fn = dplyr::coalesce(fn, vapply(file, fn_transform, character(1))),
      endpoint = route,
      title = dplyr::if_else(
        nzchar(summary %||% ""),
        summary,
        tools::toTitleCase(gsub("[/_-]", " ", route))
      )
    )

  # Parse parameters row by row
  # We use pmap to avoid rowwise() issues
  parsed_params <- purrr::pmap(
    list(
      spec$path_params,
      spec$query_params,
      spec$body_params,
      spec$num_path_params,
      spec$path_param_metadata,
      spec$query_param_metadata,
      spec$body_param_metadata
    ),
    function(pp, qp, bp, npp, ppm, qpm, bpm) {
      list(
        path_info = parse_path_parameters(pp, strategy = param_strategy, metadata = ppm %||% list()),
        query_info = parse_function_params(qp, strategy = param_strategy, metadata = qpm %||% list(), has_path_params = (npp %||% 0 > 0)),
        body_info = parse_function_params(bp, strategy = param_strategy, metadata = bpm %||% list(), has_path_params = (npp %||% 0 > 0))
      )
    }
  )

  spec$path_param_info  <- purrr::map(parsed_params, "path_info")
  spec$query_param_info <- purrr::map(parsed_params, "query_info")
  spec$body_param_info  <- purrr::map(parsed_params, "body_info")

  # Generate text row by row
  spec$text <- purrr::pmap_chr(
    list(
      fn = spec$fn,
      endpoint = spec$endpoint,
      method = spec$method,
      title = spec$title,
      batch_limit = spec$batch_limit,
      path_param_info = spec$path_param_info,
      query_param_info = spec$query_param_info,
      body_param_info = spec$body_param_info,
      content_type = spec$content_type,
      needs_resolver = spec$needs_resolver,
      body_schema_type = spec$body_schema_type,
      deprecated = spec$deprecated,
      response_schema_type = spec$response_schema_type
    ),
    function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, body_param_info, content_type, needs_resolver, body_schema_type, deprecated, response_schema_type) {
      build_function_stub(
        fn = fn,
        endpoint = endpoint,
        method = method,
        title = title,
        batch_limit = batch_limit,
        path_param_info = path_param_info,
        query_param_info = query_param_info,
        body_param_info = body_param_info,
        content_type = content_type %||% "",
        config = config,
        needs_resolver = isTRUE(as.logical(needs_resolver %||% FALSE)),
        body_schema_type = body_schema_type %||% "unknown",
        deprecated = isTRUE(as.logical(deprecated %||% FALSE)),
        response_schema_type = response_schema_type %||% "unknown"
      )
    }
  )

  spec
}
