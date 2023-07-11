#' Retrieve compound details by DTXSID
#'
#'
#' @param dtxsid A single DTXSID (in quotes) or a list to be queried
#' @param ccte_api_key Checks for API key in Sys env
#' @return Returns a tibble with results
#' @export

ct_details <- function(query, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')

  cat("Searching for compound details....\n")
  surl <- "chemical/detail/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()


  cat(green('\nSearch complete!\n'))
  return(df)
}


ct_batch_details <- function(query){
  query <- split(query, ceiling(seq_along(query)/200))

  return(df)
}
