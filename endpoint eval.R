# Install/load

library(jsonlite)
library(purrr)
library(dplyr)
library(tibble)

# Load the OpenAPI
openapi <- jsonlite::fromJSON(here::here('schema', "ctx_hazard_prod.json"), simplifyVector = FALSE)

# Helper for NULL-coalesce
`%||%` <- function(x, y) if (is.null(x)) y else x

# Endpoints table: one row per path-method
paths <- openapi$paths
endpoints_df <- imap(paths, function(path_obj, path) {
  imap(path_obj, function(op, method) {
    tibble(
      path = path,
      method = toupper(method),
      summary = op$summary %||% NA_character_,
      operationId = op$operationId %||% NA_character_,
      tags = paste(op$tags %||% character(), collapse = ", ")
    )
  }) %>% list_rbind()
}) %>% list_rbind()

# Example rows include GET /hazard/toxval/search/by-dtxsid/{dtxsid} and GET /hazard/adme-ivive/search/by-dtxsid/{dtxsid}

# Parameters table: one row per parameter on each operation
params_df <- imap_dfr(paths, function(path_obj, path) {
  imap_dfr(path_obj, function(op, method) {
    pars <- op$parameters %||% list()
    if (!length(pars)) return(tibble())
    map_dfr(pars, function(pr) {
      tibble(
        path = path,
        method = toupper(method),
        name = pr$name %||% NA_character_,
        location = pr$`in` %||% NA_character_,
        required = isTRUE(pr$required),
        type = pr$schema$type %||% NA_character_,
        format = pr$schema$format %||% NA_character_,
        example = if (!is.null(pr$example)) as.character(pr$example) else NA_character_,
        description = pr$description %||% NA_character_
      )
    })
  })
})
# You’ll see entries like dtxsid (in=path, required=TRUE, type=string) and projection (in=query, type=string)

# Component schema fields (properties) as a table
schema_fields <- function(schema_name) {
  sch <- openapi$components$schemas[[schema_name]]
  props <- sch$properties %||% list()
  imap_dfr(props, function(prop, field_name) {
    tibble(
      schema = schema_name,
      field = field_name,
      type = prop$type %||% NA_character_,
      format = prop$format %||% NA_character_,
      description = prop$description %||% NA_character_,
      maxLength = prop$maxLength %||% NA_real_,
      minLength = prop$minLength %||% NA_real_
    )
  })
}

# Example: fields for the ToxValDb component schema
toxval_fields <- schema_fields("ToxValDb")

# All component schemas’ fields
all_fields <- map_dfr(names(openapi$components$schemas), schema_fields)

# Optional: view or write out
print(endpoints_df, n = 20)
print(params_df, n = 20)
print(toxval_fields, n = 20)

# write.csv(endpoints_df, "endpoints.csv", row.names = FALSE)
# write.csv(params_df, "parameters.csv", row.names = FALSE)
# write.csv(all_fields, "component_fields.csv", row.names = FALSE)

search_package <- function(pattern, pkg_dir = ".", regex = FALSE, ignore_case = TRUE) {
  files <- list.files(pkg_dir, pattern = "\\.(R|Rmd|Rnw|qmd|Rd|md)$",
                      recursive = TRUE, full.names = TRUE)
  scan_file <- function(f, pat) {
    lines <- tryCatch(readLines(f, warn = FALSE), error = function(e) character())
    hits <- which(grepl(pat, lines, perl = regex, ignore.case = ignore_case))
    if (!length(hits)) return(NULL)
    data.frame(
      file = f,
      line = hits,
      text = substr(lines[hits], 1, 200),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, lapply(files, scan_file, pat = pattern)) %||% 
    data.frame(file=character(), line=integer(), text=character())
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Examples:
# Literal search
search_package("/hazard/toxval")

# Regex search (matches path segments even if constructed with paste/glue)
search_package("hazard\\s*/\\s*toxval", regex = TRUE)

# Find endpoint usages in an R package directory.
# - endpoints: character vector of endpoint paths (e.g., "/hazard/toxval/{dtxsid}")
# - Returns a list with:
#   $hits:   one row per file/line match
#   $summary: one row per endpoint (including those with zero matches)
find_endpoint_usages <- function(endpoints,
                                 pkg_dir = ".",
                                 ignore_case = TRUE,
                                 files_regex = "\\.(R|Rmd|qmd|Rnw|Rd|md)$",
                                 include_no_leading_slash = TRUE) {
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Build regex from endpoints: escape specials, support {param} tokens, allow optional leading slash
  escape_regex <- function(x) gsub("([][()+*?.\\^$|])", "\\\\\\1", x) # don't escape {} yet
  to_regex <- function(p) {
    # Temporarily replace {param} with a sentinel, escape, then re-expand
    sentinel <- "<<PARAM_TOKEN>>"
    p <- gsub("\\{[^}]+\\}", sentinel, p)
    p <- escape_regex(p)
    p <- gsub("\\{", "\\\\{", p, fixed = TRUE) # just in case
    p <- gsub("\\}", "\\\\}", p, fixed = TRUE)
    # Params: match a single path segment (no slash or quotes/parens/space)
    p <- gsub(sentinel, "[^/\"'()\\s]+", p, fixed = TRUE)
    p
  }

  # Candidate patterns per endpoint (with and without leading slash)
  pattern_list <- lapply(endpoints, function(ep) {
    base <- to_regex(ep)
    pats <- c(base, if (include_no_leading_slash) sub("^/", "", base) else character())
    unique(pats)
  })
  names(pattern_list) <- endpoints

  # Files to scan
  files <- list.files(pkg_dir, pattern = files_regex, recursive = TRUE, full.names = TRUE)

  # Scan helper
  scan_file_pattern <- function(file, pat) {
    lines <- tryCatch(readLines(file, warn = FALSE), error = function(e) character())
    if (!length(lines)) return(NULL)
    hits <- grep(pat, lines, perl = TRUE, ignore.case = ignore_case)
    if (!length(hits)) return(NULL)
    data.frame(
      file = file,
      line = hits,
      text = substr(lines[hits], 1, 240),
      stringsAsFactors = FALSE
    )
  }

  # Collect hits
  hits_list <- list()
  for (ep in endpoints) {
    pats <- pattern_list[[ep]]
    for (pat in pats) {
      for (f in files) {
        h <- scan_file_pattern(f, pat)
        if (!is.null(h)) {
          h$endpoint <- ep
          h$regex <- pat
          hits_list[[length(hits_list) + 1]] <- h
        }
      }
    }
  }

  hits <- if (length(hits_list)) {
    do.call(rbind, hits_list)
  } else {
    # Empty hits data frame with consistent columns
    data.frame(file = character(), line = integer(), text = character(),
               endpoint = character(), regex = character(), stringsAsFactors = FALSE)
  }

  # Build summary: one row per endpoint (include endpoints with zero matches)
  summarize_ep <- function(ep_df) {
    ep_df <- ep_df[order(ep_df$file, ep_df$line), , drop = FALSE]
    first <- ep_df[1, , drop = FALSE]
    data.frame(
      endpoint = first$endpoint,
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
      endpoint = character(), n_hits = integer(), n_files = integer(),
      first_file = character(), first_line = integer(), first_snippet = character(),
      stringsAsFactors = FALSE
    )
  }

  # Add zero rows for endpoints with no hits
  missing_eps <- setdiff(endpoints, summary_found$endpoint)
  if (length(missing_eps)) {
    summary_missing <- data.frame(
      endpoint = missing_eps,
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

  # Keep the original order of your endpoints in the summary
  summary <- summary[match(endpoints, summary$endpoint), , drop = FALSE]

  list(hits = hits, summary = summary)
}

res <- find_endpoint_usages(endpoints, pkg_dir = ".")
res$summary