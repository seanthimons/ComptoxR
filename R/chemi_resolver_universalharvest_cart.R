#' Resolver Universalharvest Cart
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param info Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_universalharvest_cart(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_universalharvest_cart <- function(query, idType = "AnyId", info = NULL) {
  # Resolve identifiers to Chemical objects
	resolved <- tryCatch(
    chemi_resolver_lookup(query = query, idType = idType),
    error = function(e) {
      tryCatch(
        chemi_resolver_lookup(query = query),
        error = function(e2) stop("chemi_resolver_lookup failed: ", e2$message)
      )
    }
  )

  if (length(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved list to Chemical object format expected by endpoint
  chemicals <- purrr::map(resolved, function(chem) {
    list(
      sid = chem$dtxsid %||% chem$sid,
      smiles = chem$smiles,
      casrn = chem$casrn,
      inchi = chem$inchi,
      inchiKey = chem$inchiKey,
      name = chem$name,
      mol = chem$mol
    )
  })

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(info)) extra_options$info <- info

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/universalharvest_cart",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


