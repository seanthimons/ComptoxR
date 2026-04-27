# ECOTOX lifestage resolution + patch helpers ----------------------------

if (!exists(".ComptoxREnv", mode = "environment", inherits = TRUE)) {
  .ComptoxREnv <- new.env(parent = emptyenv())
}

#' @keywords internal
.eco_lifestage_cache_schema <- function() {
  tibble::tibble(
    org_lifestage = character(),
    source_provider = character(),
    source_ontology = character(),
    source_term_id = character(),
    source_term_label = character(),
    source_term_definition = character(),
    source_release = character(),
    source_match_method = character(),
    source_match_status = character(),
    candidate_rank = integer(),
    candidate_score = double(),
    candidate_reason = character(),
    ecotox_release = character()
  )
}

#' @keywords internal
.eco_lifestage_dictionary_schema <- function() {
  tibble::tibble(
    org_lifestage = character(),
    source_ontology = character(),
    source_term_id = character(),
    source_term_label = character(),
    source_term_definition = character(),
    source_provider = character(),
    source_match_method = character(),
    source_match_status = character(),
    source_release = character(),
    ecotox_release = character(),
    harmonized_life_stage = character(),
    reproductive_stage = logical(),
    derivation_source = character()
  )
}

#' @keywords internal
.eco_lifestage_review_schema <- function() {
  tibble::tibble(
    org_lifestage = character(),
    candidate_source_ontology = character(),
    candidate_source_term_id = character(),
    candidate_source_term_label = character(),
    candidate_score = double(),
    candidate_reason = character(),
    source_provider = character(),
    ecotox_release = character(),
    review_status = character()
  )
}

#' @keywords internal
.eco_lifestage_release_id <- function(x) {
  if (inherits(x, "DBIConnection")) {
    meta <- DBI::dbReadTable(x, "_metadata")
    value <- meta$value[meta$key == "ecotox_release"][1]
    if (is.na(value) || !nzchar(value)) {
      cli::cli_abort("Missing {.field ecotox_release} in {.code _metadata}.")
    }
    return(value)
  }

  if (is.character(x) && length(x) == 1) {
    if (file.exists(x)) {
      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = x, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      return(.eco_lifestage_release_id(con))
    }
    return(basename(x))
  }

  cli::cli_abort("Unable to determine ECOTOX release identifier.")
}

#' @keywords internal
.eco_lifestage_cache_path <- function(ecotox_release) {
  safe_release <- gsub("[^A-Za-z0-9._-]+", "_", ecotox_release)
  dir <- tools::R_user_dir("ComptoxR", "cache")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, paste0("ecotox_lifestage_", safe_release, ".csv"))
}

#' @keywords internal
.eco_lifestage_baseline_path <- function() {
  installed <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  dev_path <- file.path("inst", "extdata", "ecotox", "lifestage_baseline.csv")
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  cli::cli_abort("Committed lifestage baseline CSV not found.")
}

#' @keywords internal
.eco_lifestage_derivation_path <- function() {
  installed <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  dev_path <- file.path("inst", "extdata", "ecotox", "lifestage_derivation.csv")
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  cli::cli_abort("Committed lifestage derivation CSV not found.")
}

#' @keywords internal
.eco_lifestage_curated_candidates_path <- function() {
  installed <- system.file(
    "extdata",
    "ecotox",
    "lifestage_curated_candidates.csv",
    package = "ComptoxR"
  )
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  dev_path <- file.path("inst", "extdata", "ecotox", "lifestage_curated_candidates.csv")
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  cli::cli_abort("Committed lifestage curated candidates CSV not found.")
}

#' @keywords internal
.eco_lifestage_policy_path <- function(filename, label) {
  installed <- system.file(
    "extdata",
    "ecotox",
    filename,
    package = "ComptoxR"
  )
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  dev_path <- file.path("inst", "extdata", "ecotox", filename)
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  cli::cli_abort("Committed lifestage {label} CSV not found.")
}

#' @keywords internal
.eco_lifestage_forced_unresolved_path <- function() {
  .eco_lifestage_policy_path(
    "lifestage_forced_unresolved.csv",
    "forced unresolved"
  )
}

#' @keywords internal
.eco_lifestage_domain_patterns_path <- function() {
  .eco_lifestage_policy_path(
    "lifestage_domain_patterns.csv",
    "domain patterns"
  )
}

#' @keywords internal
.eco_lifestage_taxon_route_families_path <- function() {
  .eco_lifestage_policy_path(
    "lifestage_taxon_route_families.csv",
    "taxon route families"
  )
}

#' @keywords internal
.eco_lifestage_read_csv <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA")
  )
}

#' @keywords internal
.eco_lifestage_forced_unresolved_policy <- function() {
  path <- .eco_lifestage_forced_unresolved_path()
  policy <- readr::read_csv(path, show_col_types = FALSE)
  required <- c("org_lifestage", "reason", "triage_bucket", "resolution_path")
  missing_cols <- setdiff(required, names(policy))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage forced unresolved schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  duplicate_terms <- unique(policy$org_lifestage[duplicated(policy$org_lifestage)])
  if (length(duplicate_terms) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage forced unresolved policy.",
      "x" = "Duplicate org_lifestage value(s): {duplicate_terms}."
    ))
  }

  policy
}

#' @keywords internal
.eco_lifestage_domain_pattern_policy <- function() {
  path <- .eco_lifestage_domain_patterns_path()
  policy <- readr::read_csv(path, show_col_types = FALSE)
  required <- c("domain", "pattern")
  valid_domains <- c("aquatic", "amphibian", "plant")
  missing_cols <- setdiff(required, names(policy))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage domain pattern schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  invalid_domains <- setdiff(unique(policy$domain), valid_domains)
  if (length(invalid_domains) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage domain pattern policy.",
      "x" = "Unknown domain value(s): {invalid_domains}."
    ))
  }

  duplicate_keys <- duplicated(policy[c("domain", "pattern")])
  if (any(duplicate_keys)) {
    keys <- paste(policy$domain[duplicate_keys], policy$pattern[duplicate_keys], sep = ":")
    cli::cli_abort(c(
      "Invalid lifestage domain pattern policy.",
      "x" = "Duplicate domain/pattern key(s): {unique(keys)}."
    ))
  }

  policy$pattern <- vapply(
    policy$pattern,
    .eco_lifestage_normalize_term,
    character(1),
    mode = "loose"
  )
  policy
}

#' @keywords internal
.eco_lifestage_taxon_route_family_policy <- function() {
  path <- .eco_lifestage_taxon_route_families_path()
  policy <- readr::read_csv(path, show_col_types = FALSE)
  required <- c("field", "value", "route_family")
  valid_fields <- c("eco_group", "kingdom", "class_name")
  valid_route_families <- c(
    "plant",
    "aquatic",
    "invertebrate",
    "amphibian",
    "vertebrate",
    "fungi",
    "algae"
  )
  missing_cols <- setdiff(required, names(policy))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage taxon route family schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  invalid_fields <- setdiff(unique(policy$field), valid_fields)
  if (length(invalid_fields) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage taxon route family policy.",
      "x" = "Unknown field value(s): {invalid_fields}."
    ))
  }

  invalid_route_families <- setdiff(unique(policy$route_family), valid_route_families)
  if (length(invalid_route_families) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage taxon route family policy.",
      "x" = "Unknown route_family value(s): {invalid_route_families}."
    ))
  }

  uppercase_fields <- policy$field %in% c("kingdom", "class_name")
  policy$value[uppercase_fields] <- toupper(policy$value[uppercase_fields])
  duplicate_keys <- duplicated(policy[c("field", "value")])
  if (any(duplicate_keys)) {
    keys <- paste(policy$field[duplicate_keys], policy$value[duplicate_keys], sep = ":")
    cli::cli_abort(c(
      "Invalid lifestage taxon route family policy.",
      "x" = "Duplicate field/value key(s): {unique(keys)}."
    ))
  }

  policy
}

#' @keywords internal
.eco_lifestage_json_col <- function(x, name, default = NA_character_) {
  value <- x[[name]]
  if (is.null(value)) {
    return(rep(default, nrow(x)))
  }
  value
}

#' @keywords internal
.eco_lifestage_json_binding_value <- function(x, name, default = NA_character_) {
  value <- x[[name]]
  if (is.null(value)) {
    return(rep(default, nrow(x)))
  }
  value$value
}

#' @keywords internal
.eco_lifestage_json_list_col <- function(x, name) {
  value <- x[[name]]
  if (is.null(value)) {
    return(vector("list", nrow(x)))
  }
  value
}

#' @keywords internal
.eco_lifestage_candidate_schema <- function() {
  tibble::tibble(
    source_provider = character(),
    source_ontology = character(),
    source_term_id = character(),
    source_term_label = character(),
    source_term_definition = character(),
    candidate_aliases = character(),
    source_release = character(),
    source_match_method = character()
  )
}

#' @keywords internal
.eco_lifestage_apply_query_alias <- function(candidates, org_lifestage, query_term) {
  candidates <- tibble::as_tibble(candidates)
  if (nrow(candidates) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  org_lifestage <- as.character(org_lifestage[[1]])
  query_term <- as.character(query_term[[1]])
  if (!nzchar(query_term) || identical(org_lifestage, query_term)) {
    return(candidates)
  }

  query_match_score <- function(label, aliases) {
    alias_texts <- if (!is.na(aliases) && nzchar(aliases)) {
      unlist(strsplit(aliases, "\\s*\\|\\s*"))
    } else {
      character()
    }
    texts <- unique(c(label, alias_texts))
    texts <- texts[nzchar(texts)]
    if (length(texts) == 0) {
      return(0)
    }
    scores <- vapply(
      texts,
      function(text) .eco_lifestage_score_text(query_term, text)$score,
      numeric(1)
    )
    max(scores, na.rm = TRUE)
  }

  candidates <- candidates |>
    dplyr::mutate(
      query_match_score = purrr::map2_dbl(
        .data$source_term_label,
        .data$candidate_aliases,
        query_match_score
      )
    ) |>
    dplyr::filter(.data$query_match_score >= 75) |>
    dplyr::select(-.data$query_match_score)

  if (nrow(candidates) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  candidates |>
    dplyr::mutate(
      candidate_aliases = vapply(
        .data$candidate_aliases,
        function(existing_aliases) {
          alias_parts <- c(org_lifestage, query_term)
          if (!is.na(existing_aliases) && nzchar(existing_aliases)) {
            alias_parts <- c(alias_parts, unlist(strsplit(existing_aliases, "\\s*\\|\\s*")))
          }
          paste(unique(alias_parts[nzchar(alias_parts)]), collapse = " | ")
        },
        character(1)
      )
    )
}

#' @keywords internal
.eco_lifestage_devstage_obo_url <- function() {
  "https://raw.githubusercontent.com/obophenotype/developmental-stage-ontologies/master/life-stages.obo"
}

#' @keywords internal
.eco_lifestage_devstage_obo_path <- function() {
  dir <- tools::R_user_dir("ComptoxR", "cache")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "developmental-stage-ontologies_life-stages.obo")
}

#' @keywords internal
.eco_lifestage_devstage_obo_lines <- function(force_refresh = FALSE) {
  cache_key <- "eco_lifestage_devstage_obo_lines"
  cache_path <- .eco_lifestage_devstage_obo_path()

  if (!force_refresh && exists(cache_key, envir = .ComptoxREnv, inherits = FALSE)) {
    return(get(cache_key, envir = .ComptoxREnv, inherits = FALSE))
  }

  needs_refresh <- force_refresh || !file.exists(cache_path)
  if (!needs_refresh) {
    age_hours <- as.numeric(difftime(Sys.time(), file.info(cache_path)$mtime, units = "hours"))
    needs_refresh <- is.na(age_hours) || age_hours > 24
  }

  if (needs_refresh) {
    response <- tryCatch(
      {
        httr2::request(.eco_lifestage_devstage_obo_url()) |>
          httr2::req_headers(Accept = "text/plain") |>
          httr2::req_perform()
      },
      error = function(e) {
        cli::cli_warn(c(
          "Developmental-stage ontology endpoint unreachable.",
          "i" = "Falling back to cached ontology snapshot if available.",
          "x" = conditionMessage(e)
        ))
        NULL
      }
    )

    if (!is.null(response)) {
      writeLines(httr2::resp_body_string(response), cache_path, useBytes = TRUE)
    }
  }

  if (!file.exists(cache_path)) {
    return(character())
  }

  lines <- readLines(cache_path, warn = FALSE, encoding = "UTF-8")
  assign(cache_key, lines, envir = .ComptoxREnv)
  lines
}

#' @keywords internal
.eco_lifestage_devstage_index <- function(force_refresh = FALSE) {
  cache_key <- "eco_lifestage_devstage_index"
  if (!force_refresh && exists(cache_key, envir = .ComptoxREnv, inherits = FALSE)) {
    return(get(cache_key, envir = .ComptoxREnv, inherits = FALSE))
  }

  lines <- .eco_lifestage_devstage_obo_lines(force_refresh = force_refresh)
  if (length(lines) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  flush_term <- function(term, out) {
    if (is.null(term$id) || isTRUE(term$is_obsolete)) {
      return(out)
    }

    label <- if (length(term$name) > 0) term$name[[1]] else NA_character_
    aliases <- unique(c(term$synonym, term$xref))
    aliases <- aliases[!is.na(aliases) & nzchar(aliases)]

    dplyr::bind_rows(
      out,
      tibble::tibble(
        source_provider = "DevStageOntologies",
        source_ontology = sub(":.*", "", term$id[[1]]),
        source_term_id = term$id[[1]],
        source_term_label = label,
        source_term_definition = if (length(term$def) > 0) term$def[[1]] else NA_character_,
        candidate_aliases = if (length(aliases) > 0) paste(aliases, collapse = " | ") else NA_character_,
        source_release = "obophenotype_life_stages_current",
        source_match_method = "dev_stage_ontology_obo"
      )
    )
  }

  terms <- .eco_lifestage_candidate_schema()
  current <- list(
    id = NULL,
    name = NULL,
    def = character(),
    synonym = character(),
    xref = character(),
    is_obsolete = FALSE
  )

  for (line in lines) {
    if (identical(line, "[Term]")) {
      terms <- flush_term(current, terms)
      current <- list(
        id = NULL,
        name = NULL,
        def = character(),
        synonym = character(),
        xref = character(),
        is_obsolete = FALSE
      )
      next
    }
    if (startsWith(line, "[Typedef]")) {
      terms <- flush_term(current, terms)
      break
    }
    if (!nzchar(line)) {
      next
    }
    if (startsWith(line, "id: ")) {
      current$id <- sub("^id: ", "", line)
    } else if (startsWith(line, "name: ")) {
      current$name <- sub("^name: ", "", line)
    } else if (startsWith(line, "def: ")) {
      current$def <- sub('^def: "([^"]*)".*$', "\\1", line)
    } else if (startsWith(line, "synonym: ")) {
      synonym_value <- sub('^synonym: "([^"]*)".*$', "\\1", line)
      current$synonym <- c(current$synonym, synonym_value)
    } else if (startsWith(line, "xref: ")) {
      current$xref <- c(current$xref, sub("^xref: ", "", line))
    } else if (startsWith(line, "is_obsolete: ")) {
      current$is_obsolete <- identical(sub("^is_obsolete: ", "", line), "true")
    }
  }

  terms <- terms |>
    dplyr::mutate(
      normalized_label = .eco_lifestage_normalize_term(.data$source_term_label, mode = "loose"),
      normalized_aliases = vapply(
        .data$candidate_aliases,
        function(x) {
          if (is.na(x) || !nzchar(x)) {
            return("")
          }
          aliases <- unlist(strsplit(x, "\\s*\\|\\s*"))
          aliases <- aliases[nzchar(aliases)]
          paste(
            unique(vapply(aliases, .eco_lifestage_normalize_term, character(1), mode = "loose")),
            collapse = " | "
          )
        },
        character(1)
      )
    )

  assign(cache_key, terms, envir = .ComptoxREnv)
  terms
}

#' @keywords internal
.eco_lifestage_query_devstage_ontology <- function(term) {
  index <- .eco_lifestage_devstage_index()
  if (nrow(index) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  lookup_term <- as.character(term[[1]])
  normalized_term <- .eco_lifestage_normalize_term(lookup_term, mode = "loose")
  contains_term <- function(x) {
    if (is.na(x) || !nzchar(x)) {
      return(FALSE)
    }
    stringr::str_detect(x, stringr::fixed(normalized_term))
  }

  matched <- index |>
    dplyr::filter(
      .data$normalized_label == normalized_term |
        vapply(.data$normalized_aliases, contains_term, logical(1)) |
        vapply(.data$normalized_label, contains_term, logical(1))
    ) |>
    dplyr::select(-dplyr::any_of(c("normalized_label", "normalized_aliases"))) |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE)

  if (nrow(matched) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  matched
}

#' @keywords internal
.eco_lifestage_po_obo_url <- function() {
  "http://purl.obolibrary.org/obo/po.obo"
}

#' @keywords internal
.eco_lifestage_po_obo_path <- function() {
  dir <- tools::R_user_dir("ComptoxR", "cache")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "plant-ontology_po.obo")
}

#' @keywords internal
.eco_lifestage_po_obo_lines <- function(force_refresh = FALSE) {
  cache_key <- "eco_lifestage_po_obo_lines"
  cache_path <- .eco_lifestage_po_obo_path()

  if (!force_refresh && exists(cache_key, envir = .ComptoxREnv, inherits = FALSE)) {
    return(get(cache_key, envir = .ComptoxREnv, inherits = FALSE))
  }

  needs_refresh <- force_refresh || !file.exists(cache_path)
  if (!needs_refresh) {
    age_hours <- as.numeric(difftime(Sys.time(), file.info(cache_path)$mtime, units = "hours"))
    needs_refresh <- is.na(age_hours) || age_hours > 24
  }

  if (needs_refresh) {
    response <- tryCatch(
      {
        httr2::request(.eco_lifestage_po_obo_url()) |>
          httr2::req_headers(Accept = "text/plain") |>
          httr2::req_perform()
      },
      error = function(e) {
        cli::cli_warn(c(
          "Plant Ontology endpoint unreachable.",
          "i" = "Falling back to cached PO snapshot if available.",
          "x" = conditionMessage(e)
        ))
        NULL
      }
    )

    if (!is.null(response)) {
      writeLines(httr2::resp_body_string(response), cache_path, useBytes = TRUE)
    }
  }

  if (!file.exists(cache_path)) {
    return(character())
  }

  lines <- readLines(cache_path, warn = FALSE, encoding = "UTF-8")
  assign(cache_key, lines, envir = .ComptoxREnv)
  lines
}

#' @keywords internal
.eco_lifestage_po_index <- function(force_refresh = FALSE) {
  cache_key <- "eco_lifestage_po_index"
  if (!force_refresh && exists(cache_key, envir = .ComptoxREnv, inherits = FALSE)) {
    return(get(cache_key, envir = .ComptoxREnv, inherits = FALSE))
  }

  lines <- .eco_lifestage_po_obo_lines(force_refresh = force_refresh)
  if (length(lines) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  flush_term <- function(term, out) {
    if (is.null(term$id) || isTRUE(term$is_obsolete) || !startsWith(term$id[[1]], "PO:")) {
      return(out)
    }

    label <- if (length(term$name) > 0) term$name[[1]] else NA_character_
    aliases <- unique(c(term$synonym, term$xref))
    aliases <- aliases[!is.na(aliases) & nzchar(aliases)]

    dplyr::bind_rows(
      out,
      tibble::tibble(
        source_provider = "PlantOntologyOBO",
        source_ontology = "PO",
        source_term_id = term$id[[1]],
        source_term_label = label,
        source_term_definition = if (length(term$def) > 0) term$def[[1]] else NA_character_,
        candidate_aliases = if (length(aliases) > 0) paste(aliases, collapse = " | ") else NA_character_,
        source_release = "po_current",
        source_match_method = "plant_ontology_obo"
      )
    )
  }

  terms <- .eco_lifestage_candidate_schema()
  current <- list(
    id = NULL,
    name = NULL,
    def = character(),
    synonym = character(),
    xref = character(),
    is_obsolete = FALSE
  )

  for (line in lines) {
    if (identical(line, "[Term]")) {
      terms <- flush_term(current, terms)
      current <- list(
        id = NULL,
        name = NULL,
        def = character(),
        synonym = character(),
        xref = character(),
        is_obsolete = FALSE
      )
      next
    }
    if (startsWith(line, "[Typedef]")) {
      terms <- flush_term(current, terms)
      break
    }
    if (!nzchar(line)) {
      next
    }
    if (startsWith(line, "id: ")) {
      current$id <- sub("^id: ", "", line)
    } else if (startsWith(line, "name: ")) {
      current$name <- sub("^name: ", "", line)
    } else if (startsWith(line, "def: ")) {
      current$def <- sub('^def: "([^"]*)".*$', "\\1", line)
    } else if (startsWith(line, "synonym: ")) {
      synonym_value <- sub('^synonym: "([^"]*)".*$', "\\1", line)
      current$synonym <- c(current$synonym, synonym_value)
    } else if (startsWith(line, "xref: ")) {
      current$xref <- c(current$xref, sub("^xref: ", "", line))
    } else if (startsWith(line, "is_obsolete: ")) {
      current$is_obsolete <- identical(sub("^is_obsolete: ", "", line), "true")
    }
  }

  terms <- terms |>
    dplyr::mutate(
      normalized_label = .eco_lifestage_normalize_term(.data$source_term_label, mode = "loose"),
      normalized_aliases = vapply(
        .data$candidate_aliases,
        function(x) {
          if (is.na(x) || !nzchar(x)) {
            return("")
          }
          aliases <- unlist(strsplit(x, "\\s*\\|\\s*"))
          aliases <- aliases[nzchar(aliases)]
          paste(
            unique(vapply(aliases, .eco_lifestage_normalize_term, character(1), mode = "loose")),
            collapse = " | "
          )
        },
        character(1)
      )
    )

  assign(cache_key, terms, envir = .ComptoxREnv)
  terms
}

#' @keywords internal
.eco_lifestage_query_po_obo <- function(term) {
  index <- .eco_lifestage_po_index()
  if (nrow(index) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  lookup_term <- as.character(term[[1]])
  normalized_term <- .eco_lifestage_normalize_term(lookup_term, mode = "loose")
  contains_term <- function(x) {
    if (is.na(x) || !nzchar(x)) {
      return(FALSE)
    }
    stringr::str_detect(x, stringr::fixed(normalized_term))
  }

  matched <- index |>
    dplyr::filter(
      .data$normalized_label == normalized_term |
        vapply(.data$normalized_aliases, contains_term, logical(1)) |
        vapply(.data$normalized_label, contains_term, logical(1))
    ) |>
    dplyr::select(-dplyr::any_of(c("normalized_label", "normalized_aliases"))) |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE)

  if (nrow(matched) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  matched
}

#' @keywords internal
.eco_lifestage_validate_cache <- function(x, expected_release = NULL, source_name = "cache") {
  if (is.null(x)) {
    return(.eco_lifestage_cache_schema())
  }

  required <- names(.eco_lifestage_cache_schema())
  missing_cols <- setdiff(required, names(x))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage {.val {source_name}} schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  x <- tibble::as_tibble(x[, required, drop = FALSE])
  x <- x |>
    dplyr::mutate(
      dplyr::across(
        c(
          "org_lifestage",
          "source_provider",
          "source_ontology",
          "source_term_id",
          "source_term_label",
          "source_term_definition",
          "source_release",
          "source_match_method",
          "source_match_status",
          "candidate_reason",
          "ecotox_release"
        ),
        ~ dplyr::na_if(as.character(.x), "")
      ),
      candidate_rank = as.integer(.data$candidate_rank),
      candidate_score = as.numeric(.data$candidate_score)
    )

  if (!is.null(expected_release) && nrow(x) > 0) {
    releases <- unique(stats::na.omit(x$ecotox_release))
    if (length(releases) != 1 || !identical(releases, expected_release)) {
      cli::cli_abort(c(
        "Release mismatch in lifestage {.val {source_name}}.",
        "x" = "Expected {.val {expected_release}} but found {.val {paste(releases, collapse = ', ')}}."
      ))
    }
  }

  x
}

#' @keywords internal
.eco_lifestage_cache_read <- function(ecotox_release, required = FALSE) {
  path <- .eco_lifestage_cache_path(ecotox_release)
  if (!file.exists(path)) {
    if (required) {
      cli::cli_abort("Release-matched lifestage cache not found at {.path {path}}.")
    }
    return(.eco_lifestage_cache_schema())
  }

  .eco_lifestage_validate_cache(
    .eco_lifestage_read_csv(path),
    expected_release = ecotox_release,
    source_name = "cache"
  )
}

#' @keywords internal
.eco_lifestage_cache_write <- function(x, ecotox_release) {
  path <- .eco_lifestage_cache_path(ecotox_release)
  x <- .eco_lifestage_validate_cache(
    x,
    expected_release = ecotox_release,
    source_name = "cache"
  )

  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

#' @keywords internal
.eco_lifestage_derivation_map <- function() {
  path <- .eco_lifestage_derivation_path()
  x <- .eco_lifestage_read_csv(path)

  required <- c(
    "source_ontology",
    "source_term_id",
    "harmonized_life_stage",
    "reproductive_stage",
    "derivation_source"
  )
  missing_cols <- setdiff(required, names(x))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage derivation schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  tibble::as_tibble(x[, required, drop = FALSE]) |>
    dplyr::mutate(
      dplyr::across(
        c("source_ontology", "source_term_id", "harmonized_life_stage", "derivation_source"),
        as.character
      ),
      reproductive_stage = as.logical(.data$reproductive_stage)
    ) |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE)
}

#' @keywords internal
.eco_lifestage_derivation_coverage_report_path <- function() {
  file.path("dev", "lifestage", "lifestage_derivation_coverage_report.csv")
}

#' @keywords internal
.eco_lifestage_load_seed_cache <- function(
  ecotox_release,
  refresh = c("auto", "cache", "baseline", "live"),
  force = FALSE
) {
  refresh <- rlang::arg_match(refresh)

  baseline <- NULL
  baseline_available <- FALSE
  baseline_matches <- FALSE
  baseline_path <- .eco_lifestage_baseline_path()

  if (file.exists(baseline_path)) {
    baseline <- .eco_lifestage_validate_cache(
      .eco_lifestage_read_csv(baseline_path),
      source_name = "baseline"
    )
    baseline_available <- nrow(baseline) > 0
    baseline_releases <- unique(stats::na.omit(baseline$ecotox_release))
    if (length(baseline_releases) > 1) {
      cli::cli_abort(c(
        "Committed lifestage baseline contains rows from multiple releases.",
        "x" = "Releases found: {.val {paste(baseline_releases, collapse = ', ')}}",
        "i" = "Re-generate the baseline for a single ECOTOX release."
      ))
    }
    baseline_matches <- length(baseline_releases) == 1L &&
      identical(baseline_releases, ecotox_release)
  }

  cache_path <- .eco_lifestage_cache_path(ecotox_release)
  cache_available <- file.exists(cache_path)

  if (refresh == "live") {
    return(list(
      seed_cache = .eco_lifestage_cache_schema(),
      refresh_mode = "live",
      cache_source = "live"
    ))
  }

  if (refresh == "cache") {
    if (!cache_available) {
      if (isTRUE(force)) {
        return(.eco_lifestage_load_seed_cache(ecotox_release, refresh = "auto", force = FALSE))
      }
      cli::cli_abort("Release-matched lifestage cache is required for {.code refresh = 'cache'}.")
    }

    return(list(
      seed_cache = .eco_lifestage_cache_read(ecotox_release, required = TRUE),
      refresh_mode = "cache",
      cache_source = "cache"
    ))
  }

  if (refresh == "baseline") {
    if (!baseline_available || !baseline_matches) {
      if (isTRUE(force)) {
        return(.eco_lifestage_load_seed_cache(ecotox_release, refresh = "auto", force = FALSE))
      }
      cli::cli_abort(c(
        "Matching committed lifestage baseline is required for {.code refresh = 'baseline'}.",
        "x" = "Expected baseline release {.val {ecotox_release}}."
      ))
    }

    .eco_lifestage_cache_write(baseline, ecotox_release)
    return(list(
      seed_cache = baseline,
      refresh_mode = "baseline",
      cache_source = "baseline"
    ))
  }

  if (cache_available) {
    return(list(
      seed_cache = .eco_lifestage_cache_read(ecotox_release, required = TRUE),
      refresh_mode = "auto",
      cache_source = "cache"
    ))
  }

  if (baseline_available && baseline_matches) {
    .eco_lifestage_cache_write(baseline, ecotox_release)
    return(list(
      seed_cache = baseline,
      refresh_mode = "auto",
      cache_source = "baseline"
    ))
  }

  list(
    seed_cache = .eco_lifestage_cache_schema(),
    refresh_mode = "auto",
    cache_source = "live"
  )
}

#' @keywords internal
.eco_lifestage_normalize_term <- function(x, mode = c("strict", "loose")) {
  mode <- rlang::arg_match(mode)
  x <- tolower(trimws(x))
  x <- stringr::str_replace_all(x, "\\s+", " ")

  if (mode == "loose") {
    x <- stringr::str_replace_all(x, "[[:punct:]]+", " ")
    x <- stringr::str_replace_all(x, "\\b([a-z]{4,})s\\b", "\\1")
    x <- stringr::str_replace_all(x, "\\s+", " ")
  }

  trimws(x)
}

#' @keywords internal
.eco_lifestage_regex_escape <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}

#' @keywords internal
.eco_lifestage_token_score <- function(term, candidate) {
  term <- as.character(term[[1]])
  candidate <- as.character(candidate[[1]])
  term_loose <- .eco_lifestage_normalize_term(term, mode = "loose")
  candidate_loose <- .eco_lifestage_normalize_term(candidate, mode = "loose")

  if (!nzchar(term_loose) || !nzchar(candidate_loose)) {
    return(list(score = 0, reason = NA_character_))
  }

  term_boundary <- paste0("(^| )", .eco_lifestage_regex_escape(term_loose), "( |$)")
  candidate_boundary <- paste0("(^| )", .eco_lifestage_regex_escape(candidate_loose), "( |$)")

  if (
    stringr::str_detect(candidate_loose, stringr::regex(term_boundary)) ||
      stringr::str_detect(term_loose, stringr::regex(candidate_boundary))
  ) {
    return(list(score = 75, reason = "boundary_match"))
  }

  term_tokens <- unique(strsplit(term_loose, " ", fixed = TRUE)[[1]])
  term_tokens <- term_tokens[nzchar(term_tokens)]
  candidate_tokens <- unique(strsplit(candidate_loose, " ", fixed = TRUE)[[1]])

  if (length(term_tokens) > 0 && all(term_tokens %in% candidate_tokens)) {
    return(list(score = 75, reason = "token_match"))
  }

  list(score = 0, reason = NA_character_)
}

#' @keywords internal
.eco_lifestage_score_text <- function(term, candidate) {
  term <- as.character(term[[1]])
  candidate <- as.character(candidate[[1]])
  term_strict <- .eco_lifestage_normalize_term(term, mode = "strict")
  term_loose <- .eco_lifestage_normalize_term(term, mode = "loose")
  candidate_strict <- .eco_lifestage_normalize_term(candidate, mode = "strict")
  candidate_loose <- .eco_lifestage_normalize_term(candidate, mode = "loose")

  if (identical(term_strict, candidate_strict)) {
    return(list(score = 100, reason = "exact_normalized_label"))
  }

  if (identical(term_loose, candidate_loose)) {
    return(list(score = 90, reason = "punctuation_plural_normalized_label"))
  }

  .eco_lifestage_token_score(term, candidate)
}

#' @keywords internal
.eco_lifestage_nvs_index <- function(refresh = FALSE) {
  cached <- .ComptoxREnv$eco_lifestage_nvs_index
  if (!isTRUE(refresh) && !is.null(cached)) {
    return(cached)
  }

  query <- paste(
    "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>",
    "SELECT ?term ?label ?altLabel ?definition WHERE {",
    "  ?term a skos:Concept ; skos:prefLabel ?label .",
    "  OPTIONAL { ?term skos:altLabel ?altLabel }",
    "  OPTIONAL { ?term skos:definition ?definition }",
    "  FILTER(REGEX(STR(?term), '^http://vocab.nerc.ac.uk/collection/S11/current/S[0-9]+/$'))",
    "}",
    sep = "\n"
  )

  payload <- tryCatch(
    {
      httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
        httr2::req_body_form(query = query) |>
        httr2::req_headers(Accept = "application/sparql-results+json") |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON(simplifyDataFrame = TRUE)
    },
    error = function(e) {
      cli::cli_warn(c(
        "NVS S11 SPARQL endpoint unreachable.",
        "i" = "NVS candidates will be skipped for this resolution run.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  nvs_empty <- .eco_lifestage_candidate_schema()

  if (is.null(payload)) {
    return(nvs_empty)
  }

  bindings <- payload$results$bindings
  if (is.null(bindings) || nrow(bindings) == 0) {
    cli::cli_warn("NVS S11 lookup returned no concepts.")
    return(nvs_empty)
  }

  index <- tibble::tibble(
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = sub(".*/(S[0-9]+)/$", "\\1", bindings$term$value),
    source_term_label = bindings$label$value,
    source_term_definition = .eco_lifestage_json_binding_value(bindings, "definition"),
    candidate_aliases = .eco_lifestage_json_binding_value(bindings, "altLabel"),
    source_release = "current",
    source_match_method = "nvs_sparql"
  ) |>
    dplyr::group_by(
      .data$source_provider,
      .data$source_ontology,
      .data$source_term_id,
      .data$source_term_label,
      .data$source_term_definition,
      .data$source_release,
      .data$source_match_method
    ) |>
    dplyr::summarise(
      candidate_aliases = paste(unique(stats::na.omit(.data$candidate_aliases)), collapse = " | "),
      .groups = "drop"
    )

  .ComptoxREnv$eco_lifestage_nvs_index <- index
  index
}

#' @keywords internal
.eco_lifestage_alias_lookup <- function(org_lifestage) {
  alias_path <- file.path("inst", "extdata", "ecotox", "lifestage_aliases.csv")
  if (!file.exists(alias_path)) {
    alias_path <- system.file(
      "extdata",
      "ecotox",
      "lifestage_aliases.csv",
      package = "ComptoxR"
    )
  }
  if (!nzchar(alias_path) || !file.exists(alias_path)) {
    return(org_lifestage)
  }

  aliases <- readr::read_csv(alias_path, show_col_types = FALSE)
  lookup_key <- as.character(org_lifestage[[1]])
  match_idx <- match(lookup_key, aliases$org_lifestage)
  if (is.na(match_idx) || is.na(aliases$normalized_query[[match_idx]])) {
    return(org_lifestage)
  }

  aliases$normalized_query[[match_idx]]
}

#' @keywords internal
.eco_lifestage_taxon_profile_path <- function() {
  dev_path <- file.path("dev", "lifestage", "lifestage_taxon_profile.csv")
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  cache_path <- file.path(tools::R_user_dir("ComptoxR", "cache"), "lifestage_taxon_profile.csv")
  if (file.exists(cache_path)) {
    return(cache_path)
  }

  ""
}

#' @keywords internal
.eco_lifestage_taxon_route_family <- function(
  eco_group = NA_character_,
  kingdom = NA_character_,
  class_name = NA_character_
) {
  route_families <- .eco_lifestage_taxon_route_family_policy()
  eco_group <- as.character(eco_group[[1]])
  kingdom <- toupper(as.character(kingdom[[1]]))
  class_name <- toupper(as.character(class_name[[1]]))

  route_inputs <- list(
    eco_group = eco_group,
    kingdom = kingdom,
    class_name = class_name
  )

  for (field in names(route_inputs)) {
    value <- route_inputs[[field]]
    if (is.na(value) || !nzchar(value)) {
      next
    }
    matches <- route_families$field == field & route_families$value == value
    if (any(matches)) {
      return(route_families$route_family[which(matches)[[1]]])
    }
  }
  NA_character_
}

#' @keywords internal
.eco_lifestage_taxon_route_lookup <- function(org_lifestage) {
  profile_path <- .eco_lifestage_taxon_profile_path()
  if (!nzchar(profile_path) || !file.exists(profile_path)) {
    return(tibble::tibble())
  }

  profile <- readr::read_csv(profile_path, show_col_types = FALSE)
  lookup_key <- as.character(org_lifestage[[1]])
  match_idx <- match(lookup_key, profile$org_lifestage)
  if (is.na(match_idx)) {
    return(tibble::tibble())
  }

  row <- profile[match_idx, , drop = FALSE]
  row$route_family <- dplyr::coalesce(
    row$route_family,
    .eco_lifestage_taxon_route_family(
      eco_group = row$eco_group[[1]],
      kingdom = row$kingdom[[1]],
      class_name = row$class_name[[1]]
    )
  )
  tibble::as_tibble(row)
}

#' @keywords internal
.eco_lifestage_forced_unresolved_terms <- function() {
  policy <- .eco_lifestage_forced_unresolved_policy()
  as.character(policy$org_lifestage)
}

#' @keywords internal
.eco_lifestage_detect_domains <- function(org_lifestage, query_term = org_lifestage) {
  text <- paste(as.character(org_lifestage[[1]]), as.character(query_term[[1]]))
  text <- .eco_lifestage_normalize_term(text, mode = "loose")

  patterns <- .eco_lifestage_domain_pattern_policy()
  matches <- vapply(
    patterns$pattern,
    function(pattern) stringr::str_detect(text, stringr::fixed(pattern)),
    logical(1)
  )
  unique(as.character(patterns$domain[matches]))
}

#' @keywords internal
.eco_lifestage_curated_candidates <- function(org_lifestage) {
  path <- .eco_lifestage_curated_candidates_path()
  curated <- readr::read_csv(path, show_col_types = FALSE)
  required <- c(
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "candidate_aliases"
  )
  missing_cols <- setdiff(required, names(curated))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Invalid lifestage curated candidates schema.",
      "x" = "Missing column(s): {missing_cols}."
    ))
  }

  hit <- curated |>
    dplyr::filter(.data$org_lifestage == !!org_lifestage)

  if (nrow(hit) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  hit |>
    dplyr::transmute(
      source_provider = "Curated",
      source_ontology = .data$source_ontology,
      source_term_id = .data$source_term_id,
      source_term_label = .data$source_term_label,
      source_term_definition = NA_character_,
      candidate_aliases = .data$candidate_aliases,
      source_release = "curated",
      source_match_method = "curated_synonym_bridge"
    )
}

.eco_lifestage_query_ols4 <- function(term) {
  relevant_prefixes <- c(
    "UBERON:",
    "PO:",
    "XAO:",
    "ECOCORE:",
    "EFO:",
    "ZFA:",
    "FBdv:",
    "MeSH:"
  )
  response <- tryCatch(
    {
      httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
        httr2::req_url_query(
          q = term,
          queryFields = "label,synonym,description",
          rows = 25
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON(simplifyDataFrame = TRUE)
    },
    error = function(e) {
      cli::cli_warn(c(
        "OLS4 endpoint unreachable for {.val {term}}.",
        "i" = "OLS4 candidates will be skipped for this resolution run.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(response)) {
    Sys.sleep(0.3)
    return(.eco_lifestage_candidate_schema())
  }

  docs <- response$response$docs
  if (is.null(docs) || is.null(nrow(docs)) || nrow(docs) == 0) {
    Sys.sleep(0.3)
    return(.eco_lifestage_candidate_schema())
  }

  result <- tibble::tibble(
    source_provider = "OLS4",
    source_ontology = sub(":.*", "", .eco_lifestage_json_col(docs, "obo_id")),
    source_term_id = .eco_lifestage_json_col(docs, "obo_id"),
    source_term_label = .eco_lifestage_json_col(docs, "label"),
    source_term_definition = vapply(
      .eco_lifestage_json_list_col(docs, "description"),
      function(x) {
        if (length(x) == 0) {
          return(NA_character_)
        }
        as.character(x[[1]])
      },
      character(1)
    ),
    candidate_aliases = vapply(
      .eco_lifestage_json_list_col(docs, "exact_synonyms"),
      function(x) {
        if (length(x) == 0) {
          return(NA_character_)
        }
        paste(unique(as.character(x)), collapse = " | ")
      },
      character(1)
    ),
    source_release = "current",
    source_match_method = "ols4_search"
  ) |>
    dplyr::filter(
      !is.na(.data$source_term_id),
      !is.na(.data$source_term_label),
      purrr::map_lgl(
        .data$source_term_id,
        function(id) {
          any(startsWith(id, relevant_prefixes))
        }
      )
    )

  Sys.sleep(0.3)
  result
}

#' @keywords internal
.eco_lifestage_query_xao <- function(term) {
  response <- tryCatch(
    {
      httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
        httr2::req_url_query(
          q = term,
          ontology = "xao",
          queryFields = "label,synonym,description",
          rows = 25
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON(simplifyDataFrame = TRUE)
    },
    error = function(e) {
      cli::cli_warn(c(
        "XAO endpoint unreachable for {.val {term}}.",
        "i" = "XAO candidates will be skipped for this resolution run.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(response)) {
    Sys.sleep(0.2)
    return(.eco_lifestage_candidate_schema())
  }

  docs <- response$response$docs
  if (is.null(docs) || is.null(nrow(docs)) || nrow(docs) == 0) {
    Sys.sleep(0.2)
    return(.eco_lifestage_candidate_schema())
  }

  result <- tibble::tibble(
    source_provider = "XAO",
    source_ontology = "XAO",
    source_term_id = .eco_lifestage_json_col(docs, "obo_id"),
    source_term_label = .eco_lifestage_json_col(docs, "label"),
    source_term_definition = vapply(
      .eco_lifestage_json_list_col(docs, "description"),
      function(x) {
        if (length(x) == 0) {
          return(NA_character_)
        }
        as.character(x[[1]])
      },
      character(1)
    ),
    candidate_aliases = vapply(
      .eco_lifestage_json_list_col(docs, "exact_synonyms"),
      function(x) {
        if (length(x) == 0) {
          return(NA_character_)
        }
        paste(unique(as.character(x)), collapse = " | ")
      },
      character(1)
    ),
    source_release = "current",
    source_match_method = "xao_ols4_search"
  ) |>
    dplyr::filter(
      !is.na(.data$source_term_id),
      !is.na(.data$source_term_label),
      startsWith(.data$source_term_id, "XAO:")
    )

  Sys.sleep(0.2)
  result
}

#' @keywords internal
.eco_lifestage_query_bioportal <- function(term) {
  bioportal_key <- Sys.getenv("BIOPORTAL_API_KEY")
  if (!nzchar(bioportal_key)) {
    cli::cli_warn(c(
      "BIOPORTAL_API_KEY is not set.",
      "i" = "BioPortal candidates will be skipped.",
      "i" = "Obtain a free key at {.url https://bioportal.bioontology.org}"
    ))
    return(.eco_lifestage_candidate_schema())
  }

  response <- tryCatch(
    {
      httr2::request("https://data.bioontology.org/search") |>
        httr2::req_url_query(
          q = term,
          ontologies = "UBERON,ZFA,ECOCORE,EFO,XAO",
          include = "prefLabel,synonym,definition,notation",
          apikey = bioportal_key
        ) |>
        httr2::req_headers(Accept = "application/json") |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      status_code <- NA_integer_
      if (!is.null(e$response) && !is.null(e$response$status_code)) {
        status_code <- e$response$status_code
      }
      auth_hint <- if (identical(status_code, 401L)) {
        "BioPortal rejected the configured API key."
      } else {
        "BioPortal candidates will be skipped for this resolution run."
      }
      cli::cli_warn(c(
        "BioPortal endpoint unreachable for {.val {term}}.",
        "i" = auth_hint,
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(response) || length(response) == 0) {
    Sys.sleep(0.5)
    return(.eco_lifestage_candidate_schema())
  }

  records <- response$collection
  if (is.null(records) || length(records) == 0) {
    Sys.sleep(0.5)
    return(.eco_lifestage_candidate_schema())
  }

  rows <- purrr::compact(purrr::map(records, function(record) {
    tryCatch(
      {
        class_id_raw <- record$`@id`
        if (is.null(class_id_raw)) {
          return(NULL)
        }

        obo_id <- if (grepl("obo/", class_id_raw, fixed = TRUE)) {
          id_part <- sub(".*obo/", "", class_id_raw)
          sub("_", ":", id_part)
        } else if (!is.null(record$notation) && nzchar(record$notation)) {
          as.character(record$notation)
        } else {
          class_id_raw
        }

        ontology_acronym <- if (!is.null(record$links$ontology)) {
          sub(".*ontologies/([^/]+).*", "\\1", record$links$ontology)
        } else {
          sub(":.*", "", obo_id)
        }

        label <- if (!is.null(record$prefLabel)) {
          as.character(record$prefLabel)
        } else {
          NA_character_
        }

        aliases <- if (!is.null(record$synonym) && length(record$synonym) > 0) {
          paste(unique(as.character(unlist(record$synonym))), collapse = " | ")
        } else {
          NA_character_
        }

        definition <- if (!is.null(record$definition) && length(record$definition) > 0) {
          as.character(unlist(record$definition)[[1]])
        } else {
          NA_character_
        }

        tibble::tibble(
          source_provider = "BioPortal",
          source_ontology = ontology_acronym,
          source_term_id = obo_id,
          source_term_label = label,
          source_term_definition = definition,
          candidate_aliases = aliases,
          source_release = "current",
          source_match_method = "bioportal_search"
        )
      },
      error = function(e) NULL
    )
  }))

  Sys.sleep(0.5)

  if (length(rows) == 0) {
    return(.eco_lifestage_candidate_schema())
  }

  dplyr::bind_rows(rows) |>
    dplyr::filter(!is.na(.data$source_term_id), !is.na(.data$source_term_label))
}

#' @keywords internal
.eco_lifestage_query_wikidata <- function(term) {
  escaped_term <- gsub('"', '\\"', tolower(term), fixed = TRUE)
  uberon_sparql <- glue::glue(
    'SELECT ?item ?itemLabel ?uberonId WHERE {{
      ?item wdt:P1554 ?uberonId .
      ?item rdfs:label ?itemLabel .
      FILTER(LANG(?itemLabel) = "en")
      FILTER(CONTAINS(LCASE(?itemLabel), "{escaped_term}"))
    }}
    LIMIT 10'
  )
  adw_sparql <- glue::glue(
    'SELECT ?item ?itemLabel ?adwId WHERE {{
      ?item wdt:P3841 ?adwId .
      ?item rdfs:label ?itemLabel .
      FILTER(LANG(?itemLabel) = "en")
      FILTER(CONTAINS(LCASE(?itemLabel), "{escaped_term}"))
    }}
    LIMIT 10'
  )

  query_wikidata <- function(sparql) {
    tryCatch(
      {
        httr2::request("https://query.wikidata.org/sparql") |>
          httr2::req_url_query(query = sparql) |>
          httr2::req_headers(
            Accept = "application/sparql-results+json",
            `User-Agent` = "ComptoxR/dev lifestage resolver (verfassergeist@gmail.com)"
          ) |>
          httr2::req_perform() |>
          httr2::resp_body_string() |>
          jsonlite::fromJSON(simplifyDataFrame = TRUE)
      },
      error = function(e) {
        cli::cli_warn(c(
          "Wikidata SPARQL endpoint unreachable for {.val {term}}.",
          "i" = "Wikidata candidates will be skipped for this resolution run.",
          "x" = conditionMessage(e)
        ))
        NULL
      }
    )
  }

  uberon_payload <- query_wikidata(uberon_sparql)
  uberon_rows <- .eco_lifestage_candidate_schema()
  if (!is.null(uberon_payload)) {
    bindings <- uberon_payload$results$bindings
    if (is.data.frame(bindings) && nrow(bindings) > 0 && "uberonId" %in% names(bindings)) {
      uberon_rows <- tibble::tibble(
        source_provider = "Wikidata",
        source_ontology = "UBERON",
        source_term_id = paste0("UBERON:", bindings$uberonId$value),
        source_term_label = bindings$itemLabel$value,
        source_term_definition = NA_character_,
        candidate_aliases = NA_character_,
        source_release = "current",
        source_match_method = "wikidata_sparql_P1554"
      )
    }
  }

  Sys.sleep(1)

  adw_payload <- query_wikidata(adw_sparql)
  adw_rows <- .eco_lifestage_candidate_schema()
  if (!is.null(adw_payload)) {
    bindings <- adw_payload$results$bindings
    if (is.data.frame(bindings) && nrow(bindings) > 0) {
      adw_rows <- tibble::tibble(
        source_provider = "Wikidata",
        source_ontology = "ADW",
        source_term_id = if ("adwId" %in% names(bindings)) {
          paste0("ADW:", bindings$adwId$value)
        } else {
          NA_character_
        },
        source_term_label = bindings$itemLabel$value,
        source_term_definition = NA_character_,
        candidate_aliases = NA_character_,
        source_release = "current",
        source_match_method = "wikidata_sparql_P3841"
      )
    }
  }

  Sys.sleep(1)

  dplyr::bind_rows(uberon_rows, adw_rows)
}

#' @keywords internal
.eco_lifestage_query_agrovoc <- function(term) {
  search_result <- tryCatch(
    {
      httr2::request("https://agrovoc.fao.org/browse/rest/v1/search/") |>
        httr2::req_url_query(query = term, lang = "en") |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      cli::cli_warn(c(
        "AGROVOC search endpoint unreachable for {.val {term}}.",
        "i" = "AGROVOC candidates will be skipped for this resolution run.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(search_result)) {
    Sys.sleep(0.5)
    return(.eco_lifestage_candidate_schema())
  }

  results_list <- search_result$results
  if (is.null(results_list) || length(results_list) == 0) {
    Sys.sleep(0.5)
    return(.eco_lifestage_candidate_schema())
  }

  first_result <- results_list[[1]]
  concept_uri <- first_result$uri
  preferred_label <- if (!is.null(first_result$prefLabel)) {
    first_result$prefLabel
  } else {
    NA_character_
  }

  broader_labels <- character(0)
  detail <- tryCatch(
    {
      httr2::request("https://agrovoc.fao.org/browse/rest/v1/data/") |>
        httr2::req_url_query(uri = concept_uri) |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      cli::cli_warn(c(
        "AGROVOC detail endpoint unreachable for {.val {term}}.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (!is.null(detail)) {
    broader_raw <- detail$broader
    if (!is.null(broader_raw) && length(broader_raw) > 0) {
      broader_labels <- vapply(
        broader_raw,
        function(b) if (!is.null(b$prefLabel)) b$prefLabel else NA_character_,
        character(1)
      )
      broader_labels <- broader_labels[!is.na(broader_labels)]
    }
  }

  Sys.sleep(0.5)

  tibble::tibble(
    source_provider = "AGROVOC",
    source_ontology = "AGROVOC",
    source_term_id = concept_uri,
    source_term_label = preferred_label,
    source_term_definition = NA_character_,
    candidate_aliases = if (length(broader_labels) > 0) {
      paste(broader_labels, collapse = " | ")
    } else {
      NA_character_
    },
    source_release = "current",
    source_match_method = "agrovoc_rest_search"
  )
}

#' @keywords internal
.eco_lifestage_query_nvs <- function(term) {
  index <- .eco_lifestage_nvs_index()
  if (nrow(index) == 0) {
    return(tibble::tibble())
  }
  term_loose <- .eco_lifestage_normalize_term(term, mode = "loose")
  term_tokens <- unique(strsplit(term_loose, " ", fixed = TRUE)[[1]])
  term_tokens <- term_tokens[nzchar(term_tokens)]

  if (length(term_tokens) == 0) {
    return(tibble::tibble())
  }

  index |>
    dplyr::filter(
      purrr::map_lgl(
        paste(.data$source_term_label, .data$candidate_aliases),
        function(txt) {
          txt <- .eco_lifestage_normalize_term(if (is.null(txt) || is.na(txt)) "" else txt, mode = "loose")
          any(term_tokens %in% strsplit(txt, " ", fixed = TRUE)[[1]]) ||
            stringr::str_detect(txt, stringr::fixed(term_loose))
        }
      )
    )
}

#' @keywords internal
.eco_lifestage_rank_candidates <- function(org_lifestage, candidates) {
  if (nrow(candidates) == 0) {
    return(
      .eco_lifestage_cache_schema() |>
        dplyr::add_row(
          org_lifestage = org_lifestage,
          source_match_method = "provider_rank",
          source_match_status = "unresolved",
          candidate_rank = 1L,
          candidate_score = 0,
          candidate_reason = "no_provider_candidates",
          ecotox_release = NA_character_
        )
    )
  }

  candidates <- tibble::as_tibble(candidates) |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE)

  domain_tags <- .eco_lifestage_detect_domains(org_lifestage)
  taxon_route <- .eco_lifestage_taxon_route_lookup(org_lifestage)
  route_family <- if (nrow(taxon_route) > 0 && "route_family" %in% names(taxon_route)) {
    as.character(taxon_route$route_family[[1]])
  } else {
    NA_character_
  }
  is_aquatic <- "aquatic" %in% domain_tags
  is_amphibian <- "amphibian" %in% domain_tags
  is_plant <- "plant" %in% domain_tags
  ranked <- purrr::pmap_dfr(
    candidates,
    function(
      source_provider,
      source_ontology,
      source_term_id,
      source_term_label,
      source_term_definition,
      candidate_aliases,
      source_release,
      source_match_method
    ) {
      alias_text <- if (is.null(candidate_aliases) || is.na(candidate_aliases)) "" else candidate_aliases
      texts <- c(source_term_label, unlist(strsplit(alias_text, "\\s*\\|\\s*")))
      texts <- unique(stats::na.omit(texts[nzchar(texts)]))
      if (length(texts) == 0) {
        texts <- source_term_label
      }

      scored <- purrr::map(texts, ~ .eco_lifestage_score_text(org_lifestage, .x))
      scores <- vapply(scored, `[[`, numeric(1), "score")
      reasons <- vapply(scored, `[[`, character(1), "reason")
      best_idx <- which.max(scores)

      tibble::tibble(
        org_lifestage = org_lifestage,
        source_provider = source_provider,
        source_ontology = source_ontology,
        source_term_id = source_term_id,
        source_term_label = source_term_label,
        source_term_definition = source_term_definition,
        source_release = source_release,
        source_match_method = source_match_method,
        candidate_score = scores[[best_idx]],
        candidate_reason = reasons[[best_idx]]
      )
    }
  ) |>
    dplyr::mutate(
      ontology_priority = dplyr::case_when(
        .data$source_provider == "Curated" ~ 0L,
        identical(route_family, "plant") & .data$source_provider == "PlantOntologyOBO" ~ 1L,
        identical(route_family, "plant") & .data$source_ontology == "PO" ~ 2L,
        identical(route_family, "plant") & .data$source_ontology == "AGROVOC" ~ 3L,
        identical(route_family, "plant") & .data$source_provider == "DevStageOntologies" ~ 4L,
        identical(route_family, "amphibian") & .data$source_ontology == "XAO" ~ 1L,
        identical(route_family, "amphibian") & .data$source_provider == "DevStageOntologies" ~ 2L,
        identical(route_family, "amphibian") & .data$source_ontology == "UBERON" ~ 3L,
        identical(route_family, "aquatic") & .data$source_provider == "DevStageOntologies" ~ 1L,
        identical(route_family, "aquatic") & .data$source_ontology == "S11" ~ 2L,
        identical(route_family, "aquatic") & .data$source_ontology == "UBERON" ~ 3L,
        identical(route_family, "invertebrate") & .data$source_provider == "DevStageOntologies" ~ 1L,
        identical(route_family, "invertebrate") & .data$source_ontology == "S11" ~ 2L,
        identical(route_family, "invertebrate") & .data$source_ontology == "UBERON" ~ 3L,
        identical(route_family, "vertebrate") & .data$source_provider == "DevStageOntologies" ~ 1L,
        identical(route_family, "vertebrate") & .data$source_ontology == "UBERON" ~ 2L,
        identical(route_family, "fungi") & .data$source_ontology == "AGROVOC" ~ 1L,
        identical(route_family, "algae") & .data$source_ontology == "AGROVOC" ~ 1L,
        is_aquatic & .data$source_ontology == "S11" ~ 1L,
        is_aquatic & .data$source_ontology == "UBERON" ~ 2L,
        is_amphibian & .data$source_ontology == "XAO" ~ 1L,
        is_amphibian & .data$source_ontology == "UBERON" ~ 2L,
        is_plant & .data$source_provider == "PlantOntologyOBO" ~ 1L,
        is_plant & .data$source_ontology == "PO" ~ 2L,
        is_plant & .data$source_ontology == "AGROVOC" ~ 3L,
        .data$source_ontology == "S11" ~ 1L,
        .data$source_provider == "PlantOntologyOBO" ~ 2L,
        .data$source_provider == "DevStageOntologies" ~ 3L,
        .data$source_ontology == "XAO" ~ 4L,
        .data$source_ontology == "UBERON" ~ 5L,
        .data$source_ontology == "PO" ~ 6L,
        .data$source_ontology == "ZFA" ~ 7L,
        .data$source_ontology == "FBdv" ~ 8L,
        .data$source_ontology == "ECOCORE" ~ 9L,
        .data$source_ontology == "AGROVOC" ~ 10L,
        .data$source_ontology == "MeSH" ~ 11L,
        .data$source_ontology == "EFO" ~ 12L,
        .data$source_ontology == "ADW" ~ 13L,
        TRUE ~ 99L
      )
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$candidate_score),
      .data$ontology_priority,
      .data$source_ontology,
      .data$source_term_id
    ) |>
    dplyr::mutate(candidate_rank = dplyr::row_number())

  top_score <- ranked$candidate_score[[1]]
  accepted <- ranked |>
    dplyr::filter(.data$candidate_score >= 75)

  if (nrow(accepted) == 0L) {
    return(
      .eco_lifestage_cache_schema() |>
        dplyr::add_row(
          org_lifestage = org_lifestage,
          source_match_method = "provider_rank",
          source_match_status = "unresolved",
          candidate_rank = 1L,
          candidate_score = 0,
          candidate_reason = "no_candidate_ge75"
        )
    )
  }

  top_candidates <- accepted |>
    dplyr::filter(.data$candidate_score == top_score)
  top_candidates <- top_candidates |>
    dplyr::filter(.data$ontology_priority == min(.data$ontology_priority))
  trusted_boundary <- c("S11", "XAO", "UBERON", "PO", "ZFA", "FBdv", "AGROVOC")
  resolved <- nrow(top_candidates) == 1 &&
    (top_score >= 90 ||
      (top_score == 75 && top_candidates$source_ontology[[1]] %in% trusted_boundary))
  status <- if (resolved) "resolved" else "ambiguous"

  output <- if (resolved) {
    top_candidates |>
      dplyr::slice(1)
  } else {
    accepted
  }

  output |>
    dplyr::mutate(
      source_match_status = status,
      source_match_method = "provider_rank",
      ecotox_release = NA_character_
    ) |>
    dplyr::select(
      dplyr::all_of(names(.eco_lifestage_cache_schema()))
    )
}

#' @keywords internal
.eco_lifestage_resolve_term <- function(org_lifestage, ecotox_release) {
  release_id <- ecotox_release
  if (org_lifestage %in% .eco_lifestage_forced_unresolved_terms()) {
    return(
      .eco_lifestage_cache_schema() |>
        dplyr::add_row(
          org_lifestage = org_lifestage,
          source_match_method = "forced_unresolved",
          source_match_status = "unresolved",
          candidate_rank = 1L,
          candidate_score = 0,
          candidate_reason = "forced_unresolved_nonstage",
          ecotox_release = release_id
        )
    )
  }
  query_term <- .eco_lifestage_alias_lookup(org_lifestage)
  domain_tags <- .eco_lifestage_detect_domains(org_lifestage, query_term)
  taxon_route <- .eco_lifestage_taxon_route_lookup(org_lifestage)
  route_family <- if (nrow(taxon_route) > 0 && "route_family" %in% names(taxon_route)) {
    as.character(taxon_route$route_family[[1]])
  } else {
    NA_character_
  }
  is_plant_route <- identical(route_family, "plant") || "plant" %in% domain_tags
  candidates <- if (is_plant_route) {
    dplyr::bind_rows(
      .eco_lifestage_curated_candidates(org_lifestage),
      .eco_lifestage_query_po_obo(org_lifestage),
      .eco_lifestage_apply_query_alias(
        .eco_lifestage_query_po_obo(query_term),
        org_lifestage = org_lifestage,
        query_term = query_term
      ),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_ols4(query_term), org_lifestage, query_term),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_agrovoc(query_term), org_lifestage, query_term)
    )
  } else {
    dplyr::bind_rows(
      .eco_lifestage_curated_candidates(org_lifestage),
      .eco_lifestage_query_devstage_ontology(org_lifestage),
      .eco_lifestage_apply_query_alias(
        .eco_lifestage_query_devstage_ontology(query_term),
        org_lifestage = org_lifestage,
        query_term = query_term
      ),
      if ("amphibian" %in% domain_tags) .eco_lifestage_query_xao(query_term) else .eco_lifestage_candidate_schema(),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_ols4(query_term), org_lifestage, query_term),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_bioportal(query_term), org_lifestage, query_term),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_nvs(query_term), org_lifestage, query_term),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_wikidata(query_term), org_lifestage, query_term),
      .eco_lifestage_apply_query_alias(.eco_lifestage_query_agrovoc(query_term), org_lifestage, query_term)
    )
  }

  .eco_lifestage_rank_candidates(org_lifestage, candidates) |>
    dplyr::mutate(ecotox_release = release_id)
}

#' @keywords internal
.eco_lifestage_review_from_cache <- function(cache_rows) {
  ambiguous_or_unresolved <- cache_rows |>
    dplyr::filter(.data$source_match_status != "resolved") |>
    dplyr::transmute(
      org_lifestage = .data$org_lifestage,
      candidate_source_ontology = .data$source_ontology,
      candidate_source_term_id = .data$source_term_id,
      candidate_source_term_label = .data$source_term_label,
      candidate_score = .data$candidate_score,
      candidate_reason = .data$candidate_reason,
      source_provider = .data$source_provider,
      ecotox_release = .data$ecotox_release,
      review_status = .data$source_match_status
    )

  dplyr::bind_rows(
    .eco_lifestage_review_schema(),
    ambiguous_or_unresolved
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$org_lifestage, dplyr::desc(.data$candidate_score), .data$candidate_source_ontology)
}

#' @keywords internal
.eco_lifestage_derive_fields <- function(resolved_rows) {
  derivation_map <- .eco_lifestage_auto_derive(resolved_rows)

  resolved_rows |>
    dplyr::left_join(
      derivation_map,
      by = c("source_ontology", "source_term_id")
    )
}

#' @keywords internal
.eco_lifestage_derivation_coverage_report <- function(
  baseline,
  derivation_map = .eco_lifestage_derivation_map()
) {
  resolved <- baseline |>
    dplyr::filter(.data$source_match_status == "resolved") |>
    dplyr::group_by(.data$org_lifestage) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE)

  derivation_keys <- derivation_map |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id) |>
    dplyr::mutate(in_derivation_csv = TRUE)

  resolved |>
    dplyr::left_join(
      derivation_keys,
      by = c("source_ontology", "source_term_id")
    ) |>
    dplyr::mutate(
      in_derivation_csv = dplyr::coalesce(.data$in_derivation_csv, FALSE),
      coverage_source = dplyr::case_when(
        .data$in_derivation_csv ~ "derivation_csv_only",
        TRUE ~ "missing_both"
      )
    ) |>
    dplyr::arrange(.data$coverage_source, .data$source_ontology, .data$source_term_id)
}

#' @keywords internal
.eco_lifestage_write_derivation_coverage_report <- function(baseline) {
  report <- .eco_lifestage_derivation_coverage_report(baseline)
  path <- .eco_lifestage_derivation_coverage_report_path()
  utils::write.csv(report, path, row.names = FALSE, na = "")
  list(
    path = path,
    rows = nrow(report),
    derivation_csv_only = sum(report$coverage_source == "derivation_csv_only", na.rm = TRUE),
    missing_both = sum(report$coverage_source == "missing_both", na.rm = TRUE)
  )
}

#' @keywords internal
.eco_lifestage_auto_derive <- function(baseline, audit = NULL) {
  existing_derivation <- .eco_lifestage_derivation_map()

  resolved <- baseline |>
    dplyr::filter(.data$source_match_status == "resolved") |>
    dplyr::group_by(.data$org_lifestage) |>
    dplyr::slice(1) |>
    dplyr::ungroup()

  resolved_keys <- resolved |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id)

  existing_keys <- dplyr::semi_join(
    existing_derivation,
    resolved_keys,
    by = c("source_ontology", "source_term_id")
  )

  new_keys <- dplyr::anti_join(
    resolved_keys,
    existing_derivation,
    by = c("source_ontology", "source_term_id")
  )

  auto_derived <- new_keys |>
    dplyr::mutate(
      harmonized_life_stage = "Other/Unknown",
      reproductive_stage = FALSE,
      derivation_source = "auto_unmatched_needs_review"
    )

  unresolvable_rows <- tibble::tibble(
    source_ontology = character(),
    source_term_id = character(),
    harmonized_life_stage = character(),
    reproductive_stage = logical(),
    derivation_source = character()
  )
  if (!is.null(audit) && nrow(audit) > 0) {
    unresolved_terms <- baseline |>
      dplyr::filter(.data$source_match_status != "resolved") |>
      dplyr::distinct(.data$org_lifestage)

    unresolvable_rows <- audit |>
      dplyr::inner_join(unresolved_terms, by = "org_lifestage") |>
      dplyr::transmute(
        source_ontology = "ECOTOX_UNRESOLVED",
        source_term_id = .data$org_lifestage,
        harmonized_life_stage = dplyr::case_when(
          .data$triage_bucket == "administrative_noise" ~ "Unspecified",
          TRUE ~ "Other/Unknown"
        ),
        reproductive_stage = FALSE,
        derivation_source = dplyr::case_when(
          .data$resolution_path %in%
            c("manual_curator", "manual_derivation", "permanently_unresolved") ~ .data$resolution_path,
          .data$triage_bucket == "out_of_scope_biology" ~ "auto_triage_out_of_scope",
          .data$triage_bucket == "administrative_noise" ~ "administrative_noise_audit",
          .data$triage_bucket == "ambiguous" ~ "auto_triage_ambiguous",
          .data$triage_bucket == "alias_synonym" ~ "auto_triage_alias_synonym",
          .data$triage_bucket == "needs_ontology_expansion" ~ "auto_triage_needs_expansion",
          TRUE ~ "auto_triage_needs_review"
        )
      )
  }

  missing_audit_rows <- baseline |>
    dplyr::filter(.data$source_match_status != "resolved") |>
    dplyr::distinct(.data$org_lifestage) |>
    dplyr::anti_join(
      unresolvable_rows |>
        dplyr::transmute(org_lifestage = .data$source_term_id),
      by = "org_lifestage"
    ) |>
    dplyr::transmute(
      source_ontology = "ECOTOX_UNRESOLVED",
      source_term_id = .data$org_lifestage,
      harmonized_life_stage = "Other/Unknown",
      reproductive_stage = FALSE,
      derivation_source = "auto_triage_missing_audit"
    )

  dplyr::bind_rows(
    existing_keys,
    auto_derived,
    unresolvable_rows,
    missing_audit_rows
  ) |>
    dplyr::distinct(.data$source_ontology, .data$source_term_id, .keep_all = TRUE) |>
    dplyr::arrange(.data$source_ontology, .data$source_term_id)
}

#' @keywords internal
.eco_lifestage_materialize_tables <- function(
  org_lifestages,
  ecotox_release,
  refresh = c("auto", "cache", "baseline", "live"),
  force = FALSE,
  write_cache = TRUE
) {
  refresh <- rlang::arg_match(refresh)
  org_lifestages <- sort(unique(stats::na.omit(as.character(org_lifestages))))

  seed <- .eco_lifestage_load_seed_cache(
    ecotox_release = ecotox_release,
    refresh = refresh,
    force = force
  )

  cache_rows <- seed$seed_cache |>
    dplyr::filter(.data$org_lifestage %in% org_lifestages)

  missing_terms <- setdiff(org_lifestages, unique(cache_rows$org_lifestage))
  strict_seed <- seed$cache_source %in% c("cache", "baseline") && refresh %in% c("cache", "baseline") && !isTRUE(force)

  if (length(missing_terms) > 0 && identical(refresh, "live")) {
    cache_rows <- purrr::map_dfr(
      org_lifestages,
      .eco_lifestage_resolve_term,
      ecotox_release = ecotox_release
    )
  } else if (length(missing_terms) > 0 && strict_seed) {
    cli::cli_abort(c(
      "Lifestage {.val {seed$cache_source}} is incomplete for release {.val {ecotox_release}}.",
      "x" = "Missing term(s): {missing_terms}."
    ))
  } else if (length(missing_terms) > 0) {
    live_rows <- purrr::map_dfr(
      missing_terms,
      .eco_lifestage_resolve_term,
      ecotox_release = ecotox_release
    )
    cache_rows <- dplyr::bind_rows(cache_rows, live_rows)
  }

  cache_rows <- cache_rows |>
    dplyr::arrange(.data$org_lifestage, .data$candidate_rank)

  # -- Audit coverage gate (D-10): warn for unclassified unresolved terms ------
  audit_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_audit.csv",
    package = "ComptoxR"
  )
  if (!nzchar(audit_path)) {
    audit_path <- file.path("inst", "extdata", "ecotox", "lifestage_audit.csv")
  }
  if (nzchar(audit_path) && file.exists(audit_path)) {
    audit <- readr::read_csv(audit_path, show_col_types = FALSE)
    unresolved_terms <- cache_rows |>
      dplyr::filter(.data$source_match_status == "unresolved") |>
      dplyr::pull(.data$org_lifestage) |>
      unique()
    unclassified <- setdiff(unresolved_terms, audit$org_lifestage)
    if (length(unclassified) > 0) {
      cli::cli_warn(c(
        "{length(unclassified)} unresolved term(s) not found in lifestage audit CSV.",
        "i" = "Terms: {.val {unclassified}}",
        "i" = "Edit {.path {audit_path}} to classify these terms."
      ))
    }
  }

  if (isTRUE(write_cache)) {
    .eco_lifestage_cache_write(cache_rows, ecotox_release)
  }

  resolved <- cache_rows |>
    dplyr::filter(.data$source_match_status == "resolved") |>
    dplyr::arrange(.data$org_lifestage, .data$candidate_rank) |>
    dplyr::group_by(.data$org_lifestage) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    .eco_lifestage_derive_fields()

  needs_derivation <- resolved |>
    dplyr::filter(is.na(.data$harmonized_life_stage) | is.na(.data$derivation_source)) |>
    dplyr::transmute(
      org_lifestage = .data$org_lifestage,
      candidate_source_ontology = .data$source_ontology,
      candidate_source_term_id = .data$source_term_id,
      candidate_source_term_label = .data$source_term_label,
      candidate_score = .data$candidate_score,
      candidate_reason = dplyr::coalesce(.data$candidate_reason, "resolved_missing_derivation"),
      source_provider = .data$source_provider,
      ecotox_release = .data$ecotox_release,
      review_status = "needs_derivation"
    )

  dictionary <- resolved |>
    dplyr::filter(!is.na(.data$harmonized_life_stage), !is.na(.data$derivation_source)) |>
    dplyr::transmute(
      org_lifestage = .data$org_lifestage,
      source_ontology = .data$source_ontology,
      source_term_id = .data$source_term_id,
      source_term_label = .data$source_term_label,
      source_term_definition = .data$source_term_definition,
      source_provider = .data$source_provider,
      source_match_method = .data$source_match_method,
      source_match_status = .data$source_match_status,
      source_release = .data$source_release,
      ecotox_release = .data$ecotox_release,
      harmonized_life_stage = .data$harmonized_life_stage,
      reproductive_stage = .data$reproductive_stage,
      derivation_source = .data$derivation_source
    ) |>
    dplyr::arrange(.data$org_lifestage)

  review <- dplyr::bind_rows(
    .eco_lifestage_review_from_cache(cache_rows),
    needs_derivation
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$org_lifestage, dplyr::desc(.data$candidate_score), .data$candidate_source_ontology)

  list(
    cache = dplyr::bind_rows(.eco_lifestage_cache_schema(), cache_rows),
    dictionary = dplyr::bind_rows(.eco_lifestage_dictionary_schema(), dictionary),
    review = dplyr::bind_rows(.eco_lifestage_review_schema(), review),
    refresh_mode = refresh
  )
}

#' Patch ECOTOX lifestage tables in place
#' @param db_path Path to the installed ECOTOX DuckDB file.
#' @param refresh Lifestage refresh mode.
#' @param force Fallback to {.code refresh = "auto"} when strict cache or
#'   baseline inputs are unavailable?
#' @return Invisibly, patch metadata.
#' @keywords internal
#' @noRd
.eco_patch_lifestage <- function(
  db_path = eco_path(),
  refresh = c("auto", "cache", "baseline", "live"),
  force = FALSE
) {
  refresh <- rlang::arg_match(refresh)

  if (!file.exists(db_path)) {
    cli::cli_abort("ECOTOX database not found at {.path {db_path}}.")
  }

  .eco_close_con()

  con <- tryCatch(
    DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE),
    error = function(e) {
      cli::cli_abort(c(
        "Unable to open ECOTOX database read-write.",
        "x" = conditionMessage(e)
      ))
    }
  )

  on.exit(
    {
      if (DBI::dbIsValid(con)) {
        DBI::dbDisconnect(con, shutdown = TRUE)
      }
      .eco_close_con()
    },
    add = TRUE
  )

  if (!DBI::dbExistsTable(con, "_metadata")) {
    cli::cli_abort("Missing {.code _metadata}; cannot patch lifestage tables.")
  }

  metadata <- DBI::dbReadTable(con, "_metadata")
  if (!all(c("key", "value") %in% names(metadata))) {
    cli::cli_abort("Invalid {.code _metadata} schema; expected {.field key} and {.field value}.")
  }

  ecotox_release <- metadata$value[metadata$key == "ecotox_release"][1]
  if (is.na(ecotox_release) || !nzchar(ecotox_release)) {
    cli::cli_abort("Installed ECOTOX database is missing {.field ecotox_release} metadata.")
  }

  if (!DBI::dbExistsTable(con, "lifestage_codes")) {
    cli::cli_abort("Missing {.code lifestage_codes}; cannot patch lifestage tables.")
  }

  if (!"description" %in% DBI::dbListFields(con, "lifestage_codes")) {
    cli::cli_abort("Missing {.code lifestage_codes.description}; cannot patch lifestage tables.")
  }

  org_lifestages <- DBI::dbGetQuery(
    con,
    "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
  )$description

  materialized <- .eco_lifestage_materialize_tables(
    org_lifestages = org_lifestages,
    ecotox_release = ecotox_release,
    refresh = refresh,
    force = force,
    write_cache = TRUE
  )

  DBI::dbWriteTable(con, "lifestage_dictionary", materialized$dictionary, overwrite = TRUE)
  DBI::dbWriteTable(con, "lifestage_review", materialized$review, overwrite = TRUE)

  patch_rows <- tibble::tibble(
    key = c(
      "lifestage_patch_applied_at",
      "lifestage_patch_release",
      "lifestage_patch_method",
      "lifestage_patch_version"
    ),
    value = c(
      format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      ecotox_release,
      materialized$refresh_mode,
      as.character(utils::packageVersion("ComptoxR"))
    )
  )

  metadata <- tibble::as_tibble(metadata) |>
    dplyr::filter(!.data$key %in% patch_rows$key) |>
    dplyr::bind_rows(patch_rows)

  DBI::dbWriteTable(con, "_metadata", metadata, overwrite = TRUE)

  if (nrow(materialized$review) > 0) {
    cli::cli_alert_warning(
      "{nrow(materialized$review)} lifestage row(s) remain quarantined in {.code lifestage_review}."
    )
  }

  invisible(list(
    db_path = db_path,
    ecotox_release = ecotox_release,
    dictionary_rows = nrow(materialized$dictionary),
    review_rows = nrow(materialized$review),
    refresh_mode = materialized$refresh_mode
  ))
}
