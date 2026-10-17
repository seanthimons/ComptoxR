#' Get Single Sample data by Medium
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param medium medium
#' @param pageNumber pageNumber
#' @param all_pages TRUE (the default) requests page after page, starting at pageNumber, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in pageNumber.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning; attr(result, 'pagination')$stop_reason records why paging stopped.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_single_sample_by_medium(medium = "surface water")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_mmdb_single_sample_by_medium <- function(medium, pageNumber = 1L, all_pages = TRUE, max_pages = 100L) {
  if (base::is.null(medium)) {
    base::stop("Required input: medium")
  }
  .api_validation$parameter_values(
    base::list("medium" = medium, "pageNumber" = pageNumber),
    list(medium = list(type = "string"), pageNumber = list(default = 1L, format = "int32", type = "integer")),
    .api_validation$body_value,
    c(medium = "query", pageNumber = "query")
  )
  params <- base::list("medium" = medium, "pageNumber" = pageNumber)
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  if (base::is.character(params[["medium"]]) && base::any(!base::nzchar(params[["medium"]]))) {
    base::stop("Empty query parameter: medium")
  }
  if (base::is.character(params[["pageNumber"]]) && base::any(!base::nzchar(params[["pageNumber"]]))) {
    base::stop("Empty query parameter: pageNumber")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/exposure/mmdb/single-sample/by-medium",
      path_params = base::list(),
      query = base::list("medium" = params[["medium"]], "pageNumber" = params[["pageNumber"]]),
      body = NULL,
      response_policy = ".ct_paged",
      request_controls = list(timeout = Inf),
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
  if (!base::isTRUE(all_pages)) {
    base::return(send(params))
  }
  if (base::is.null(params[["pageNumber"]])) {
    base::stop("Supply pageNumber to start paging, or set all_pages = FALSE", call. = FALSE)
  }
  result <- .ct_request_pages(
    function(page) {
      params[base::names(page)] <- page
      send(params)
    },
    "pageNumber",
    params[["pageNumber"]],
    max_pages,
    completed = .ct_last_page
  )
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  result
}
