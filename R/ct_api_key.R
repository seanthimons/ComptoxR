#' Retrieves CCTE API key from the Sys Environment
#'
#' @description An API Key is needed to access these APIs. Each user will need a specific key for each application. Please send an email to request an API key.
#'
#' to: `ccte_api@epa.gov`
#'
#' subject: `API Key Request`
#'
#' @usage Use `Sys.setenv(ccte_api_key = 'TOKEN HERE')` to set it.
#'
#' Run the function to check to see if R has detected it. A restart of R may be needed.
#'
#' @export

ct_api_key <- function() {

  ccte_api_key <- Sys.getenv("ccte_api_key")

  if(ccte_api_key == ""){
    stop("No API key saved. Sys.setenv(ccte_api_key = 'TOKEN HERE')")
  }else{return(ccte_api_key)}

  check_burl <- Sys.getenv('burl')
  if(is.na(check_burl) == T || isTRUE(check_burl == "") == T || isTRUE(check_burl == "NA") == T){
    comptox_server(server = 1)
    rm(check_burl)
    }else{rm(check_burl)}
}



