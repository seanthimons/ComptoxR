#' Return one library and its editable details
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lib_id Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_libraries(lib_id = "DTXSID7020182")
#' }
chemi_chet_curators_libraries <- function(lib_id) {
  result <- generic_request(
    query = lib_id,
    endpoint = "curators/libraries/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


