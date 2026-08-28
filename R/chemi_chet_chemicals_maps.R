#' Map list for a chemical
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_maps(chemid = "DTXSID7020182")
#' }
chemi_chet_chemicals_maps <- function(chemid = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_maps", "pre_request", list(params = list(`chemid` = chemid, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemid" %in% names(req_data$params)) {
    chemid <- req_data$params[["chemid"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(chemid)) options[['chemid']] <- chemid
    result <- generic_request(
    endpoint = "chemicals/maps",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
