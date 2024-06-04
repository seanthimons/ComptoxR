#'Retrieves for hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_hazard <- function(query, ccte_api_key = NULL, debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')
  surl <- "hazard/search/by-dtxsid/"

  payload <- as.list(query)

  cli::cli_rule(left = 'Hazard payload options')
  cli::cli_dl(
    c(
      'Number of compounds: ' = '{length(payload)}'

  ))

  if(length(query) > 200){

    sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
    sublists <- map(sublists, as.list)
    }else{
      sublists <- vector(mode = 'list', length = 1L)
      sublists[[1]] <- query %>% as.list()
    }

  df <- map(sublists, ~{

    response <- POST(
      url = paste0(burl, surl),
      body = .x,
      add_headers("x-api-key" = token),
      encode = 'json',
      progress()
      )
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }, .progress = T) %>% list_rbind()

  return(df)
}
