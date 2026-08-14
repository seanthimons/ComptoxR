#' List chemicals by library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param setid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemset(setid = "DTXSID7020182")
#' }
chemi_chet_chemicals_chemset <- function(setid = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_chemicals_chemset",
    "pre_request",
    list(params = list(`setid` = setid, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("setid" %in% names(req_data$params)) {
    setid <- req_data$params[["setid"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(setid)) {
    options[['setid']] <- setid
  }
  result <- generic_request(
    endpoint = "chemicals/chemset",
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
