#' Cheminformatics Predictions
#'
#' @param query A list of DTXSIDs
#'
#' @return A dataframe of results
#' @export

chemi_predict <- function(query){

  payload <- list(
    report = 'JSON',
    structures = query
  )

  burl <- paste0(Sys.getenv("chemi_burl"), "api/webtest/predict")

  response <- POST(
    url = burl,
    body = jsonlite::toJSON(payload),
    content_type("application/json"),
    accept("*/*"),
    encode = "json",
    progress()
  )


  if (response$status_code == 200) {
    df <- content(response, "text", encoding = "UTF-8") %>%
      fromJSON(simplifyVector = TRUE)
  } else {
    cli::cli_abort("\nBad request!")
  }

  df <- df %>%
    pluck('chemicals', 'endpoints') %>%
    set_names(., test)

  endpoints <- df %>%
    map(., pluck('endpoint')) %>%
    map(., pluck('id'))

  predictions <- df %>%
    map(., pluck('predicted'))

  df <- predictions %>%
    map2(., endpoints, ~set_names(.x, .y)) %>%
    map(., ~list_rbind(., names_to = 'id')) %>%
    list_rbind(., names_to = 'dtxsid')

  return(df)
}
