#' Get all data by Study Type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyType studyType
#' @param pageNumber pageNumber
#' @param all_pages TRUE (the default) requests page after page, starting at pageNumber, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in pageNumber.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning; attr(result, 'pagination')$stop_reason records why paging stopped.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_data_search_by_study_type(studyType = "DEV")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_data_search_by_study_type <- function(studyType, pageNumber = 1L, all_pages = TRUE, max_pages = 100L) {
  if (base::is.null(studyType)) {
    base::stop("Required input: studyType")
  }
  .api_validation$parameter_values(
    base::list("studyType" = studyType, "pageNumber" = pageNumber),
    list(studyType = list(type = "string"), pageNumber = list(default = 1L, format = "int32", type = "integer")),
    .api_validation$body_value,
    c(studyType = "path", pageNumber = "query")
  )
  params <- base::list("studyType" = studyType, "pageNumber" = pageNumber)
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  if (base::is.character(params[["pageNumber"]]) && base::any(!base::nzchar(params[["pageNumber"]]))) {
    base::stop("Empty query parameter: pageNumber")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxref/data/search/by-study-type/{studyType}",
      path_params = base::list("studyType" = params[["studyType"]]),
      query = base::list("pageNumber" = params[["pageNumber"]]),
      body = NULL,
      response_policy = ".ct_paged",
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
