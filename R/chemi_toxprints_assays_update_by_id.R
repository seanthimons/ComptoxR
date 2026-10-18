#' Update a ToxPrints assay
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
chemi_toxprints_assays_update_by_id <- function(id, body) {
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
              actives = list(format = "int32", type = "integer"),
              category = list(type = "string"),
              chemicals = list(
                items = structure(
                  list(
                    properties = list(
                      active = list(type = "boolean"),
                      activity = list(type = "string"),
                      additionalProps = list(
                        additionalProperties = structure(list(), names = character(0)),
                        type = "object"
                      ),
                      averageMass = list(format = "double", type = "number"),
                      bits = list(items = list(format = "int32", type = "integer"), type = "array"),
                      canonicalSmiles = list(type = "string"),
                      casrn = list(type = "string"),
                      chemId = list(type = "string"),
                      cid = list(type = "string"),
                      id = list(type = "string"),
                      image = list(type = "string"),
                      inchi = list(type = "string"),
                      inchiKey = list(type = "string"),
                      key = list(type = "string"),
                      message = list(type = "string"),
                      mol = list(type = "string"),
                      molFormula = list(type = "string"),
                      monoisotopicMass = list(format = "double", type = "number"),
                      name = list(type = "string"),
                      sid = list(type = "string"),
                      smiles = list(type = "string")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/ActivityChemical"
                ),
                type = "array"
              ),
              id = list(type = "string"),
              labels = list(items = list(type = "string"), type = "array"),
              metrics = list(
                items = structure(
                  list(
                    properties = list(
                      ACC = list(format = "double", type = "number"),
                      BA = list(format = "double", type = "number"),
                      BM = list(format = "double", type = "number"),
                      CTE = list(type = "boolean"),
                      F1 = list(format = "double", type = "number"),
                      FDR = list(format = "double", type = "number"),
                      FM = list(format = "double", type = "number"),
                      FN = list(format = "int32", type = "integer"),
                      FNR = list(format = "double", type = "number"),
                      FOR = list(format = "double", type = "number"),
                      FP = list(format = "int32", type = "integer"),
                      FPR = list(format = "double", type = "number"),
                      MCC = list(format = "double", type = "number"),
                      MK = list(format = "double", type = "number"),
                      NPV = list(format = "double", type = "number"),
                      OR = list(format = "double", type = "number"),
                      PPV = list(format = "double", type = "number"),
                      PT = list(format = "double", type = "number"),
                      PV1 = list(format = "double", type = "number"),
                      PV2 = list(format = "double", type = "number"),
                      TN = list(
                        format = "int32",
                        type = "integer"
                      ),
                      TNR = list(format = "double", type = "number"),
                      TP = list(format = "int32", type = "integer"),
                      TPR = list(format = "double", type = "number"),
                      TS = list(format = "double", type = "number"),
                      count = list(format = "int32", type = "integer"),
                      label = list(type = "string"),
                      ordinal = list(format = "int32", type = "integer")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/ToxprintMetrics"
                ),
                type = "array"
              ),
              name = list(type = "string"),
              options = structure(
                list(
                  properties = list(
                    OR = list(format = "double", type = "number"),
                    PV1 = list(format = "double", type = "number"),
                    TP = list(format = "int32", type = "integer"),
                    or = list(format = "double", type = "number"),
                    profile = list(type = "string"),
                    pv1 = list(format = "double", type = "number"),
                    tp = list(format = "int32", type = "integer")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/ToxprintsOptions"
              ),
              total = list(format = "int32", type = "integer")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/Assay"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("id" = id, "body" = body)
  result <- .ct_request(
    method = "PUT",
    path = "/api/toxprints/assays/{id}",
    path_params = base::list("id" = params[["id"]]),
    query = base::list(),
    body = params[["body"]],
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
