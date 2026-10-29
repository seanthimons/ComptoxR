#' Stdizer Records
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Named list with records (a list of records, each list(rid = <id>, chemical = list(smiles = <SMILES>))), options (for example list(workflow = "qsar-ready")) and optional full (TRUE or FALSE).
#' @return The standardized records, one per input record.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_records(body = list(options = list(workflow = "qsar-ready"), records = list(list(rid = "ethanol", chemical = list(smiles = "CCO")))))
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer_records <- function(body) {
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
              full = list(type = "boolean"),
              options = structure(
                list(
                  properties = list(
                    recordId = list(type = "string"),
                    run = list(type = "string"),
                    workflow = list(type = "string")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/StdizerOptions"
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
                      ordinal = list(format = "int32", type = "integer"),
                      properties = list(
                        additionalProperties = structure(list(), names = character(0)),
                        type = "object"
                      ),
                      rid = list(type = "string")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/ChemicalRecord"
                ),
                type = "array"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/StdizerRecordsRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/stdizer/records",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
