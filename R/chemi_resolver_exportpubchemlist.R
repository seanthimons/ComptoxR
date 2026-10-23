#' exportpubchemlist (POST)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param search search
#' @param linkBy linkBy
#' @param report report
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_exportpubchemlist <- function(search, linkBy, report, body) {
  if (base::is.null(search)) {
    base::stop("Required input: search")
  }
  if (base::is.null(linkBy)) {
    base::stop("Required input: linkBy")
  }
  if (base::is.null(report)) {
    base::stop("Required input: report")
  }
  .api_validation$parameter_values(
    base::list("search" = search, "linkBy" = linkBy, "report" = report),
    list(search = list(type = "string"), linkBy = list(type = "string"), report = list(type = "string")),
    .api_validation$body_value,
    c(search = "query", linkBy = "query", report = "query")
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
  params <- base::list("search" = search, "linkBy" = linkBy, "report" = report, "body" = body)
  if (base::is.character(params[["search"]]) && base::any(!base::nzchar(params[["search"]]))) {
    base::stop("Empty query parameter: search")
  }
  if (base::is.character(params[["linkBy"]]) && base::any(!base::nzchar(params[["linkBy"]]))) {
    base::stop("Empty query parameter: linkBy")
  }
  if (base::is.character(params[["report"]]) && base::any(!base::nzchar(params[["report"]]))) {
    base::stop("Empty query parameter: report")
  }
  result <- .ct_request(
    method = "POST",
    path = "/api/resolver/exportpubchemlist",
    path_params = base::list(),
    query = base::list("search" = params[["search"]], "linkBy" = params[["linkBy"]], "report" = params[["report"]]),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
