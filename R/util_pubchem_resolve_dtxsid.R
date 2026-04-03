# CAS checksum validator (internal) -----------------------------------------

# Validate a CAS Registry Number check digit.
# Returns TRUE if the check digit is correct, FALSE otherwise.
# @param cas Character string in format "NNNNNNN-NN-N"
# @noRd
is_valid_cas <- function(cas) {
  parts <- strsplit(cas, "-")[[1]]
  if (length(parts) != 3) return(FALSE)
  digits <- paste0(parts[1], parts[2])
  digit_vec <- as.integer(strsplit(digits, "")[[1]])
  if (any(is.na(digit_vec))) return(FALSE)
  n <- length(digit_vec)
  weighted_sum <- sum(digit_vec * seq(n, 1))
  check_digit <- weighted_sum %% 10
  check_digit == as.integer(parts[3])
}

#' Resolve PubChem CIDs to CompTox DTXSIDs
#'
#' Extracts DTXSIDs from PubChem synonym lists, with a CAS-based CompTox
#' fallback for compounds not directly annotated with DTXSIDs.
#'
#' @param cid Integer or character vector of PubChem CIDs.
#' @param cache Logical. If `TRUE` (default), results are cached in the session
#'   environment (`.ComptoxREnv$pubchem_cid_map`) to avoid redundant API calls.
#'
#' @return A named character vector where names are CIDs (as character) and
#'   values are DTXSID strings. `NA_character_` for CIDs that could not be
#'   resolved.
#'
#' @details
#' Resolution uses a two-step approach:
#'
#' 1. **PubChem synonyms**: Fetches synonym lists via [pubchem_synonyms()] and
#'    searches for DTXSID patterns using regex (`\\bDTXSID\\d+\\b`).
#'
#' 2. **CAS fallback**: For unresolved CIDs, extracts CAS numbers from the
#'    synonym list, validates their check digits, and performs a single batched
#'    lookup against the CompTox Dashboard via [ct_chemical_search_equal_bulk()].
#'    This step requires a CompTox API key (`ctx_api_key`).
#'
#' Session caching stores resolved CID-to-DTXSID mappings so repeated calls
#' for the same CIDs are instant.
#'
#' @seealso [pubchem_synonyms()] for raw synonym lists,
#'   [chemi_resolver_pubchem_section()] for EPA's curated PubChem resolver,
#'   [ct_chemical_search_equal_bulk()] for CompTox batch search.
#'
#' @examples
#' \dontrun{
#' # Single CID (aspirin)
#' util_pubchem_resolve_dtxsid(2244)
#'
#' # Multiple CIDs
#' util_pubchem_resolve_dtxsid(c(2244, 6623))
#'
#' # Disable session cache
#' util_pubchem_resolve_dtxsid(2244, cache = FALSE)
#' }
#'
#' @export
util_pubchem_resolve_dtxsid <- function(cid, cache = TRUE) {
  cid <- as.integer(cid)
  cid <- cid[!is.na(cid)]
  if (length(cid) == 0) {
    cli::cli_abort("{.arg cid} must contain at least one valid integer CID.")
  }

  cid_chr <- as.character(cid)

  # --- Session cache check ---
  if (cache) {
    if (!exists("pubchem_cid_map", envir = .ComptoxREnv)) {
      .ComptoxREnv$pubchem_cid_map <- new.env(hash = TRUE, parent = emptyenv())
    }

    cached <- purrr::map_chr(cid_chr, function(c) {
      if (exists(c, envir = .ComptoxREnv$pubchem_cid_map)) {
        get(c, envir = .ComptoxREnv$pubchem_cid_map)
      } else {
        NA_character_
      }
    })

    uncached_idx <- which(is.na(cached))
    if (length(uncached_idx) == 0) {
      return(stats::setNames(cached, cid_chr))
    }
    uncached_cids <- cid[uncached_idx]
  } else {
    cached <- rep(NA_character_, length(cid))
    uncached_idx <- seq_along(cid)
    uncached_cids <- cid
  }

  # --- Step 1: Bulk synonym fetch ---
  syns <- pubchem_synonyms(uncached_cids, tidy = FALSE)

  resolved <- purrr::map_chr(syns, function(info) {
    # Step 2: DTXSID regex (word-boundary anchored)
    dtxsid_pattern <- "\\bDTXSID\\d+\\b"
    synonyms_to_search <- utils::head(info$Synonym, 500)
    matches <- grep(dtxsid_pattern, synonyms_to_search, value = TRUE)

    if (length(matches) == 1) return(matches)
    if (length(matches) > 1) {
      cli::cli_warn("Multiple DTXSIDs for CID {info$CID}: {.val {matches}}. Using first.")
      return(matches[1])
    }
    NA_character_
  })

  # --- Step 3: Batch CAS fallback for unresolved CIDs ---
  unresolved_idx <- which(is.na(resolved))
  if (length(unresolved_idx) > 0) {
    cas_candidates <- purrr::map_chr(syns[unresolved_idx], function(info) {
      cas_pattern <- "^\\d{1,7}-\\d{2}-\\d$"
      cas_matches <- grep(cas_pattern, info$Synonym, value = TRUE)
      valid <- Filter(is_valid_cas, cas_matches)
      if (length(valid) > 0) valid[1] else NA_character_
    })

    valid_cas <- cas_candidates[!is.na(cas_candidates)]
    if (length(valid_cas) > 0) {
      tryCatch({
        ct_results <- ct_chemical_search_equal_bulk(valid_cas)
        if (!is.null(ct_results) && nrow(ct_results) > 0) {
          # Extract DTXSID and CASRN columns
          if ("dtxsid" %in% names(ct_results) && "casrn" %in% names(ct_results)) {
            cas_to_dtxsid <- stats::setNames(ct_results$dtxsid, ct_results$casrn)
            for (i in seq_along(unresolved_idx)) {
              cas <- cas_candidates[i]
              if (!is.na(cas) && cas %in% names(cas_to_dtxsid)) {
                resolved[unresolved_idx[i]] <- cas_to_dtxsid[[cas]]
              }
            }
          }
        }
      }, error = function(e) {
        cli::cli_warn("CompTox CAS fallback failed: {e$message}")
      })
    }
  }

  # --- Cache results ---
  if (cache) {
    purrr::walk2(as.character(uncached_cids), resolved, function(c, dtxsid) {
      assign(c, dtxsid %||% NA_character_, envir = .ComptoxREnv$pubchem_cid_map)
    })
  }

  # --- Merge cached + newly resolved ---
  cached[uncached_idx] <- resolved
  final <- stats::setNames(cached, cid_chr)

  # Warn for unresolved
  still_na <- sum(is.na(final))
  if (still_na > 0) {
    cli::cli_warn("{still_na} CID{?s} could not be resolved to DTXSID{?s}")
  }

  final
}
