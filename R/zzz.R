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
  #cli::cli_text()

  ping_list <-
    list(
      'https://api-ccte.epa.gov/exposure/health',
      'https://api-ccte.epa.gov/hazard/health',
      'https://api-ccte.epa.gov/bioactivity/health',
      'https://api-ccte.epa.gov/chemical/health',

      'https://hcd.rtpnc.epa.gov/#/', #prod
      'https://hazard-dev.sciencedataexperts.com/#/', #dev

      'https://episuite.dev/EpiWebSuite/#/',
      "https://cfpub.epa.gov/ecotox/index.cfm"

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
    ct_server(server = 1)
    chemi_server(server = 1)
    epi_server(server = 1)
    eco_server(server = 1)

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
    cli::cli_alert_warning('You can change these using the *_server() function!')
    cli::cli_dl(c(
      'CompTox Chemistry Dashboard' = '{Sys.getenv("burl")}',
      'Cheminformatics' =  '{Sys.getenv("chemi_burl")}',
      'ECOTOX' = '{Sys.getenv("eco_burl")}',
      'EPI Suite' = '{Sys.getenv("epi_burl")}'
    ))
  })

  run_setup()

}

#' Set API endpoints for Comptox API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable 'burl'
#' @export

ct_server <- function(server = NULL){
  if (is.null(server)) {
    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("burl" = "")
    }

  } else {

    switch(
      as.character(server),
      "1" = Sys.setenv('burl' = 'https://api-ccte.epa.gov/'),
      "2" = Sys.setenv('burl' = 'https://api-ccte-stg.epa.gov/'),
      {
        cli::cli_alert_warning("\nServer URL reset!\n")
        Sys.setenv("burl" = "")
      }
    )

    Sys.getenv('burl')
  }
}

#' Set API endpoints for Cheminformatics API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `chemi_burl`
#' @export

chemi_server <- function(server = NULL){

  if (is.null(server)) {

    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("chemi_burl" = "")
    }

  } else {

    switch(
      as.character(server),
      "1" = Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/"),
      "2" = Sys.setenv("chemi_burl" = "https://hazard-dev.sciencedataexperts.com/"),
      "3" = Sys.setenv("chemi_burl" = "https://ccte-cced-cheminformatics.epa.gov/"),
      {
        cli::cli_alert_warning("\nServer URL reset!\n")
        Sys.setenv("chemi_burl" = "")
      }
    )

    Sys.getenv("chemi_burl")
  }
}

#' Set API endpoints for EPI Suite API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `epi_burl`
#' @export

epi_server <- function(server = NULL){

  if (is.null(server)) {

    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("epi_burl" = "")
    }

  } else {

    switch(
      as.character(server),
      "1" = Sys.setenv("epi_burl" = "https://episuite.dev/EpiWebSuite/api"),
      {
        cli::cli_alert_warning("\nServer URL reset!\n")
        Sys.setenv("epi_burl" = "")
      }
    )

    Sys.getenv("epi_burl")
  }
}

#' Set API endpoints for ECOTOX API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `eco_burl`
#' @export

eco_server <- function(server = NULL){

  if (is.null(server)) {

    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("eco_burl" = "")
    }

  } else {

    switch(
      as.character(server),
      "2" = Sys.setenv("eco_burl" = "https://hcd.rtpnc.epa.gov/"),
      "1" = Sys.setenv("eco_burl" = "http://127.0.0.1:5555"),
      {
        cli::cli_alert_warning("\nServer URL reset!\n")
        Sys.setenv("eco_burl" = "")
      }
    )

    Sys.getenv("eco_burl")
  }
}

#' Reset all servers

reset_servers <- function(){

  ct_server()
  chemi_server()
  epi_server()
  eco_server()

}
