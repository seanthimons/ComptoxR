#' Toxprints Chemicals Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_chemicals_categories(chemicals = "DTXSID1024122")
#' }
chemi_toxprints_chemicals_categories <- function(chemicals = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_toxprints_chemicals_categories", "pre_request", list(params = list(`chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "toxprints/chemicals_categories",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
