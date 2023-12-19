
#' Reportable quantity limits
#'
#' Returns the RQs for compounds with their hazard class and numeric limits in pounds and kilograms.
#'
#' @param query A list of DTXSIDs to search by.
#'
#' @return A tibble of results.
#' @export
#'

chemi_rq <- function(query){

  url <- 'https://hazard-dev.sciencedataexperts.com/api/safety/rqcodes'

  chemicals <- vector(mode = "list", length = length(query))

  chemicals <- map2(
    chemicals, query,
    \(x, y) x <- list(
      sid = y
    )
  )

  payload <- chemicals

  response <- POST(
    url = url,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = "json",
    progress()
  )

  df <- content(response, "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  df <- df %>%
    map(., ~pluck(., 'rqCode')) %>%
    compact() %>%
    map_dfr(., as_tibble) %>%
    separate_wider_delim(rq, ' ', names = c('rq_lbs', 'rq_kgs')) %>%
    mutate(
      rq_lbs = as.numeric(str_remove_all(rq_lbs, '\\(|\\)|\\,')),
      rq_kgs = as.numeric(str_remove_all(rq_kgs, '\\(|\\)|\\,')))

  return(df)
}
