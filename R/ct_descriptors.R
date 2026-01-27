# TODO Migrate to generic requests + promote to stable after testing

#' INDIGO conversion service
#'
#' Takes SMILES or MOL array for input to convert a single compound.
#'
#' @param query SMILES or MOL array
#' @param type Search type: 'smiles', 'canonical_smiles', 'mol2000', 'mol3000', or 'inchi'
#'
#' @return A string with the converted structure
#' @export

ct_descriptors <- function(
  query,
  type = c('smiles', 'canonical_smiles', 'mol2000', 'mol3000', 'inchi')
) {

  if (grepl(pattern = 'DTX', x = query)) {
    cli::cli_abort('DTXSID string detected! Use a SMILES or MOL!')
  }

  if (missing(type) | is.null(type)) {
    cli::cli_abort('Missing search parameter!')
  }

  # Map type to endpoint path
  type_option <- switch(
    type,
    'smiles' = 'to-smiles',
    'canonical_smiles' = 'to-canonicalsmiles',
    'mol2000' = 'to-mol2000',
    'mol3000' = 'to-mol3000',
    'inchi' = 'to-inchi',
    cli::cli_abort('Invalid type specified!')
  )

  # Build request
  ctx_burl <- Sys.getenv('ctx_burl')

  req <- httr2::request(ctx_burl) %>%
    httr2::req_url_path_append('chemical/indigo/') %>%
    httr2::req_url_path_append(type_option) %>%
    httr2::req_method("POST") %>%
    httr2::req_body_raw(query, type = "text/plain") %>%
    httr2::req_headers(`x-api-key` = ct_api_key())

  # Perform request
  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) == 200) {
    return(httr2::resp_body_string(resp))
  } else {
    cli::cli_abort('Bad request! Status: {httr2::resp_status(resp)}')
  }
}
