#' Retrieves CTX API key from the Sys Environment
#'
#' @description An API Key is needed to access these APIs. Each user will need a specific key for each application. Please send an email to request an API key.
#'
#' to: `ccte_api@epa.gov`
#'
#' subject: `API Key Request`
#'
#' @usage Use `Sys.setenv(ctx_api_key= 'TOKEN HERE')` to set it.
#'
#' Run the function to check to see if R has detected it. A restart of R may be needed.
#'
#' @export

ct_api_key <- function() {
  ctx_api_key <- Sys.getenv("ctx_api_key")

  if (ctx_api_key == "") {
    cli::cli_abort(
      c(
        "x" = "No CTX API key found.",
        "i" = "Please set it using {.run Sys.setenv(ctx_api_key = 'YOUR_KEY_HERE')}.",
        "i" = "You may need to restart your R session after setting it."
      )
    )
  }
  return(ctx_api_key)
}
