#' Searches for compound  by string
#'
#' @param query A single query (in quotes) or a list to be queried. Currently accepts DTXSIDs, CASRNs, URL encoded chemical names, and matches of InChIKey
#' @param param A list of options to search by, default option is to use all options which will result in a long search query.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_name <- function(query,
                    param = c('start-with',
                              'equal',
                              'contain'),

                    ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }
  burl <- Sys.getenv('burl')

  if(identical(c('start-with',
                 'equal',
                 'contain'),param)){
    cat(red('\n/!\\ WARNING!/!\\\nLarge request detected!\nRequest may time out!\nRecommend to change search parameters or break up requests!\n'))
  }else{cat('\nParameter(s) declared:',param)}

  cat("\nRequesting valid names by provided search parameters....\n\n")

  surl <- "chemical/search/"

  urls <- do.call(paste0, expand.grid(burl,surl,param,'/',query))

  df <- map(urls, possibly(~{

    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

  }, otherwise = NULL)) %>% compact %>% map_dfr(as.data.frame)

  df <- if('rank' %in% colnames(df)){arrange(df,rank)} else{df}
  df <-df %>% as_tibble()
  cat(green('\nSearch complete!\n'))
  return(df)
}

