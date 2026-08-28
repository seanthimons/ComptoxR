#' Estimate a cationic dye
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_dye()
#' }
epi_ecosar_dye <- function() {
  result <- generic_request(
    endpoint = "ecosar/dye",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE
  )

    result <- run_hook("epi_ecosar_dye", "post_response", list(result = result, params = list()))
# Additional post-processing can be added here

  return(result)
}


