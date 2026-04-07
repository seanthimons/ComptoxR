# PubChem property name allowlist -------------------------------------------

# All valid PubChem computed property names (prevents path injection)
.pubchem_valid_properties <- c(
  "MolecularFormula", "MolecularWeight", "CanonicalSMILES", "IsomericSMILES",
  "InChI", "InChIKey", "IUPACName", "XLogP", "ExactMass", "MonoisotopicMass",
  "TPSA", "Complexity", "Charge", "HBondDonorCount", "HBondAcceptorCount",
  "RotatableBondCount", "HeavyAtomCount", "IsotopeAtomCount", "AtomStereoCount",
  "DefinedAtomStereoCount", "UndefinedAtomStereoCount", "BondStereoCount",
  "DefinedBondStereoCount", "UndefinedBondStereoCount", "CovalentUnitCount",
  "Volume3D", "XStericQuadrupole3D", "YStericQuadrupole3D", "ZStericQuadrupole3D",
  "FeatureCount3D", "FeatureAcceptorCount3D", "FeatureDonorCount3D",
  "FeatureAnionCount3D", "FeatureCationCount3D", "FeatureRingCount3D",
  "FeatureHydrophobeCount3D", "ConformerModelRMSD3D", "EffectiveRotorCount3D",
  "ConformerCount3D", "Fingerprint2D"
)

# Default property set for pubchem_properties()
.pubchem_default_properties <- c(
  "MolecularFormula", "MolecularWeight", "CanonicalSMILES", "InChI", "InChIKey",
  "XLogP", "TPSA", "HBondDonorCount", "HBondAcceptorCount", "Complexity",
  "ExactMass", "MonoisotopicMass", "HeavyAtomCount"
)

#' Fetch computed properties from PubChem
#'
#' Retrieve computed physico-chemical properties for one or more PubChem
#' Compound IDs (CIDs) via the PUG REST API.
#'
#' @param cid Integer or character vector of PubChem CIDs. Does NOT accept
#'   compound names or DTXSIDs — use [pubchem_search()] first to resolve CIDs.
#' @param properties Character vector of property names to retrieve. If `NULL`
#'   (default), returns 13 core properties: MolecularFormula, MolecularWeight,
#'   CanonicalSMILES, InChI, InChIKey, XLogP, TPSA, HBondDonorCount,
#'   HBondAcceptorCount, Complexity, ExactMass, MonoisotopicMass, HeavyAtomCount.
#' @param cache Logical. If `TRUE` (default), results are cached in the session
#'   environment keyed by CID and property set, so repeated calls are instant.
#'
#' @return A tibble with one row per CID and columns for each requested property
#'   plus a `CID` column. Returns an empty tibble if no results are found.
#'
#' @details
#' Property names are validated against PubChem's documented allowlist before
#' the request is made. Invalid property names cause an immediate error.
#'
#' For multiple CIDs, requests are batched at 100 CIDs per POST request
#' (PubChem's documented limit for list-based requests).
#'
#' @seealso [pubchem_search()] to find CIDs by name/structure,
#'   [ct_chemical_property_search()] for CompTox Dashboard properties.
#'
#' @examples
#' \dontrun{
#' # Default properties for aspirin
#' pubchem_properties(2244)
#'
#' # Specific properties for multiple CIDs
#' pubchem_properties(c(2244, 6623), properties = c("MolecularWeight", "XLogP"))
#' }
#'
#' @export
pubchem_properties <- function(cid, properties = NULL, cache = TRUE) {
  if (is.null(properties)) {
    properties <- .pubchem_default_properties
  }

  # Allowlist validation — prevents path injection
  invalid <- setdiff(properties, .pubchem_valid_properties)
  if (length(invalid) > 0) {
    cli::cli_abort("Invalid PubChem property name{?s}: {.val {invalid}}")
  }

  cid <- as.integer(cid)
  cid <- cid[!is.na(cid)]
  if (length(cid) == 0) {
    cli::cli_abort("{.arg cid} must contain at least one valid integer CID.")
  }

  props_csv <- paste(sort(properties), collapse = ",")

  # --- Session cache: per-CID, keyed by property set ---
  if (cache) {
    if (!exists("pubchem_props_cache", envir = .ComptoxREnv)) {
      .ComptoxREnv$pubchem_props_cache <- new.env(hash = TRUE, parent = emptyenv())
    }
    cache_env <- .ComptoxREnv$pubchem_props_cache

    cached_rows <- list()
    uncached_cids <- integer(0)
    for (id in cid) {
      key <- paste0(id, "|", props_csv)
      if (exists(key, envir = cache_env)) {
        cached_rows <- c(cached_rows, list(get(key, envir = cache_env)))
      } else {
        uncached_cids <- c(uncached_cids, id)
      }
    }

    if (length(uncached_cids) == 0) {
      return(dplyr::bind_rows(cached_rows))
    }
  } else {
    uncached_cids <- cid
    cached_rows <- list()
  }

  # --- Fetch uncached CIDs ---
  if (length(uncached_cids) > 1) {
    cid_batches <- split(uncached_cids, ceiling(seq_along(uncached_cids) / 100))
    results <- purrr::map(cid_batches, function(batch) {
      generic_pubchem_request(
        namespace = "cid",
        operation = paste0("property/", props_csv),
        method = "POST",
        body = list(cid = paste(batch, collapse = ",")),
        pluck_path = c("PropertyTable", "Properties"),
        tidy = TRUE
      )
    })
    fresh <- dplyr::bind_rows(purrr::compact(results))
  } else {
    fresh <- generic_pubchem_request(
      query = uncached_cids,
      namespace = "cid",
      operation = paste0("property/", props_csv),
      pluck_path = c("PropertyTable", "Properties"),
      tidy = TRUE
    )
  }

  # --- Store each row in cache ---
  if (cache && nrow(fresh) > 0) {
    cache_env <- .ComptoxREnv$pubchem_props_cache
    for (i in seq_len(nrow(fresh))) {
      row <- fresh[i, , drop = FALSE]
      key <- paste0(row$CID, "|", props_csv)
      assign(key, row, envir = cache_env)
    }
  }

  dplyr::bind_rows(cached_rows, fresh)
}
