#' Set API endpoints for Comptox API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable 'burl'
#' @export

comptox_server <- function(server = 1){

  if(isTRUE(server == 1) == TRUE){Sys.setenv('burl' = 'https://api-ccte.epa.gov/')}
  else{
    if(isTRUE(server == 2) == TRUE){Sys.setenv('burl' = 'https://api-ccte-stg.epa.gov/')}
    else{
      cat('\nServer URL reset!\n')
      Sys.setenv("burl" = NA)}}

  Sys.getenv('burl')
}


#' Set API endpoints for Cheminformatics API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `chemi_burl`
#' @export

chemi_server <- function(server = 1){

  if(isTRUE(server == 1) == TRUE){Sys.setenv('chemi_burl' = 'https://hcd.rtpnc.epa.gov/')}
  else{
    if(isTRUE(server == 2) == TRUE){Sys.setenv('chemi_burl' = 'https://hazard-dev.sciencedataexperts.com/')}
    else{
      cat('\nServer URL reset!\n')
      Sys.setenv("burl" = NA)}}

  Sys.getenv('chemi_burl')
}
