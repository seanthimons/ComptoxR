#' Requests bioactivity assay data
#'
#' @param search_type Choose from `aeid`, `spid`, `m4id`, and `dtxsid`. Defaults to `dtxsid` if not specified.
#' @param query List of variables to be queried.
#' @param annotate Boolean, if `TRUE` will perform a secondary request to join the the assay details against the assay IDs.
#'
#' @return A data frame
#' @export

ct_bioactivity <- function(
  search_type,
  query,
  annotate = FALSE
) {
  query <- unique(as.vector(query))

  if (length(query) == 0) {
    cli::cli_abort('Query must be a character vector.')
  }

  if (missing(search_type)) {
    cli::cli_alert_warning(
      'No parameter specified for search type, defaulting to DTXSID!'
    )

    search_type <- 'by-dtxsid'
    search_payload <- 'DTXSID'
  } else {
    search_type <- match.arg(
      search_type,
      choices = c('dtxsid', 'aeid', 'spid', 'm4id')
    )

    search_payload <- search_type

    search_type <- search_type %>%
      case_when(
        search_type == 'aeid' ~ 'by-aeid',
        search_type == 'spid' ~ 'by-spid',
        search_type == 'm4id' ~ 'by-m4id',
        search_type == 'dtxsid' ~ 'by-dtxsid'
      )
  }

  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = 'Bioactivity payload options')
    cli::cli_dl(c(
      'Number of items' = '{length(query)}',
      'Search type' = '{search_payload}',
      'Assay annotation' = '{annotate}'
    ))
    cli::cli_rule()
    cli::cli_end()
  }

  # Build requests
  req_list <- map(
    query,
    function(query_item) {
      request(Sys.getenv('ctx_burl')) %>%
        req_method("GET") %>%
        req_url_path_append("bioactivity/data/search/") %>%
        req_url_path_append(search_type) %>%
        req_url_path_append(query_item) %>%
        req_headers(
          Accept = "application/json",
          `x-api-key` = ct_api_key()
        )
    }
  )

  if (run_debug) {
    return(req_list %>% pluck(., 1) %>% req_dry_run())
  }

  # Perform requests
  resp_list <- req_perform_sequential(req_list, on_error = 'continue', progress = TRUE)

  # Process responses
  body_list <- map2(
    resp_list,
    query,
    function(r, query_item) {
      if (inherits(r, "httr2_error")) {
        r <- r$resp
      }

      if (!inherits(r, "httr2_response")) {
        cli::cli_warn("Request failed for {query_item}")
        return(list())
      }

      if (resp_status(r) < 200 || resp_status(r) >= 300) {
        cli::cli_warn("API request failed for {query_item} with status {resp_status(r)}")
        return(list())
      }

      body <- resp_body_json(r)

      if (length(body) == 0) {
        return(list())
      }
      return(body)
    }
  )

  df <- body_list %>%
    set_names(query) %>%
    compact() %>%
    list_rbind(names_to = "query_id")

  if (annotate == TRUE) {
		# TODO: UPDATE THIS TO CORRECT FUNCTION
    bioassay_all <- ct_bio_assay_all()
    df <- left_join(df, bioassay_all, join_by('aeid'))
  }

  return(df)
}
