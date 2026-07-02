#' Stdizer Chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param full Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_chemicals(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_stdizer_chemicals <- function(query, idType = "AnyId", options = NULL, full = NULL) {
  # Resolve identifiers to Chemical objects via bulk POST endpoint
  resolved <- tryCatch(
    chemi_resolver_lookup_bulk(ids = query, idsType = idType, tidy = FALSE),
    error = function(e) {
      tryCatch(
        chemi_resolver_lookup_bulk(ids = query, tidy = FALSE),
        error = function(e2) stop("chemi_resolver_lookup_bulk failed: ", e2$message)
      )
    }
  )

  # Keep only successfully resolved entries
  resolved <- purrr::keep(resolved, function(item) identical(item$result, "FOUND"))

  if (length(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved list to ChemicalRecord format expected by endpoint
  chemicals <- purrr::map(resolved, function(item) {
    chem <- item$chemical
    list(
      chemical = list(
        sid = chem$chemId %||% chem$sid,
        smiles = chem$canonicalSmiles %||% chem$smiles,
        casrn = chem$casrn,
        inchi = chem$inchi,
        inchiKey = chem$inchiKey,
        name = chem$name
      )
    )
  })

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) {
    extra_options$options <- options
  }
  if (!is.null(full)) {
    extra_options$full <- full
  }

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "stdizer/chemicals",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
