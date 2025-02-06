


df <- map(query$searchValue, ~possibly({

  df <- GET(
    url = paste0(burl, string_url, .x),
    add_headers("x-api-key" = ct_api_key())
  )

}, paste0('Failed request:', .x)), .progress = T)

