
chemi_rq <- function(query){

  url <- 'https://hazard-dev.sciencedataexperts.com/api/safety/rqcodes'

  chemicals <- vector(mode = 'list', length = length(query))

  payload <- purrr::map2(chemicals, query, ~{.x <- .y})

  # response <- POST(
  #   url = url,
  #   body = rjson::toJSON(payload),
  #   content_type("application/json"),
  #   accept("application/json, text/plain, */*"),
  #   encode = 'json'
  # )
  #
  # df <- content(response, "text", encoding = 'UTF-8') %>%
  #   jsonlite::fromJSON(simplifyVector = FALSE)
  #
  # return(df)
}
