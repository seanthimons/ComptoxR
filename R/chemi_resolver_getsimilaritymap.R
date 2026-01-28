#' Resolver Getsimilaritymap
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param id_type Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param section Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritymap(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_getsimilaritymap <- function(query, id_type = "AnyId", section = NULL) {
  # Resolve identifiers to Chemical objects
	resolved <- tryCatch(
    chemi_resolver_lookup(query = query, id_type = id_type),
    error = function(e) {
      tryCatch(
        chemi_resolver_lookup(query = query),
        error = function(e2) stop("chemi_resolver_lookup failed: ", e2$message)
      )
    }
  )

  if (nrow(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved tibble to Chemical object format
  # Map column names: dtxsid -> sid, etc.
  chemicals <- purrr::map(seq_len(nrow(resolved)), function(i) {
    row <- resolved[i, ]
    list(
      sid = row$dtxsid,
      smiles = row$smiles,
      casrn = row$casrn,
      inchi = row$inchi,
      inchiKey = row$inchiKey,
      name = row$name,
      mol = row$mol
    )
  })

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(section)) extra_options$section <- section

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/getsimilaritymap",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


