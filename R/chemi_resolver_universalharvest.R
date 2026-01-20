#' Resolver Universalharvest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request.info.keyName Required parameter
#' @param request.info.keyType Optional parameter
#' @param request.info.loadNames Optional parameter
#' @param request.info.loadCASRNs Optional parameter
#' @param request.info.loadDeletedCASRNs Optional parameter
#' @param request.info.loadInChIKeys Optional parameter
#' @param request.info.loadDTXSIDs Optional parameter
#' @param request.info.loadSMILESs Optional parameter
#' @param request.info.loadTotals Optional parameter
#' @param request.info.loadVendors Optional parameter
#' @param request.info.useResolver Optional parameter
#' @param request.info.usePubchem Optional parameter
#' @param request.info.useCommonchemistry Optional parameter
#' @param request.info.deepSearch Optional parameter
#' @param request.info.pubchem_headers Optional parameter
#' @param request.info.cc_headers Optional parameter
#' @param request.info.resolver_headers Optional parameter
#' @param request.info.keyChemIdType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId
#' @param request.chemicals Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_universalharvest(request.info.keyName = "DTXSID7020182")
#' }
chemi_resolver_universalharvest <- function(request.info.keyName, request.info.keyType = NULL, request.info.loadNames = NULL, request.info.loadCASRNs = NULL, request.info.loadDeletedCASRNs = NULL, request.info.loadInChIKeys = NULL, request.info.loadDTXSIDs = NULL, request.info.loadSMILESs = NULL, request.info.loadTotals = NULL, request.info.loadVendors = NULL, request.info.useResolver = NULL, request.info.usePubchem = NULL, request.info.useCommonchemistry = NULL, request.info.deepSearch = NULL, request.info.pubchem_headers = NULL, request.info.cc_headers = NULL, request.info.resolver_headers = NULL, request.info.keyChemIdType = NULL, request.chemicals = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.info.keyName)) options[['request.info.keyName']] <- request.info.keyName
  if (!is.null(request.info.keyType)) options[['request.info.keyType']] <- request.info.keyType
  if (!is.null(request.info.loadNames)) options[['request.info.loadNames']] <- request.info.loadNames
  if (!is.null(request.info.loadCASRNs)) options[['request.info.loadCASRNs']] <- request.info.loadCASRNs
  if (!is.null(request.info.loadDeletedCASRNs)) options[['request.info.loadDeletedCASRNs']] <- request.info.loadDeletedCASRNs
  if (!is.null(request.info.loadInChIKeys)) options[['request.info.loadInChIKeys']] <- request.info.loadInChIKeys
  if (!is.null(request.info.loadDTXSIDs)) options[['request.info.loadDTXSIDs']] <- request.info.loadDTXSIDs
  if (!is.null(request.info.loadSMILESs)) options[['request.info.loadSMILESs']] <- request.info.loadSMILESs
  if (!is.null(request.info.loadTotals)) options[['request.info.loadTotals']] <- request.info.loadTotals
  if (!is.null(request.info.loadVendors)) options[['request.info.loadVendors']] <- request.info.loadVendors
  if (!is.null(request.info.useResolver)) options[['request.info.useResolver']] <- request.info.useResolver
  if (!is.null(request.info.usePubchem)) options[['request.info.usePubchem']] <- request.info.usePubchem
  if (!is.null(request.info.useCommonchemistry)) options[['request.info.useCommonchemistry']] <- request.info.useCommonchemistry
  if (!is.null(request.info.deepSearch)) options[['request.info.deepSearch']] <- request.info.deepSearch
  if (!is.null(request.info.pubchem_headers)) options[['request.info.pubchem_headers']] <- request.info.pubchem_headers
  if (!is.null(request.info.cc_headers)) options[['request.info.cc_headers']] <- request.info.cc_headers
  if (!is.null(request.info.resolver_headers)) options[['request.info.resolver_headers']] <- request.info.resolver_headers
  if (!is.null(request.info.keyChemIdType)) options[['request.info.keyChemIdType']] <- request.info.keyChemIdType
  if (!is.null(request.chemicals)) options[['request.chemicals']] <- request.chemicals
    result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/universalharvest",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


