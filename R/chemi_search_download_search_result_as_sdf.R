#' Chemi search download sdf
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_search_download_search_result_as_sdf <- function(body) {
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
              hazardNames = list(items = list(type = "string"), type = "array"),
              inputType = list(
                enum = list(
                  "UNKNOWN",
                  "AUTO",
                  "MOL",
                  "RXN",
                  "SDF",
                  "RDF",
                  "SMI",
                  "SMILES",
                  "SMIRKS",
                  "CSV",
                  "TSV",
                  "JSON",
                  "XLSX",
                  "TXT",
                  "MSP"
                ),
                type = "string"
              ),
              limit = list(format = "int32", type = "integer"),
              maxNumber = list(format = "int32", type = "integer"),
              minNumber = list(format = "int32", type = "integer"),
              offset = list(format = "int32", type = "integer"),
              params = list(
                additionalProperties = list(
                  type = "string"
                ),
                type = "object"
              ),
              query = list(type = "string"),
              querySmiles = list(type = "string"),
              searchType = list(
                enum = list("EXACT", "SUBSTRUCTURE", "SIMILAR", "FORMULA", "MASS", "FEATURES", "HAZARD", "ADVANCED"),
                type = "string"
              ),
              smiles = list(type = "string"),
              sortBy = list(type = "string"),
              sortDirection = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/SearchRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/search/download/search-result-as-sdf",
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
