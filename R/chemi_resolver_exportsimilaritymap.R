#' chemi_resolver_exportsimilaritymap
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param format format
#' @param sort sort
#' @param showImage showImage
#' @param limit limit
#' @param body Request body.
#' @return Decoded JSON or text, raw binary bytes, or NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_exportsimilaritymap <- function(format, sort, showImage, limit, body) {
  if (base::is.null(format)) {
    base::stop("Required input: format")
  }
  if (base::is.null(sort)) {
    base::stop("Required input: sort")
  }
  if (base::is.null(showImage)) {
    base::stop("Required input: showImage")
  }
  if (base::is.null(limit)) {
    base::stop("Required input: limit")
  }
  .api_validation$parameter_values(
    base::list("format" = format, "sort" = sort, "showImage" = showImage, "limit" = limit),
    list(
      format = list(
        enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
        type = "string"
      ),
      sort = list(type = "boolean"),
      showImage = list(type = "boolean"),
      limit = list(type = "string")
    ),
    .api_validation$body_value,
    c(format = "query", sort = "query", showImage = "query", limit = "query")
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
              section = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/PubchemRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("format" = format, "sort" = sort, "showImage" = showImage, "limit" = limit, "body" = body)
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  if (base::is.character(params[["sort"]]) && base::any(!base::nzchar(params[["sort"]]))) {
    base::stop("Empty query parameter: sort")
  }
  if (base::is.character(params[["showImage"]]) && base::any(!base::nzchar(params[["showImage"]]))) {
    base::stop("Empty query parameter: showImage")
  }
  if (base::is.character(params[["limit"]]) && base::any(!base::nzchar(params[["limit"]]))) {
    base::stop("Empty query parameter: limit")
  }
  result <- .ct_request(
    method = "POST",
    path = "/api/resolver/exportsimilaritymap",
    path_params = base::list(),
    query = base::list(
      "format" = params[["format"]],
      "sort" = params[["sort"]],
      "showImage" = params[["showImage"]],
      "limit" = params[["limit"]]
    ),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(
      list(
        name = "sort",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = TRUE
      ),
      list(
        name = "showImage",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = TRUE
      )
    )
  )
  result
}
