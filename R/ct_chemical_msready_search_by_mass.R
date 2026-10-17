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
#' @param start start Accepts a vector: one request is sent per element and the results are combined.
#' @param end end
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass(start = 200.9, end = 201)
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_mass <- function(start, end) {
  if (base::is.null(start)) {
    base::stop("Required input: start")
  }
  if (base::is.null(end)) {
    base::stop("Required input: end")
  }
  .api_validation$parameter_values(
    base::list("start" = start, "end" = end),
    list(
      start = list(type = "array", items = list(format = "double", type = "number")),
      end = list(format = "double", type = "number")
    ),
    .api_validation$body_value,
    c(start = "path", end = "path")
  )
  params <- base::list("start" = start, "end" = end)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/msready/search/by-mass/{start}/{end}",
      path_params = base::list("start" = params[["start"]], "end" = params[["end"]]),
      query = base::list(),
      body = NULL,
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
  .ct_request_each(
    function(chunk) {
      params["start"] <- base::list(chunk)
      send(params)
    },
    params[["start"]],
    1L,
    on_error = "drop"
  )
}
