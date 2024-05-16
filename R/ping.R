#' Ping test for servers
#'
#' @export
#'
ping_ccte <- function(){

  cli::cli_rule()
  cli::cli_alert_warning(
    '\nAttempting ping test....\n')

ping_list <- list(

  'https://api-ccte.epa.gov/exposure/health',
  'https://api-ccte.epa.gov/hazard/health',
  'https://api-ccte.epa.gov/bioactivity/health',
  'https://api-ccte.epa.gov/chemical/health',

  'https://hcd.rtpnc.epa.gov/api/search/metadata', #prod
  'https://hazard-dev.sciencedataexperts.com/api/search/version' #dev
  )

for (url in ping_list) {
  response <- httr::GET(url)
  status <- httr::status_code(response)
  cat(url, "Status Code:", status, "\n")
  }
}
