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

# ct_search ---------------------------------------------------------------

.string_search <- function(query, sp = 'equal', sugs = T){

  headers <- c(
    `x-api-key` = ct_api_key()
  )

  burl <- Sys.getenv('burl')

  string_url = case_when(
    sp == 'equal' ~ 'chemical/search/equal/',
    sp == 'start-with' ~ 'chemical/search/start-with/',
    sp == 'substring' ~  'chemical/search/contain/',
    #  .default = 'chemical/search/equal/'
  )

  cli::cli_rule(left = 'String Payload options')
  cli::cli_dl(c(
    'Compound count' = '{length(query)}',
    'Search type' = '{sp}',
    #  'Search type' = '{string_url}',
    'Suggestions' = '{sugs}'))
  cli::cli_text("")

  query = as.vector(query)
  query = enframe(query, name = 'idx', value = 'raw_search') %>%
    mutate(
      cas_chk = str_remove(raw_search, "^0+") %>%
        as.cas(.),

      searchValue  = str_to_upper(raw_search) %>%
        str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),

      searchValue = case_when(
        !is.na(cas_chk) ~ cas_chk,
        .default = searchValue
      )
    ) %>%
    select(-cas_chk)

  # Exact -------------------------------------------------------------------

  if(sp == 'equal'){

    sublists <- split(query, rep(1:ceiling(nrow(query)/50), each = 50, length.out = nrow(query)))

    df <- map(sublists, ~{

      df <- POST(
        url = paste0(burl, string_url),
        body = .x$searchValue,
        add_headers(.headers = headers),
        content_type("application/json"),
        accept("application/json"),
        encode = "json",
        progress() # progress bar
      )

      df <- content(df, "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(simplifyVector = TRUE)

      .x <- left_join(.x, df, join_by(searchValue), relationship = 'many-to-many')

    }) %>%
      list_rbind() %>%
      select(-c(idx)) %>% distinct(raw_search, searchValue, dtxsid, .keep_all = T)

    if(sugs == FALSE){
      df <- df %>%
        select(!c('searchMsgs', 'suggestions', 'isDuplicate'))
      return(df)
    }else{
      return(df)
    }

  }else{

    # Substring ---------------------------------------------------------------

    if(sp %in% c('start-with', 'substring')){

      query <- query %>%
        select(-searchValue, -idx) %>%
        mutate(url = paste0(burl, string_url, utils::URLencode(raw_search, reserved = T),'?top=500')) %>%
        split(., .$raw_search)

      df <- map(query, possibly(~{

        cli::cli_text(.x$raw_search, '\n')
        response <- GET(url = .x$url, add_headers(.headers = headers))

        df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>%
          as_tibble()

      }, otherwise = NULL), .progress = T) %>% list_rbind(., names_to = 'raw_search')

      if(sugs == FALSE){
        df <- df %>%
          select(!c('type', 'title', 'status', 'detail', 'instance', 'suggestions'))
        return(df)
      }else{
        return(df)
      }

    }else{
      cli::cli_abort('Search parameter for `string` search failed!')
    }
  }
}

search_list <- rio::import('cas_list.csv', na.strings = "") %>%
  select(analyte, cas_number)

# # temp <- '2,4-Dinitrophenol'
# # temp <- c('Glycerol 1,2-diacetate', '2,4-Dinitrophenol')
# #
#  ctxR::chemical_equal_batch(word = c('Glycerol 1,2-diacetate', '2,4-Dinitrophenol', '13-Docosenamide, (Z)-')) %>% select(searchValue, preferredName)
#  ctxR::chemical_equal_batch(word = '13-Docosenamide, (Z)-') %>%
#    select(searchValue, preferredName)
#  ctxR::chemical_starts_with(word = '13-Docosenamide, (Z)-') %>%
#    select(searchValue, preferredName)

ctxR::chemical_equal_batch(word = search_list$analyte) %>% View()
#
# string_search(query = temp) %>%
#   select(raw_search, preferredName) %>%
#   print(n = Inf)
#
# ct_search(type = 'string', search_param = 'equal', query = temp) %>% select(raw_search, preferredName)
# ct_search(type = 'string', search_param = 'equal', query = as.vector(search_list$analyte)) %>% select(raw_search, preferredName)
#
# rm(comp)
# comp <- ct_search(type = 'string', search_param = 'equal', query = as.vector(search_list$analyte)) %>%
#   select(raw_search, preferredName) %>%
#
#
# cas <- .string_search(query = search_list$cas_number) %>%
#   rename_with(., ~paste0('cas_', .x, recycle0 = T), !raw_search)


# curation ----------------------------------------------------------------

comp <- ct_search(type = 'string', search_param = 'equal', query = search_list$analyte) %>%
  rename_with(., ~paste0('compound_', .x, recycle0 = T), !raw_search)

comp %>% filter(raw_search == '2,4-Dinitrophenol')

# comp_sw <- comp %>%
#   filter(is.na(compound_dtxsid)) %>%
#   select(raw_search) %>%
#   ct_search(type = 'string', search_param = 'start-with', query = .$raw_search, suggestions = T) %>%
#   rename_with(., ~paste0('compound_sw_', .x, recycle0 = T), !raw_search)


cas <- ct_search(type = 'string', search_param = 'equal', query = search_list$cas_number, suggestions = T) %>%
  rename_with(., ~paste0('cas_', .x, recycle0 = T), !raw_search)

search_cur <- left_join(search_list, comp, join_by(analyte == raw_search)) %>%
  left_join(., cas, join_by(cas_number == raw_search)) %>%
  select(contains(c('analyte', 'cas_number')),ends_with(c('_dtxsid', '_rank', '_preferredName'))) %>%
  mutate(auth = case_when(
    cas_dtxsid == compound_dtxsid ~ 'TRUE',
    cas_dtxsid != compound_dtxsid ~ 'FALSE',
    is.na(cas_dtxsid) & is.na(compound_dtxsid) ~ 'NA'),
         final_dtx = case_when(
          # auth == FALSE ~ NA,
           auth == TRUE ~ compound_dtxsid,
           as.numeric(cas_rank) < as.numeric(compound_rank) ~ cas_dtxsid,
           is.na(compound_rank) & !is.na(cas_rank) ~ cas_dtxsid,
           as.numeric(cas_rank) > as.numeric(compound_rank) ~ compound_dtxsid,
           !is.na(compound_rank) & is.na(cas_rank) ~ compound_dtxsid,
           .default = NA
         ),
         auth = forcats::fct_relevel(auth, c('TRUE', 'FALSE'))
       ) %>%
  arrange(auth)


