#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param debug Flag to show API calls
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_env_fate <- function(query, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')
  surl <- "chemical/fate/search/by-dtxsid/"

  urls <- paste0(burl, surl)
  df <- map(urls, ~{

    df <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(df, as = "text", encoding = "UTF-8"))
  })

  return(df)
}
