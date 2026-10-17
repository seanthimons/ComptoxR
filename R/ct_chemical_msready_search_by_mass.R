#' Get MS-ready chemicals for a batch of mass ranges
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body A named list with integer error (mass tolerance) and a numeric masses vector.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass_bulk(body = list(error = 5L, masses = list(200.9, 201L)))
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_mass_bulk <- function(body) {
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
              error = list(format = "int32", type = "integer"),
              masses = list(items = list(format = "double", type = "number"), minItems = 1L, type = "array")
            ),
            required = list("error", "masses"),
            type = "object"
          ),
          specmill_id = "#/components/schemas/BatchMsReadyMassForm"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/chemical/msready/search/by-mass/",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    response_policy = ".ct_tidy",
    server = list(url = "https://comptox.epa.gov/ctx-api"),
    server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
    auth = list(list(list(
      scheme = "ctx",
      type = "apiKey",
      location = "header",
      name = "x-api-key",
      envvar = "ctx_api_key"
    )))
  )
  result
}

#' Get MS-ready chemicals using mass range
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param start Starting mass value. Type: number
#' @param end Ending mass value. Type: number
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass(start = "200.9")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_mass <- function(start, end = NULL) {
  params <- base::list("start" = start, "end" = end)
  result <- generic_request(
    "query" = params[["start"]],
    "endpoint" = "chemical/msready/search/by-mass/",
    "method" = "GET",
    "batch_limit" = 1,
    "path_params" = c(end = params[["end"]])
  )
  result
}
