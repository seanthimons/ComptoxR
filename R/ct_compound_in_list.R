#' Returns all public lists that contain a queried compound
#'
#' @param query A DTXSID to search by.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_compound_in_list <- function(query, ccte_api_key = NULL) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  df <- map(
    query,
    possibly(
      ~ {
        cli::cli_alert_info('Searching for lists that contain {(.x)}')
        cli::cli_end()

        burl <- Sys.getenv('burl')
        surl <- "chemical/list/search/by-dtxsid/"
        urls <- paste0(burl, surl, .x, '?projection=chemicallistname')

        response <- GET(
          url = urls,
          add_headers("x-api-key" = ct_api_key()),
          progress()
        )

        if (response$status != 200) {
          cli::cli_alert_warning('Request failed on {(.x)}')
          cli::cli_end()
          return(NULL)
        } else {
          df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

          df <- as.list(df) %>% pluck(1)

          cli::cli_alert_success('{length(df)} lists found!')
          cli::cli_end()
          return(df)
        }
      },
      NULL
    )
  ) %>%
    set_names(., query) %>%
    compact()
}
