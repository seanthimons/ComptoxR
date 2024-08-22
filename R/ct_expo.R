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
#' @param ccte_api_key CCTE API token.
#'
#' @return A list of data frames
#' @export

ct_exposure <- function(query, param = c('func_use', 'product_data', 'list'), ccte_api_key = NULL){

  burl <- Sys.getenv('burl')

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  cli::cli_rule(left = 'Exposure payload options')
  cli::cli_dl(c(
    'Compound count' = '{length(query)}',
    'Search param' = '{param}'))

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
      url = paste0(Sys.getenv('burl'), surl, query), .keep = 'all',
      surl = str_remove_all(surl, 'exposure/|/by-dtxsid/')) %>%
    ungroup() %>%
    split(.$surl) %>%
    map(., ~discard_at(., c('surl'))) %>%
    map(., ~modify_in(., c('url'), as.list)) %>%
    map(., as.list) %>%
    map(., ~map_at(., .at = 'query', .f = ~setNames(., query)))

  surl <- map(search, ~{

    .x <- map2(.x =.x$query, .y = .x$url, ~{

      .x  <- VERB("GET", url = .y, add_headers("x-api-key" = ct_api_key()))

      if(.x$status_code != 200){
        .x <- NULL
      }else{
        .x <- fromJSON(content(.x, as = "text", encoding = "UTF-8"))
      }

    }, .progress = T) %>%
      compact() %>%
      list_rbind(., names_to = 'dtxsid') %>%
      as_tibble()
  }, .progress = T)

  cat_surl <- map(cat_surl, ~{

    .x <- VERB("GET", url = paste0(burl, .x), add_headers("x-api-key" = ct_api_key()))

    if(.x$status_code != 200){
      .x <- NULL
    }else{
      .x <- fromJSON(content(.x, as = "text", encoding = "UTF-8")) %>%
        as_tibble()
    }

  }, .progress = T)

  df <- list(
    data = surl,
    records = cat_surl
  )

  return(df)
}
