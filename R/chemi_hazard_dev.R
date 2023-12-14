#' Hazard Comparison
#'
#' @param query A list of DTXSIDS to search for.
#'
#' @return A data frame
#'
chemi_hazard_dev <- function(query
                         ){

  url <- "https://hcd.rtpnc.epa.gov/api/hazard"

  chemicals <- vector(mode = 'list', length = length(query))

  chemicals <- map2(chemicals,query,
                    ~{.x <- list(chemical = list(
                      .y))})

  payload <- list(
    'chemicals' = NULL,
    'options' = list(
      cts = cts_pred,
      minSimilarity = '0.49',
      analogsSearchType = NULL)
  )

  payload$chemicals <- chemicals

  response <- POST(
    url = url,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = 'json'
  )

  df <- content(response, "text", encoding = 'UTF-8') %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

#
#   df <- df %>% pluck('hazardChemicals') %>%
#     map(., ~ discard(.x, names(.x) == 'requestChemical')) %>%
#     map(., ~ discard(.x, names(.x) == 'chemicalId'))
#
#   names_list <- df %>%
#     map(., ~map_at(., 'chemical', ~ keep(.x, names(.x) == 'sid'))) %>%
#     map(., ~ discard(.x, names(.x) == 'scores')) %>%
#     list_c() %>% list_c %>% unname()
#
#   data <- list(headers = NULL, score = NULL, records = NULL)
#
#   #headers
#   data$headers <- df %>%
#     map(., 1) %>%
#     map_df(., ~.x) %>%
#     mutate(dtxsid = sid)
#
#   #score
#   data$score <- df %>%
#     map(., 2) %>%
#     set_names(as.list(data$headers$sid)) %>%
#     map(.,  ~map_df(., ~discard(.x, names(.x) == 'records'))) %>%
#     map_dfr(., ~.x, .id = 'dtxsid')
#
#   #endpoint names
#   endpoint_names <- df %>%
#     map(., ~pluck(., 'scores')) %>%
#     map_dfr(.,  ~map(., ~keep(.x, names(.x) == 'hazardId'))) %>%
#     distinct() %>%
#     as.list()
#
#   #records
#
#   data$records <- df %>%
#     map(., ~pluck(., 'scores')) %>%
#     {. <- set_names(., names_list)} %>%
#     map(., ~set_names(.x, endpoint_names$hazardId)) %>%
#     map(., ~map(., ~modify_if(., .p = is_empty, .f = ~{(list(name = NA))}))) %>%
#     map_dfr(., #dtx
#             ~map_dfr(., #endpoint
#                      ~.x,
#                      , .id = 'endpoint'
#             )
#             , .id ='dtxsid'
#     ) %>%
#     unnest_wider(., col = 'records', names_sep = '_')
#
#   df <- data %>% reduce(., left_join, by = 'dtxsid')

  return(df)
}
