#' Searches for listed synonyms by DTXSID
#'
#' @param query A single string (in quotes) or a list of strings to be queried.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_synonym <- function(query, ccte_api_key = NULL) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  surl <- "chemical/synonym/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map(
    urls,
    ~ {
      response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    }
  )

  names(df) <- query

  df <- df %>%
    map(., compact) %>%
    map(., ~ discard_at(., 'dtxsid'))

  return(df)
}
