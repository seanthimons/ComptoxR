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
      Sys.setenv("chemi_burl" = "NA")
    }

  } else {

  switch(
    as.character(server),
    "1" = Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/"),
    "2" = Sys.setenv("chemi_burl" = "https://hazard-dev.sciencedataexperts.com/"),
    "3" = Sys.setenv("chemi_burl" = "https://ccte-cced-cheminformatics.epa.gov/"),
    {
      cli::cli_alert_warning("\nServer URL reset!\n")
      Sys.setenv("chemi_burl" = NA)
    }
  )

  Sys.getenv("chemi_burl")
  }
}
