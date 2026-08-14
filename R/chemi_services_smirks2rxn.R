#' Services Smirks2rxn
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smirks Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_smirks2rxn(smirks = "DTXSID7020182")
#' }
chemi_services_smirks2rxn <- function(smirks) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_services_smirks2rxn",
    "pre_request",
    list(params = list(`smirks` = smirks, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smirks" %in% names(req_data$params)) {
    smirks <- req_data$params[["smirks"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smirks)) {
    options[['smirks']] <- smirks
  }
  result <- generic_request(
    endpoint = "services/smirks2rxn",
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
