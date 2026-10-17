#' Get chemicals for a batch of  MS-ready formulas
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula MS-ready molecular formulas. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula_bulk(formula = list("C15H16O2", "C6H6"))
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_by_msready_formula_bulk <- function(formula) {
  formula <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(formula)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(formula)) {
    base::stop("Required formula")
  }
  if (!base::missing(formula)) {
    formula <- base::tryCatch(
      .api_validation$body_value(formula, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid formula: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(formula)) formula <- jsonlite::unbox(NA)
  }
  params <- base::list("formula" = formula)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/chemical/search/by-msready-formula/",
      path_params = base::list(),
      query = base::list(),
      body = params[["formula"]],
      response_policy = ".ct_tidy",
      server = list(url = "https://comptox.epa.gov/ctx-api"),
      server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
      auth = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      ))),
      batch = base::list(max_items = .batch_limit)
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["formula"] <- base::list(chunk)
      send(params)
    },
    params[["formula"]],
    .batch_limit,
    on_error = "drop"
  )
}

#' Get chemicals by MS-ready formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula formula Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula(formula = "C15H16O2")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_by_msready_formula <- function(formula) {
  formula <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(formula)
  if (base::is.null(formula)) {
    base::stop("Required input: formula")
  }
  .api_validation$parameter_values(
    base::list("formula" = formula),
    list(formula = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(formula = "path")
  )
  params <- base::list("formula" = formula)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/search/by-msready-formula/{formula}",
      path_params = base::list("formula" = params[["formula"]]),
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
      params["formula"] <- base::list(chunk)
      send(params)
    },
    params[["formula"]],
    1L,
    on_error = "drop"
  )
}
