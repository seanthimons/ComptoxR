#'Retrieves for hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#' @param debug Flag to show API calls
#'
#' @return Returns a tibble with results
#' @export

ct_hazard <- function(query, ccte_api_key = NULL, debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  cat("\nSearching for hazard data....\n")
  surl <- "hazard/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)


  df <- map_dfr(urls, ~{
    if (debug == TRUE) {
      cat(.x, "\n")
    }
    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  df <- df %>%
    rename(compound = dtxsid)

  return(df)
}
