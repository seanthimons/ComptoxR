#' Retrieves CAS Common Chemistry API token 
#'
#' @description An API Key is needed to access these APIs. 
#'
#' @usage Use `Sys.setenv(cc_api_key= 'TOKEN HERE')` to set it.
#'
#' Run the function to check to see if R has detected it. A restart of R may be needed.
#'
#' @export

cc_api_key <- function() {
  cc_api_key <- Sys.getenv("cc_api_key")

  if (cc_api_key == "") {
    cli::cli_abort(
      c(
        "x" = "No CAS Common Chemistry API key found.",
        "i" = "Please set it using {.run Sys.setenv(cc_api_key = 'YOUR_KEY_HERE')}.",
        "i" = "You may need to restart your R session after setting it."
      )
    )
  }
  return(cc_api_key)
}
