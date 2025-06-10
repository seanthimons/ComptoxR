#' Returns all compounds on a given list
#'
#' Can be used to return all compounds from a single list (e.g.:'PRODWATER') or a list of aggregated lists.
#'
#' @param list_name Search parameter
#' @param extract_dtxsids Boolean to pluck out just the DTXSIDs.
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#'  ct_list(list_name = c("PRODWATER", "CWA311HS"), extract_dtxsids = TRUE)
#' }
ct_list <- function(list_name, extract_dtxsids = TRUE) {
  req_list <- map(
    list_name,
    ~ {
      #cli::cli_alert_info('Searching for compounds on {(.x)} list...')
      req <- request(Sys.getenv('burl')) %>%
        req_url_path("chemical/list/search/by-name/") %>%
        req_url_path_append(stringr::str_to_upper(.x)) %>%
        req_url_query('projection' = 'chemicallistwithdtxsids') %>%
        req_headers("x-api-key" = ct_api_key())
    }
  )

  if (Sys.getenv("run_debug") == "TRUE") {
    cli::cli_alert_warning('DEBUGGING REQUEST')

    map(req_list, req_dry_run)
  } else {
    response <- req_perform_sequential(
      reqs = req_list,
      on_error = 'continue',
      progress = TRUE
    )

    dat <- response %>%
      resps_successes() %>%
      map(., ~ resp_body_json(.x))

    if (extract_dtxsids) {
      dat <- dat %>%
        map(
          .,
          ~ pluck(., 'dtxsids') %>% stringr::str_split(., pattern = ',')
        ) %>%
        unlist() %>%
        unique()
    }

    return(dat)
  }
}
