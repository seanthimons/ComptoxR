groq <- function(query) {
  GROQ_API_KEY <- "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"

  headers <- c(
    `Authorization` = paste("Bearer ", GROQ_API_KEY, sep = ""),
    `Content-Type` = "application/json"
  )

  data <- jsonlite::toJSON(
    list(
      messages = list(
        list(
          role = "user",
          content = query
        )
      ),
      model = "mixtral-8x7b-32768"
    ),
    auto_unbox = T
  )

  res <- httr::POST(
    url = "https://api.groq.com/openai/v1/chat/completions",
    httr::add_headers(.headers = headers),
    body = data,
    httr::progress()
  )

  res <- httr::content(
    res
    # , as = 'text'
  )
  res <- purrr::pluck(res, "choices", 1, "message", "content") %>% cat("\n", .)

  return(res)
}

# testing ----

df <- chemi_predict(query = "DTXSID1034187")

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "exact"
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "substructure",
  min_similarity = 0.8
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "similar",
  min_similarity = 0.8
)

df <- chemi_search(
  searchType = "features",
  element_inc = "Cr",
  element_exc = "ALL"
)

df <- ct_details(query = df$sid, projection = "structure")

###########################

query <- as.list(dtx_list$dtxsid[1:5])

burl <- paste0(Sys.getenv("chemi_burl"), "api/toxprints/calculate")

options <- list(
  "OR" = 3L,
  "PV1" = 0.05,
  "TP" = 3
)

chemicals <- vector(mode = "list", length = length(query))

chemicals <- map(query, ~ {
  list(
    sid = .x
  )
})

{
  chemicals <- list(
    list(
      # "id"= "34187",
      # "cid"= "DTXCID9014187",
      "sid" = "DTXSID1034187",
      # "casrn"= "10540-29-1",
      # "name"= "Tamoxifen",
      "smiles" = "C(/C1C=CC=CC=1)(\\C1=CC=C(C=C1)OCCN(C)C)=C(/CC)\\C1=CC=CC=C1"
      # "canonicalSmiles"= "CC/C(=C(\\C1C=CC=CC=1)/C1C=CC(=CC=1)OCCN(C)C)/C1C=CC=CC=1",
      # "inchi"= "InChI=1S/C26H29NO/c1-4-25(21-11-7-5-8-12-21)26(22-13-9-6-10-14-22)23-15-17-24(18-16-23)28-20-19-27(2)3/h5-18H,4,19-20H2,1-3H3/b26-25-",
      # "inchiKey"= "NKANXQFJJICGDU-QPLCGJKRSA-N",
      # "checked"= 'true'
    )
  )

  payload <- list(
    "chemicals" = chemicals,
    "options" = options
  ) %>%
    jsonlite::toJSON(., auto_unbox = T)

  df <- POST(
    url = burl,
    body = payload,
    content_type("application/json"),
    encode = "json",
    progress()
  ) %>%
    content(., "text", encoding = "UTF-8") %>%
    fromJSON(simplifyVector = TRUE)
}


cas_list <- rio::import('cas_list.csv') %>%
  select(analyte, cas_number)

comp <- ct_search(type = 'string', search_param = 'equal', query = cas_list$analyte, suggestions = T) %>%
  select(raw_search, dtxsid, preferredName) %>%
  rename(dtxsid_name = dtxsid,
         prefname_name = preferredName)

cas <- ct_search(type = 'string', search_param = 'equal', query = cas_list$cas_number, suggestions = T) %>%
  select(raw_search, dtxsid, preferredName) %>%
  rename(dtxsid_cas = dtxsid,
        prefname_cas = preferredName)

cas_cur <- left_join(cas_list, comp, join_by(analyte == raw_search)) %>%
  left_join(., cas, join_by(cas_number == raw_search)) %>%
  mutate(auth = if_else(dtxsid_cas == dtxsid_name, T, F))




