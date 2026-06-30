#' Retrieve the CTX API key from the environment
#'
#' @description An API key is needed to access CTX APIs. Each user needs a
#' specific key for each application. To request a key, email
#' `ccte_api@epa.gov` with the subject `API Key Request`.
#'
#' Set the key with `Sys.setenv(ctx_api_key = "TOKEN HERE")`, then run
#' `ct_api_key()` to confirm R can detect it. A restart of R may be needed.
#'
#' @return A character string containing the configured CTX API key.
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
