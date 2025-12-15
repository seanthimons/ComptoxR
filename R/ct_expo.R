#' Product usage, functional usage, and exposure searching
#'
#' @details
#' For argument `param` a list of parameters is offered:
#' \itemize{
#'  \item `func_use` Functional use, returns both reported and predicted
#'  \item `product_data` Product data records
#'  \item `list` List presence by DTXSID
#' }
#'
#'
#' @param query A list of DTXSIDs
#' @param param Search parameter to look for.
#'
#' @return A list of data frames
#' @export

ct_functional_use <- function(
  query,
  param = c('func_use', 'product_data', 'list')
) {
  query <- unique(as.vector(query))

  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = 'Exposure payload options')
    cli::cli_dl(c(
      'Compound count' = '{length(query)}',
      'Search param' = '{param}'
    ))
    cli::cli_rule()
    cli::cli_end()
  }

  surl_list <- list(
    func_use = list(
      'exposure/functional-use/search/by-dtxsid/',
      'exposure/functional-use/probability/search/by-dtxsid/'
    ),
    product_data = list(
      'exposure/product-data/search/by-dtxsid/'
    ),
    list = list(
      'exposure/list-presence/search/by-dtxsid/'
    )
  )

  cat_list <- list(
    func_use = 'exposure/functional-use/category',
    product_data = 'exposure/product-data/puc',
    list = 'exposure/list-presence/tags'
  )

  surl <- keep(surl_list, names(surl_list) %in% param)
  cat_surl <- keep(cat_list, names(cat_list) %in% param)

  search <-
    expand_grid(surl, query) %>%
    unnest(surl) %>%
    rowwise() %>%
    mutate(
      endpoint = surl,
      .keep = 'all',
      surl = str_remove_all(surl, 'exposure/|/by-dtxsid/')
    ) %>%
    ungroup() %>%
    split(.$surl)

  # Build and execute requests for each endpoint
  surl_results <- map(
    search,
    ~ {
      endpoint_data <- .x
      req_list <- map2(
        endpoint_data$endpoint,
        endpoint_data$query,
        function(endpoint, query_item) {
          request(Sys.getenv('ctx_burl')) %>%
            req_method("GET") %>%
            req_url_path_append(endpoint) %>%
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

      resp_list <- req_perform_sequential(req_list, on_error = 'continue', progress = TRUE)

      body_list <- map2(
        resp_list,
        endpoint_data$query,
        function(r, query_item) {
          if (inherits(r, "httr2_error")) {
            r <- r$resp
          }

          if (!inherits(r, "httr2_response")) {
            return(NULL)
          }

          if (resp_status(r) < 200 || resp_status(r) >= 300) {
            return(NULL)
          }

          body <- resp_body_json(r)
          if (length(body) == 0) {
            return(NULL)
          }
          return(body)
        }
      )

      body_list %>%
        set_names(endpoint_data$query) %>%
        compact() %>%
        list_rbind(names_to = 'dtxsid') %>%
        as_tibble()
    },
    .progress = TRUE
  )

  # Fetch category data
  cat_surl_results <- map(
    cat_surl,
    ~ {
      req <- request(Sys.getenv('ctx_burl')) %>%
        req_method("GET") %>%
        req_url_path_append(.x) %>%
        req_headers(
          Accept = "application/json",
          `x-api-key` = ct_api_key()
        )

      if (run_debug) {
        return(req_dry_run(req))
      }

      resp <- req_perform(req)

      if (resp_status(resp) < 200 || resp_status(resp) >= 300) {
        return(NULL)
      }

      body <- resp_body_json(resp)
      if (length(body) == 0) {
        return(NULL)
      }

      body %>% as_tibble()
    },
    .progress = TRUE
  )

  df <- list(
    data = surl_results,
    records = cat_surl_results
  )

  return(df)
}

# TODO : implement ct_demo_exposure
ct_demo_exposure <- function(query) {

		



}