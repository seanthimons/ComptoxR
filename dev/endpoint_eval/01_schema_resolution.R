# Compatibility entry point; implementation is installed development tooling.
wrapmaint::bind_tools("schema", environment())
formals(preprocess_schema)$exclude_endpoints <- quote(ENDPOINT_PATTERNS_TO_EXCLUDE)

# Client schema stage selection remains local.
select_schema_files <- function(
  pattern,
  exclude_pattern = NULL,
  stage_priority = NULL,
  schema_dir = NULL
) {
  if (is.null(schema_dir)) {
    schema_dir <- here::here("schema")
  }

  # List matching files
  files <- list.files(path = schema_dir, pattern = pattern, full.names = FALSE)

  if (length(files) == 0) {
    return(character(0))
  }

  # Apply exclusion filter
  if (!is.null(exclude_pattern) && nzchar(exclude_pattern)) {
    files <- files[!grepl(exclude_pattern, files, ignore.case = TRUE)]
  }

  if (length(files) == 0) {
    return(character(0))
  }

  # Stage-based selection (if stage_priority provided)
  # STAGE PRIORITY LOGIC:
  # For chemi microservices, each domain (amos, rdkit, mordred, etc.) may have
  # multiple schemas: chemi-{domain}-prod.json, chemi-{domain}-staging.json, chemi-{domain}-dev.json
  # We select the BEST available stage per domain using the priority order.
  # Example: If prod exists, use it. If only staging exists, use that.
  if (!is.null(stage_priority)) {
    schema_meta <- tibble::tibble(file = files) %>%
      tidyr::separate_wider_delim(
        cols = file,
        delim = "-",
        names = c("origin", "domain", "stage"),
        cols_remove = FALSE,
        too_few = "align_start", # Handle files with < 3 hyphen-delimited parts
        too_many = "merge" # Handle files with > 3 hyphen-delimited parts
      ) %>%
      dplyr::filter(!is.na(stage)) %>% # Drop files without stage component
      dplyr::mutate(
        stage = stringr::str_remove(stage, "\\.json$"),
        stage = factor(stage, levels = stage_priority) # Factor ordering = priority
      )

    # Files that couldn't be parsed (no stage) are included as-is
    unparsed <- setdiff(files, schema_meta$file)

    # Group by domain, sort by stage priority, take first (highest priority)
    files <- schema_meta %>%
      dplyr::group_by(domain) %>%
      dplyr::arrange(stage, .by_group = TRUE) %>%
      dplyr::slice(1) %>% # Take highest priority stage per domain
      dplyr::ungroup() %>%
      dplyr::pull(file)

    files <- c(files, unparsed)
  }

  files
}
