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
.eco_lifestage_load_seed_cache <- function(ecotox_release, refresh = c("auto", "cache", "baseline", "live"), force = FALSE) {
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
    baseline_matches <- identical(baseline_releases, ecotox_release)
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

  payload <- httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
    httr2::req_body_form(query = query) |>
    httr2::req_headers(Accept = "application/sparql-results+json") |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON(simplifyDataFrame = TRUE)

  bindings <- payload$results$bindings
  if (is.null(bindings) || nrow(bindings) == 0) {
    cli::cli_abort("NVS S11 lookup returned no concepts.")
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
.eco_lifestage_query_ols4 <- function(term, ontology = c("UBERON", "PO")) {
  ontology <- rlang::arg_match(ontology)

  response <- httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
    httr2::req_url_query(
      q = term,
      ontology = tolower(ontology),
      rows = 25
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON(simplifyDataFrame = TRUE)

  docs <- response$response$docs
  if (is.null(docs) || is.null(nrow(docs)) || nrow(docs) == 0) {
    return(tibble::tibble())
  }

  tibble::tibble(
    source_provider = "OLS4",
    source_ontology = toupper(ontology),
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
    dplyr::filter(!is.na(.data$source_term_id), !is.na(.data$source_term_label))
}

#' @keywords internal
.eco_lifestage_query_nvs <- function(term) {
  index <- .eco_lifestage_nvs_index()
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
    return(.eco_lifestage_cache_schema() |>
      dplyr::add_row(
        org_lifestage = org_lifestage,
        source_match_method = "provider_rank",
        source_match_status = "unresolved",
        candidate_rank = 1L,
        candidate_score = 0,
        candidate_reason = "no_provider_candidates",
        ecotox_release = NA_character_
      ))
  }

  candidates <- tibble::as_tibble(candidates) |>
    dplyr::distinct(.data$source_provider, .data$source_ontology, .data$source_term_id, .keep_all = TRUE)

  ranked <- purrr::pmap_dfr(
    candidates,
    function(source_provider,
             source_ontology,
             source_term_id,
             source_term_label,
             source_term_definition,
             candidate_aliases,
             source_release,
             source_match_method) {
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
    dplyr::arrange(dplyr::desc(.data$candidate_score), .data$source_ontology, .data$source_term_id) |>
    dplyr::mutate(candidate_rank = dplyr::row_number())

  top_score <- ranked$candidate_score[[1]]
  accepted <- ranked |>
    dplyr::filter(.data$candidate_score >= 75)

  if (!nrow(accepted)) {
    return(.eco_lifestage_cache_schema() |>
      dplyr::add_row(
        org_lifestage = org_lifestage,
        source_match_method = "provider_rank",
        source_match_status = "unresolved",
        candidate_rank = 1L,
        candidate_score = 0,
        candidate_reason = "no_candidate_ge75"
      ))
  }

  resolved <- top_score >= 90 && sum(ranked$candidate_score == top_score) == 1
  status <- if (resolved) "resolved" else "ambiguous"

  output <- if (resolved) {
    ranked |>
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
  candidates <- dplyr::bind_rows(
    .eco_lifestage_query_ols4(org_lifestage, "UBERON"),
    .eco_lifestage_query_ols4(org_lifestage, "PO"),
    .eco_lifestage_query_nvs(org_lifestage)
  )

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
  derivation_map <- .eco_lifestage_derivation_map()

  resolved_rows |>
    dplyr::left_join(
      derivation_map,
      by = c("source_ontology", "source_term_id")
    )
}

#' @keywords internal
.eco_lifestage_materialize_tables <- function(org_lifestages,
                                              ecotox_release,
                                              refresh = c("auto", "cache", "baseline", "live"),
                                              force = FALSE,
                                              write_cache = TRUE) {
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
  strict_seed <- seed$cache_source %in% c("cache", "baseline") && refresh %in% c("cache", "baseline")

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
.eco_patch_lifestage <- function(db_path = eco_path(),
                                 refresh = c("auto", "cache", "baseline", "live"),
                                 force = FALSE) {
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

  on.exit({
    if (DBI::dbIsValid(con)) {
      DBI::dbDisconnect(con, shutdown = TRUE)
    }
    .eco_close_con()
  }, add = TRUE)

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
