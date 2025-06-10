#' Retrieves CCTE API key from the Sys Environment
#'
#' @description An API Key is needed to access these APIs. Each user will need a specific key for each application. Please send an email to request an API key.
#'
#' to: `ccte_api@epa.gov`
#'
#' subject: `API Key Request`
#'
#' @usage Use `Sys.setenv(ccte_api_key = 'TOKEN HERE')` to set it.
#'
#' Run the function to check to see if R has detected it. A restart of R may be needed.
#'
#' @export

ct_api_key <- function() {
  ccte_api_key <- Sys.getenv("ccte_api_key")

  if (ccte_api_key == "") {
    ccte_api_key <- "No API key saved. Sys.setenv(ccte_api_key = 'TOKEN HERE')"
  }
  
  return(ccte_api_key)
}
