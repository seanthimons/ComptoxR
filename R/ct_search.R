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
#'
#' @return A data frame
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


  if(type == 'string' & missing(search_param)){

    cli::cli_alert_warning('Defaulting to exact search!')
    cli::cli_alert_warning('Did you forget to specify which `search_param`?')

    search_param <- match.arg(search_param, c('equal', 'start-with', 'substring'))

    df <- .string_search(query, sp = search_param)

    return(df)
  }else{

    search_param <- match.arg(search_param, c('equal', 'start-with', 'substring'))

    df <- .string_search(query, sp = search_param)

    return(df)

  }

}

.string_search <- function(query, sp){

  headers <- c(
    `x-api-key` = ct_api_key()
  )

  burl <- Sys.getenv('burl')

  cli::cli_rule(left = 'String Payload options')
  cli::cli_dl(c(
    'Compound count' = '{length(query)}',
    'Search type' = '{sp}'))

# Exact -------------------------------------------------------------------

  if(sp == 'equal'){

    surl <- "chemical/search/"

    urls <- do.call(paste0, expand.grid(burl,surl,sp,'/',query))

    df <- map(urls, possibly(~{

      response <- VERB("GET", url = .x, add_headers("x-api-key" = ct_api_key()))
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

    }, otherwise = NULL)) %>%
      compact %>%
      map(., as_tibble) %>%
      list_rbind()

    df <- if('rank' %in% colnames(df)){arrange(df,rank)}else{df}
    df <- df %>% as_tibble()


    # string_url <- 'chemical/search/equal/'
    #
    # if(length(query) > 200){
    #
    #   cli::cli_alert_warning('Large request detected!')
    #
    #   sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
    #   sublists <- map(sublists, as.list)
    #
    #   df <- map(sublists, ~{
    #
    #     .x <- paste0(.x)
    #
    #     .x <- POST(
    #       url = paste0(burl, string_url),
    #       body = .x,
    #       add_headers(.headers = headers),
    #       content_type("application/json"),
    #       accept("application/json"),
    #       encode = "json",
    #       progress() # progress bar
    #     )
    #
    #     .x <- content(.x, "text", encoding = "UTF-8") %>%
    #       jsonlite::fromJSON(simplifyVector = TRUE)
    #
    #   }) %>% list_rbind()
    #
    # }else{
    #
    #   response <- POST(
    #     url = paste0(burl, string_url),
    #     body = query,
    #     content_type("application/json"),
    #     accept("application/json"),
    #     encode = 'json',
    #     add_headers(`x-api-key` = ct_api_key()),
    #     progress() #progress bar
    #   )
    #
    #   df <- content(response, "text", encoding = 'UTF-8') %>%
    #     jsonlite::fromJSON(simplifyVector = TRUE)
    }else{

# Substring ---------------------------------------------------------------


    if(sp %in% c('start-with', 'substring')){

    surl <- "chemical/search/"

    urls <- do.call(paste0, expand.grid(burl,surl,search_param,'/',query))

    df <- map(urls, possibly(~{

      response <- VERB("GET", url = .x, add_headers("x-api-key" = ct_api_key()))
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

    }, otherwise = NULL)) %>%
      compact %>%
      map_dfr(as.data.frame)

    df <- if('rank' %in% colnames(df)){arrange(df,rank)}else{df}
    df <-df %>% as_tibble()
    return(df)

  }else{
    cli::cli_abort('Search parameter for `string` search failed!')
  }
}}
