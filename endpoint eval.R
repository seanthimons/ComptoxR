# Install/load required packages and define helper utilities for endpoint analysis

library(jsonlite)
library(tidyverse)

# Helper: NULL-coalesce
`%||%` <- function(x, y) if (is.null(x)) y else x

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

# Examples
# endpoints <- c(
#   "/hazard/toxval/search/by-dtxsid/{dtxsid}",
#   "/hazard/iris/{id}/details",
#   "hazard/hawc/study/{study_id}/metrics/"
# )

#strip_curly_params(endpoints, leading_slash = 'remove')
# [1] "/hazard/toxval/search/by-dtxsid/"
# [2] "/hazard/iris/details"
# [3] "/hazard/hawc/study/metrics/"

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

  # Include variants without a leading slash to catch code that stores paths “bare”
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

      # Combine all parameters first
      combined <- c(path_names, query_names)

      # For GET requests, discard the first element from the combined list
      # (typically the primary identifier that's already in the endpoint path)
      if (identical(toupper(method), "GET") && length(combined) > 0) {
        combined <- combined[-1]
      }

      has_body <- !is.null(op$requestBody)
      operationId <- op$operationId %||% paste(method, route)
      summary <- op$summary %||% ""

      fn <- if (name_strategy == "operationId") sanitize_name(operationId) else sanitize_name(method_path_name(route, method))

      tibble::tibble(
        route = route,
        method = toupper(method),
        summary = summary,
        has_body = has_body,
        params = if (length(combined) > 0) paste(combined, collapse = ",") else ""
      )
    })
  })
}

#' Template for generating a standard API wrapper function stub
#'
#' This string is used with `glue` to create R source files for endpoint wrappers.
#' Placeholders include `{title}`, `{fn}`, `{example_query}`, `{endpoint}`, `{method}`, `{batch_limit}`,
#' `{fn_signature}`, `{param_docs}`, and `{extra_params_code}`.
#' @format A character string containing a roxygen template.
#' @usage Not intended for direct use; passed to `render_stubs`.
default_stub_template <- '
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("experimental")`
#\'
#\' @param query A single DTXSID (in quotes) or a list to be queried
{param_docs}
#\' @return Returns a tibble with results
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = "{example_query}")
#\' }}
{fn} <- function({fn_signature}) {{
{extra_params_code}  generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
		batch_limit = {batch_limit}{extra_params_call}
  )
}}


'

#' Render R function stubs from an endpoint specification
#'
#' Takes a tibble of endpoint specifications and generates R source code strings using a template.
#' @param spec Data frame produced by `openapi_to_spec` containing endpoint metadata (must include `params` column).
#' @param template Character string template for generating the stub; defaults to `default_stub_template`.
#' @param example_query Example query value used in the @examples section of generated docs.
#' @param title_fallback Fallback title for functions lacking a summary.
#' @param fn_transform Function to derive the R function name from the source file name; defaults to sanitising the file name.
#' @return The original `spec` tibble with additional columns `fn`, `endpoint`, `title`, and `text` (the rendered R code).
#' @export
render_stubs <- function(spec,
                         template = default_stub_template,
                         example_query = "DTXSID7020182",
                         title_fallback = "API wrapper",
                         fn_transform = function(x) {
                           # default: derive fn from file name and make it R-safe
                           nm <- tools::file_path_sans_ext(basename(x))
                           nm <- gsub("-", "_", nm, fixed = TRUE)
                           nm
                         }) {
  stopifnot(is.data.frame(spec))
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.")
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")
  if (!requireNamespace("glue",  quietly = TRUE)) stop("Package 'glue' is required.")

  # Helper function to parse params and generate function signature components
  parse_params <- function(params_str) {
    if (is.na(params_str) || params_str == "" || nchar(trimws(params_str)) == 0) {
      return(list(
        fn_signature = "query",
        param_docs = "",
        extra_params_code = "",
        extra_params_call = ""
      ))
    }

    # Split comma-separated params
    param_vec <- strsplit(params_str, ",")[[1]]
    param_vec <- trimws(param_vec)
    param_vec <- param_vec[nzchar(param_vec)]

    if (length(param_vec) == 0) {
      return(list(
        fn_signature = "query",
        param_docs = "",
        extra_params_code = "",
        extra_params_call = ""
      ))
    }

    # Generate function signature: query, param1 = NULL, param2 = NULL, ...
    fn_signature <- paste0("query, ", paste(param_vec, "= NULL", collapse = ", "))

    # Generate @param documentation lines
    param_docs <- paste0("#' @param ", param_vec, " Optional parameter\n", collapse = "")

    # Generate code to collect non-NULL params into a list for do.call
    extra_params_code <- paste0(
      "  # Collect optional parameters\n",
      "  extra_params <- list()\n",
      paste0("  if (!is.null(", param_vec, ")) extra_params$", param_vec, " <- ", param_vec, "\n", collapse = ""),
      "\n  "
    )

    # Modify the call to use do.call with extra_params
    extra_params_call <- paste0(
      "\n\n  do.call(\n",
      "    generic_request,\n",
      "    c(\n",
      "      list(\n",
      "        query = query,\n",
      "        endpoint = \"{endpoint}\",\n",
      "        method = \"{method}\",\n",
      "        batch_limit = \"{batch_limit}\"\n",
      "      ),\n",
      "      extra_params\n",
      "    )\n",
      "  )"
    )

    list(
      fn_signature = fn_signature,
      param_docs = param_docs,
      extra_params_code = extra_params_code,
      extra_params_call = extra_params_call,
      has_params = TRUE
    )
  }

  spec %>%
    dplyr::mutate(
      fn       = purrr::map_chr(file, fn_transform),
      endpoint = route,
      title    = dplyr::coalesce(summary, title_fallback)
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      param_info = list(parse_params(if ("params" %in% names(.)) params else ""))
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
          param_info = param_info
        ),
        function(fn, endpoint, method, title, batch_limit, param_info) {
          # Format batch_limit for code generation (handle NULL properly)
          batch_limit_code <- if (is.null(batch_limit)) "NULL" else as.character(batch_limit)

          # If there are no extra params, use simple template; otherwise use do.call approach
          if (isTRUE(param_info$has_params)) {
            # Build the full function with do.call
            stub_text <- glue::glue('
#\' {title}
#\'
#\' @description
#\' `r lifecycle::badge("experimental")`
#\'
#\' @param query A single DTXSID (in quotes) or a list to be queried
{param_info$param_docs}
#\' @return Returns a tibble with results
#\' @export
#\'
#\' @examples
#\' \\dontrun{{
#\' {fn}(query = "{example_query}")
#\' }}
{fn} <- function({param_info$fn_signature}) {{
{param_info$extra_params_code}do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "{endpoint}",
        method = "{method}",
		batch_limit = {batch_limit_code}
      ),
      extra_params
    )
  )
}}
')
          } else {
            # Use original simple template
            stub_text <- glue::glue(template,
              fn            = fn,
              endpoint      = endpoint,
              method        = method,
              title         = title,
              example_query = example_query,
              batch_limit   = batch_limit_code,
              fn_signature  = "query",
              param_docs    = "",
              extra_params_code = "",
              extra_params_call = ""
            )
          }
          return(stub_text)
        }
      )
    ) %>%
    dplyr::select(-param_info)  # Remove temporary column
}

#' Create files and write text content from a tibble spec
#'
#' @param data A tibble/data.frame describing files and content
#' @param path_col Column name containing file paths (character)
#' @param text_col Column name containing text (character scalar or list-column of character vectors)
#' @param base_dir Base directory to prefix to relative paths
#' @param overwrite If TRUE, overwrite existing files (ignored if append = TRUE)
#' @param append If TRUE, append to existing files
#' @param quiet If FALSE, emit progress messages
#'
#' @return A tibble with one row per attempted write, describing what happened
#' Write generated files to disk based on a specification tibble
#'
#' Creates or updates files according to a data frame describing file paths and their content.
#' @param data Data frame or tibble with at least columns for file paths and text.
#' @param path_col Name of the column containing file paths; default "file".
#' @param text_col Name of the column containing the file content; default "text".
#' @param base_dir Base directory to prepend to relative paths.
#' @param overwrite If TRUE, existing files will be overwritten; otherwise they are skipped.
#' @param append If TRUE, text is appended to existing files.
#' @param quiet If FALSE, progress messages are printed.
#' @return A tibble summarising each write operation (path, action, etc.).
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
  purrr::pmap_dfr(jobs, write_one)
}

# Load the OpenAPI schema files and generate endpoint specifications

# Find all ctx production schema files
ctx_schema_files <- list.files(
  path = here::here('schema'),
  pattern = "^ctx_.*_prod\\.json$",
  full.names = FALSE
)

endpoints <- map(
  ctx_schema_files,
  ~ {
    openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
    dat <- openapi_to_spec(openapi)
  },
  .progress = TRUE
) %>% 
  list_rbind() %>% 
  mutate(
    route = strip_curly_params(route, leading_slash = 'remove'),
		domain = route %>% 
			stringr::str_extract(., "^[^/]+"),
    file = route %>%
  # 1) Remove tokens with optional left separator, only when delimited on the right
  str_remove_all(
    regex("(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")
  ) %>%
	str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>% 
  # 2) Collapse any remaining separators to spaces
	str_replace_all("[/]+", " ") %>%
  # 3) Trim and normalize whitespace
  str_squish() %>% 
	# 4)
	str_replace_all(., pattern = "\\s", replacement = "_"),
	file = paste0("ct_", domain,"_", file, ".R"),
	batch_limit = case_when(
		method == 'GET' ~ 1,
		.default = NULL
	)
) %>% 
	arrange(
		forcats::fct_inorder(domain), 
		route, 
		factor(method, levels = c('POST', 'GET'))
	) %>% 
	distinct(route, .keep_all = TRUE)

res <- find_endpoint_usages_base(endpoints$route, pkg_dir = here::here("R"))

endpoints_to_build <- endpoints %>% 
	filter(route %in% {res$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

spec_with_text <- render_stubs(
  endpoints_to_build,
  example_query = "DTXSID7020182"
)

# ! BUILD ----
scaffold_files(spec_with_text, base_dir = "R", overwrite = TRUE, append = TRUE)
