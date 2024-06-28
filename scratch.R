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

#testing ----

df <- chemi_search(
  query = 'DTXSID9025114',
  searchType = 'exact')

df <- chemi_search(
  query = 'DTXSID9025114',
  searchType = 'substructure',
  min_similarity = 0.8)

df <- chemi_search(
  query = 'DTXSID9025114',
  searchType = 'similar',
  min_similarity = 0.8)

df <- chemi_search(
  searchType = 'features',
  element_inc = 'Cr',
  element_exc = 'ALL')

df <- ct_details(query = df$sid, projection = 'structure')

list("Search type" = "{searchType}",
     "Similarity type" = "{similarity_type}",
     "Minimum simularity" = "{min_sim}",
     "Minimum toxicity" = "{min_toxicity}")
cli::cli_dl()


