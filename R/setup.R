#' First time setup for functions
#'
#' Tests to see if APIs are up and tokens are present.
#'
#' @return Ping tests and API tokens.
#' @export
#'
run_setup <- function(){

  ping_ccte()

  cli::cli_rule()
  cli::cli_alert_warning('Looking for API tokens...')
  cli::cli_end()
  cli::cli_text('CCD token: {ct_api_key()}')

}
