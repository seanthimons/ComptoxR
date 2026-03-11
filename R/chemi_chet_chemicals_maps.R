#' Map list for a chemical
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_maps(chemid = "DTXSID7020182")
#' }
chemi_chet_chemicals_maps <- function(chemid = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(chemid)) options[['chemid']] <- chemid
    result <- generic_request(
    endpoint = "chemicals/maps",
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


