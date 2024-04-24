#' MOL file request
#'
#' @param query
#' @param ccte_api_key
#' @param debug
#'
#' @return

ct_mol <- function(query,
                   #ccte_api_key = NULL,
                   debug = F
                   ){

burl <- Sys.getenv('burl')

response <- GET(
  url <- paste0(burl, 'chemical-file/mol/search/by-dtxsid/', query),
  accept("application/hal+json"),
  progress()
)

if(response$status_code == 200){


  df <- content(response, "text", encoding = "UTF-8")

  # debug -------------------------------------------------------------------

  if(debug == TRUE){
    data <- list()
    data$response <- response
    data$content <- df
    return(data)}else{
      return(df)
    }
}else{cli_abort('Bad request!')}

}



#' Descriptors
#'
#' @param query string
#' @param type string
#' @param coerce string
#' @param debug string
#'
#' @return

ct_descriptors <- function(query,
                           type = c('smiles', 'canonical_smiles', 'mol2000', 'mol3000', 'inchi'),
                           coerce = T,
                           ccte_api_key = NULL,
                           debug = F){
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  if(missing(type) | is.null(type)){cli_abort('Missing search parameter!')}

  type_option <-
    if(type == 'smiles'){
      'to-smiles'
  }else{
    if(type == 'canonical_smiles'){
      'to-canonicalsmiles'
    }else{
      if(type == 'mol2000'){
        'to-mol2000'
      }else{
        if(type == 'mol3000'){
          'to-mol3000'
        }else{
          if(type == 'inchi'){
            'to-inchi'
          }
        }
      }
    }
  }

# payload -----------------------------------------------------------------

  payload <- as.list(query)

# request -----------------------------------------------------------------

  burl <- Sys.getenv('burl')

  response <- POST(
    url <- paste0(burl, 'chemical/indigo/', type_option),
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json"),
    encode = "json",
    add_headers(`x-api-key` = token),
    progress()
  )

  if(response$status_code == 200){


    df <- content(response, "text", encoding = "UTF-8") %>%
      fromJSON(simplifyVector = FALSE)

    # Coerce----

    if (coerce == TRUE) {
      df <- map_dfr(df, \(x) as_tibble(x))
    } else {
      df
    }


    # debug -------------------------------------------------------------------

    if(debug == TRUE){
      data <- list()
      data$payload <- payload
      data$response <- response
      data$content <- df
      return(data)}else{
        return(df)
      }
  }else{cli_abort('Bad request!')}
}
