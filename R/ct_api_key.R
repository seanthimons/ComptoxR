#' Retrieves CCTE API key from the Sys Environment
#'
#' An API Key is needed to access these APIs. Each user will need a specific key for each application. Please send an email to request an API key.
#' Set API key in Sys Environment to the variable `ccte_api_key`
#' to:`ccte_api@epa.gov`
#' subject: API Key Request
#'
#'
#' @export

ct_api_key <- function() {
  ccte_api_key <- Sys.getenv("ccte_api_key", "")
  if (ccte_api_key == "") {
    ccte_api_key <- getOption("ccte_api_key", "")
  }
  if (ccte_api_key == "")
    stop("No API key saved. Set it in Sys.env")
  else ccte_api_key
}
