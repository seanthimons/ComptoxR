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

# pulling------
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


# testing -----------------------------------------------------------------

s1 <- chemi_search(query = dtx_list$dtxsid[10],
                   searchType = 'similar',
                   min_similarity = 0.7
                   )

s2 <- chemi_hazard_dev(query = dtx_list$dtxsid[29],
                   analogs = 'similar',
                   min_sim = 0.8
                   )

query <- dtx_list$dtxsid[29]
chemicals <- vector(mode = 'list', length = length(query))

chemicals <- map2(chemicals,query,
                  ~{.x <- list(chemical = list(
                    sid = .y))}
)

#orig----
payload <- jsonlite::fromJSON('{"chemicals":[{"chemical":{"id":"20182","cid":"DTXCID30182","sid":"DTXSID7020182","casrn":"80-05-7","name":"Bisphenol A","smiles":"C(C)(C)(C1C=CC(O)=CC=1)C1C=CC(O)=CC=1","canonicalSmiles":"CC(C)(C1C=CC(O)=CC=1)C1C=CC(O)=CC=1","inchi":"InChI=1S/C15H16O2/c1-15(2,11-3-7-13(16)8-4-11)12-5-9-14(17)10-6-12/h3-10,16-17H,1-2H3","inchiKey":"IISBACLAFKSPIT-UHFFFAOYSA-N","checked":true},"properties":{}}],"options":{"cts":null,"minSimilarity":"0.9","analogsSearchType":"SIMILAR"}}', simplifyVector = F)
payload <- jsonlite::toJSON(payload, auto_unbox = T)

payload$options$cts <- 'null'

payload <- list(
  chemicals = list(
    list(
      chemical = list(
        #id = "20182"
        #,cid = "DTXCID30182"
        #sid = "DTXSID7020182"
        #,casrn = "80-05-7"
        #,name = "Bisphenol A"
        smiles = "C(C)(C)(C1C=CC(O)=CC=1)C1C=CC(O)=CC=1"
        #,canonicalSmiles = "CC(C)(C1C=CC(O)=CC=1)C1C=CC(O)=CC=1"
        #,inchi = "InChI=1S/C15H16O2/c1-15(2,11-3-7-13(16)8-4-11)12-5-9-14(17)10-6-12/h3-10,16-17H,1-2H3"
        #,inchiKey = "IISBACLAFKSPIT-UHFFFAOYSA-N"
        ,checked = TRUE
      ),
      properties = NULL
    )),
  options = list(
    cts = NA,
    analogsSearchType = 'SIMILAR',
    minSimilarity = 0.9
  )
)


#mod-----
chemical <- ct_details(query = query, projection = 'structure') %>%
  select(dtxsid, smiles) %>%
  rename(sid = dtxsid) %>%
  as.list()

payload <- list(
  chemicals = list(
    list(
      chemical = chemical,
      properties = NULL
    )),
  options = list(
    cts = NA,
    analogsSearchType = 'SIMILAR',
    minSimilarity = 0.9
  )
)

jsonlite::toJSON(payload, auto_unbox = T)

#response----

response <- httr::POST(
  url = "https://hcd.rtpnc.epa.gov/api/hazard",
  body = payload,
  content_type("application/json"),
  accept("application/json, text/plain, */*"),
  encode = 'json',
  progress() #progress bar
)

df <- content(response, "text", encoding = 'UTF-8') %>%
  jsonlite::fromJSON(simplifyVector = FALSE)

df <- s1

df1 <- df %>%
  pluck(., 'records') %>%
  map(., as_tibble) %>%
  list_rbind()

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

df <- ct_exposure(query = dtx_list[6:8], param = 'func_use')

df$data$`functional-use/search` %>%
  count(dtxsid, functioncategory) %>%
  #filter(., dtxsid %in% dtx_list[6:8])
  ggplot(.) +
  aes(x = functioncategory,
      y = n,
    #  color = harmonizedFunctionalUse
      fill = functioncategory) +
  geom_bar(stat = 'identity') +
  colorspace::scale_fill_discrete_qualitative() +
  #coord_polar() +
  facet_wrap(vars(dtxsid))


#testing ----

df <- chemi_search(
  searchType = 'features',
                          filter_results = F,
                          #filter_inc = list('charged'),
                          element_inc = "Pb",
                          element_exc = "ALL",
                          debug = F)

df1 <-   ct_details(query = df$sid)


df <- chemi_search(
  query = 'DTXSID9025114',
  searchType = 'similar',
  min_similarity = 0.8,
  min_toxicity = 'A')

df <- chemi_search(
  searchType = 'features',
  filter_results = T,
  filter_inc = c('isotopes','charged'),
  element_inc = 'Cr',
  element_exc = 'ALL',
  min_toxicity = 'A')


df <- pt$oxidation_state %>%
  #filter(element == 'arsenic') %>%
  select(search)

df <- ct_search(type = 'string', search_param = 'equal', query = df$search)
df <- df %>%
  filter(!is.na(dtxsid)) %>%
  mutate(dim = nchar(smiles)) %>%
  filter(dim <= 7)


######
query <- prodwater$dtxsid[1:10]

burl <- Sys.getenv('burl')

surl <- "chemical/synonym/search/by-dtxsid/"

urls <- paste0(burl, surl, query)

df <- map(urls, ~{

  response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
  df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
}, progress())

names(df) <- query

####

headers <- c(
  `x-api-key` = ct_api_key()
)

burl <- Sys.getenv('burl')

#string_url <- 'chemical/search/equal/'
string_url <- '/chemical/search/equal/'

  query <- unique(pt$symbol)
#
#   sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
#   sublists <- map(sublists, as.list)

  df <- map(query, ~{

    #.x <- paste0(.x)

    .x <- GET(
      url = paste0(burl, string_url, .x),
      #body = .x,
      add_headers(.headers = headers)
      #content_type("application/json"),
      #accept("application/json"),
      #encode = "json",
      #progress() # progress bar
    )

    .x <- content(.x, "text", encoding = "UTF-8") %>%
      jsonlite::fromJSON(simplifyVector = TRUE) #%>%
      # discard(., is_list) %>%
      # distinct(.keep_all = T) %>%
      # filter(!is.na(rank))

  }, .progress = T) #%>% list_rbind()



