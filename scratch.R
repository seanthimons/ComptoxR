chemi_predict <- function(query){

  payload <- list(
    report = 'JSON',
    structures = query
  )

  burl <- paste0(Sys.getenv("chemi_burl"), "api/webtest/predict")

  response <- POST(
    url = burl,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("*/*"),
    encode = "json",
    progress()
  )


  if (response$status_code == 200) {
    df <- content(response, "text", encoding = "UTF-8") %>%
      fromJSON(simplifyVector = FALSE)
  } else {
    cli_alert_danger("\nBad request!")
  }

return(df)
}

# testing -----------------------------------------------------------------

q1 <- chemi_predict(dtx_list[6:9])

q2 <- q1 %>%
  pluck('chemicals') %>%
  set_names(., dtx_list[6:9]) %>%
  map(., pluck('endpoints'))

endpoints <- q2 %>%
  map(., ~map(., pluck('endpoint'))) %>%
  map(., ~map(.,as.data.frame)) %>%
  map(., list_rbind)

predictions <- q2 %>%
  map(., ~map(., pluck('predicted'))) %>%
  map(., ~set_names())
  map(., ~map(.,as.data.frame))
  map(., list_rbind)



q2 <- q1 %>%
  keep(is.list) %>%
  discard_at('request')

q2$records <- q2$records %>%
  map_dfr(., ~as_tibble(.x))


##### similar

s1 <- chemi_search(query = dtx_list[8],
                   searchType = 'similar',
                   min_similarity = 0.7,
                   verbose = T
                   )


groq <- function(query){

  GROQ_API_KEY <- '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'

  headers = c(
    `Authorization` = paste("Bearer ", GROQ_API_KEY, sep = ""),
    `Content-Type` = "application/json"
  )

  data = jsonlite::toJSON(list(
    messages = list(
        list(
      role = 'user',
      content = query
    )),
    model = "mixtral-8x7b-32768"
  ),
  auto_unbox = T)

  res <- httr::POST(
    url = "https://api.groq.com/openai/v1/chat/completions",
    httr::add_headers(.headers=headers),
    body = data,
    httr::progress())

  res <- httr::content(res
                       #, as = 'text'
                       )
  res <- purrr::pluck(res, 'choices', 1, 'message', 'content') %>% cat('\n', .)

  return(res)
}
