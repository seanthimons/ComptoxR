#' Retrieves compound physio-chem properties by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_prop <- function(query, server = 1, ccte_api_key = NULL){

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

  cat("Searching for compound details....\n")
  surl <- "chemical/property/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  return(df)
}
#
