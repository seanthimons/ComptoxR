#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param coerce Boolean to split returned data into a list by endpoint type.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_env_fate <- function(query, coerce = TRUE, ccte_api_key = NULL) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')
  surl <- "chemical/fate/search/by-dtxsid/"
  urls <- paste0(burl, surl)

  cli_rule(left = 'Fate and transport payload options')
  cli_dl(
    c(
      'Number of compounds' = '{length(query)}',
      'Coerce' = '{coerce}'
    )
  )
  cli::cli_text()
  cli::cli_end()

  if (length(query) > 1000) {
    sublists <- split(
      query,
      rep(
        1:ceiling(length(query) / 1000),
        each = 1000,
        length.out = length(query)
      )
    )
    sublists <- map(sublists, as.list)

    df <- map(
      sublists,
      ~ {
        .x <- POST(
          url = urls,
          body = .x,
          add_headers(`x-api-key` = token),
          content_type("application/json"),
          accept("application/json, text/plain, */*"),
          encode = "json",
          progress() # progress bar
        )

        .x <- content(.x, "text", encoding = "UTF-8") %>%
          jsonlite::fromJSON(simplifyVector = TRUE)
      }
    ) %>%
      list_rbind()
  } else {
    payload <- as.list(query)

    response <- POST(
      url = urls,
      body = payload,
      add_headers(.headers = headers),
      content_type("application/json"),
      accept("application/json, text/plain, */*"),
      encode = "json",
      progress() # progress bar
    )

    df <- content(response, "text", encoding = "UTF-8") %>%
      jsonlite::fromJSON(simplifyVector = TRUE)
  }

  if (coerce == TRUE) {
    df <- df %>%
      split(.$endpointName)

    return(df)
  }
}
