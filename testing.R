
make_request <- function(query, path_modification, dry_run = FALSE) {
  base_url <- "https://api-ccte.epa.gov/"

  path <- switch(
    path_modification,
    "equal" = "chemical/search/equal/",
    "start-with" = "chemical/search/start-with/",
    "substring" = "chemical/search/contain/",
    cli_abort("Invalid path modification")
  )

  req <- request(base_url) %>%
    req_headers(
      accept = "application/json",
      `x-api-key` = ct_api_key()
    ) %>%
    req_url_path_append(path)

  #req %>% req_dry_run()

  # HACK
  method <- "GET"

  req <- switch(
    method,
    "GET" = req %>% req_method("GET"),
    "POST" = req %>% req_method("POST"),
    cli_abort("Invalid method")
  )

  query = unique(as.vector(query))
  query = enframe(query, name = 'idx', value = 'raw_search') %>%
    mutate(
      cas_chk = str_remove(raw_search, "^0+"),
      cas_chk = str_remove_all(cas_chk, "-"),
      cas_chk = as.cas(cas_chk),

      searchValue  = str_to_upper(raw_search) %>%
        str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),

      searchValue = case_when(
        !is.na(cas_chk) ~ cas_chk,
        .default = searchValue
      )
    ) %>%
    select(-cas_chk) %>%
    filter(!is.na(searchValue))


  if (method == 'GET'){
    req <- map(query$searchValue, ~ {
      req <-  req %>%
        req_url_path_append(., URLencode(.x))

      req <- switch(
        path_modification,
        "equal" = req,
        #TODO Could expose this as an new arguement
        "start-with" = req %>% req_url_query(., top = '500'),
        "substring" = req %>% req_url_query(., top = '500'),
        cli_abort("Invalid path modification")
      )
    })
  }

  # if (method == 'POST'){
  #
  #   sublists <- split(query, rep(1:ceiling(nrow(query)/50), each = 50, length.out = nrow(query)))
  #
  #   req <- map(sublists, ~ {
  #     req %>%
  #       req_body_json(., .x$searchValue, type = "application/json")
  #   })
  #
  # }

  if (dry_run) {

    map(req, req_dry_run)

  }else{

    resps <- req %>% req_perform_sequential(., on_error = 'continue', progress = TRUE)

    resps %>%
      resps_successes() %>%
      resps_data(\(resp) resp_body_json(resp))
  }
}



# testing -----------------------------------------------------------------

#q1 <- make_request(query = "cadimum", path_mod = 'equal', method = 'GET', dry_run = F)

q1 <- make_request(query = c(
  #'benze',
  'cadmium',
  'bisphenol a'), path_mod = 'equal', dry_run = F)


# ions --------------------------------------------------------------------


q1 <-
  map(pt$elements$Symbol, ~chemi_search(
  #query = 'DTXSID4023886',
  searchType = 'features',
  element_inc = .x,
  element_exc = 'ALL'), .progress = T) %>%
  keep(., ~is_tibble(.x)) %>%
  list_rbind()

q2 <- ct_details(query = q1$sid, projection = 'all')

q5 <- ct_details(query = ComptoxR::testing_chemicals$dtxsid, projection = 'all')

q6 <- q2 %>%
        select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString) %>%
        mutate(
          inchiString = str_replace(inchiString, ".*?/", ""),
          class = case_when(
            str_detect(molFormula, "\\[") ~ "INORG", #NUC
            str_detect(molFormula, "^C[a-z]") ~ 'INORG',
            str_detect(molFormula, "^C[0-9]*H?[0-9]*") ~ "ORG",

            str_detect(inchiString, "^C[0-9]*H?[0-9]*") ~"ORG",

            str_detect(smiles, "\\*") ~ "ORG",

            is.na(molFormula) ~ 'INORG', #TODO figure out if this will crash on other things than quartz

            isMarkush == TRUE ~ "ORG",

            .default = "INORG")) %>%
        split(.$class)
