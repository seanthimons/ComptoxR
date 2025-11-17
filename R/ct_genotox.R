#' Retrieves data on known or predicted genotoxic effects by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ctx_api_keyChecks for API key in Sys env
#' @param debug Flag to show API calls
#' @return Returns a tibble with results
#' @export
ct_genotox <- function(query, ctx_api_key= NULL, debug = F) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  ctx_burl <- Sys.getenv('ctx_burl')

  cat('\nSearching for genetox data...\n')
  surl <- "hazard/genetox/details/search/by-dtxsid/"

  urls <- paste0(ctx_burl, surl, query)

  df <- map_dfr(
    urls,
    ~ {
      if (debug == TRUE) {
        cat(.x, "\n")
      }

      response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    }
  ) %>%
    as_tibble()

  return(df)
}
