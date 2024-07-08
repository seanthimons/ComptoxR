#' Requests bioactivity assay data
#'
#' @param search_type Choose from `aeid`, `spid`, `m4id`, and `dtxsid`. Defaults to `dtxsid` if not specified.
#' @param query List of variables to be queried.
#' @param annotate Boolean, if `TRUE` will perform a secondary request to join the the assay details against the assay IDs.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return A data frame
#' @export

ct_bioactivity <- function(search_type, query, annotate = FALSE, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv("burl")

  if(missing(query) == TRUE){
    cli::cli_abort('Missing query!')
  }

  if(missing(search_type)){
    cli::cli_alert_warning('No parameter specified for search type, defaulting to DTXSID!')

    search_type <- 'by-dtxsid'

    search_payload <- 'DTXSID'

  }else{

    search_type <- match.arg(search_type, choices = c('dtxsid', 'aeid', 'spid', 'm4id'))

    search_payload <- search_type

    search_type <- search_type %>%
      case_when(
        search_type == 'aeid' ~ 'by-aeid',
        search_type == 'spid' ~ 'by-spid',
        search_type == 'm4id' ~ 'by-m4id',
        search_type == 'dtxsid' ~ 'by-dtxsid'
      )
  }

  payload <- list(search_payload)

  cli::cli_rule(left = 'Payload options')
  cli::cli_dl(c(
    'Search type' = '{search_payload}',
    'Assay annotation' = '{annotate}'))
  cli::cli_end()

  urls <- paste0(burl, 'bioactivity/data/search/', search_type,'/', query)

  df <- map(urls, ~{

    response <- GET(
      url = .x,
      add_headers("x-api-key" = token),
      encode = 'json',
      progress()
    )

    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }, .progress = T)

  df <- set_names(df, query) %>% compact() %>% list_rbind()

  if(annotate == TRUE){

    bioassay_all <- ct_bio_assay_all()

    df <- left_join(df, bioassay_all, join_by('aeid'))

  }else{df}

}

#' Gets all bioassays
#'
#' Requests all bioassays; the package will automatically grab this information everytime the package is attached.
#'
#' @return Data frame

ct_bio_assay_all <- function(){

  token <- ct_api_key()

  burl <- Sys.getenv("burl")

  response <- GET(
    url = paste0(Sys.getenv('burl'), 'bioactivity/assay/'),
    add_headers("x-api-key" = token),
    accept('application/hal+json')
  )

  df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
}

