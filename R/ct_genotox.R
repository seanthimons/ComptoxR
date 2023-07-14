
#' Retrieves data on known or predicted genotoxic effects by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_genotox <- function(query, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  cat('\nSearching for genetox data...\n')
  surl <- "hazard/genetox/details/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n'))
  return(df)
}
