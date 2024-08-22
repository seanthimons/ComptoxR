#' First time setup for functions
#'
#' Tests to see if APIs are up and tokens are present.
#'
#' @return Ping tests and API tokens.
#' @export

run_setup <- function(){

  cli::cli_rule()
  cli::cli_alert_warning(
    '\nAttempting ping test...')
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
      response <- httr::GET(url, httr::timeout(5))
      status_code <- httr::status_code(response)
      return(paste(url, ": ", status_code))
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

  cli::cli_rule()
  cli::cli_alert_warning('Looking for API tokens...')

  cli::cli_text('CCD token: {ct_api_key()}')

}

.onAttach <- function(libname, ComptoxR) {

  if(Sys.getenv('burl') == "" | Sys.getenv("chemi_burl") == ""){
    ct_server()
    chemi_server()
  }

  packageStartupMessage(
    .header()
  )
}

.header <- function(){

  if(is.na(build_date <- utils::packageDate('ComptoxR'))){
    build_date <- as.character(Sys.Date())
  }else{
    build_date <- as.character(utils::packageDate('ComptoxR'))
  }

  cli::cli({
    cli::cli_rule()

    cli::cli_alert_success(
      c("This is version ", {as.character(utils::packageVersion('ComptoxR'))}," of ComptoxR"))
    cli::cli_alert_success(
      c('Built on: ', {build_date})
    )
    cli::cli_rule()
    cli::cli_alert_warning('Available API endpoints:')
    cli::cli_dl(c(
      'CompTox' = '{Sys.getenv("burl")}',
      'Cheminformatics' =  '{Sys.getenv("chemi_burl")}'
    ))
  })

  run_setup()

}
