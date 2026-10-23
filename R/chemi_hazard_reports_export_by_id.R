#' Export a saved hazard report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param body Request body.
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard_reports_export_by_id <- function(id, body) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id),
    list(id = list(type = "string")),
    .api_validation$body_value,
    c(id = "path")
  )
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
              outputFormat = list(
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              report = structure(
                list(
                  properties = list(
                    acl = structure(
                      list(
                        properties = list(
                          access = list(enum = list("PUBLIC", "AUTHENTICATED", "PRIVATE"), type = "string"),
                          owner = list(type = "string"),
                          read = list(items = list(type = "string"), type = "array"),
                          write = list(items = list(type = "string"), type = "array")
                        ),
                        type = "object"
                      ),
                      specmill_id = "#/components/schemas/ACL"
                    ),
                    comment = list(type = "string"),
                    exception = list(type = "string"),
                    hazardChemicals = list(
                      items = structure(
                        list(
                          properties = list(
                            chemical = structure(
                              list(
                                properties = list(
                                  casrn = list(type = "string"),
                                  chemId = list(type = "string"),
                                  cid = list(type = "string"),
                                  error = list(type = "string"),
                                  gsid = list(format = "int32", type = "integer"),
                                  id = list(type = "string"),
                                  inchi = list(type = "string"),
                                  inchiKey = list(type = "string"),
                                  inchiKey1 = list(type = "string"),
                                  mol = list(type = "string"),
                                  name = list(type = "string"),
                                  sid = list(type = "string"),
                                  smiles = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/DSSToxRecord2"
                            ),
                            chemicalId = list(type = "string"),
                            requestChemical = structure(
                              list(
                                properties = list(
                                  chemical = structure(
                                    list(
                                      properties = list(
                                        averageMass = list(format = "double", type = "number"),
                                        canonicalSmiles = list(type = "string"),
                                        casrn = list(type = "string"),
                                        chemId = list(type = "string"),
                                        cid = list(type = "string"),
                                        image = list(
                                          type = "string"
                                        ),
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
                                  properties = list(additionalProperties = list(type = "object"), type = "object"),
                                  rid = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/ChemicalRecord"
                            ),
                            scores = list(
                              items = structure(
                                list(
                                  properties = list(
                                    finalAuthority = list(type = "string"),
                                    finalScore = list(type = "string"),
                                    finalScoreSource = list(type = "string"),
                                    hazardId = list(type = "string"),
                                    hazardName = list(type = "string"),
                                    records = list(
                                      items = structure(
                                        list(
                                          properties = list(
                                            CAS = list(type = "string"),
                                            cas = list(type = "string"),
                                            category = list(type = "string"),
                                            duration = list(format = "double", type = "number"),
                                            durationUnits = list(type = "string"),
                                            effect = list(type = "string"),
                                            hazardCode = list(type = "string"),
                                            hazardName = list(type = "string"),
                                            hazardStatement = list(type = "string"),
                                            listType = list(type = "string"),
                                            longRef = list(type = "string"),
                                            name = list(type = "string"),
                                            note = list(type = "string"),
                                            note2 = list(type = "string"),
                                            rationale = list(type = "string"),
                                            route = list(type = "string"),
                                            score = list(type = "string"),
                                            source = list(
                                              type = "string"
                                            ),
                                            sourceOriginal = list(type = "string"),
                                            testOrganism = list(type = "string"),
                                            testType = list(type = "string"),
                                            toxvalID = list(type = "string"),
                                            url = list(type = "string"),
                                            valueActive = list(type = "boolean"),
                                            valueMass = list(format = "double", type = "number"),
                                            valueMassOperator = list(type = "string"),
                                            valueMassUnits = list(type = "string")
                                          ),
                                          type = "object"
                                        ),
                                        specmill_id = "#/components/schemas/ScoreRecord"
                                      ),
                                      type = "array"
                                    )
                                  ),
                                  type = "object"
                                ),
                                specmill_id = "#/components/schemas/Score"
                              ),
                              type = "array"
                            )
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/HazardChemical"
                      ),
                      type = "array"
                    ),
                    id = list(type = "string"),
                    name = list(type = "string"),
                    options = structure(
                      list(
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
                      ),
                      specmill_id = "#/components/schemas/HazardOptions"
                    ),
                    skippedChemicals = list(
                      items = structure(
                        list(
                          properties = list(
                            casrn = list(type = "string"),
                            chemId = list(type = "string"),
                            cid = list(type = "string"),
                            error = list(type = "string"),
                            gsid = list(format = "int32", type = "integer"),
                            id = list(type = "string"),
                            inchi = list(type = "string"),
                            inchiKey = list(type = "string"),
                            inchiKey1 = list(type = "string"),
                            mol = list(type = "string"),
                            name = list(type = "string"),
                            sid = list(type = "string"),
                            smiles = list(type = "string")
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/DSSToxRecord"
                      ),
                      type = "array"
                    ),
                    status = list(
                      enum = list("NONE", "SUBMITTED", "PROCESSING", "SUCCEEDED", "FAILED"),
                      type = "string"
                    )
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/HazardReport"
              ),
              showImages = list(type = "boolean")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/HazardExportRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("id" = id, "body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/hazard/reports/{id}/export",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
