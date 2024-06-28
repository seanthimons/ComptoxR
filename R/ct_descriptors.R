#' INDIGO conversion service
#'
#' Takes SMILES or MOL array for input to convert a single compound.
#'
#' @param query SMILES or MOL array
#' @param type Search type
#'
#' @return A string

ct_descriptors <- function(query,
                           type = c('smiles', 'canonical_smiles', 'mol2000', 'mol3000', 'inchi'),
                           #coerce = T,
                           ccte_api_key = NULL
                           #debug = F
                           ){

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

  payload <- query

# request -----------------------------------------------------------------

  burl <- Sys.getenv('burl')

  response <- POST(
    url <- paste0(burl, 'chemical/indigo/', type_option),
    body = payload,
    content_type("text/plain"),
    #content_type("application/json"),
    #accept("application/json"),
    #encode = "json",
    add_headers(`x-api-key` = token),
    progress()
  )

  if(response$status_code == 200){

    df <- content(response, "text", encoding = "UTF-8")

    return(df)

  }else{
    cli::cli_abort('Bad request!')}

}
