#' Toxprints Toxprints Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories(chemical = "DTXSID1024122")
#' }
chemi_toxprints_toxprints_categories <- function(chemical = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_toxprints_categories",
    "pre_request",
    list(params = list(`chemical` = chemical, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemical" %in% names(req_data$params)) {
    chemical <- req_data$params[["chemical"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = chemical,
    endpoint = "toxprints/toxprints_categories",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
