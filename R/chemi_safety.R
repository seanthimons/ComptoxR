
chemi_safety <- function(query){

  #url <- "https://hcd.rtpnc.epa.gov/api/safety"
  url <- 'https://hazard-dev.sciencedataexperts.com/api/resolver/safety-flags'

  chemicals <- vector(mode = 'list', length = length(query))

  chemicals <- map2(chemicals, query,
                    \(x,y) x <- list(sid = y))

  payload <- chemicals

  response <- POST(
    url = url,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = 'json'
  )

  df <- content(response, "text", encoding = 'UTF-8') %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  df <- df %>%
    set_names(., query)

  #return(df)
}


