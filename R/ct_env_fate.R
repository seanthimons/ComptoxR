#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param debug Flag to show API calls
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_env_fate <- function(query, ccte_api_key = NULL, debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  cat('\nSearching for environmetal fate and transport data...\n')
  surl <- "chemical/fate/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    if (debug == TRUE) {
      cat(.x, "\n")
    }

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  return(df)
}
