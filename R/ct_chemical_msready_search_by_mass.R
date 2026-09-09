#' Get MS-ready chemicals for a batch of mass ranges
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param error Required parameter
#' @param masses Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass_bulk(error = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_msready_search_by_mass_bulk <- function(error, masses) {
  params <- list("error" = error, "masses" = masses)
  result <- generic_request(
    "query" = NULL,
    "endpoint" = "chemical/msready/search/by-mass/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "1000")),
    "body" = local({
      .body <- Filter(Negate(is.null), list("error" = params[["error"]], "masses" = params[["masses"]]))
      if (length(.body)) .body else list()
    })
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
# Generated with apipak; do not edit by hand.
ct_chemical_msready_search_by_mass <- function(start, end = NULL) {
  params <- list("start" = start, "end" = end)
  result <- generic_request(
    "query" = params[["start"]],
    "endpoint" = "chemical/msready/search/by-mass/",
    "method" = "GET",
    "batch_limit" = 1,
    "path_params" = c("end" = params[["end"]])
  )
  result
}
