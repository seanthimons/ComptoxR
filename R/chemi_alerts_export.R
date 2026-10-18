#' Export an alerts report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_alerts_export <- function(body) {
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
              alertResult = structure(
                list(
                  properties = list(
                    alerts = list(
                      items = structure(
                        list(
                          properties = list(
                            alertFlags = list(
                              items = structure(
                                list(
                                  properties = list(
                                    flags = list(
                                      items = structure(
                                        list(
                                          properties = list(
                                            description = list(type = "string"),
                                            logicType = list(enum = list("NONE", "OR", "AND", "NOT"), type = "string"),
                                            text = list(type = "string"),
                                            type = list(
                                              enum = list(
                                                "METHOD",
                                                "SMILES",
                                                "SMARTS",
                                                "TOXPRINT",
                                                "HAZARD",
                                                "PROPERTY",
                                                "GROUP",
                                                "REFERENCE"
                                              ),
                                              type = "string"
                                            ),
                                            value = list(type = "string")
                                          ),
                                          type = "object"
                                        ),
                                        specmill_id = "#/components/schemas/Check"
                                      ),
                                      type = "array"
                                    ),
                                    name = list(type = "string")
                                  ),
                                  type = "object"
                                ),
                                specmill_id = "#/components/schemas/AlertFlags"
                              ),
                              type = "array"
                            ),
                            chemical = structure(
                              list(
                                properties = list(
                                  averageMass = list(format = "double", type = "number"),
                                  canonicalSmiles = list(type = "string"),
                                  casrn = list(type = "string"),
                                  chemId = list(type = "string"),
                                  cid = list(type = "string"),
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
                            )
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/ChemicalAlerts"
                      ),
                      type = "array"
                    ),
                    errors = list(items = list(type = "string"), type = "array"),
                    options = structure(
                      list(
                        properties = list(
                          alerts = list(items = list(type = "string"), type = "array"),
                          resolve = list(type = "boolean")
                        ),
                        type = "object"
                      ),
                      specmill_id = "#/components/schemas/AlertOptions"
                    )
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/AlertResult"
              ),
              collapse = list(type = "boolean"),
              format = list(
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              showAlertsOnly = list(type = "boolean"),
              showDetails = list(
                type = "boolean"
              )
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
    path = "/api/alerts/export",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
