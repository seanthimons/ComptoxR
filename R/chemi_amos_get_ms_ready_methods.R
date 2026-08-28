#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param inchikey InChIKey to search by.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
#' }
chemi_amos_get_ms_ready_methods <- function(inchikey) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_get_ms_ready_methods", "pre_request", list(params = list(`inchikey` = inchikey, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("inchikey" %in% names(req_data$params)) {
    inchikey <- req_data$params[["inchikey"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = inchikey,
    endpoint = "amos/get_ms_ready_methods/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
