#' Retrieves Chemical Fate and Transport parameters
#'
#' @param dtxsid A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#' @return Returns a tibble with results
#' @export

ct_env_fate <- function(dtxsid, server = 1, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  {
    #Switch for server URLS

    if(server == 1){
      burl <- 'https://api-ccte.epa.gov/'
      cat(green('Public API selected!\n'))
    }else{
      burl <- 'https://api-ccte-stg.epa.gov/'
      cat(red('Staging API selected!\n'))
    }
  }

  cat('\nSearching for environmetal fate and transport data...\n')
  surl <- "chemical/fate/search/by-dtxsid/"

  urls <- paste0(burl, surl, dtxsid)

  df <- map_dfr(urls, ~{
    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n'))
  return(df)
}
