# ==============================================================================
# Stub Generation
# ==============================================================================

# Helper function to handle both NULL and NA with a default value
# Unlike %||% which only handles NULL, this also handles NA
`%|NA|%` <- function(x, default) {
  if (is.null(x) || (length(x) == 1 && is.na(x))) default else x
}

# Environment for tracking skipped/suspicious endpoints during generation
.StubGenEnv <- new.env(parent = emptyenv())
.StubGenEnv$skipped <- list()
.StubGenEnv$suspicious <- list()

#' Detect empty POST endpoints that cannot accept meaningful input
#'
#' Checks if a POST endpoint has no query params, no path params, and an empty
#' body schema. Such endpoints cannot receive any user input and should be skipped.
#'
#' @param method HTTP method (GET, POST, etc.)
#' @param query_params Query parameters string (comma-separated or empty)
#' @param path_params Path parameters string (comma-separated or empty)
#' @param body_schema_full Full body schema list from OpenAPI spec
#' @param body_schema_type Character type classification of body schema
#' @return A list with:
#'   - skip: Boolean, TRUE if endpoint should be skipped
#'   - reason: Character, explanation for skipping
#'   - suspicious: Boolean, TRUE if endpoint has only optional params
#'   - suspicious_reason: Character, explanation for suspicion
#' @keywords internal
is_empty_post_endpoint <- function(method, query_params, path_params, body_schema_full, body_schema_type) {
  # SCOPE-01: Only analyze POST endpoints

  if (!identical(toupper(method), "POST")) {
    return(list(
      skip = FALSE,
      reason = "",
      suspicious = FALSE,
      suspicious_reason = ""
    ))
  }

  # Check for no query params
  has_query_params <- !is.null(query_params) && nzchar(query_params %||% "")

  # Check for no path params
  has_path_params <- !is.null(path_params) && nzchar(path_params %||% "")


  # Check for empty body schema

  # Empty body conditions:
  #   - NULL or missing body_schema_full
  #   - length(body_schema_full) == 0
  #   - type == "object" with no properties or empty properties
  #   - type == "array" with primitive items (no named properties extractable)
  #   - No $ref and no meaningful schema content
  is_body_empty <- FALSE
  body_empty_reason <- ""

  if (is.null(body_schema_full)) {
    is_body_empty <- TRUE
    body_empty_reason <- "null body schema"
  } else if (length(body_schema_full) == 0) {
    is_body_empty <- TRUE
    body_empty_reason <- "empty body schema"
  } else if (is.list(body_schema_full)) {
    schema_type <- body_schema_full$type %||% ""
    has_properties <- !is.null(body_schema_full$properties) && length(body_schema_full$properties) > 0
    has_ref <- !is.null(body_schema_full$`$ref`)
    has_items <- !is.null(body_schema_full$items) && length(body_schema_full$items) > 0

    if (schema_type == "object" && !has_properties && !has_ref) {
      is_body_empty <- TRUE
      body_empty_reason <- "object with no properties"
    } else if (schema_type %in% c("", "unknown") && !has_properties && !has_ref && !has_items) {
      # Unknown or empty type with no properties/ref/items cannot produce named params
      is_body_empty <- TRUE
      body_empty_reason <- "no properties, ref, or items"
    } else if (schema_type == "array" && has_items) {
      # Array with items but no named properties - check if items are primitive
      # e.g., {"type": "array", "items": {"type": "string"}} yields no function parameters
      items_schema <- body_schema_full$items
      if (is.list(items_schema)) {
        items_type <- items_schema$type %||% ""
        items_has_properties <- !is.null(items_schema$properties) && length(items_schema$properties) > 0
        items_has_ref <- !is.null(items_schema$`$ref`)

        # Primitive array items (string, integer, number, boolean) with no properties/ref
        # cannot produce named function parameters
        if (items_type %in% c("string", "integer", "number", "boolean") &&
            !items_has_properties && !items_has_ref) {
          is_body_empty <- TRUE
          body_empty_reason <- paste0("array of ", items_type, " (no named parameters)")
        }
      }
    }
  }

  # Determine skip status
  # DETECT-04: All conditions must be TRUE for skip
  should_skip <- !has_query_params && !has_path_params && is_body_empty

  skip_reason <- ""
  if (should_skip) {
    skip_reason <- paste0("No query params, no path params, ", body_empty_reason)
  }

  # Determine suspicious status
  # Suspicious: Has query params but they might all be optional, and body is empty
  # We check if query_params exist but pattern suggests optional-only
  # (This is a heuristic - full optional detection would require metadata parsing)
  is_suspicious <- FALSE
  suspicious_reason <- ""

  if (!should_skip && has_query_params && is_body_empty && !has_path_params) {
    # Has some query params but empty body - mark as suspicious
    # In practice, endpoints with only optional query params and no body
    # may not function meaningfully
    is_suspicious <- TRUE
    suspicious_reason <- "Only query parameters with empty body schema (verify API docs)"
  }

  list(
    skip = should_skip,
    reason = skip_reason,
    suspicious = is_suspicious,
    suspicious_reason = suspicious_reason
  )
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
#' @param body_schema_type Character; type of body schema ("chemical_array", "string_array", "object_array", "simple_object", "unknown").
#' @param deprecated Boolean; whether endpoint is deprecated in OpenAPI spec.
#' @param response_schema_type Character; type of response schema ("array", "object", "scalar", "binary", "unknown").
#' @param request_type Character; type classification of request ("json", "query_only", "query_with_schema").
#' @return Character string containing complete function definition.
#' @export
build_function_stub <- function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, body_param_info, content_type, config, needs_resolver = FALSE, body_schema_type = "unknown", deprecated = FALSE, response_schema_type = "unknown", request_type = NULL) {
  if (!requireNamespace("glue", quietly = TRUE)) stop("Package 'glue' is required.")

  # Format batch_limit for code
  # For POST methods with bulk requests, use environment variable for runtime configuration
  batch_limit_code <- if (is.null(batch_limit) || is.na(batch_limit)) {
    'as.numeric(Sys.getenv("batch_limit", "1000"))'
  } else if (batch_limit > 1) {
    # Bulk batching - use environment variable
    'as.numeric(Sys.getenv("batch_limit", "1000"))'
  } else {
    # batch_limit = 0 (static) or 1 (path-based) - keep as-is
    as.character(batch_limit)
  }

  # Determine response type and return documentation based on content_type
  content_type <- if (is.null(content_type) || is.na(content_type)) "" else content_type
  is_image <- grepl("image/", content_type, fixed = TRUE)
  is_text <- grepl("text/plain", content_type, fixed = TRUE)
  is_json <- content_type == "" || grepl("application/json", content_type, fixed = TRUE)

  # Set return type documentation based on response schema
  if (isTRUE(is_image)) {
    return_doc <- "Returns image data (raw bytes or magick image object)"
    content_type_call <- paste0(',\n    content_type = "', content_type, '"')
  } else if (isTRUE(is_text)) {
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
  chemi_server_params <- if (isTRUE(is_chemi_get)) ',\n    server = "chemi_burl",\n    auth = FALSE' else ""

  # Build tidy param for chemi GET endpoints (return raw list instead of tibble)
  chemi_tidy_param <- if (isTRUE(is_chemi_get)) ',\n    tidy = FALSE' else ""

	# Build server and auth params for common_chemistry (cc_) GET endpoints 
	cc_server_params <- if (isTRUE(grepl("^cc_", fn))) ',\n    server = "cc_burl",\n    auth = TRUE' else ""

  # Check endpoint type using request_type if available, otherwise use legacy detection
  # This provides cleaner, more explicit endpoint classification
  # Request types:
  #   - "json": POST/PUT/PATCH with request body (body_only)
  #   - "path": GET with path parameters (standard path-based endpoint)
  #   - "query_only": GET without path parameters (static endpoint, query params only)
  if (!is.null(request_type) && !is.na(request_type) && nzchar(request_type)) {
    is_body_only <- request_type == "json"
    # NEW: Simple body types are also body-only
    is_simple_body <- body_schema_type %in% c("string", "string_array")
    is_query_only <- request_type == "query_only"  # "path" falls through to standard case
  } else {
    # Legacy detection for backward compatibility
    is_query_only <- (!is.null(batch_limit) && !is.na(batch_limit) && batch_limit == 0 &&
                      isTRUE(query_param_info$has_params) &&
                      !is.null(query_param_info$primary_param))

    is_body_only <- (isTRUE(body_param_info$has_params) &&
                     !isTRUE(path_param_info$has_path_params) &&
                     nchar(path_param_info$fn_signature %|NA|% "") == 0)

    # NEW: Simple body types are body-only even if body_param_info$has_params is FALSE
    is_simple_body <- body_schema_type %in% c("string", "string_array")
  }

  if (isTRUE(is_body_only)) {
    # Body-only endpoint (POST/PUT/PATCH with no path params): primary param from body
    primary_param <- body_param_info$primary_param %||% "data"
    fn_signature <- body_param_info$fn_signature
    combined_calls <- ""  # Body params handled differently
    param_docs <- body_param_info$param_docs

    # Example value from body param metadata
    example_value <- example_query
    if (!is.null(body_param_info$primary_example) && length(body_param_info$primary_example) > 0 && !is.na(body_param_info$primary_example[1])) {
      example_value <- as.character(body_param_info$primary_example[1])
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
    # Use path param as primary if query doesn't have one (e.g., endpoint with path + optional query params)
    primary_param <- query_param_info$primary_param %||% path_param_info$primary_param %||% "NULL"
    fn_signature <- query_param_info$fn_signature
    combined_calls <- query_param_info$params_call
    param_docs <- query_param_info$param_docs

    # Example value from query param metadata
    example_value <- example_query
    if (!is.null(query_param_info$primary_example) && length(query_param_info$primary_example) > 0 && !is.na(query_param_info$primary_example[1])) {
      example_value <- as.character(query_param_info$primary_example[1])
    }
    
    # Build example_value_vec for example call generation
    example_value_vec <- paste0('"', example_value, '"')
  } else {
    # Standard case: primary param comes from path params
    primary_param <- "NULL"
    if (nzchar(path_param_info$fn_signature %||% "")) {
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
      if (nzchar(query_sig %||% "")) {
        if (nzchar(fn_signature %||% "")) {
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
    if (!is.null(path_param_info$primary_example) && length(path_param_info$primary_example) > 0 && !is.na(path_param_info$primary_example[1])) {
      example_value <- as.character(path_param_info$primary_example[1])
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
  # Use %|NA|% to handle NULL/NA values safely
  fn_signature_safe <- fn_signature %|NA|% ""
  primary_param_safe <- primary_param %|NA|% "NULL"
  example_call <- if (primary_param_safe == "NULL" || primary_param_safe == "" || nchar(fn_signature_safe) == 0) {
    paste0(fn, "()")
  } else {
    paste0(fn, "(", primary_param_safe, ' = ', example_value_vec, ')')
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
    # We first resolve identifiers via chemi_resolver_lookup, then send to the endpoint

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

    # Build function signature: query, idType, plus any additional body params
    additional_sig <- if (length(body_params_vec) > 0) {
      paste0(", ", paste(body_params_vec, "= NULL", collapse = ", "))
    } else {
      ""
    }

    fn_signature_resolver <- paste0('query, idType = "AnyId"', additional_sig)

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
      "#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)\n"
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
#\' This function first resolves chemical identifiers using `chemi_resolver_lookup`,
#\' then sends the resolved Chemical objects to the API endpoint.
#\'
{resolver_param_docs}#\' @return {return_doc}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = c("50-00-0", "DTXSID7020182"))
#\' }}')

    # Generate resolver-wrapped function body using generic_chemi_request
    fn_body <- glue::glue('
{fn} <- function({fn_signature_resolver}) {{
  # Resolve identifiers to Chemical objects
	resolved <- tryCatch(
    chemi_resolver_lookup(query = query, idType = idType),
    error = function(e) {{
      tryCatch(
        chemi_resolver_lookup(query = query),
        error = function(e2) stop("chemi_resolver_lookup failed: ", e2$message)
      )
    }}
  )

  if (length(resolved) == 0) {{
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }}

  # Transform resolved list to Chemical object format expected by endpoint
  chemicals <- purrr::map(resolved, function(chem) {{
    list(
      sid = chem$dtxsid %||% chem$sid,
      smiles = chem$smiles,
      casrn = chem$casrn,
      inchi = chem$inchi,
      inchiKey = chem$inchiKey,
      name = chem$name,
      mol = chem$mol
    )
  }})

{options_assembly}

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "{endpoint}",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')

    # Combine header and body and return
    return(paste0(roxygen_header, "\n", fn_body, "\n\n"))
  }

  # ===========================================================================
  # Body Type Handling for POST Requests
  # ===========================================================================
  # Most POST endpoints expect JSON-encoded request bodies. The CompTox API has
  # exactly ONE endpoint that requires raw text (newline-delimited):
  #   - POST /chemical/search/equal/ (body_schema_type == "string")
  #
  # All other POST endpoints with array bodies (body_schema_type == "string_array")
  # should use the default JSON encoding via generic_request().
  #
  # Decision: RAW-TEXT-01 (2026-01-27) - Special case in stub generation
  # ===========================================================================

  # Handle raw text body endpoints (body_schema_type == "string" for POST)
  # These endpoints expect newline-delimited plain text, not JSON
  # IMPORTANT: Only /chemical/search/equal/ uses this pattern
  is_raw_text_body <- (
    body_schema_type == "string" &&
    toupper(method) == "POST" &&
    wrapper_fn == "generic_request" &&
    (endpoint == "chemical/search/equal/" || grepl("chemical/search/equal/$", endpoint))
  )

  if (isTRUE(is_raw_text_body)) {
    # Build roxygen header for raw text body endpoint
    roxygen_header <- glue::glue('
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
#\' @param query Character vector of values to search for
#\' @return {return_doc}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = c("DTXSID7020182", "DTXSID9020112"))
#\' }}')

    # Generate function body using generic_request with body_type = "raw_text"
    fn_body <- glue::glue('
{fn} <- function(query) {{
  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "POST",
    batch_limit = {batch_limit_code},
    body_type = "raw_text"
  )

  return(result)
}}

')

    return(paste0(roxygen_header, "\n", fn_body, "\n\n"))
  }

  # Handle simple body types (string, string_array)
  if (isTRUE(is_simple_body)) {
    # For simple body types, use "query" as the primary parameter
    primary_param <- "query"
    fn_signature <- "query"

    # Build parameter documentation based on body schema type
    if (body_schema_type == "string") {
      param_docs <- "#' @param query Character string to send in request body\n"
    } else if (body_schema_type == "string_array") {
      param_docs <- "#' @param query Character vector of strings to send in request body\n"
    } else {
      param_docs <- "#' @param query Query data to send in request body\n"
    }

    # Build example value
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 3, custom_list = config$example_dtxsids %||% NULL)
      if (length(dtxsids) > 1) {
        example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
      } else {
        example_value_vec <- paste0('"', dtxsids, '"')
      }
    } else {
      example_value_vec <- '"DTXSID7020182"'
    }

    # Build roxygen header
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
#\' {fn}(query = {example_value_vec})
#\' }}')

    # Generate function body based on body schema type
    if (body_schema_type == "string_array") {
      # Array body: pass directly, generic_request() handles JSON encoding
      fn_body <- glue::glue('
{fn} <- function(query) {{
  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}}

')
    } else {
      # Simple string body: pass directly
      fn_body <- glue::glue('
{fn} <- function(query) {{
  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}}

')
    }

    # Return early with generated stub
    return(paste0(roxygen_header, "\n", fn_body, "\n\n"))
  }

  if (isTRUE(is_body_only)) {
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
        # Body schema has properties but none could be extracted as function params
        # (e.g., array-only properties). Skip gracefully and track for reporting.
        cli::cli_alert_warning("Skipping body-only endpoint {fn}: body schema has no extractable parameters")
        .StubGenEnv$skipped <- c(.StubGenEnv$skipped, list(tibble::tibble(
          route = endpoint, method = method,
          skip_reason = "Body properties not extractable as function parameters",
          source_file = NA_character_
        )))
        return(NA_character_)
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
  } else if (isTRUE(is_query_only)) {
    # Query-only endpoint: all params via ellipsis, no query parameter needed
    # For query-only endpoints, batch_limit should be 0 (static endpoint)
    effective_batch_limit <- if (batch_limit_code == "NULL") "0" else batch_limit_code
    
    if (wrapper_fn == "generic_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_request(
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{cc_server_params}{content_type_call}{combined_calls}
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_chemi_request(
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}}

')
    } else if (wrapper_fn == "generic_cc_request") {
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_cc_request(
    endpoint = "{endpoint}",
    method = "{method}"{combined_calls}
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
    response_schema_type = "unknown",
    request_type = NA_character_,
    body_schema_full = list(list()),
    body_item_type = NA_character_,
    source_file = NA_character_,
    pagination_strategy = "none",
    pagination_metadata = list(NULL)
  ))

  # ===========================================================================
  # Empty POST Detection and Filtering
  # ===========================================================================
  # Detect POST endpoints with no query params, no path params, and empty body.
  # These endpoints cannot accept meaningful user input and should be skipped.

  detection_results <- purrr::pmap(
    list(
      method = spec$method,
      query_params = spec$query_params,
      path_params = spec$path_params,
      body_schema_full = spec$body_schema_full,
      body_schema_type = spec$body_schema_type
    ),
    is_empty_post_endpoint
  )

  spec$skip_endpoint <- purrr::map_lgl(detection_results, "skip")
  spec$skip_reason <- purrr::map_chr(detection_results, "reason")
  spec$suspicious <- purrr::map_lgl(detection_results, "suspicious")
  spec$suspicious_reason <- purrr::map_chr(detection_results, ~ .x$suspicious_reason %||% "")

  # Collect skipped endpoints for reporting (NOTIFY-02)
  skipped_endpoints <- spec %>%
    dplyr::filter(skip_endpoint) %>%
    dplyr::select(route, method, skip_reason, source_file)

  # Collect suspicious endpoints for reporting
  suspicious_endpoints <- spec %>%
    dplyr::filter(suspicious, !skip_endpoint) %>%
    dplyr::select(route, method, suspicious_reason, source_file)

  # Store in tracking environment for later summary
  .StubGenEnv$skipped <- c(.StubGenEnv$skipped, list(skipped_endpoints))
  .StubGenEnv$suspicious <- c(.StubGenEnv$suspicious, list(suspicious_endpoints))

  # Filter out skipped endpoints before processing
  spec <- spec %>% dplyr::filter(!skip_endpoint)

  # Early return if all endpoints were skipped
 if (nrow(spec) == 0) {
    cli::cli_alert_warning("All endpoints were skipped (empty POST schemas)")
    return(tibble::tibble(
      fn = character(), endpoint = character(), title = character(), text = character()
    ))
  }

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
      response_schema_type = spec$response_schema_type,
      request_type = spec$request_type
    ),
    function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, body_param_info, content_type, needs_resolver, body_schema_type, deprecated, response_schema_type, request_type) {
      build_function_stub(
        fn = fn,
        endpoint = endpoint,
        method = method,
        title = title,
        batch_limit = batch_limit,
        path_param_info = path_param_info,
        query_param_info = query_param_info,
        body_param_info = body_param_info,
        content_type = content_type %|NA|% "",
        config = config,
        needs_resolver = isTRUE(as.logical(needs_resolver %|NA|% FALSE)),
        body_schema_type = body_schema_type %|NA|% "unknown",
        deprecated = isTRUE(as.logical(deprecated %|NA|% FALSE)),
        response_schema_type = response_schema_type %|NA|% "unknown",
        request_type = request_type %|NA|% ""
      )
    }
  )

  # Remove endpoints that returned NA (skipped during stub generation)
  spec <- spec %>% dplyr::filter(!is.na(text))

  spec
}

# ==============================================================================
# Endpoint Tracking and Reporting
# ==============================================================================

#' Report skipped and suspicious endpoints from stub generation
#'
#' Call this after all render_endpoint_stubs() calls to display summary.
#' Also writes to log file for later reference.
#'
#' @param log_dir Directory for log file. Default: "dev/logs"
#' @return Invisible NULL. Called for side effects (cli output).
#' @export
report_skipped_endpoints <- function(log_dir = "dev/logs") {
  # Combine all tracked results
  skipped <- dplyr::bind_rows(.StubGenEnv$skipped)
  suspicious <- dplyr::bind_rows(.StubGenEnv$suspicious)

  n_skipped <- nrow(skipped)
  n_suspicious <- nrow(suspicious)

  if (n_skipped == 0 && n_suspicious == 0) {
    cli::cli_alert_success("All endpoints generated successfully")
    return(invisible(NULL))
  }

  # Summary count line (NOTIFY-03)
  cli::cli_h2("Endpoint Generation Report")

  if (n_skipped > 0) {
    cli::cli_alert_danger("{n_skipped} endpoint{?s} skipped")
    cli::cli_div(theme = list(span.skip = list(color = "red")))
    for (i in seq_len(n_skipped)) {
      source_info <- if (!is.na(skipped$source_file[i])) paste0(" [", skipped$source_file[i], "]") else ""
      cli::cli_bullets(c(
        " " = "{.emph {skipped$method[i]} {skipped$route[i]}}{source_info}: {skipped$skip_reason[i]}"
      ))
    }
    cli::cli_end()
  }

  if (n_suspicious > 0) {
    cli::cli_alert_warning("{n_suspicious} endpoint{?s} suspicious (may have incomplete API docs)")
    cli::cli_div(theme = list(span.warn = list(color = "yellow")))
    for (i in seq_len(n_suspicious)) {
      source_info <- if (!is.na(suspicious$source_file[i])) paste0(" [", suspicious$source_file[i], "]") else ""
      cli::cli_bullets(c(
        " " = "{.emph {suspicious$method[i]} {suspicious$route[i]}}{source_info}: {suspicious$suspicious_reason[i]}"
      ))
    }
    cli::cli_end()
  }

  # Write to log file
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }

  log_file <- file.path(log_dir, paste0("stub_generation_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))

  log_lines <- c(
    paste0("Stub Generation Report - ", Sys.time()),
    paste0("Skipped: ", n_skipped),
    paste0("Suspicious: ", n_suspicious),
    ""
  )

  if (n_skipped > 0) {
    log_lines <- c(log_lines, "SKIPPED ENDPOINTS:", "")
    for (i in seq_len(n_skipped)) {
      source_info <- if (!is.na(skipped$source_file[i])) paste0(" [", skipped$source_file[i], "]") else ""
      log_lines <- c(log_lines, paste0("  ", skipped$method[i], " ", skipped$route[i], source_info, " - ", skipped$skip_reason[i]))
    }
    log_lines <- c(log_lines, "")
  }

  if (n_suspicious > 0) {
    log_lines <- c(log_lines, "SUSPICIOUS ENDPOINTS:", "")
    for (i in seq_len(n_suspicious)) {
      source_info <- if (!is.na(suspicious$source_file[i])) paste0(" [", suspicious$source_file[i], "]") else ""
      log_lines <- c(log_lines, paste0("  ", suspicious$method[i], " ", suspicious$route[i], source_info, " - ", suspicious$suspicious_reason[i]))
    }
  }

  writeLines(log_lines, log_file)
  cli::cli_alert_info("Log written to {.file {log_file}}")

  invisible(NULL)
}

#' Reset skipped/suspicious endpoint tracking
#'
#' Call before starting a new generation run to clear previous results.
#'
#' @return Invisible NULL.
#' @export
reset_endpoint_tracking <- function() {
  .StubGenEnv$skipped <- list()
  .StubGenEnv$suspicious <- list()
  invisible(NULL)
}
