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

#' Flatten similarity-map Chemical records
#'
#' The resolver schema expects a flat Chemical array rather than the nested
#' ChemicalRecord payload used by other bulk endpoints.
#'
#' @param data Hook data after `resolve_query_to_chemical_records()`.
#' @return Hook data with a flat `params$chemicals` list.
#' @noRd
flatten_similarity_map_chemicals <- function(data) {
  if (isTRUE(data$skip_request)) {
    return(data)
  }

  data$params$chemicals <- purrr::map(data$params$chemicals, "chemical")
  data
}

similarity_map_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NA_character_)
  }

  as.character(x[[1]])
}

similarity_map_names <- function(order) {
  chemicals <- purrr::map(order, ~ purrr::pluck(.x, "chemical", .default = list()))
  molecule_names <- purrr::map_chr(chemicals, ~ similarity_map_scalar(.x$name))
  dtxsids <- purrr::map_chr(
    chemicals,
    ~ similarity_map_scalar(.x$sid %||% .x$dtxsid %||% .x$chemId)
  )

  if (any(!is.na(dtxsids))) {
    return(tibble::tibble(dtxsid = dtxsids, name = molecule_names))
  }

  tibble::tibble(name = molecule_names)
}

similarity_map_value <- function(cell) {
  if (!is.list(cell)) {
    return(as.numeric(cell))
  }
  if ("value" %in% names(cell)) {
    return(as.numeric(cell$value))
  }
  if ("sim" %in% names(cell)) {
    return(as.numeric(cell$sim))
  }

  cell <- cell[setdiff(names(cell), "cl")]
  if (length(cell) == 0) {
    return(NA_real_)
  }

  as.numeric(unlist(cell, use.names = FALSE)[[1]])
}

similarity_map_cluster <- function(result, hclust_method) {
  if (is.null(result) || length(result) == 0) {
    cli::cli_alert_danger("No data found!")
    return(NULL)
  }

  molecule_names <- similarity_map_names(
    purrr::pluck(result, "order", .default = list())
  )
  similarity <- purrr::map(
    purrr::pluck(result, "similarity", .default = list()),
    ~ purrr::map_dbl(.x, similarity_map_value)
  )
  if (nrow(molecule_names) == 0 || length(similarity) == 0) {
    cli::cli_alert_danger("No data found!")
    return(NULL)
  }

  molecule_labels <- molecule_names$name
  if ("dtxsid" %in% names(molecule_names)) {
    has_dtxsid <- !is.na(molecule_names$dtxsid) & nzchar(molecule_names$dtxsid)
    molecule_labels[has_dtxsid] <- molecule_names$dtxsid[has_dtxsid]
  }

  similarity <- matrix(
    unlist(similarity),
    nrow = length(similarity),
    byrow = TRUE,
    dimnames = list(molecule_labels, molecule_labels)
  )

  list(
    mol_names = molecule_names,
    similarity = similarity,
    hc = stats::hclust(stats::as.dist(1 - similarity), method = hclust_method)
  )
}

similarity_map_long <- function(cluster) {
  similarity <- cluster$similarity
  row_index <- rep(seq_len(nrow(similarity)), each = ncol(similarity))
  column_index <- rep(seq_len(ncol(similarity)), times = nrow(similarity))
  keep <- row_index != column_index

  tibble::tibble(
    parent = rownames(similarity)[row_index[keep]],
    child = colnames(similarity)[column_index[keep]],
    value = as.vector(t(similarity))[keep]
  )
}

#' Format a chemical similarity map
#'
#' @param data Post-response hook data containing the raw result, output format,
#'   and hierarchical clustering method.
#' @return A cluster list, long-form tibble, or the raw API result.
#' @noRd
format_similarity_map_result <- function(data) {
  format <- match.arg(
    data$params$format %||% c("cluster", "long", "raw"),
    c("cluster", "long", "raw")
  )
  if (identical(format, "raw")) {
    return(data$result)
  }

  cluster <- similarity_map_cluster(
    data$result,
    hclust_method = data$params$hclust_method %||% "complete"
  )
  if (identical(format, "long") && !is.null(cluster)) {
    return(similarity_map_long(cluster))
  }

  cluster
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
