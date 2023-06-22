#'Retrieves for hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_hazard <- function(query, server = 1, ccte_api_key = NULL){

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

  cat("\nSearching for hazard data....\n")
  surl <- "hazard/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)


  df <- map_dfr(urls, ~{
    cat('\n',.x,'\n')
    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  df <- df %>%
    rename(compound = dtxsid)

  cat(green('\nSearch complete!\n'))
  return(df)
}
