
#' Search by string
#'
#' @param query Vector of strings
#' @param request_method String: 'GET' or 'POST'
#' @param search_method 'exact', 'starts', or 'contains'
#' @param dry_run Boolean to debug, defaults to FALSE
#'
#' @returns dataframe
#' @export

ct_search <- function(query,
                      request_method,
                      search_method,
                      dry_run){

  query_list <- unique(as.vector(query)) %>%
    as.list() %>%
    set_names(., unique(as.vector(query)))

  if(missing(request_method)){request_method <- "GET"}
  if(missing(search_method)){search_method <- "exact"}
  if(missing(dry_run)){dry_run <- FALSE}

  {
    cli::cli_rule(left = 'String search options')
    cli::cli_dl()
    cli::cli_li(c('Compound count' = "{length(query_list)}"))
    #cli::cli_li(c('Batch iterations' = "{ceiling(length(query)/50L)}"))
    cli::cli_li(c('Search type' = "{search_method}"))
    #cli::cli_li(c('Suggestions' = "{sugs}"))
    cli::cli_end()
    cli::cat_line()
  }



  df <- map(query_list,
            ~make_request(query = .x,
                          rq_method = request_method,
                          sch_method = search_method,
                          dry_run = dry_run
            ), .progress = T)

  if(dry_run == FALSE){
  df <- df %>%
    compact() %>% list_rbind(names_to = 'raw_search')
  return(df)
  }
}


#' Make requests
#'
#' @param query Vector
#' @param request_method String
#' @param search_method String
#' @param dry_run Boolean
#'
#' @returns List
#' @export
make_request <- function(
    query,
    rq_method,
    sch_method,
    dry_run
) {

  if(is_missing(sch_method)){
    cli::cli_alert_warning('Missing search method, defaulting to `equal`')
    sch_method <- 'exact'
  }

  sch_method <- arg_match(sch_method, values = c('exact', 'starts', 'contains'))

  path <- switch(
    sch_method,
    "exact" = "chemical/search/equal/",
    "starts" = "chemical/search/start-with/",
    "contains" = "chemical/search/contain/",
    cli_abort("Invalid path modification for search method")
  )

  req <- request(Sys.getenv('burl')) %>%
    req_headers(
      accept = "application/json",
      `x-api-key` = ct_api_key()
    ) %>%
    req_url_path_append(path)

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

  #req %>% req_dry_run()

  # HACK Until POSTs work

  if(missing(rq_method)){
    cli::cli_alert_warning('Missing method, defaulting to GET request')
    rq_method <- 'GET'
  }else{
    rq_method <- arg_match(rq_method, values = c('GET', 'POST'))
  }

  req <- switch(
    rq_method,
    "GET" = req %>% req_method("GET"),
    "POST" = req %>% req_method("POST"),
    cli::cli_abort("Invalid request method")
  )

  if (rq_method == 'GET'){
    req <- map(query$searchValue, ~ {
      req <-  req %>%
        req_url_path_append(., URLencode(.x))

      req <- switch(
        sch_method,
        "exact" = req,
        #TODO Could expose this as an new arguement
        "starts" = req %>% req_url_query(., top = '500'),
        "contains" = req %>% req_url_query(., top = '500')
      )
    })
  }

  if (rq_method == 'POST'){
    cli::cli_abort('POST requests not allowed at this time!')

    #   sublists <- split(query, rep(1:ceiling(nrow(query)/50), each = 50, length.out = nrow(query)))
    #
    #   req <- map(sublists, ~ {
    #     req %>%
    #       req_body_json(., .x$searchValue, type = "application/json")
    #   })
    #
  }

  if (dry_run) {

    map(req, req_dry_run)

  }else{

    resps <- req %>% req_perform_sequential(., on_error = 'continue', progress = TRUE)

    resps %>%
      resps_successes() %>%
      resps_data(\(resp) resp_body_json(resp)) %>%
      map(.,
          ~map(.x,
                ~if(is.null(.x)){NA}else{.x}) %>%
          as_tibble) %>% list_rbind()
  }
}
