#' Searching by string, mass, or chemical formula
#'
#' @details
#'
#' Search type options:
#' \itemize{
#' \item `string`: Currently accepts:
#'  \itemize{
#'  \item DTXSIDs
#'  \item CASRNs
#'  \item Chemical names
#'  \item InChIKey
#'  }
#' \item `mass`: Search for any MS-ready compounds that are between the queried mass range. Removes multicomponent compounds.
#' \item `formula`: Search for any MS-ready compounds by a generic chemical formula. Removes multicomponent compounds.
#'}
#' Additional search parameters:
#' \itemize{
#'
#'\item For searching by mass, a single value +/- the mass query to search by
#'
#'\item For searching by string:
#'  \itemize{
#'    \item `exact`: Default searching method
#'    \item `start-with`: Substring search
#'    \item `contains`: Substring search
#'  }
#'}
#'
#' @param type Type of search parameter. Required parameter.
#' @param query Either a vector or a string.
#' @param search_param Additional parameters to modify search by.
#' @param ccte_api_key Checks for API key in Sys env
#' @param suggestions Boolean to return suggestions if a record is not found. Defaults to `TRUE`
#'
#' @return A tibble
#' @export

ct_search <- function(type = c(
                            'string',
                            'mass'
                            #,'formula'
                            ),
                      search_param = c(
                        'equal',
                        'start-with',
                        'substring'
                        ),
                      query,
                      suggestions = TRUE,
                      ccte_api_key = NULL
                          ){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  {
  burl <- Sys.getenv('burl')
  string_url <- 'chemical/search/equal/'
  formula_url <- 'chemical/msready/search/by-formula/'
  mass_url <- 'chemical/msready/search/by-mass/'
  }

  if(missing(type)){cli::cli_abort('Missing type search')}

# Mass --------------------------------------------------------------------


  if(type == 'mass' & missing(search_param)){
    cli::cli_abort('Missing mass range!')
  }

  if(type == 'mass' & !missing(search_param)){

      if(!is.numeric(query)){
        query <- as.numeric(query)
      }

      if(!is.numeric(search_param)){
        search_param <- as.numeric(search_param)
      }

      payload <- list(
        masses = query,
        error = search_param
      )

      cli::cli_rule(left = 'Mass Payload options')
      cli::cli_dl(c(
        'Masses' = '{query}',
        'Error' = '{search_param}'))

      df <- POST(
        url = paste0(burl, mass_url),
        body =  jsonlite::toJSON(payload, auto_unbox = T),
        add_headers(`x-api-key` = token),
        content_type("application/json"),
        accept("application/json"),
        encode = "json",
        progress() # progress bar
      )

      df <- content(df, "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(simplifyVector = FALSE)

  return(df)
  }

# String ------------------------------------------------------------------

  if(missing(suggestions)){
    cli::cli_alert_warning('Defaulting to including suggestions!')
    cli::cli_alert_warning('Did you forget to specify `suggestions`?')
    cli::cli_text('')

    suggestions  <- TRUE

  }

  if(type == 'string' & missing(search_param)){

    cli::cli_alert_warning('Defaulting to exact search!')
    cli::cli_alert_warning('Did you forget to specify which `search_param`?')

    #search_param <- match.arg(search_param, c('equal', 'start-with', 'substring'))

    df <- .string_search(query, sp = 'equal', sugs = suggestions)

  }else{

    search_param <- match.arg(search_param, c('equal', 'start-with', 'substring'))

    df <- .string_search(query, sp = search_param, sugs = suggestions)

  }

}

.string_search <- function(query, sp, sugs){

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

    sublists <- split(query, rep(1:ceiling(nrow(query)/200), each = 200, length.out = nrow(query)))

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
      select(-idx) %>%
      distinct(raw_search, searchValue, dtxsid, .keep_all = T)

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
