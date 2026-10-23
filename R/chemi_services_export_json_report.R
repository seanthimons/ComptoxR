#' Chemi services export json report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_services_export_json_report <- function(body) {
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
              readyReport = structure(
                list(
                  properties = list(
                    columns = list(
                      items = structure(
                        list(
                          properties = list(
                            colDef = structure(
                              list(
                                properties = list(
                                  cellClasses = list(items = list(type = "string"), type = "array"),
                                  field = list(type = "string"),
                                  headerName = list(type = "string"),
                                  unit = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/ColDef"
                            ),
                            field = list(type = "string"),
                            fullName = list(type = "string"),
                            headerName = list(type = "string"),
                            parent = structure(
                              list(
                                properties = list(
                                  fullName = list(type = "string"),
                                  headerName = list(
                                    type = "string"
                                  ),
                                  headerNameWithUnits = list(type = "string"),
                                  parent = structure(list(), names = character(0)),
                                  unit = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/Parent"
                            ),
                            strippedBackground = list(type = "boolean")
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/PassedColumn"
                      ),
                      type = "array"
                    ),
                    dataColumns = list(
                      items = structure(
                        list(
                          properties = list(
                            colDef = structure(
                              list(
                                properties = list(
                                  cellClasses = list(items = list(type = "string"), type = "array"),
                                  field = list(type = "string"),
                                  headerName = list(type = "string"),
                                  unit = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/ColDef"
                            ),
                            field = list(type = "string"),
                            fullName = list(type = "string"),
                            headerName = list(type = "string"),
                            parent = structure(
                              list(
                                properties = list(
                                  fullName = list(type = "string"),
                                  headerName = list(type = "string"),
                                  headerNameWithUnits = list(type = "string"),
                                  parent = structure(list(), names = character(0)),
                                  unit = list(
                                    type = "string"
                                  )
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/Parent"
                            ),
                            strippedBackground = list(type = "boolean")
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/PassedColumn"
                      ),
                      type = "array"
                    ),
                    message = list(type = "string"),
                    modelDetails = list(
                      additionalProperties = structure(list(), names = character(0)),
                      type = "object"
                    ),
                    modelName = list(type = "string"),
                    result = list(items = list(type = "string"), type = "array"),
                    resultType = list(type = "string")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/ReadyReport"
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
    path = "/api/services/export_json_report",
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
