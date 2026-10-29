#' Append WebTEST predictions to an uploaded report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON or text, raw binary bytes, or NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_webtest_export_append <- function(body = NULL) {
  if (!base::missing(body)) {
    body <- .api_validation$form_value(
      body,
      list(
        properties = list(
          file = list(format = "binary", type = "string"),
          predictionRequest = list(
            description = "WebTEST prediction request",
            properties = list(
              chemicals = list(
                description = "Molecule expressed as ID & SMILES or MOL",
                items = list(
                  properties = list(
                    additionalProps = list(
                      additionalProperties = structure(list(), names = character(0)),
                      type = "object"
                    ),
                    averageMass = list(format = "double", type = "number"),
                    canonicalSmiles = list(type = "string"),
                    casrn = list(type = "string"),
                    chemId = list(
                      type = "string"
                    ),
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
                type = "array"
              ),
              endpoints = list(description = "Endpoint to predict", items = list(type = "string"), type = "array"),
              format = list(
                description = "Report type: JSON, HTML or PDF",
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              methods = list(
                description = "Prediction method: hc (Hierarchical Clustering), sm (Single Model), nn (Nearest Neighbour), gc (Group Contribution) or consensus (Default)",
                items = list(type = "string"),
                type = "array"
              ),
              structures = list(
                description = "Molecule expressed as SMILES or MOL",
                items = list(
                  type = "string"
                ),
                type = "array"
              )
            ),
            type = "object"
          )
        ),
        required = list("predictionRequest"),
        type = "object"
      ),
      .api_validation$body_value,
      FALSE
    )
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/webtest/export-append",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    body_media = "multipart/form-data",
    body_encoding = list(),
    form_schema = list(
      properties = list(
        file = list(format = "binary", type = "string"),
        predictionRequest = list(
          description = "WebTEST prediction request",
          properties = list(
            chemicals = list(
              description = "Molecule expressed as ID & SMILES or MOL",
              items = list(
                properties = list(
                  additionalProps = list(
                    additionalProperties = structure(list(), names = character(0)),
                    type = "object"
                  ),
                  averageMass = list(format = "double", type = "number"),
                  canonicalSmiles = list(type = "string"),
                  casrn = list(type = "string"),
                  chemId = list(
                    type = "string"
                  ),
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
              type = "array"
            ),
            endpoints = list(description = "Endpoint to predict", items = list(type = "string"), type = "array"),
            format = list(
              description = "Report type: JSON, HTML or PDF",
              enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
              type = "string"
            ),
            methods = list(
              description = "Prediction method: hc (Hierarchical Clustering), sm (Single Model), nn (Nearest Neighbour), gc (Group Contribution) or consensus (Default)",
              items = list(type = "string"),
              type = "array"
            ),
            structures = list(
              description = "Molecule expressed as SMILES or MOL",
              items = list(
                type = "string"
              ),
              type = "array"
            )
          ),
          type = "object"
        )
      ),
      required = list("predictionRequest"),
      type = "object"
    )
  )
  result
}
