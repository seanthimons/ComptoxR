#' universalharvest cart (POST)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_universalharvest_cart <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              chemicals = list(
                items = structure(
                  list(
                    properties = list(
                      additionalProps = list(
                        additionalProperties = structure(list(), names = character(0)),
                        type = "object"
                      ),
                      averageMass = list(format = "double", type = "number"),
                      canonicalSmiles = list(type = "string"),
                      casrn = list(type = "string"),
                      chemId = list(type = "string"),
                      cid = list(type = "string"),
                      id = list(type = "string"),
                      image = list(type = "string"),
                      inchi = list(type = "string"),
                      inchiKey = list(type = "string"),
                      mol = list(type = "string"),
                      molFormula = list(type = "string"),
                      monoisotopicMass = list(format = "double", type = "number"),
                      name = list(type = "string"),
                      sid = list(type = "string"),
                      smiles = list(type = "string")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/Chemical"
                ),
                type = "array"
              ),
              info = structure(
                list(
                  properties = list(
                    cc_headers = list(additionalProperties = list(type = "string"), type = "object"),
                    deepSearch = list(type = "boolean"),
                    keyChemIdType = list(
                      enum = list(
                        "DTXSID",
                        "DTXCID",
                        "SMILES",
                        "MOL",
                        "CAS",
                        "Name",
                        "InChI",
                        "InChIKey",
                        "InChIKey_1",
                        "AnyId"
                      ),
                      type = "string"
                    ),
                    keyName = list(type = "string"),
                    keyType = list(type = "string"),
                    loadCASRNs = list(type = "boolean"),
                    loadDTXSIDs = list(type = "boolean"),
                    loadDeletedCASRNs = list(type = "boolean"),
                    loadInChIKeys = list(type = "boolean"),
                    loadNames = list(type = "boolean"),
                    loadSMILESs = list(type = "boolean"),
                    loadTotals = list(type = "boolean"),
                    loadVendors = list(type = "boolean"),
                    pubchem_headers = list(
                      additionalProperties = list(type = "string"),
                      type = "object"
                    ),
                    resolver_headers = list(additionalProperties = list(type = "string"), type = "object"),
                    useCommonchemistry = list(type = "boolean"),
                    usePubchem = list(type = "boolean"),
                    useResolver = list(type = "boolean")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/UniversalHarvestInfo"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/UniversalHarvestRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/resolver/universalharvest_cart",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
