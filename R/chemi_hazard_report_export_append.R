#' Append hazard results to an uploaded report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard_report_export_append <- function(body = NULL) {
  if (!base::missing(body)) {
    body <- .api_validation$form_value(
      body,
      list(
        properties = list(
          file = list(format = "binary", type = "string"),
          hazardRequest = list(
            description = "Hazard calculation or report request",
            properties = list(
              chemicals = list(
                description = "Molecules expressed as any type of supported identifier",
                items = list(
                  properties = list(
                    chemical = list(
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
                    ordinal = list(format = "int32", type = "integer"),
                    properties = list(additionalProperties = list(type = "object"), type = "object"),
                    rid = list(type = "string")
                  ),
                  type = "object"
                ),
                type = "array"
              ),
              empty = list(type = "boolean"),
              options = list(
                properties = list(
                  analogsSearchType = list(
                    enum = list(
                      "EXACT",
                      "SUBSTRUCTURE",
                      "SIMILAR",
                      "TOXPRINTS",
                      "FORMULA",
                      "MASS",
                      "FEATURES",
                      "HAZARD",
                      "ADVANCED"
                    ),
                    type = "string"
                  ),
                  cts = list(format = "int32", type = "integer"),
                  minSimilarity = list(format = "float", type = "number"),
                  noRecords = list(type = "boolean"),
                  usePredictions = list(type = "boolean")
                ),
                type = "object"
              )
            ),
            required = list("chemicals"),
            type = "object"
          )
        ),
        required = list(
          "hazardRequest"
        ),
        type = "object"
      ),
      .api_validation$body_value,
      FALSE
    )
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/hazard/report/export-append",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    body_media = "multipart/form-data",
    body_encoding = list(),
    form_schema = list(
      properties = list(
        file = list(format = "binary", type = "string"),
        hazardRequest = list(
          description = "Hazard calculation or report request",
          properties = list(
            chemicals = list(
              description = "Molecules expressed as any type of supported identifier",
              items = list(
                properties = list(
                  chemical = list(
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
                  ordinal = list(format = "int32", type = "integer"),
                  properties = list(additionalProperties = list(type = "object"), type = "object"),
                  rid = list(type = "string")
                ),
                type = "object"
              ),
              type = "array"
            ),
            empty = list(type = "boolean"),
            options = list(
              properties = list(
                analogsSearchType = list(
                  enum = list(
                    "EXACT",
                    "SUBSTRUCTURE",
                    "SIMILAR",
                    "TOXPRINTS",
                    "FORMULA",
                    "MASS",
                    "FEATURES",
                    "HAZARD",
                    "ADVANCED"
                  ),
                  type = "string"
                ),
                cts = list(format = "int32", type = "integer"),
                minSimilarity = list(format = "float", type = "number"),
                noRecords = list(type = "boolean"),
                usePredictions = list(type = "boolean")
              ),
              type = "object"
            )
          ),
          required = list("chemicals"),
          type = "object"
        )
      ),
      required = list(
        "hazardRequest"
      ),
      type = "object"
    )
  )
  result
}
