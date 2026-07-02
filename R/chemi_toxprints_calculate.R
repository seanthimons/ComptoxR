#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param labels Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate(smiles = "DTXSID7020182")
#' }
chemi_toxprints_calculate <- function(smiles, labels = FALSE, profile = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(labels)) {
    options[['labels']] <- labels
  }
  if (!is.null(profile)) {
    options[['profile']] <- profile
  }
  result <- generic_request(
    endpoint = "toxprints/calculate",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param labels Optional parameter
#' @param options Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_toxprints_calculate_bulk <- function(query, idType = "AnyId", labels = NULL, options = NULL) {
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
  if (!is.null(labels)) {
    extra_options$labels <- labels
  }
  if (!is.null(options)) {
    extra_options$options <- options
  }

  result <- generic_chemi_request(
    query = NULL,
    endpoint = "toxprints/calculate",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
