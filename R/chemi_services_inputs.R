# Legacy public formals project to the service's top-level JSON object.
.ct_services_body <- function(params, schema) {
  body <- Filter(Negate(is.null), params)
  if (!length(body)) cli::cli_abort('Either query or chemicals parameter must be provided.')
  body <- .api_validation$body_value(body, schema)
  if ('content' %in% names(params) && (is.null(body$content) || !nzchar(body$content))) {
    cli::cli_abort('Either query or chemicals parameter must be provided.')
  }
  body
}

# Convert returns an unquoted MOL/SMILES string even with application/json media.
.ct_services_convert_response <- function(response, context, decode) {
  if (context$status >= 400L) return(decode())
  observe_api_responses(list(response))
  httr2::resp_body_string(response)
}
