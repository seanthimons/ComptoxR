# ==============================================================================
# Parameter Parsing
# ==============================================================================

#' Helper function to build parameter default value based on schema metadata
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
    
    # For primary parameters (first query param when no path params exist),
    # only mark as required if the schema says so AND it has no default value.
    # This ensures optional params with default values keep their defaults.
    if (!is.null(primary_param) && p_san == primary_param) {
      # Only mark as required if the schema explicitly says required=true
      # and there's no default value provided
      has_default <- is.list(entry) && !is.null(entry$default) && 
                     !(length(entry$default) == 1 && is.na(entry$default))
      schema_required <- is.list(entry) && isTRUE(entry$required)
      
      if (schema_required && !has_default) {
        is_required <- TRUE
      }
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
#' @param body_schema_full Optional; full body schema structure for enhanced documentation.
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
parse_path_parameters <- function(path_params_str, strategy = c("extra_params", "options"), metadata = list(), body_schema_full = NULL) {
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
      param_type <- entry$type %||% NA
      param_format <- entry$format %||% NA

      # Start with description or generic fallback
      if (nzchar(desc)) {
        param_desc <- desc
      } else if (p == primary_param) {
        param_desc <- "Primary query parameter"
      } else {
        param_desc <- "Optional parameter"
      }

      # Add type information if available
      if (!is.na(param_type) && nzchar(param_type)) {
        param_desc <- paste0(param_desc, ". Type: ", param_type)
        if (!is.na(param_format) && nzchar(param_format)) {
          param_desc <- paste0(param_desc, " (", param_format, ")")
        }
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
