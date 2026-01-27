# Function Metadata Extraction for ComptoxR
#
# This helper extracts metadata from function source files to generate
# appropriate tests based on actual function signatures and return types.

#' Extract function metadata from R source file
#'
#' @param function_file Path to R source file
#' @return List with function metadata
extract_function_metadata <- function(function_file) {

  if (!file.exists(function_file)) {
    stop("File not found: ", function_file)
  }

  # Read file content
  content <- readLines(function_file, warn = FALSE)
  full_text <- paste(content, collapse = "\n")

  # Extract function name from file path (R/ct_hazard.R -> ct_hazard)
  fn_name <- gsub("\\.R$", "", basename(function_file))

  # Extract roxygen documentation
  roxygen_start <- grep("^#'", content)
  roxygen_lines <- content[roxygen_start]

  # Extract @return documentation
  return_doc <- extract_return_type(roxygen_lines)

  # Extract @param documentation
  params <- extract_parameters(roxygen_lines)

  # Extract @examples
  examples <- extract_examples(roxygen_lines, content)

  # Parse function definition to get actual parameters
  fn_def <- extract_function_definition(content, fn_name)

  # Determine if function uses generic_request and get details
  generic_info <- extract_generic_request_info(content)

  list(
    name = fn_name,
    file = function_file,
    return_type = return_doc,
    parameters = params,
    function_def = fn_def,
    examples = examples,
    generic_request = generic_info
  )
}

#' Extract return type from roxygen comments
extract_return_type <- function(roxygen_lines) {
  return_line <- roxygen_lines[grepl("^#'\\s*@return", roxygen_lines)]

  if (length(return_line) == 0) {
    return(list(type = "unknown", description = ""))
  }

  # Parse return description
  desc <- gsub("^#'\\s*@return\\s*", "", return_line[1])

  # Determine type from description
  type <- "unknown"
  if (grepl("tibble|tbl_df|data\\.frame", desc, ignore.case = TRUE)) {
    type <- "tibble"
  } else if (grepl("character vector", desc, ignore.case = TRUE)) {
    type <- "character"
  } else if (grepl("list", desc, ignore.case = TRUE)) {
    type <- "list"
  } else if (grepl("image|raw|magick", desc, ignore.case = TRUE)) {
    type <- "image"
  } else if (grepl("logical|boolean", desc, ignore.case = TRUE)) {
    type <- "logical"
  } else if (grepl("numeric|integer", desc, ignore.case = TRUE)) {
    type <- "numeric"
  }

  list(type = type, description = desc)
}

#' Extract parameter information from roxygen comments
extract_parameters <- function(roxygen_lines) {
  param_lines <- roxygen_lines[grepl("^#'\\s*@param", roxygen_lines)]

  if (length(param_lines) == 0) {
    return(list())
  }

  params <- list()
  for (line in param_lines) {
    # Extract param name and description
    clean <- gsub("^#'\\s*@param\\s+", "", line)
    parts <- strsplit(clean, "\\s+", 2)[[1]]

    if (length(parts) >= 1) {
      param_name <- parts[1]
      param_desc <- if (length(parts) == 2) parts[2] else ""

      # Determine if required based on description
      is_required <- !grepl("optional|default", param_desc, ignore.case = TRUE)

      params[[param_name]] <- list(
        name = param_name,
        description = param_desc,
        required = is_required
      )
    }
  }

  params
}

#' Extract examples from roxygen comments
extract_examples <- function(roxygen_lines, full_content) {
  # Find @examples section
  example_start <- which(grepl("^#'\\s*@examples", roxygen_lines))

  if (length(example_start) == 0) {
    return(character(0))
  }

  # Find where examples section ends (next @tag or end of roxygen)
  roxygen_idx <- which(grepl("^#'", full_content))
  example_idx <- roxygen_idx[example_start]

  examples <- character()
  for (i in (example_idx + 1):length(full_content)) {
    line <- full_content[i]

    # Stop if we hit non-roxygen line or another @tag
    if (!grepl("^#'", line) || grepl("^#'\\s*@", line)) {
      break
    }

    # Extract example code (skip \\dontrun markers)
    clean <- gsub("^#'\\s*", "", line)
    if (!grepl("\\\\dontrun|\\{|\\}", clean)) {
      examples <- c(examples, clean)
    }
  }

  # Remove empty lines and trim
  examples <- examples[nzchar(trimws(examples))]
  examples
}

#' Extract function definition and parameters
extract_function_definition <- function(content, fn_name) {
  # Find function definition line
  fn_pattern <- paste0("^", fn_name, "\\s*<-\\s*function\\s*\\(")
  fn_start <- grep(fn_pattern, content)

  if (length(fn_start) == 0) {
    return(list(params = list(), has_dots = FALSE))
  }

  # Extract function signature (may span multiple lines)
  sig_lines <- character()
  paren_count <- 0
  found_opening <- FALSE

  for (i in fn_start[1]:length(content)) {
    line <- content[i]
    sig_lines <- c(sig_lines, line)

    # Count parentheses
    opens <- length(gregexpr("\\(", line, fixed = TRUE)[[1]])
    closes <- length(gregexpr("\\)", line, fixed = TRUE)[[1]])

    if (grepl("\\(", line)) found_opening <- TRUE
    paren_count <- paren_count + opens - closes

    # Stop when we've closed all parentheses
    if (found_opening && paren_count == 0) break
  }

  # Parse signature
  sig <- paste(sig_lines, collapse = " ")

  # Extract parameters
  param_str <- sub(".*?\\((.*)\\).*", "\\1", sig)

  # Check for ...
  has_dots <- grepl("\\.\\.\\.", param_str)

  # Parse individual parameters
  if (nzchar(trimws(param_str))) {
    # Simple split (doesn't handle complex defaults perfectly, but good enough)
    param_parts <- strsplit(param_str, ",\\s*")[[1]]

    params <- lapply(param_parts, function(p) {
      p <- trimws(p)

      # Check if has default
      if (grepl("=", p)) {
        parts <- strsplit(p, "\\s*=\\s*", 2)[[1]]
        list(name = parts[1], default = parts[2], required = FALSE)
      } else {
        list(name = p, default = NULL, required = !grepl("\\.\\.\\.", p))
      }
    })

    names(params) <- sapply(params, function(p) p$name)
  } else {
    params <- list()
  }

  list(params = params, has_dots = has_dots)
}

#' Extract generic_request usage information
extract_generic_request_info <- function(content) {
  # Find generic_request call
  gr_lines <- grep("generic_request\\s*\\(", content, value = TRUE)

  if (length(gr_lines) == 0) {
    return(NULL)
  }

  # Combine all generic_request lines
  full_call <- paste(gr_lines, collapse = " ")

  # Extract key parameters
  info <- list(
    uses_generic_request = TRUE,
    endpoint = extract_param_value(full_call, "endpoint"),
    method = extract_param_value(full_call, "method"),
    tidy = extract_param_value(full_call, "tidy"),
    server = extract_param_value(full_call, "server"),
    batch_limit = extract_param_value(full_call, "batch_limit")
  )

  info
}

#' Helper to extract parameter value from function call
extract_param_value <- function(call_text, param_name) {
  pattern <- paste0(param_name, "\\s*=\\s*([^,)]+)")
  match <- regexec(pattern, call_text)

  if (match[[1]][1] == -1) {
    return(NULL)
  }

  value <- regmatches(call_text, match)[[1]][2]
  trimws(gsub("\"", "", value))
}

#' Get all ct_ and chemi_ function files
get_all_function_files <- function(r_dir = "R") {
  all_files <- list.files(r_dir, pattern = "^(ct_|chemi_).*\\.R$", full.names = TRUE)

  # Exclude configuration functions
  exclude_patterns <- c("ct_api_key", "ct_server", "chemi_server")

  all_files[!grepl(paste(exclude_patterns, collapse = "|"), all_files)]
}

#' Extract metadata for all functions
extract_all_metadata <- function(r_dir = "R") {
  files <- get_all_function_files(r_dir)

  metadata <- list()
  for (file in files) {
    tryCatch({
      fn_name <- gsub("\\.R$", "", basename(file))
      metadata[[fn_name]] <- extract_function_metadata(file)
    }, error = function(e) {
      message("Error processing ", file, ": ", conditionMessage(e))
    })
  }

  metadata
}
