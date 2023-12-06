#' Cheminformatics Search
#'
#' Searching function that interfaces with the Cheminformatics API. Sends POST request.
#'
#' @param query Takes a list of variables (such as DTXSIDs, CASRN, names, etc.) to search by.
#' @param coerce Boolean variable to coerce list to a data.frame. Defaults to `FALSE`.
#'
#' @return A list of results with multiple parameters, which can then be fed into other Cheminformatic functions.
#' @export

chemi_search <- function(query, coerce = FALSE){

  url <- "https://hcd.rtpnc.epa.gov/api/resolver/lookup"

  if(typeof(query) == 'list'){
    payload <- list(
      ids = vector(mode = 'list', length = length(query))
    )
  }else{
    if(typeof(query) == 'character'){
      query <- as.list(query)

      payload <- list(
        ids = vector(mode = 'list', length = length(query))
      )

    }else{stop('Check query type!')}
  }

  payload$ids <- query

  response <- POST(
    url = url,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = 'json'
  )

  df <- content(response, "text", encoding = 'UTF-8') %>%
    fromJSON(simplifyVector = FALSE)

  #Coerce----

  if(coerce == TRUE){
  df <- map_dfr(df, \(x) as_tibble(x))
  }else{df}

  return(df)
}
