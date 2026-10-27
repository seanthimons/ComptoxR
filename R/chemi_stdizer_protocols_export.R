#' Standardizer protocolExportByIdPost
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
chemi_stdizer_protocols_export <- function(id, body) {
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
              change = list(type = "string"),
              changed = list(type = "boolean"),
              components = list(type = "boolean"),
              curationFilter = list(items = list(type = "string"), type = "array"),
              failed = list(type = "boolean"),
              format = list(
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              hidden = list(type = "boolean"),
              issue = list(type = "string"),
              passed = list(type = "boolean"),
              protocol = structure(
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
                    changedNumber = list(format = "int32", type = "integer"),
                    comment = list(type = "string"),
                    componentsNumber = list(format = "int32", type = "integer"),
                    exception = list(
                      type = "string"
                    ),
                    failedNumber = list(format = "int32", type = "integer"),
                    filteredNumber = list(format = "int64", type = "integer"),
                    hiddenNumber = list(format = "int32", type = "integer"),
                    id = list(type = "string"),
                    name = list(type = "string"),
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
                    passedNumber = list(format = "int32", type = "integer"),
                    records = list(
                      items = structure(
                        list(
                          properties = list(
                            "@id" = list(format = "int32", type = "integer"),
                            comment = list(type = "string"),
                            curationStatus = list(
                              enum = list("NONE", "CORRECT", "INCORRECT", "QUESTIONABLE"),
                              type = "string"
                            ),
                            id = list(type = "string"),
                            issues = list(
                              items = structure(
                                list(
                                  properties = list(
                                    message = list(type = "string"),
                                    severity = list(enum = list("INFO", "WARNING", "ERROR", "FATAL"), type = "string")
                                  ),
                                  type = "object"
                                ),
                                specmill_id = "#/components/schemas/Issue"
                              ),
                              type = "array"
                            ),
                            original = structure(
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
                                        inchiKey = list(
                                          type = "string"
                                        ),
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
                            parent = structure(
                              list(),
                              names = character(0),
                              specmill_ref = "#/components/schemas/ProtocolRecord"
                            ),
                            protocolId = list(type = "string"),
                            status = list(enum = list("ORIGINAL", "PASSED", "FAILED", "SKIPPED"), type = "string"),
                            transformLog = list(
                              items = structure(
                                list(
                                  properties = list(
                                    change = structure(
                                      list(
                                        properties = list(
                                          description = list(type = "string"),
                                          flag = list(type = "string"),
                                          invalid = list(type = "boolean"),
                                          invalidMessage = list(type = "string"),
                                          text = list(type = "string"),
                                          type = list(
                                            enum = list("METHOD", "SMIRKS", "SMILES", "SMARTS", "GROUP", "REFERENCE"),
                                            type = "string"
                                          ),
                                          value = list(type = "string")
                                        ),
                                        type = "object"
                                      ),
                                      specmill_id = "#/components/schemas/Change"
                                    ),
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
                                specmill_id = "#/components/schemas/StdizerRecord"
                              ),
                              type = "array"
                            ),
                            type = list(enum = list("ORIGINAL", "COMPONENT", "PARENT", "DUPLICATE"), type = "string")
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/ProtocolRecord"
                      ),
                      type = "array"
                    ),
                    recordsNumber = list(format = "int32", type = "integer"),
                    status = list(
                      enum = list("NONE", "SUBMITTED", "PROCESSING", "SUCCEEDED", "FAILED"),
                      type = "string"
                    )
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/Protocol"
              ),
              query = list(type = "string"),
              rids = list(items = list(type = "string"), type = "array")
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
  params <- base::list("id" = id, "body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/stdizer/protocols/{id}/export",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
