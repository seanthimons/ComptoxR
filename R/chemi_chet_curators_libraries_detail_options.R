#' List deduplicated detail definitions available to curator library editor
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lib_id Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_libraries_detail_options(lib_id = "DTXSID7020182")
#' }
chemi_chet_curators_libraries_detail_options <- function(lib_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(lib_id)) options[['lib_id']] <- lib_id
    result <- generic_request(
    endpoint = "curators/libraries/detail-options",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


