#' export classyfire (POST)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_export_classyfire <- function(body) {
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
              format = list(
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              records = list(
                items = structure(
                  list(
                    properties = list(
                      chemical = structure(
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
                      confidence = list(format = "float", type = "number"),
                      message = list(type = "string"),
                      query = list(type = "string"),
                      resolvedBy = list(
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
                      result = list(
                        enum = list("NOT_RESOLVED", "FOUND", "CONVERTED", "MALFORMED", "DUPLICATE"),
                        type = "string"
                      ),
                      similarity = list(format = "float", type = "number"),
                      source = list(enum = list("DTX", "COMMONCHEMISTRY", "PUBCHEM"), type = "string")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/ResolvedChemical"
                ),
                type = "array"
              ),
              selectedForSimilarity = structure(
                list(
                  properties = list(
                    additionalProps = list(
                      additionalProperties = structure(list(), names = character(0)),
                      type = "object"
                    ),
                    averageMass = list(
                      format = "double",
                      type = "number"
                    ),
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
              showImages = list(type = "boolean")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/ExportRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/resolver/export_classyfire",
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
