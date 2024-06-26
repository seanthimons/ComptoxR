#' Ping test for servers
#'
#' @export
#'
ping_ccte <- function(){

  cli::cli_rule()
  cli::cli_alert_warning(
    '\nAttempting ping test....\n')
  cli::cli_text()

  ping_list <-
    list(
      'https://api-ccte.epa.gov/exposure/health',
      'https://api-ccte.epa.gov/hazard/health',
      'https://api-ccte.epa.gov/bioactivity/health',
      'https://api-ccte.epa.gov/chemical/health',

      # "https://www.nonexistentwebsite123456.com", #TESTING

      'https://hcd.rtpnc.epa.gov/api/search/metadata', #prod
      'https://hazard-dev.sciencedataexperts.com/api/search/version' #dev

      )


  check_url <- function(url) {
    tryCatch({
      response <- GET(url, timeout(5))
      status_code <- status_code(response)
      return(paste(url, "- Status Code:", status_code))
    }, error = function(e) {
      if (grepl("Could not resolve host", e$message)) {
        return(paste(url, "- Error: Could not resolve host"))
      } else if (grepl("Timeout", e$message)) {
        return(paste(url, "- Error: Request timed out"))
      } else {
        return(paste(url, "- Error:", e$message))
      }
    })
  }

  results <- lapply(ping_list, check_url)

  cli::cli_li(items = results)
  cli::cli_end()

}

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
  cli::cli_text('CCD token: {ct_api_key()}')
  #cli::cli_end()

}
