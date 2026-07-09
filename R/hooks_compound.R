# Compound Hook Primitives
# Hooks for compound/chemical operations

hook_first_non_null <- function(...) {
  values <- list(...)
  for (value in values) {
    if (!is.null(value)) {
      return(value)
    }
  }
  NULL
}

chemical_record_from_resolver_item <- function(item) {
  chem <- item$chemical
  if (is.null(chem)) {
    chem <- list()
  }

  list(
    chemical = list(
      sid = hook_first_non_null(chem$chemId, chem$sid),
      smiles = hook_first_non_null(chem$canonicalSmiles, chem$smiles),
      casrn = chem$casrn,
      inchi = chem$inchi,
      inchiKey = chem$inchiKey,
      name = chem$name
    )
  )
}

#' Resolve query identifiers to ChemicalRecord payloads
#'
#' Pre-request hook for bulk ChemicalRecord endpoints. Resolves `query` with the
#' resolver service, filters to FOUND records, maps them to the nested payload
#' expected by cheminformatics POST endpoints, and sets `query` to NULL so the
#' pre-resolved `chemicals` payload is used.
#'
#' @param data Hook data structure with list(params = list(query = ..., idType = ...))
#' @return Modified hook data with params$chemicals, or a short-circuit result
#' @noRd
resolve_query_to_chemical_records <- function(data) {
  query <- data$params$query
  id_type <- hook_first_non_null(data$params$idType, "AnyId")

  resolved <- tryCatch(
    chemi_resolver_lookup_bulk(ids = query, idsType = id_type, tidy = FALSE),
    error = function(e) {
      tryCatch(
        chemi_resolver_lookup_bulk(ids = query, tidy = FALSE),
        error = function(e2) {
          cli::cli_abort("chemi_resolver_lookup_bulk failed: {e2$message}")
        }
      )
    }
  )

  resolved <- purrr::keep(resolved, function(item) identical(item$result, "FOUND"))

  if (length(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    data$skip_request <- TRUE
    data$result <- NULL
    return(data)
  }

  data$params$chemicals <- purrr::map(resolved, chemical_record_from_resolver_item)
  data$params["query"] <- list(NULL)
  data
}

looks_like_smiles_identifier <- function(x) {
  if (length(x) != 1 || is.na(x) || !nzchar(x)) {
    return(FALSE)
  }

  x <- trimws(as.character(x))
  grepl("^DTXSID[A-Z0-9]+$", x, ignore.case = TRUE) ||
    grepl("^DTXCID[A-Z0-9]+$", x, ignore.case = TRUE) ||
    isTRUE(is_cas(x))
}

#' Resolve identifier-like smiles inputs to canonical SMILES
#'
#' Pre-request hook for descriptor endpoints whose scalar `smiles` parameter is
#' often called with DTXSID/DTXCID/CASRN examples.
#'
#' @param data Hook data structure with list(params = list(smiles = ...))
#' @return Modified data with params$smiles replaced by canonical SMILES when needed
#' @noRd
resolve_smiles_identifier <- function(data) {
  smiles <- data$params$smiles

  if (!looks_like_smiles_identifier(smiles)) {
    return(data)
  }

  identifier <- trimws(as.character(smiles))
  resolved <- tryCatch(
    chemi_resolver_lookup_bulk(ids = identifier, idsType = "AnyId", tidy = FALSE),
    error = function(e) {
      cli::cli_abort("Unable to resolve chemical identifier {.val {identifier}} to SMILES: {e$message}")
    }
  )

  found <- purrr::keep(resolved, function(item) identical(item$result, "FOUND"))
  canonical <- NULL
  if (length(found) > 0) {
    chem <- found[[1]]$chemical
    canonical <- hook_first_non_null(chem$canonicalSmiles, chem$smiles)
  }

  if (is.null(canonical) || length(canonical) == 0 || is.na(canonical[[1]]) || !nzchar(canonical[[1]])) {
    cli::cli_abort("Unable to resolve chemical identifier {.val {identifier}} to canonical SMILES")
  }

  data$params$smiles <- canonical[[1]]
  data
}
