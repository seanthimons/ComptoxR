#' Retrieves compound physio-chem properties by DTXSID
#'
#' Returns both experimental and predicted results.
#'
#' @param search_param Search for `compound` or `property` to look for.
#' @param query A list of DTXSIDs or a property to be queries against. See details for full list of properties available.
#' @param range A lower and upper range of values to search for if a property was specified for.
#' @param ccte_api_key Checks for API key in Sys env
#' @param coerce Boolean to coerce data to a list of data frames
#'
#' @return A list or dataframe
#' @export

ct_properties <- function(search_param,
                          query,
                          range,
                          coerce = TRUE,
                          ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  headers <- c(
    `x-api-key` = token
  )

  if(missing(search_param)){cli::cli_abort('Missing search type!')}

  burl <- Sys.getenv('burl')


  if(search_param == 'compound'){

    cli_rule(left = 'Phys-chem properties payload options')
    cli_dl(
      c(
        'Search type' = '{search_param}',
        'Number of compounds' = '{length(query)}',
        'Coerce' = '{coerce}'
      )
    )
    cli::cli_text()
    cli::cli_end()

    surl <- "chemical/property/search/by-dtxsid/"
    urls <- paste0(burl, surl)

    if(length(query) > 1000){

    sublists <- split(query, rep(1:ceiling(length(query)/1000), each = 1000, length.out = length(query)))
    sublists <- map(sublists, as.list)

    df <- map(sublists, ~{

      .x <- POST(
        url = urls,
        body = .x,
        add_headers(.headers = headers),
        content_type("application/json"),
        accept("application/json, text/plain, */*"),
        encode = "json",
        progress() # progress bar
      )

      .x <- content(.x, "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(simplifyVector = TRUE)

    }) %>% list_rbind()

  }else{
    payload <- as.list(query)

    response <- POST(
      url = urls,
      body = payload,
      add_headers(.headers = headers),
      content_type("application/json"),
      accept("application/json, text/plain, */*"),
      encode = "json",
      progress() # progress bar
    )

    df <- content(response, "text", encoding = "UTF-8") %>%
      jsonlite::fromJSON(simplifyVector = TRUE)

  }

    if(coerce == TRUE){

      df <- df %>%
        split(.$propertyId)

      return(df)
}

  }

  if(search_param == 'property'){
    if(!missing(range) & length(range) == 2){

      range <- as.numeric(range)

      cli_rule(left = 'Phys-chem properties payload options')
      cli_dl(
        c(
          'Search type' = '{search_param}',
          'Property' = '{query}',
          'Range' = '{range}',
          'Coerce' = '{coerce}'
        )
      )
      cli::cli_text()
      cli::cli_end()

      surl <- "chemical/property/search/by-range/"
      urls <- paste0(burl, surl, query, "/", range[1], "/", range[2])

      df <- GET(urls, progress(), add_headers(.headers = headers))

    }else{
      cli::cli_abort('Missing range for property search!')
    }

  }
}
