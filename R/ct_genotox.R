#' Retrieves data on known or predicted genotoxic effects by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @return Returns a tibble with results
#' @export
ct_genotox <- function(query) {
  query <- unique(as.vector(query))

  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  init_query <- length(query)
  batch_limit <- as.numeric(Sys.getenv("batch_limit"))
  mult_count <- ceiling(length(query) / batch_limit)
  mult_request <- mult_count > 1

  if (length(query) > batch_limit) {
    query_list <- split(
      query,
      rep(1:mult_count, each = batch_limit, length.out = length(query))
    )
  } else {
    query_list <- list(query)
  }

  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = 'Genotox data payload options')
    cli::cli_dl(c(
      'Number of compounds' = '{length(query)}',
      'Number of batches' = '{mult_count}'
    ))
    cli::cli_rule()
    cli::cli_end()
  }

  # Build requests
  req_list <- map(
    query_list,
    function(query_part) {
      request(Sys.getenv('ctx_burl')) %>%
        req_method("POST") %>%
        req_url_path_append("hazard/genetox/details/search/by-dtxsid/") %>%
        req_headers(
          Accept = "application/json",
          `x-api-key` = ct_api_key()
        ) %>%
        req_body_json(
          query_part,
          auto_unbox = FALSE
        )
    }
  )

  if (run_debug) {
    return(req_list %>% pluck(., 1) %>% req_dry_run())
  }

  # Perform requests
  if (mult_request) {
    resp_list <- req_perform_sequential(req_list, on_error = 'continue', progress = TRUE)
  } else {
    resp_list <- list(req_perform(req_list[[1]]))
  }

  # Process responses
  body_list <- resp_list %>%
    map(., function(r) {
      if (resp_status(r) < 200 || resp_status(r) >= 300) {
        cli::cli_abort(paste(
          "API request failed with status",
          resp_status(r)
        ))
      }

      body <- resp_body_json(r)

      if (length(body) == 0) {
        cli::cli_alert_warning("No results found for the given query.")
        return(list())
      }
      return(body)
    }) %>%
    list_c()

  return(
    body_list %>%
      map(., function(x) {
        x[purrr::map_lgl(x, is.null)] <- NA
        as_tibble(x)
      }) %>%
      list_rbind()
  )
}
