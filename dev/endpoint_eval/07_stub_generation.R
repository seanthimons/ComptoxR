# ==============================================================================
# Stub Generation
# ==============================================================================

# Helper function to handle both NULL and NA with a default value
# Unlike %||% which only handles NULL, this also handles NA
`%|NA|%` <- function(x, default) {
  if (is.null(x) || (length(x) == 1 && is.na(x))) default else x
}

stubgen_value_missing <- function(value) {
  is.null(value) ||
    (is.atomic(value) && length(value) == 1L && is.na(value))
}

stubgen_example_value <- function(value) {
  if (is.list(value)) {
    return(paste(deparse(value, width.cutoff = 500L), collapse = " "))
  }
  as.character(value)[1]
}

stubgen_read_hook_config <- function() {
  if (!exists("read_hook_configs", mode = "function")) {
    source(here::here("R", "hook_registry.R"), local = FALSE)
  }
  read_hook_configs(
    here::here("inst", "hook_config.yml"),
    here::here("inst", "hook_config_generated.yml")
  )
}

stubgen_formal_names <- function(fn_signature) {
  fn_signature <- fn_signature %|NA|% ""
  if (!nzchar(trimws(fn_signature))) {
    return(character(0))
  }

  parsed <- tryCatch(
    parse(text = paste0("function(", fn_signature, ") NULL"))[[1]],
    error = function(e) NULL
  )

  if (!is.null(parsed)) {
    return(names(formals(eval(parsed))))
  }

  sig_parts <- strsplit(fn_signature, ",")[[1]]
  sig_parts <- trimws(sig_parts)
  sig_parts <- gsub("\\s*=\\s*.*$", "", sig_parts)
  sig_parts <- gsub("^`|`$", "", sig_parts)
  sig_parts[nzchar(sig_parts)]
}

stubgen_symbol <- function(name) {
  reserved <- c(
    "if",
    "else",
    "repeat",
    "while",
    "function",
    "for",
    "in",
    "next",
    "break",
    "TRUE",
    "FALSE",
    "NULL",
    "Inf",
    "NaN",
    "NA",
    "NA_integer_",
    "NA_real_",
    "NA_complex_",
    "NA_character_"
  )

  if (identical(make.names(name), name) && !name %in% reserved) {
    return(name)
  }

  paste0("`", gsub("`", "\\\\`", name, fixed = TRUE), "`")
}

stubgen_hook_params_expr <- function(param_names) {
  param_names <- unique(param_names[nzchar(param_names)])
  if (length(param_names) == 0) {
    return("list()")
  }

  entries <- vapply(
    param_names,
    function(param_name) paste0("`", param_name, "` = ", stubgen_symbol(param_name)),
    character(1)
  )

  paste0("list(", paste(entries, collapse = ", "), ")")
}

stubgen_build_pre_hook <- function(
  fn,
  fn_config,
  fn_signature,
  additional_params = character(),
  return_on_skip = TRUE,
  writeback_params = TRUE,
  param_inits = list()
) {
  if (is.null(fn_config$pre_request) || length(fn_config$pre_request) == 0) {
    return("")
  }

  formal_names <- stubgen_formal_names(fn_signature)
  param_names <- unique(c(formal_names, additional_params))
  params_expr <- stubgen_hook_params_expr(param_names)

  # additional_params that are not function formals are initialised before the
  # hook runs. Default init is NULL; `param_inits` supplies a code-string RHS for
  # specific params (e.g. server <- "chemi_burl") so the hook has a value to
  # override and the wrapper call has a valid fallback.
  init_names <- setdiff(additional_params, formal_names)
  init_lines <- if (length(init_names) > 0) {
    paste0(
      "  ",
      vapply(init_names, stubgen_symbol, character(1)),
      " <- ",
      vapply(init_names, function(nm) param_inits[[nm]] %||% "NULL", character(1)),
      "\n",
      collapse = ""
    )
  } else {
    ""
  }
  hook_missing_params <- intersect(
    fn_config$hook_missing_params %||% character(),
    formal_names
  )
  missing_lines <- paste0(
    vapply(
      hook_missing_params,
      function(param_name) {
        symbol <- stubgen_symbol(param_name)
        paste0("  if (missing(", symbol, ")) ", symbol, " <- NULL\n")
      },
      character(1)
    ),
    collapse = ""
  )

  writeback <- if (isTRUE(writeback_params)) {
    paste0(
      vapply(
        param_names,
        function(param_name) {
          paste0(
            "  if (\"",
            param_name,
            "\" %in% names(req_data$params)) {\n",
            "    ",
            stubgen_symbol(param_name),
            " <- req_data$params[[\"",
            param_name,
            "\"]]\n",
            "  }\n"
          )
        },
        character(1)
      ),
      collapse = ""
    )
  } else {
    ""
  }

  skip_lines <- if (isTRUE(return_on_skip)) {
    paste0(
      "  if (isTRUE(req_data$skip_request)) {\n",
      "    return(req_data$result)\n",
      "  }\n"
    )
  } else {
    ""
  }

  paste0(
    init_lines,
    missing_lines,
    "  req_data <- run_hook(\"",
    fn,
    "\", \"pre_request\", list(params = ",
    params_expr,
    "))\n",
    skip_lines,
    writeback
  )
}

stubgen_build_post_hook <- function(fn, fn_config, fn_signature) {
  if (is.null(fn_config$post_response) || length(fn_config$post_response) == 0) {
    return("")
  }

  params_expr <- stubgen_hook_params_expr(stubgen_formal_names(fn_signature))

  paste0(
    "  result <- run_hook(\"",
    fn,
    "\", \"post_response\", list(result = result, params = ",
    params_expr,
    "))\n"
  )
}

stubgen_apply_signature_overrides <- function(fn_signature, overrides) {
  if (is.null(overrides) || length(overrides) == 0) {
    return(fn_signature)
  }

  parsed <- parse(text = paste0("function(", fn_signature %|NA|% "", ") NULL"))[[1]]
  fn <- eval(parsed)
  fn_formals <- as.list(formals(fn))
  missing_value <- as.list(alist(value = ))

  for (param_name in names(overrides)) {
    if (!param_name %in% names(fn_formals)) {
      next
    }
    override <- overrides[[param_name]]
    if (isTRUE(override$required)) {
      fn_formals[param_name] <- missing_value
    } else if (!is.null(override$default)) {
      fn_formals[[param_name]] <- parse(text = as.character(override$default))[[1]]
    }
  }

  entries <- vapply(
    names(fn_formals),
    function(param_name) {
      value <- fn_formals[param_name]
      symbol <- stubgen_symbol(param_name)
      if (identical(unname(value), unname(missing_value))) {
        symbol
      } else {
        paste0(symbol, " = ", paste(deparse(value[[1]], width.cutoff = 500L), collapse = " "))
      }
    },
    character(1)
  )
  paste(entries, collapse = ", ")
}

stubgen_apply_signature_order <- function(fn_signature, signature_order) {
  if (is.null(signature_order) || length(signature_order) == 0) {
    return(fn_signature)
  }

  parsed <- parse(text = paste0("function(", fn_signature %|NA|% "", ") NULL"))[[1]]
  fn_formals <- as.list(formals(eval(parsed)))
  unknown <- setdiff(signature_order, names(fn_formals))
  if (length(unknown) > 0) {
    cli::cli_abort(
      "Unknown signature_order parameter{?s}: {paste(unknown, collapse = ', ')}."
    )
  }

  ordered_names <- c(signature_order, setdiff(names(fn_formals), signature_order))
  missing_value <- as.list(alist(value = ))
  entries <- vapply(
    ordered_names,
    function(param_name) {
      value <- fn_formals[param_name]
      symbol <- stubgen_symbol(param_name)
      if (identical(unname(value), unname(missing_value))) {
        symbol
      } else {
        paste0(
          symbol,
          " = ",
          paste(deparse(value[[1]], width.cutoff = 500L), collapse = " ")
        )
      }
    },
    character(1)
  )
  paste(entries, collapse = ", ")
}

stubgen_configured_parameter_order <- function(fn_config, fn_signature) {
  configured <- c(
    fn_config$parameter_overrides %||% list(),
    fn_config$extra_params %||% list()
  )
  if (length(configured) == 0) {
    return(character())
  }

  formal_names <- stubgen_formal_names(fn_signature)
  ordered <- lapply(names(configured), function(config_name) {
    spec <- configured[[config_name]]
    public_name <- spec$name %||% config_name
    if (is.null(spec$order) || !public_name %in% formal_names) {
      return(NULL)
    }
    list(name = public_name, order = as.numeric(spec$order))
  })
  ordered <- Filter(Negate(is.null), ordered)
  if (length(ordered) == 0) {
    return(character())
  }

  names <- vapply(ordered, `[[`, character(1), "name")
  positions <- vapply(ordered, `[[`, numeric(1), "order")
  configured_order <- order(positions, match(names, formal_names))
  names <- names[configured_order]
  positions <- positions[configured_order]

  result <- setdiff(formal_names, names)
  used_positions <- list()
  for (i in seq_along(names)) {
    position <- max(1L, as.integer(positions[[i]]))
    position_key <- as.character(position)
    same_position <- used_positions[[position_key]] %||% 0L
    after <- min(position - 1L + same_position, length(result))
    result <- append(result, names[[i]], after = after)
    used_positions[[position_key]] <- same_position + 1L
  }
  unique(result)
}

stubgen_reorder_param_docs <- function(param_docs, formal_names) {
  lines <- strsplit(param_docs %||% "", "\n", fixed = TRUE)[[1]]
  doc_pattern <- "^#' @param ([^ ]+) "
  is_param <- grepl(doc_pattern, lines)
  param_lines <- lines[is_param]
  if (length(param_lines) == 0) {
    return(param_docs)
  }

  param_names <- sub(doc_pattern, "\\1", param_lines)
  keep <- !duplicated(param_names)
  param_lines <- param_lines[keep]
  param_names <- param_names[keep]
  ordered_names <- c(formal_names, setdiff(param_names, formal_names))
  ordered_lines <- param_lines[match(ordered_names, param_names, nomatch = 0L)]
  other_lines <- lines[!is_param & nzchar(lines)]
  paste0(paste(c(ordered_lines, other_lines), collapse = "\n"), "\n")
}

stubgen_build_request_template <- function(
  fn,
  fn_signature,
  fn_config,
  hook_pre_request,
  pagination_call_params
) {
  template <- fn_config$request_template
  if (is.null(template)) {
    return(NULL)
  }
  if (is.null(fn_config$pre_request) || length(fn_config$pre_request) == 0) {
    cli::cli_abort(
      "Request template for {.fn {fn}} requires at least one pre-request hook."
    )
  }

  helper <- template$helper
  allowed_helpers <- c("generic_request", "generic_chemi_request")
  if (!is.character(helper) || length(helper) != 1 || !helper %in% allowed_helpers) {
    cli::cli_abort(
      "Request template for {.fn {fn}} must use one of: {paste(allowed_helpers, collapse = ', ')}."
    )
  }

  args <- template$args
  if (!is.list(args) || length(args) == 0 || is.null(names(args)) || any(!nzchar(names(args)))) {
    cli::cli_abort(
      "Request template for {.fn {fn}} must define named helper arguments."
    )
  }
  duplicate_args <- unique(names(args)[duplicated(names(args))])
  if (length(duplicate_args) > 0) {
    cli::cli_abort(
      "Request template for {.fn {fn}} repeats argument{?s}: {paste(duplicate_args, collapse = ', ')}."
    )
  }
  expressions <- vapply(args, as.character, character(1))
  for (expression in expressions) {
    tryCatch(
      parse(text = expression),
      error = function(error) {
        cli::cli_abort(
          "Request template for {.fn {fn}} has invalid R expression {.code {expression}}.",
          parent = error
        )
      }
    )
  }

  argument_lines <- paste0(
    "      ",
    names(expressions),
    " = ",
    expressions,
    collapse = ",\n"
  )
  helper_call <- paste0(
    "    result <- ",
    helper,
    "(\n",
    argument_lines,
    pagination_call_params,
    "\n    )"
  )
  request_lines <- if (isTRUE(template$post_on_skip)) {
    paste0(
      "  if (isTRUE(req_data$skip_request)) {\n",
      "    result <- req_data$result\n",
      "  } else {\n",
      helper_call,
      "\n  }\n"
    )
  } else {
    paste0(helper_call, "\n")
  }

  post_lines <- if (!is.null(fn_config$post_response) && length(fn_config$post_response) > 0) {
    paste0(
      "  post_data <- req_data\n",
      "  post_data$result <- result\n",
      "  result <- run_hook(\"",
      fn,
      "\", \"post_response\", post_data)\n"
    )
  } else {
    ""
  }

  body <- paste0(
    fn,
    " <- function(",
    fn_signature,
    ") {\n",
    hook_pre_request,
    request_lines,
    "\n",
    post_lines,
    "\n  return(result)\n",
    "}\n"
  )
  tryCatch(
    parse(text = body),
    error = function(error) {
      cli::cli_abort(
        "Generated invalid request-template syntax for function {.fn {fn}}.",
        parent = error
      )
    }
  )
  body
}

stubgen_build_request_override <- function(
  fn,
  fn_signature,
  endpoint,
  wrapper_fn,
  request_override,
  hook_pre_request,
  hook_post_response,
  pagination_call_params,
  stage_server_call
) {
  if (is.null(request_override)) {
    return(NULL)
  }
  if (
    !identical(wrapper_fn, "generic_chemi_request") ||
      !isTRUE(request_override$array_payload)
  ) {
    cli::cli_abort(
      "Unsupported request override configured for {.fn {fn}}."
    )
  }

  formal_names <- stubgen_formal_names(fn_signature)
  query_param <- request_override$query
  sid_label <- request_override$sid_label %||% query_param
  top_level <- request_override$top_level %||% character()
  referenced_params <- c(query_param, top_level)
  unknown <- setdiff(referenced_params, formal_names)
  if (length(unknown) > 0) {
    cli::cli_abort(
      "Request override for {.fn {fn}} references unknown parameter{?s}: {paste(unknown, collapse = ', ')}."
    )
  }

  option_lines <- paste0(
    "    ",
    vapply(
      top_level,
      function(param_name) {
        paste0(stubgen_symbol(param_name), " = ", stubgen_symbol(param_name))
      },
      character(1)
    ),
    collapse = ",\n"
  )

  glue::glue(
    '
{fn} <- function({fn_signature}) {{
{hook_pre_request}  request_options <- list(
{option_lines}
  )
  result <- generic_chemi_request(
    query = {stubgen_symbol(query_param)},
    endpoint = "{endpoint}",
    options = request_options,
    sid_label = "{sid_label}",
    array_payload = TRUE,
    tidy = FALSE{stage_server_call}{pagination_call_params}
  )

{hook_post_response}  # Additional post-processing can be added here

  return(result)
}}

'
  )
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
        if (items_type %in% c("string", "integer", "number", "boolean") && !items_has_properties && !items_has_ref) {
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
build_function_stub <- function(fn, ..., schema_stage = "public") {
  build_function_stub_impl(fn = fn, ..., schema_stage = schema_stage)
}

build_function_stub_impl <- function(
  fn,
  endpoint,
  method,
  title,
  batch_limit,
  path_param_info,
  query_param_info,
  body_param_info,
  content_type,
  config,
  needs_resolver = FALSE,
  body_schema_type = "unknown",
  deprecated = FALSE,
  response_schema_type = "unknown",
  request_type = NULL,
  pagination_strategy = "none",
  pagination_metadata = NULL,
  schema_stage = "public"
) {
  if (!requireNamespace("glue", quietly = TRUE)) {
    stop("Package 'glue' is required.")
  }

  # Deployment stage the endpoint was generated from (public/staging/development).
  # Emitted as the @apiStage doc tag; non-public stages also drive the
  # server-swap hook wiring below.
  schema_stage <- schema_stage %|NA|% "public"
  hook_config <- stubgen_read_hook_config()
  fn_config <- hook_config[[fn]]
  has_hooks <- !is.null(fn_config)
  has_stage_server_hook <- isTRUE(has_hooks) &&
    "enforce_stage_server" %in% (fn_config$pre_request %||% character())
  stage_server_call <- if (has_stage_server_hook) ',\n    server = server' else ""
  chemi_server_value <- if (has_stage_server_hook) "server" else '"chemi_burl"'

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
    return_doc <- switch(
      response_schema_type,
      "array" = "Returns a tibble with results (array of objects)",
      "object" = "Returns a list with result object",
      "scalar" = "Returns a scalar value",
      "binary" = "Returns binary data",
      "Returns a tibble with results" # default
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
    is_chemi_get <- TRUE # Track this to set correct server/auth
  }

  # epi_* wrappers hit the unauthenticated EPI Suite API on epi_burl. They reuse
  # the chemi GET server/tidy slots (threaded into every GET template) rather than
  # the generic_request ctx_burl default. Responses are deeply nested, so return
  # the raw list (tidy = FALSE) and let post_response hooks shape each module.
  is_epi_get <- isTRUE(grepl("^epi_", fn))

  # Build server and auth params for chemi/epi GET endpoints
  chemi_server_params <- if (isTRUE(is_chemi_get)) {
    paste0(
      if (has_stage_server_hook) ',\n    server = server' else ',\n    server = "chemi_burl"',
      ",\n    auth = FALSE"
    )
  } else if (is_epi_get) {
    ',\n    server = "epi_burl",\n    auth = FALSE'
  } else {
    ""
  }

  # Build tidy param for chemi/epi GET endpoints (return raw list instead of tibble)
  chemi_tidy_param <- if (isTRUE(is_chemi_get) || is_epi_get) ',\n    tidy = FALSE' else ""

  # Build server and auth params for common_chemistry (cc_) GET endpoints
  cc_server_params <- if (isTRUE(grepl("^cc_", fn))) ',\n    server = "cc_burl",\n    auth = TRUE' else ""

  # Check endpoint type using request_type if available, otherwise use legacy detection
  # This provides cleaner, more explicit endpoint classification
  # Request types:
  #   - "json": POST/PUT/PATCH with request body (body_only)
  #   - "path": GET with path parameters (standard path-based endpoint)
  #   - "query_only": GET without path parameters (static endpoint, query params only)
  if (!is.null(request_type) && !is.na(request_type) && nzchar(request_type)) {
    is_path_body <- request_type == "json" && isTRUE(path_param_info$has_any_path_params)
    is_body_only <- request_type == "json" && !is_path_body
    # NEW: Simple body types are also body-only
    is_simple_body <- body_schema_type %in% c("string", "string_array")
    is_query_only <- request_type == "query_only" # "path" falls through to standard case
  } else {
    is_path_body <- FALSE
    # Legacy detection for backward compatibility
    is_query_only <- (!is.null(batch_limit) &&
      !is.na(batch_limit) &&
      batch_limit == 0 &&
      isTRUE(query_param_info$has_params) &&
      !is.null(query_param_info$primary_param))

    is_body_only <- (isTRUE(body_param_info$has_params) &&
      !isTRUE(path_param_info$has_path_params) &&
      nchar(path_param_info$fn_signature %|NA|% "") == 0)

    # NEW: Simple body types are body-only even if body_param_info$has_params is FALSE
    is_simple_body <- body_schema_type %in% c("string", "string_array")
  }

  if (isTRUE(is_path_body)) {
    primary_param <- path_param_info$primary_param
    fn_signature <- paste(
      c(path_param_info$fn_signature, body_param_info$fn_signature)[
        nzchar(c(path_param_info$fn_signature, body_param_info$fn_signature))
      ],
      collapse = ", "
    )
    combined_calls <- ""
    param_docs <- paste0(path_param_info$param_docs, body_param_info$param_docs)
    example_value <- example_query
    if (!stubgen_value_missing(path_param_info$primary_example)) {
      example_value <- stubgen_example_value(path_param_info$primary_example)
    }
    example_value_vec <- paste0('"', example_value, '"')
  } else if (isTRUE(is_body_only)) {
    # Body-only endpoint (POST/PUT/PATCH with no path params): primary param from body
    primary_param <- body_param_info$primary_param %||% "data"
    fn_signature <- body_param_info$fn_signature
    combined_calls <- "" # Body params handled differently
    param_docs <- body_param_info$param_docs

    # Example value from body param metadata
    example_value <- example_query
    if (
      !is.null(body_param_info$primary_example) &&
        !stubgen_value_missing(body_param_info$primary_example)
    ) {
      example_value <- stubgen_example_value(body_param_info$primary_example)
    }

    # Build example_value_vec for example call generation
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 1, custom_list = config$example_dtxsids %||% NULL)
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
    if (
      !is.null(query_param_info$primary_example) &&
        !stubgen_value_missing(query_param_info$primary_example)
    ) {
      example_value <- stubgen_example_value(query_param_info$primary_example)
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
    if (
      !is.null(path_param_info$primary_example) &&
        !stubgen_value_missing(path_param_info$primary_example)
    ) {
      example_value <- stubgen_example_value(path_param_info$primary_example)
    }

    # For POST requests, use sample from testing_chemicals
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 1, custom_list = config$example_dtxsids %||% NULL)
      if (length(dtxsids) > 1) {
        example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
      } else {
        example_value_vec <- paste0('"', dtxsids, '"')
      }
    } else {
      example_value_vec <- paste0('"', example_value, '"')
    }
  }

  # =========================================================================
  # Pagination Parameter Generation (Phase 21)
  # =========================================================================
  # For paginated endpoints, add all_pages parameter and pagination call args
  pagination_call_params <- ""

  if (!isTRUE(pagination_strategy == "none") && !is.null(pagination_strategy) && !is.na(pagination_strategy)) {
    # 1. Set sensible defaults for pagination params already in signature
    pag_params <- if (!is.null(pagination_metadata) && !is.null(pagination_metadata$params)) {
      pagination_metadata$params
    } else {
      character(0)
    }

    fn_signature_safe_pag <- fn_signature %|NA|% ""
    if ("offset" %in% pag_params && grepl("\\boffset\\b", fn_signature_safe_pag)) {
      # Replace bare "offset" or "offset = NULL" with "offset = 0"
      fn_signature <- gsub("\\boffset\\s*=\\s*NULL", "offset = 0", fn_signature, perl = TRUE)
      fn_signature <- gsub("\\boffset(?!\\s*=)", "offset = 0", fn_signature, perl = TRUE)
    }
    if (
      "page" %in%
        pag_params &&
        grepl("\\bpage\\b", fn_signature_safe_pag) &&
        !grepl("\\bpageNumber\\b", fn_signature_safe_pag)
    ) {
      # Replace bare "page" or "page = NULL" with "page = 0"
      fn_signature <- gsub("\\bpage\\s*=\\s*NULL", "page = 0", fn_signature, perl = TRUE)
      fn_signature <- gsub("\\bpage(?!\\s*=|Number)", "page = 0", fn_signature, perl = TRUE)
    }
    if ("pageNumber" %in% pag_params && grepl("\\bpageNumber\\b", fn_signature_safe_pag)) {
      # Replace bare "pageNumber" or "pageNumber = NULL" with "pageNumber = 1"
      fn_signature <- gsub("\\bpageNumber\\s*=\\s*NULL", "pageNumber = 1", fn_signature, perl = TRUE)
      fn_signature <- gsub("\\bpageNumber(?!\\s*=)", "pageNumber = 1", fn_signature, perl = TRUE)
    }

    # 2. Append the automatic pagination controls to the signature.
    fn_signature_check <- fn_signature %|NA|% ""
    if (nzchar(fn_signature_check)) {
      fn_signature <- paste0(fn_signature, ", all_pages = TRUE, max_pages = 100")
    } else {
      fn_signature <- "all_pages = TRUE, max_pages = 100"
    }

    # 3. Add @param all_pages documentation
    param_docs <- paste0(
      param_docs,
      "#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.\n",
      "#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.\n"
    )

    # 4. Build pagination call params string (inserted into glue templates)
    pagination_call_params <- paste0(
      ",\n    paginate = all_pages",
      ",\n    max_pages = max_pages",
      ',\n    pagination_strategy = "',
      pagination_strategy,
      '"',
      if (
        identical(pagination_strategy, "cursor") &&
          !stubgen_value_missing(pagination_metadata$cursor_location)
      ) {
        paste0(',\n    pagination_cursor_location = "', pagination_metadata$cursor_location, '"')
      } else {
        ""
      }
    )
  }

  # =========================================================================
  # Hook Parameter Injection (Phase 28)
  # =========================================================================
  if (isTRUE(has_hooks)) {
    if (!is.null(fn_config$extra_params)) {
      for (param_name in names(fn_config$extra_params)) {
        param_spec <- fn_config$extra_params[[param_name]]
        formal_names <- stubgen_formal_names(fn_signature)

        # 1. Append to fn_signature (same pattern as pagination all_pages)
        if (!param_name %in% formal_names) {
          param_code <- if (isTRUE(param_spec$required)) {
            param_name
          } else {
            paste0(param_name, " = ", param_spec$default)
          }
          fn_signature_check <- fn_signature %|NA|% ""
          if (nzchar(fn_signature_check)) {
            fn_signature <- paste0(fn_signature, ", ", param_code)
          } else {
            fn_signature <- param_code
          }
        }

        # 2. Add @param doc only for newly injected parameters.
        if (!param_name %in% formal_names) {
          param_docs <- paste0(
            param_docs,
            "#' @param ",
            param_name,
            " ",
            param_spec$description,
            "\n"
          )
        }
      }
    }

    fn_signature <- stubgen_apply_signature_overrides(
      fn_signature,
      fn_config$signature_overrides
    )
    configured_order <- stubgen_configured_parameter_order(
      fn_config,
      fn_signature
    )
    fn_signature <- stubgen_apply_signature_order(
      fn_signature,
      c(configured_order, setdiff(stubgen_formal_names(fn_signature), configured_order))
    )
    fn_signature <- stubgen_apply_signature_order(
      fn_signature,
      fn_config$signature_order
    )
    param_docs <- stubgen_reorder_param_docs(
      param_docs,
      stubgen_formal_names(fn_signature)
    )
  }

  # =========================================================================
  # Hook Call Generation (Phase 28)
  # =========================================================================
  # Build hook call snippets that will be inserted into stub bodies
  # Pre-request hooks: wrap query before generic_request
  # Post-response hooks: wrap result after generic_request
  hook_pre_request <- ""
  hook_post_response <- ""
  hook_chemi_chemicals_arg <- ""

  if (isTRUE(has_hooks)) {
    fn_config <- hook_config[[fn]]

    uses_chemical_objects <- identical(wrapper_fn, "generic_chemi_request") &&
      !isTRUE(is_path_body) &&
      is.null(fn_config$request_template) &&
      !isTRUE(fn_config$request_override$array_payload) &&
      "resolve_query_to_chemical_records" %in% (fn_config$pre_request %||% character())
    hook_extra_params <- if (uses_chemical_objects) "chemicals" else character(0)
    hook_param_inits <- list()
    if (isTRUE(has_stage_server_hook)) {
      hook_extra_params <- unique(c(hook_extra_params, "server"))
      hook_param_inits <- list(
        server = if (grepl("^cc_", fn)) {
          '"cc_burl"'
        } else if (grepl("^ct_", fn)) {
          '"ctx_burl"'
        } else {
          '"chemi_burl"'
        }
      )
    }
    hook_pre_request <- stubgen_build_pre_hook(
      fn,
      fn_config,
      fn_signature,
      additional_params = hook_extra_params,
      return_on_skip = is.null(fn_config$request_template),
      writeback_params = is.null(fn_config$request_template),
      param_inits = hook_param_inits
    )
    hook_post_response <- stubgen_build_post_hook(fn, fn_config, fn_signature)
    if (
      nzchar(hook_pre_request) &&
        identical(wrapper_fn, "generic_chemi_request") &&
        isTRUE(uses_chemical_objects)
    ) {
      hook_chemi_chemicals_arg <- ",\n    chemicals = chemicals"
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
  roxygen_header <- glue::glue(
    '
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
{param_docs}#\' @return {return_doc}
#\' @apiStage {schema_stage}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {example_call}
#\' }}'
  )

  request_template_body <- stubgen_build_request_template(
    fn = fn,
    fn_signature = fn_signature,
    fn_config = fn_config,
    hook_pre_request = hook_pre_request,
    pagination_call_params = pagination_call_params
  )
  if (!is.null(request_template_body)) {
    return(paste0(roxygen_header, "\n", request_template_body, "\n"))
  }

  request_override_body <- stubgen_build_request_override(
    fn = fn,
    fn_signature = fn_signature,
    endpoint = endpoint,
    wrapper_fn = wrapper_fn,
    request_override = fn_config$request_override,
    hook_pre_request = hook_pre_request,
    hook_post_response = hook_post_response,
    pagination_call_params = pagination_call_params,
    stage_server_call = stage_server_call
  )
  if (!is.null(request_override_body)) {
    override_result <- paste0(
      roxygen_header,
      "\n",
      request_override_body,
      "\n\n"
    )
    tryCatch(
      parse(text = override_result),
      error = function(e) {
        cli::cli_abort(c(
          "x" = "Generated invalid request override syntax for function {.fn {fn}}",
          "i" = "Parse error: {e$message}",
          "i" = "Endpoint: {endpoint}"
        ))
      }
    )
    return(override_result)
  }

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
      params <- gsub("\\s*=\\s*.*$", "", params)
      # Filter out 'chemicals' as we'll handle that via resolver
      params[!params %in% c("chemicals")]
    } else {
      character(0)
    }

    query_params_vec <- if (isTRUE(query_param_info$has_params)) {
      params <- strsplit(query_param_info$fn_signature, ",")[[1]]
      params <- trimws(params)
      gsub("\\s*=\\s*.*$", "", params)
    } else {
      character(0)
    }

    # Build function signature: query, idType, plus any additional body params
    additional_sig <- if (length(body_params_vec) > 0) {
      paste0(", ", paste(body_params_vec, "= NULL", collapse = ", "))
    } else {
      ""
    }

    additional_query_sig <- if (length(query_params_vec) > 0) {
      paste0(", ", query_param_info$fn_signature)
    } else {
      ""
    }

    fn_signature_resolver <- paste0('query, idType = "AnyId"', additional_sig, additional_query_sig)

    # Append all_pages param when pagination is active
    if (nzchar(pagination_call_params)) {
      fn_signature_resolver <- paste0(fn_signature_resolver, ", all_pages = TRUE, max_pages = 100")
      resolver_pagination_param_doc <- paste0(
        "#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.\n",
        "#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.\n"
      )
    } else {
      resolver_pagination_param_doc <- ""
    }

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
    resolver_param_docs <- paste0(resolver_param_docs, resolver_pagination_param_doc)
    if (length(query_params_vec) > 0) {
      resolver_param_docs <- paste0(resolver_param_docs, query_param_info$param_docs)
    }

    if (isTRUE(has_hooks) && !is.null(fn_config$extra_params)) {
      for (param_name in names(fn_config$extra_params)) {
        param_spec <- fn_config$extra_params[[param_name]]
        if (!param_name %in% stubgen_formal_names(fn_signature_resolver)) {
          param_code <- if (isTRUE(param_spec$required)) {
            param_name
          } else {
            paste0(param_name, " = ", param_spec$default)
          }
          fn_signature_resolver <- paste0(fn_signature_resolver, ", ", param_code)
          resolver_param_docs <- paste0(
            resolver_param_docs,
            "#' @param ",
            param_name,
            " ",
            param_spec$description,
            "\n"
          )
        }
      }
    }

    resolver_query_params_call <- if (length(query_params_vec) > 0) {
      query_args <- vapply(
        query_params_vec,
        function(p) {
          value_expr <- if (identical(p, "sort")) {
            paste0("if (!is.null(", p, ")) tolower(as.character(", p, ")) else NULL")
          } else {
            p
          }
          paste0(p, " = ", value_expr)
        },
        character(1)
      )
      paste0(",\n    ", paste(query_args, collapse = ",\n    "))
    } else {
      ""
    }

    resolver_hook_pre_request <- if (isTRUE(has_hooks)) {
      resolver_extra_params <- c(
        "chemicals",
        if (has_stage_server_hook) "server" else character()
      )
      resolver_param_inits <- if (has_stage_server_hook) list(server = '"chemi_burl"') else list()
      stubgen_build_pre_hook(
        fn,
        hook_config[[fn]],
        fn_signature_resolver,
        additional_params = resolver_extra_params,
        param_inits = resolver_param_inits
      )
    } else {
      ""
    }
    resolver_hook_post_response <- if (isTRUE(has_hooks)) {
      stubgen_build_post_hook(fn, hook_config[[fn]], fn_signature_resolver)
    } else {
      ""
    }
    resolver_chemicals_arg <- if (nzchar(resolver_hook_pre_request)) ",\n    chemicals = chemicals" else ""
    resolver_return_doc <- fn_config$return_description %||% return_doc

    # Update roxygen header with resolver-specific docs
    roxygen_header <- glue::glue(
      '
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
#\' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#\' then sends the resolved Chemical objects to the API endpoint.
#\'
{resolver_param_docs}#\' @return {resolver_return_doc}
#\' @apiStage {schema_stage}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = c("50-00-0", "DTXSID7020182"))
#\' }}'
    )

    # Generate resolver-wrapped function body using generic_chemi_request
    fn_body <- glue::glue(
      '
{fn} <- function({fn_signature_resolver}) {{
{resolver_hook_pre_request}
{options_assembly}

  result <- generic_chemi_request(
    query = query,
    endpoint = "{endpoint}",
    options = extra_options,
    tidy = FALSE{resolver_chemicals_arg}{resolver_query_params_call}{stage_server_call}{pagination_call_params}
  )

{resolver_hook_post_response}  # Additional post-processing can be added here

  return(result)
}}

'
    )

    # Combine header and body and return
    return(paste0(roxygen_header, "\n", fn_body))
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
  is_raw_text_body <- (body_schema_type == "string" &&
    toupper(method) == "POST" &&
    wrapper_fn == "generic_request" &&
    (endpoint == "chemical/search/equal/" || grepl("chemical/search/equal/$", endpoint)))

  if (isTRUE(is_raw_text_body)) {
    # Build roxygen header for raw text body endpoint
    roxygen_header <- glue::glue(
      '
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
#\' @param query Character vector of values to search for
#\' @return {return_doc}
#\' @apiStage {schema_stage}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = c("DTXSID7020182", "DTXSID9020112"))
#\' }}'
    )

    # Generate function body using generic_request with body_type = "raw_text"
    fn_body <- glue::glue(
      '
{fn} <- function(query) {{
{hook_pre_request}  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "POST",
    batch_limit = {batch_limit_code},
    body_type = "raw_text"{pagination_call_params}
  )

  return(result)
}}

'
    )

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

    # Merge query parameters into signature/docs if present
    query_params_call <- ""
    query_params_code <- ""
    if (isTRUE(query_param_info$has_params)) {
      query_sig <- query_param_info$fn_signature
      if (nzchar(query_sig %||% "")) {
        fn_signature <- paste0(fn_signature, ", ", query_sig)
      }
      param_docs <- paste0(param_docs, query_param_info$param_docs)
      query_params_call <- query_param_info$params_call %||% ""
      query_params_code <- query_param_info$params_code %||% ""
    }

    # Simple-body endpoints replace the schema-derived signature with `query`.
    # Rebuild the stage hook after that replacement so it does not reference
    # discarded body-property parameters.
    if (isTRUE(has_hooks)) {
      simple_additional_params <- if (isTRUE(has_stage_server_hook)) {
        "server"
      } else {
        character()
      }
      hook_pre_request <- stubgen_build_pre_hook(
        fn,
        fn_config,
        fn_signature,
        additional_params = simple_additional_params,
        param_inits = if (isTRUE(has_stage_server_hook)) {
          list(server = '"chemi_burl"')
        } else {
          list()
        }
      )
    }

    # Build example value
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 1, custom_list = config$example_dtxsids %||% NULL)
      if (length(dtxsids) > 1) {
        example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
      } else {
        example_value_vec <- paste0('"', dtxsids, '"')
      }
    } else {
      example_value_vec <- '"DTXSID7020182"'
    }

    # Build roxygen header
    roxygen_header <- glue::glue(
      '
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
{param_docs}#\' @return {return_doc}
#\' @apiStage {schema_stage}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = {example_value_vec})
#\' }}'
    )

    # Generate function body based on body schema type
    if (body_schema_type == "string_array") {
      # Array body: pass directly, generic_request() handles JSON encoding
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_params_code}  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100")){stage_server_call}{query_params_call}{pagination_call_params}
  )

  return(result)
}}

'
      )
    } else {
      # Simple string body: pass directly
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_params_code}  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100")){stage_server_call}{query_params_call}{pagination_call_params}
  )

  return(result)
}}

'
      )
    }

    # Return early with generated stub
    return(paste0(roxygen_header, "\n", fn_body, "\n\n"))
  }

  if (isTRUE(is_path_body)) {
    body_params <- stubgen_formal_names(body_param_info$fn_signature)
    required_body_params <- body_params[
      !grepl(
        "=",
        trimws(strsplit(body_param_info$fn_signature, ",")[[1]]),
        fixed = TRUE
      )
    ]
    optional_body_params <- setdiff(body_params, required_body_params)
    body_lines <- c("  # Build request body", "  request_body <- list()")
    for (param_name in required_body_params) {
      body_lines <- c(body_lines, paste0("  request_body$", param_name, " <- ", param_name))
    }
    for (param_name in optional_body_params) {
      body_lines <- c(
        body_lines,
        paste0("  if (!is.null(", param_name, ")) request_body$", param_name, " <- ", param_name)
      )
    }
    path_names <- stubgen_formal_names(path_param_info$fn_signature)
    path_call <- paste0(
      ",\n    path_params = c(",
      paste(path_names, "=", path_names, collapse = ", "),
      ")"
    )
    path_body_server_call <- if (identical(wrapper_fn, "generic_chemi_request")) {
      paste0(
        if (has_stage_server_hook) ',\n    server = server' else ',\n    server = "chemi_burl"',
        ",\n    auth = FALSE,\n    tidy = FALSE"
      )
    } else {
      ""
    }

    fn_body <- glue::glue(
      '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{paste(body_lines, collapse = "\n")}
  result <- generic_request(
    query = NULL,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = 0{path_body_server_call}{path_call},
    body = request_body{content_type_call}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
    )
  } else if (isTRUE(is_body_only)) {
    # Body-only endpoint (POST/PUT/PATCH with body params): build request body
    if (wrapper_fn == "generic_chemi_request") {
      # Extract parameter info from body_param_info
      param_vec <- strsplit(body_param_info$fn_signature, ",")[[1]]
      param_vec <- trimws(param_vec)
      # BUILD-01 FIX: Remove ALL default values, not just " = NULL"
      # This ensures param_vec contains only parameter names (e.g., "model" not "model = \"RF\"")
      param_vec <- gsub("\\s*=\\s*.*$", "", param_vec) # Remove " = <anything>" suffix

      # Identify required params (no "=" in original signature)
      sig_parts <- strsplit(body_param_info$fn_signature, ",")[[1]]
      sig_parts <- trimws(sig_parts)
      required_params_mask <- !grepl("=", sig_parts)
      required_params <- param_vec[required_params_mask]
      optional_params <- param_vec[!required_params_mask]

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
        .StubGenEnv$skipped <- c(
          .StubGenEnv$skipped,
          list(tibble::tibble(
            route = endpoint,
            method = method,
            skip_reason = "Body properties not extractable as function parameters",
            source_file = NA_character_
          ))
        )
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
        # BUILD-01 FIX: Use clean parameter name in condition and assignment
        # Previously generated: if (!is.null(model = "RF")) options$model = "RF" <- model = "RF"
        # Now generates: if (!is.null(model)) options$model <- model
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

      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{options_assembly}
  result <- generic_chemi_request(
    query = {query_param},
    endpoint = "{endpoint}"{options_call}{wrap_param},
    tidy = FALSE{hook_chemi_chemicals_arg}{stage_server_call}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_request") {
      # Similar logic for generic_request
      param_vec <- strsplit(body_param_info$fn_signature, ",")[[1]]
      param_vec <- trimws(param_vec)
      # BUILD-01 FIX: Remove ALL default values, not just " = NULL"
      param_vec <- gsub("\\s*=\\s*.*$", "", param_vec)

      sig_parts <- strsplit(body_param_info$fn_signature, ",")[[1]]
      sig_parts <- trimws(sig_parts)
      required_params_mask <- !grepl("=", sig_parts)
      required_params <- param_vec[required_params_mask]
      optional_params <- param_vec[!required_params_mask]

      body_code_lines <- c(
        "  # Build request body",
        "  request_body <- list()"
      )

      for (p in required_params) {
        body_code_lines <- c(body_code_lines, paste0("  request_body$", p, " <- ", p))
      }

      for (p in optional_params) {
        body_code_lines <- c(body_code_lines, paste0("  if (!is.null(", p, ")) request_body$", p, " <- ", p))
      }

      body_assembly <- paste(body_code_lines, collapse = "\n")

      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}
{body_assembly}
  result <- generic_request(
    query = NULL,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code},
    body = request_body{content_type_call}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_cts_request") {
      param_vec <- strsplit(body_param_info$fn_signature, ",")[[1]]
      param_vec <- trimws(param_vec)
      param_vec <- gsub("\\s*=\\s*.*$", "", param_vec)

      sig_parts <- strsplit(body_param_info$fn_signature, ",")[[1]]
      sig_parts <- trimws(sig_parts)
      required_params_mask <- !grepl("=", sig_parts)
      required_params <- param_vec[required_params_mask]
      optional_params <- param_vec[!required_params_mask]

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

      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}
{body_assembly}
  result <- generic_cts_request(
    endpoint = "{endpoint}",
    body = body,
    method = "{method}",
    tidy = FALSE
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  } else if (isTRUE(is_query_only)) {
    # Query-only endpoint: all params via ellipsis, no query parameter needed
    # For query-only endpoints, batch_limit should be 0 (static endpoint)
    effective_batch_limit <- if (batch_limit_code == "NULL") "0" else batch_limit_code

    if (wrapper_fn == "generic_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_request(
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{cc_server_params}{content_type_call}{combined_calls}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_chemi_request(
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE{hook_chemi_chemicals_arg}{stage_server_call}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_cc_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}  result <- generic_cc_request(
    endpoint = "{endpoint}",
    method = "{method}"{combined_calls}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_cts_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_cts_request(
    endpoint = "{endpoint}",
    method = "{method}",
    body = list(),
    tidy = FALSE
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
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
        fn_body <- glue::glue(
          '
{fn} <- function({fn_signature}) {{
{hook_pre_request}  result <- generic_request(
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{direct_params}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
        )
      } else {
        # Standard generation with existing logic
        fn_body <- glue::glue(
          '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_request(
    query = {effective_query},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{combined_calls}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
        )
      }
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE{hook_chemi_chemicals_arg}{stage_server_call}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_cts_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_signature}) {{
{hook_pre_request}{query_param_info$params_code}  result <- generic_cts_request(
    endpoint = "{endpoint}",
    method = "{method}",
    body = list(),
    tidy = FALSE
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
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

      fn_body <- glue::glue(
        '
{fn} <- function({fn_arg}) {{
{hook_pre_request}  result <- generic_request(
    query = {effective_query},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {effective_batch_limit}{chemi_server_params}{chemi_tidy_param}{content_type_call}{extra_params}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_arg}) {{
{hook_pre_request}  result <- generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    server = {chemi_server_value},
    auth = FALSE,
    tidy = FALSE{hook_chemi_chemicals_arg}{pagination_call_params}
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else if (wrapper_fn == "generic_cts_request") {
      fn_body <- glue::glue(
        '
{fn} <- function({fn_arg}) {{
{hook_pre_request}  result <- generic_cts_request(
    endpoint = "{endpoint}",
    method = "{method}",
    body = list(),
    tidy = FALSE
  )

  {hook_post_response}# Additional post-processing can be added here

  return(result)
}}

'
      )
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  }

  # Combine header and body
  result <- paste0(roxygen_header, "\n", fn_body, "\n\n")

  # BUILD-01 FIX: Validate syntax before returning
  # This catches syntax errors at generation time rather than at runtime
  parsed <- tryCatch(
    {
      parse(text = result)
    },
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Generated invalid R syntax for function {.fn {fn}}",
        "i" = "Parse error: {e$message}",
        "i" = "Endpoint: {endpoint}",
        "i" = "Check parameter defaults and assignment operators in generated code"
      ))
    }
  )

  # BUILD-06 FIX: Validate @param tags match function formals
  # Extract formals from parsed function
  fn_expr <- NULL
  for (i in seq_along(parsed)) {
    expr <- parsed[[i]]
    if (
      is.call(expr) &&
        as.character(expr[[1]]) == "<-" &&
        is.call(expr[[3]]) &&
        as.character(expr[[3]][[1]]) == "function"
    ) {
      fn_expr <- expr[[3]]
      break
    }
  }

  if (!is.null(fn_expr)) {
    actual_formals <- names(formals(eval(fn_expr)))

    # Extract @param names from roxygen
    param_lines <- strsplit(roxygen_header, "\n")[[1]]
    param_lines <- grep("^#' @param ", param_lines, value = TRUE)
    documented_params <- sub("^#' @param (\\S+).*", "\\1", param_lines)

    # Check for mismatches
    missing_docs <- setdiff(actual_formals, documented_params)
    extra_docs <- setdiff(documented_params, actual_formals)

    if (length(missing_docs) > 0 || length(extra_docs) > 0) {
      cli::cli_warn(c(
        "!" = "Roxygen @param mismatch for function {.fn {fn}}",
        "i" = if (length(missing_docs) > 0) paste0("Missing docs: ", paste(missing_docs, collapse = ", ")),
        "i" = if (length(extra_docs) > 0) paste0("Extra docs: ", paste(extra_docs, collapse = ", ")),
        "i" = "Function formals: ",
        paste(actual_formals, collapse = ", "),
        "i" = "Documented params: ",
        paste(documented_params, collapse = ", ")
      ))
    }
  }

  result
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
render_endpoint_stubs <- function(
  spec,
  config,
  fn_transform = function(x) {
    nm <- tools::file_path_sans_ext(basename(x))
    nm <- gsub("-", "_", nm, fixed = TRUE)
    nm
  }
) {
  stopifnot(is.data.frame(spec))
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }
  if (!requireNamespace("purrr", quietly = TRUE)) {
    stop("Package 'purrr' is required.")
  }

  # Extract strategy from config
  param_strategy <- config$param_strategy %||% "extra_params"

  # Ensure all necessary columns exist with defaults
  spec <- ensure_cols(
    spec,
    list(
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
      schema_stage = "public",
      pagination_strategy = "none",
      pagination_metadata = list(NULL)
    )
  )

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
      fn = character(),
      endpoint = character(),
      title = character(),
      text = character()
    ))
  }

  # Pre-process some columns
  spec <- spec %>%
    dplyr::mutate(
      fn = dplyr::coalesce(fn, vapply(file, fn_transform, character(1))),
      endpoint = route,
      title = trimws(dplyr::if_else(
        nzchar(summary %||% ""),
        summary,
        tools::toTitleCase(gsub("[/_-]", " ", route))
      ))
    )

  hook_config <- stubgen_read_hook_config()

  # Parse parameters row by row
  # We use pmap to avoid rowwise() issues
  parsed_params <- purrr::pmap(
    list(
      spec$fn,
      spec$path_params,
      spec$query_params,
      spec$body_params,
      spec$num_path_params,
      spec$path_param_metadata,
      spec$query_param_metadata,
      spec$body_param_metadata
    ),
    function(fn, pp, qp, bp, npp, ppm, qpm, bpm) {
      parameter_overrides <- hook_config[[fn]]$parameter_overrides %||% list()
      list(
        path_info = parse_path_parameters(pp, strategy = param_strategy, metadata = ppm %||% list()),
        query_info = parse_function_params(
          qp,
          strategy = param_strategy,
          metadata = qpm %||% list(),
          has_path_params = (npp %||% 0 > 0),
          overrides = parameter_overrides
        ),
        body_info = parse_function_params(
          bp,
          strategy = param_strategy,
          metadata = bpm %||% list(),
          has_path_params = (npp %||% 0 > 0),
          overrides = parameter_overrides
        )
      )
    }
  )

  spec$path_param_info <- purrr::map(parsed_params, "path_info")
  spec$query_param_info <- purrr::map(parsed_params, "query_info")
  spec$body_param_info <- purrr::map(parsed_params, "body_info")

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
      request_type = spec$request_type,
      pagination_strategy = spec$pagination_strategy,
      pagination_metadata = spec$pagination_metadata,
      schema_stage = spec$schema_stage
    ),
    function(
      fn,
      endpoint,
      method,
      title,
      batch_limit,
      path_param_info,
      query_param_info,
      body_param_info,
      content_type,
      needs_resolver,
      body_schema_type,
      deprecated,
      response_schema_type,
      request_type,
      pagination_strategy,
      pagination_metadata,
      schema_stage
    ) {
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
        request_type = request_type %|NA|% "",
        pagination_strategy = pagination_strategy %|NA|% "none",
        pagination_metadata = pagination_metadata,
        schema_stage = schema_stage %|NA|% "public"
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
      log_lines <- c(
        log_lines,
        paste0("  ", skipped$method[i], " ", skipped$route[i], source_info, " - ", skipped$skip_reason[i])
      )
    }
    log_lines <- c(log_lines, "")
  }

  if (n_suspicious > 0) {
    log_lines <- c(log_lines, "SUSPICIOUS ENDPOINTS:", "")
    for (i in seq_len(n_suspicious)) {
      source_info <- if (!is.na(suspicious$source_file[i])) paste0(" [", suspicious$source_file[i], "]") else ""
      log_lines <- c(
        log_lines,
        paste0(
          "  ",
          suspicious$method[i],
          " ",
          suspicious$route[i],
          source_info,
          " - ",
          suspicious$suspicious_reason[i]
        )
      )
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
