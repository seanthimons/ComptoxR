#' Set API endpoints for Comptox API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable 'burl'
#' @export

comptox_server <- function(server = NA){

  if(isTRUE(server == 1) == TRUE){Sys.setenv('burl' = 'https://api-ccte.epa.gov/')}
  else{
    if(isTRUE(server == 2) == TRUE){Sys.setenv('burl' = 'https://api-ccte-stg.epa.gov/')}
    else{Sys.setenv("burl" = NA)}}

  Sys.getenv('burl')
}
