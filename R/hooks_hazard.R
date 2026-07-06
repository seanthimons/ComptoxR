# Hazard Hook Primitives
# Hooks for shaping Cheminformatics hazard responses

chemi_hazard_format_choices <- function() {
  c("compact", "tidy", "raw")
}

chemi_hazard_endpoint_order <- function() {
  c(
    "acuteMammalianOral",
    "acuteMammalianDermal",
    "acuteMammalianInhalation",
    "developmental",
    "reproductive",
    "endocrine",
    "genotoxicity",
    "carcinogenicity",
    "neurotoxicitySingle",
    "neurotoxicityRepeat",
    "systemicToxicitySingle",
    "systemicToxicityRepeat",
    "eyeIrritation",
    "skinIrritation",
    "skinSensitization",
    "acuteAquatic",
    "chronicAquatic",
    "persistence",
    "bioaccumulation",
    "exposure"
  )
}

chemi_hazard_tidy_columns <- function() {
  c(
    "dtxsid",
    "casrn",
    "name",
    "hazard_id",
    "hazard_name",
    "final_score",
    "display_score",
    "final_authority",
    "final_score_source",
    "record_name",
    "record_source",
    "record_source_original",
    "record_list_type",
    "record_score",
    "record_category",
    "hazard_code",
    "hazard_statement",
    "rationale",
    "route",
    "value_mass",
    "value_mass_units",
    "value_mass_operator",
    "value_active",
    "duration",
    "duration_units",
    "effect",
    "url",
    "long_ref",
    "test_organism",
    "test_type",
    "toxval_id",
    "record_cas"
  )
}

chemi_hazard_compact_columns <- function() {
  c("dtxsid", "casrn", "name", "n_hazards", chemi_hazard_endpoint_order())
}

chemi_hazard_scalar <- function(...) {
  values <- list(...)

  for (value in values) {
    if (is.null(value) || length(value) == 0) {
      next
    }

    if (is.list(value) && !is.data.frame(value)) {
      value <- unlist(value, recursive = TRUE, use.names = FALSE)
    }

    if (length(value) == 0) {
      next
    }

    value <- value[[1]]
    if (is.null(value) || length(value) == 0 || is.na(value)) {
      next
    }

    return(value)
  }

  NA
}

chemi_hazard_chr <- function(...) {
  value <- chemi_hazard_scalar(...)

  if (is.null(value) || length(value) == 0 || is.na(value)) {
    return(NA_character_)
  }

  as.character(value)
}

chemi_hazard_lgl <- function(...) {
  value <- chemi_hazard_scalar(...)

  if (is.null(value) || length(value) == 0 || is.na(value)) {
    return(NA)
  }

  if (is.logical(value)) {
    return(value)
  }

  if (is.numeric(value)) {
    return(as.logical(value))
  }

  value <- tolower(trimws(as.character(value)))
  if (value %in% c("true", "t", "yes", "y", "1")) {
    return(TRUE)
  }
  if (value %in% c("false", "f", "no", "n", "0")) {
    return(FALSE)
  }

  NA
}

chemi_hazard_empty_tidy <- function() {
  columns <- chemi_hazard_tidy_columns()
  typed <- stats::setNames(rep(list(character()), length(columns)), columns)
  typed$value_active <- logical()
  tibble::as_tibble(typed)
}

chemi_hazard_empty_compact <- function() {
  columns <- chemi_hazard_compact_columns()
  typed <- stats::setNames(rep(list(character()), length(columns)), columns)
  typed$n_hazards <- integer()
  tibble::as_tibble(typed)
}

chemi_hazard_is_chemical <- function(x) {
  is.list(x) &&
    !is.null(names(x)) &&
    "scores" %in% names(x) &&
    ("chemical" %in% names(x) || "chemicalId" %in% names(x))
}

chemi_hazard_collect_chemicals <- function(x) {
  if (is.null(x) || is.data.frame(x) || length(x) == 0) {
    return(list())
  }

  if (chemi_hazard_is_chemical(x)) {
    return(list(x))
  }

  if (is.list(x) && !is.null(names(x)) && "hazardChemicals" %in% names(x)) {
    return(chemi_hazard_collect_chemicals(x$hazardChemicals))
  }

  if (is.list(x)) {
    collected <- lapply(x, chemi_hazard_collect_chemicals)
    return(unlist(collected, recursive = FALSE, use.names = FALSE))
  }

  list()
}

chemi_hazard_normalize_chemicals <- function(result) {
  chemi_hazard_collect_chemicals(result)
}

chemi_hazard_as_scores <- function(scores) {
  if (is.null(scores) || length(scores) == 0) {
    return(list())
  }

  if (!is.list(scores)) {
    if (length(scores) == 1 && is.na(scores)) {
      return(list())
    }
    return(list())
  }

  if (is.list(scores) && !is.null(names(scores)) && any(c("hazardId", "finalScore") %in% names(scores))) {
    return(list(scores))
  }

  scores
}

chemi_hazard_as_records <- function(records) {
  if (is.null(records) || length(records) == 0) {
    return(list(NULL))
  }

  if (!is.list(records)) {
    return(list(NULL))
  }

  if (is.list(records) && !is.null(names(records)) && !any(vapply(records, is.list, logical(1)))) {
    return(list(records))
  }

  records
}

chemi_hazard_display_score <- function(final_score, final_authority) {
  if (length(final_score) == 0 || is.na(final_score)) {
    return(NA_character_)
  }

  final_score <- as.character(final_score)
  final_authority <- if (length(final_authority) == 0 || is.na(final_authority)) {
    NA_character_
  } else {
    as.character(final_authority)
  }

  if (identical(final_authority, "Authoritative")) {
    return(paste0("<b>", final_score, "</b>"))
  }

  if (identical(final_authority, "QSAR Model")) {
    return(paste0("<i>", final_score, "</i>"))
  }

  final_score
}

chemi_hazard_record_row <- function(chemical, score, record) {
  if (!is.list(chemical)) {
    chemical <- list()
  }
  if (!is.list(score)) {
    score <- list()
  }
  if (!is.list(record)) {
    record <- list()
  }

  final_score <- chemi_hazard_chr(score$finalScore)
  final_authority <- chemi_hazard_chr(score$finalAuthority)

  list(
    dtxsid = chemi_hazard_chr(chemical$chemical$sid, chemical$chemical$chemId, chemical$chemicalId),
    casrn = chemi_hazard_chr(chemical$chemical$casrn, chemical$chemical$CAS, chemical$chemical$cas),
    name = chemi_hazard_chr(chemical$chemical$name),
    hazard_id = chemi_hazard_chr(score$hazardId),
    hazard_name = chemi_hazard_chr(score$hazardName),
    final_score = final_score,
    display_score = chemi_hazard_display_score(final_score, final_authority),
    final_authority = final_authority,
    final_score_source = chemi_hazard_chr(score$finalScoreSource),
    record_name = chemi_hazard_chr(record$name),
    record_source = chemi_hazard_chr(record$source),
    record_source_original = chemi_hazard_chr(record$sourceOriginal),
    record_list_type = chemi_hazard_chr(record$listType),
    record_score = chemi_hazard_chr(record$score),
    record_category = chemi_hazard_chr(record$category),
    hazard_code = chemi_hazard_chr(record$hazardCode),
    hazard_statement = chemi_hazard_chr(record$hazardStatement),
    rationale = chemi_hazard_chr(record$rationale),
    route = chemi_hazard_chr(record$route),
    value_mass = chemi_hazard_chr(record$valueMass),
    value_mass_units = chemi_hazard_chr(record$valueMassUnits),
    value_mass_operator = chemi_hazard_chr(record$valueMassOperator),
    value_active = chemi_hazard_lgl(record$valueActive),
    duration = chemi_hazard_chr(record$duration),
    duration_units = chemi_hazard_chr(record$durationUnits),
    effect = chemi_hazard_chr(record$effect),
    url = chemi_hazard_chr(record$url),
    long_ref = chemi_hazard_chr(record$longRef),
    test_organism = chemi_hazard_chr(record$testOrganism),
    test_type = chemi_hazard_chr(record$testType),
    toxval_id = chemi_hazard_chr(record$toxvalID, record$toxvalId),
    record_cas = chemi_hazard_chr(record$CAS, record$cas)
  )
}

chemi_hazard_score_only_row <- function(chemical) {
  empty_score <- list()
  chemi_hazard_record_row(chemical, empty_score, NULL)
}

chemi_hazard_tidy_result <- function(result) {
  chemicals <- chemi_hazard_normalize_chemicals(result)
  if (length(chemicals) == 0) {
    return(chemi_hazard_empty_tidy())
  }

  rows <- list()
  row_index <- 0L

  for (chemical in chemicals) {
    scores <- chemi_hazard_as_scores(chemical$scores)
    if (length(scores) == 0) {
      row_index <- row_index + 1L
      rows[[row_index]] <- chemi_hazard_score_only_row(chemical)
      next
    }

    for (score in scores) {
      records <- chemi_hazard_as_records(score$records)

      for (record in records) {
        row_index <- row_index + 1L
        rows[[row_index]] <- chemi_hazard_record_row(chemical, score, record)
      }
    }
  }

  if (length(rows) == 0) {
    return(chemi_hazard_empty_tidy())
  }

  out <- dplyr::bind_rows(rows)
  out <- out[, chemi_hazard_tidy_columns(), drop = FALSE]
  tibble::as_tibble(out)
}

chemi_hazard_rank <- function(x, levels) {
  ranks <- match(as.character(x), levels)
  ranks[is.na(ranks)] <- length(levels) + 1L
  ranks
}

chemi_hazard_distinct_scores <- function(tidy) {
  if (nrow(tidy) == 0) {
    return(tidy)
  }

  score_cols <- c(
    "dtxsid",
    "casrn",
    "name",
    "hazard_id",
    "final_score",
    "display_score",
    "final_authority"
  )
  scores <- unique(tidy[, score_cols, drop = FALSE])
  scores$.hazard_rank <- chemi_hazard_rank(scores$hazard_id, chemi_hazard_endpoint_order())
  scores$.score_rank <- chemi_hazard_rank(scores$final_score, c("VH", "H", "M", "L", "I", "ND"))
  scores$.authority_rank <- chemi_hazard_rank(scores$final_authority, c("Authoritative", "Screening", "QSAR Model"))

  scores <- scores[
    order(scores$dtxsid, scores$.hazard_rank, scores$.score_rank, scores$.authority_rank),
    ,
    drop = FALSE
  ]
  keys <- paste(scores$dtxsid, scores$hazard_id, sep = "\r")
  scores <- scores[!duplicated(keys), , drop = FALSE]
  scores[, score_cols, drop = FALSE]
}

chemi_hazard_compact_result <- function(tidy) {
  if (nrow(tidy) == 0) {
    return(chemi_hazard_empty_compact())
  }

  endpoints <- chemi_hazard_endpoint_order()
  chemicals <- unique(tidy[, c("dtxsid", "casrn", "name"), drop = FALSE])
  scores <- chemi_hazard_distinct_scores(tidy)
  rows <- vector("list", nrow(chemicals))

  for (i in seq_len(nrow(chemicals))) {
    dtxsid <- chemicals$dtxsid[[i]]
    if (is.na(dtxsid)) {
      chemical_scores <- scores[is.na(scores$dtxsid), , drop = FALSE]
    } else {
      chemical_scores <- scores[!is.na(scores$dtxsid) & scores$dtxsid == dtxsid, , drop = FALSE]
    }

    endpoint_values <- stats::setNames(rep(list(NA_character_), length(endpoints)), endpoints)
    known_endpoint <- !is.na(chemical_scores$hazard_id) & chemical_scores$hazard_id %in% endpoints
    if (any(known_endpoint)) {
      for (j in which(known_endpoint)) {
        endpoint_values[[chemical_scores$hazard_id[[j]]]] <- chemical_scores$display_score[[j]]
      }
    }

    n_hazards <- sum(!is.na(chemical_scores$hazard_id))
    rows[[i]] <- c(
      list(
        dtxsid = chemicals$dtxsid[[i]],
        casrn = chemicals$casrn[[i]],
        name = chemicals$name[[i]],
        n_hazards = as.integer(n_hazards)
      ),
      endpoint_values
    )
  }

  out <- dplyr::bind_rows(rows)
  out <- out[, chemi_hazard_compact_columns(), drop = FALSE]
  tibble::as_tibble(out)
}

#' Format Cheminformatics hazard results
#'
#' Post-response hook for `chemi_hazard()` and `chemi_hazard_bulk()`.
#'
#' @param data Hook data structure with list(result = ..., params = list(format = ...))
#' @return Raw result, tidy long tibble, or compact wide tibble
#' @noRd
format_chemi_hazard_result <- function(data) {
  format <- data$params$format
  if (is.null(format)) {
    format <- chemi_hazard_format_choices()
  }
  format <- match.arg(format, choices = chemi_hazard_format_choices())

  if (identical(format, "raw")) {
    return(data$result)
  }

  tidy <- chemi_hazard_tidy_result(data$result)
  if (identical(format, "tidy")) {
    return(tidy)
  }

  chemi_hazard_compact_result(tidy)
}
