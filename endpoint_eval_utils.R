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

# Helper: NULL-coalesce
`%||%` <- function(x, y) if (is.null(x)) y else x

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
  `%||%` <- function(x, y) if (is.null(x)) y else x

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
  `%||%` <- function(a, b) if (is.null(a)) b else a

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
  param_names <- function(params, where) {
    purrr::map_chr(
      purrr::keep(params, ~ identical(.x[["in"]], where)),
      ~ .x[["name"]] %||% ""
    ) -> nm
    nm[nzchar(nm)]
  }

  # Extract parameter metadata (examples and descriptions)
  param_metadata <- function(params, where) {
    relevant_params <- purrr::keep(params, ~ identical(.x[["in"]], where))
    if (length(relevant_params) == 0) return(list())

    metadata <- purrr::map(relevant_params, function(p) {
      list(
        name = p[["name"]] %||% "",
        example = p[["example"]] %||% NA,
        description = p[["description"]] %||% ""
      )
    })

    # Filter out params with no name
    metadata <- purrr::keep(metadata, ~ nzchar(.x$name))

    # Convert to named list for easier lookup
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

      # Combine all parameters (path parameters first, then query parameters)
      combined <- c(path_names, query_names)

      has_body <- !is.null(op$requestBody)
      operationId <- op$operationId %||% paste(method, route)
      summary <- op$summary %||% ""

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
        num_path_params = length(path_names),
        # NEW: Parameter metadata with examples and descriptions
        path_param_metadata = list(path_meta),
        query_param_metadata = list(query_meta),
        # NEW: Response content type(s)
        content_type = content_type
      )
    })
  })
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

  `%||%` <- function(a, b) if (is.null(a)) b else a
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
#' @return A list with: fn_signature, param_docs, params_code, params_call, has_params.
#' @export
parse_function_params <- function(params_str, strategy = c("extra_params", "options"), metadata = list()) {
  strategy <- match.arg(strategy)

  # Handle empty/NA params
  if (is.na(params_str) || params_str == "" || nchar(trimws(params_str)) == 0) {
    return(list(
      fn_signature = "query",
      param_docs = "",
      params_code = "",
      params_call = "",
      has_params = FALSE
    ))
  }

  # Split and clean parameter names
  param_vec <- strsplit(params_str, ",")[[1]]
  param_vec <- trimws(param_vec)
  param_vec <- param_vec[nzchar(param_vec)]

  if (length(param_vec) == 0) {
    return(list(
      fn_signature = "query",
      param_docs = "",
      params_code = "",
      params_call = "",
      has_params = FALSE
    ))
  }

  # Generate function signature: query, param1 = NULL, param2 = NULL, ...
  fn_signature <- paste0("query, ", paste(param_vec, "= NULL", collapse = ", "))

  # Generate @param documentation lines using metadata if available
  doc_lines <- character(0)
  for (p in param_vec) {
    if (!is.null(metadata[[p]]) && nzchar(metadata[[p]]$description)) {
      doc_lines <- c(doc_lines, paste0("#' @param ", p, " ", metadata[[p]]$description))
    } else {
      doc_lines <- c(doc_lines, paste0("#' @param ", p, " Optional parameter"))
    }
  }
  param_docs <- paste0(paste(doc_lines, collapse = "\n"), "\n")

  # Strategy-specific code generation
  if (strategy == "extra_params") {
    # For generic_request: pass parameters directly via ellipsis
    # httr2::req_url_query() automatically filters NULL values
    params_code <- ""
    params_call <- paste0(",\n    ", paste(param_vec, "=", param_vec, collapse = ",\n    "))

  } else if (strategy == "options") {
    # For generic_chemi_request: use options list
    params_code <- paste0(
      "  # Collect optional parameters\n",
      "  options <- list()\n",
      paste0("  if (!is.null(", param_vec, ")) options$", param_vec, " <- ", param_vec, "\n", collapse = ""),
      "\n  "
    )

    params_call <- ",\n    options = options"
  }

  list(
    fn_signature = fn_signature,
    param_docs = param_docs,
    params_code = params_code,
    params_call = params_call,
    has_params = TRUE
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

  # Handle empty path params
  if (is.na(path_params_str) || path_params_str == "" || nchar(trimws(path_params_str)) == 0) {
    return(list(
      fn_signature = "query",
      path_params_call = "",
      has_path_params = FALSE,
      param_docs = "",
      primary_param = "query",
      primary_example = NA
    ))
  }

  # Split into individual parameters
  param_vec <- strsplit(path_params_str, ",")[[1]]
  param_vec <- trimws(param_vec)
  param_vec <- param_vec[nzchar(param_vec)]

  if (length(param_vec) == 0) {
    return(list(
      fn_signature = "query",
      path_params_call = "",
      has_path_params = FALSE,
      param_docs = "",
      primary_param = "query",
      primary_example = NA
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

  # Extract primary parameter example
  primary_example <- NA
  if (!is.null(metadata[[primary_param]]) && !is.null(metadata[[primary_param]]$example)) {
    primary_example <- metadata[[primary_param]]$example
  }

  # Build param_docs from metadata
  param_docs <- ""
  all_params <- c(primary_param, additional_params)
  doc_lines <- character(0)
  for (p in all_params) {
    if (!is.null(metadata[[p]]) && nzchar(metadata[[p]]$description)) {
      doc_lines <- c(doc_lines, paste0("#' @param ", p, " ", metadata[[p]]$description))
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
    if (strategy == "extra_params") {
      # For generic_request
      path_params_call <- paste0(
        ",\n    path_params = c(",
        paste(additional_params, "=", additional_params, collapse = ", "),
        ")"
      )
    } else {
      # For generic_chemi_request (doesn't support path_params yet, but keeping consistent)
      path_params_call <- paste0(
        ",\n    path_params = c(",
        paste(additional_params, "=", additional_params, collapse = ", "),
        ")"
      )
    }
  } else {
    path_params_call <- ""
  }

  list(
    fn_signature = fn_signature,
    path_params_call = path_params_call,
    has_path_params = length(additional_params) > 0,
    param_docs = param_docs,
    primary_param = primary_param,
    primary_example = primary_example
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
#' @param content_type Response content type(s) from OpenAPI spec (e.g., "application/json", "image/png").
#' @param config Configuration list specifying template behavior.
#' @return Character string containing complete function definition.
#' @export
build_function_stub <- function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, content_type, config) {
  if (!requireNamespace("glue", quietly = TRUE)) stop("Package 'glue' is required.")

  # Format batch_limit for code
  batch_limit_code <- if (is.null(batch_limit) || is.na(batch_limit)) "NULL" else as.character(batch_limit)

  # Determine response type and return documentation based on content_type
  content_type <- content_type %||% ""
  is_image <- grepl("image/", content_type, fixed = TRUE)
  is_text <- grepl("text/plain", content_type, fixed = TRUE)
  is_json <- content_type == "" || grepl("application/json", content_type, fixed = TRUE)

  # Set return type documentation
  if (is_image) {
    return_doc <- "Returns image data (raw bytes or magick image object)"
    content_type_call <- paste0(',\n    content_type = "', content_type, '"')
  } else if (is_text) {
    return_doc <- "Returns a character string"
    content_type_call <- ',\n    content_type = "text/plain"'
  } else {
    return_doc <- "Returns a tibble with results"
    content_type_call <- ""
  }

  # Extract config values
  wrapper_fn <- config$wrapper_function
  example_query <- config$example_query %||% "DTXSID7020182"
  lifecycle_badge <- config$lifecycle_badge %||% "experimental"

  # Determine the primary parameter name from path_param_info
  primary_param <- strsplit(path_param_info$fn_signature, ",")[[1]][1]
  primary_param <- trimws(primary_param)

  # Build combined function signature
  # Start with path parameters (which includes the primary param)
  fn_signature <- path_param_info$fn_signature

  # Add query parameters if they exist
  if (isTRUE(query_param_info$has_params)) {
    # Remove "query" from query_param_info signature since path params already provide parameters
    query_sig <- query_param_info$fn_signature
    # Remove leading "query, " if present
    query_sig <- sub("^query,\\s*", "", query_sig)
    if (nzchar(query_sig)) {
      fn_signature <- paste0(fn_signature, ", ", query_sig)
    }
  }

  # Build combined parameter calls
  combined_calls <- ""
  if (isTRUE(path_param_info$has_path_params)) {
    combined_calls <- paste0(combined_calls, path_param_info$path_params_call)
  }
  if (isTRUE(query_param_info$has_params)) {
    combined_calls <- paste0(combined_calls, query_param_info$params_call)
  }

  # Determine example value to use in documentation
  # Prefer actual example from schema, fall back to config default
  example_value <- example_query  # default from config
  if (!is.null(path_param_info$primary_example) && !is.na(path_param_info$primary_example)) {
    # Format example value appropriately (add quotes for strings)
    if (is.character(path_param_info$primary_example)) {
      example_value <- path_param_info$primary_example
    } else {
      example_value <- as.character(path_param_info$primary_example)
    }
  }

  # Build roxygen header with parameter descriptions from metadata
  roxygen_header <- glue::glue('
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("{lifecycle_badge}")`
#\'
{path_param_info$param_docs}{query_param_info$param_docs}#\' @return {return_doc}
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}({primary_param} = "{example_value}")
#\' }}')

  # Build function body based on whether we have additional params
  has_additional_params <- isTRUE(path_param_info$has_path_params) || isTRUE(query_param_info$has_params)

  if (has_additional_params) {
    # Strategy-specific body construction
    if (wrapper_fn == "generic_request") {
      # CT style: pass parameters directly via ellipsis
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
  generic_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code}{content_type_call}{combined_calls}
  )
}}')
    } else if (wrapper_fn == "generic_chemi_request") {
      # Chemi style: use options list
      fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
{query_param_info$params_code}generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}"{combined_calls}
  )
}}')
    } else {
      stop("Unknown wrapper function: ", wrapper_fn)
    }
  } else {
    # No extra params: simple call
    if (wrapper_fn == "generic_request") {
      fn_body <- glue::glue('
{fn} <- function({primary_param}) {{
  generic_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code}{content_type_call}
  )
}}')
    } else if (wrapper_fn == "generic_chemi_request") {
      fn_body <- glue::glue('
{fn} <- function({primary_param}) {{
  generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    server = "chemi_burl",
    auth = FALSE
  )
}}')
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

  # Process spec: add derived columns and parse parameters
  spec %>%
    dplyr::mutate(
      fn       = purrr::map_chr(file, fn_transform),
      endpoint = route,
      title    = dplyr::coalesce(summary, "API wrapper")
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      # Parse path parameters (primary param + additional path params)
      # Note: In rowwise context, list columns are already unwrapped, so access directly
      path_param_info = list(parse_path_parameters(
        if ("path_params" %in% names(.)) path_params else "",
        strategy = param_strategy,
        metadata = if ("path_param_metadata" %in% names(.) && is.list(path_param_metadata)) path_param_metadata else list()
      )),
      # Parse query parameters (optional query string params)
      query_param_info = list(parse_function_params(
        if ("query_params" %in% names(.)) query_params else "",
        strategy = param_strategy,
        metadata = if ("query_param_metadata" %in% names(.) && is.list(query_param_metadata)) query_param_metadata else list()
      ))
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      text = purrr::pmap_chr(
        list(
          fn = fn,
          endpoint = endpoint,
          method = method,
          title = title,
          batch_limit = batch_limit,
          path_param_info = path_param_info,
          query_param_info = query_param_info,
          content_type = if ("content_type" %in% names(.)) content_type else ""
        ),
        function(fn, endpoint, method, title, batch_limit, path_param_info, query_param_info, content_type) {
          build_function_stub(
            fn = fn,
            endpoint = endpoint,
            method = method,
            title = title,
            batch_limit = batch_limit,
            path_param_info = path_param_info,
            query_param_info = query_param_info,
            content_type = content_type,
            config = config
          )
        }
      )
    )
}
