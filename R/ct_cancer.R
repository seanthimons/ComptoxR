#' Retrieves cancer-related hazard and risk values for a give DTXSID
#'
#'Values returned include source and URL, level of known or predicted risk, and exposure route (if known).
#'Cancer slope values and THQ values can also be found from running the `ct_hazard()` or `ct_ghs` functions.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#' @param debug Flag to show API calls
#' @return Returns a tibble with results
#' @export
ct_cancer <- function(query, ccte_api_key = NULL, debug = F) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  cat('\nSearching for cancer data...\n')
  surl <- "hazard/cancer-summary/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

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
