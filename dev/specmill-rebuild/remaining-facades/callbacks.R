# Pure schema-body projections for the remaining legacy public signatures.
remaining_facade_body <- function(operation) {
  primary <- switch(operation$path,
    '/api/resolver/safety-flags' = 'additionalProps',
    '/api/stdizer/groups' = 'acl',
    '/api/alerts/groups' = 'description')
  array <- identical(operation$path, '/api/resolver/safety-flags')
  schema <- if (array) operation$schema_body$items else operation$schema_body
  fields <- intersect(names(schema$properties), vapply(operation$parameters, `[[`, '', 'name'))
  fields <- c(setdiff(fields, primary), primary)
  body <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(field) as.call(list(call('[[', as.name('params'), field)))), fields)))
  substitute(base::local({
    body <- BODY
    value <- unique(as.vector(body[[PRIMARY]]))
    value <- value[!is.na(value) & value != '']
    if (!length(value)) cli::cli_abort('Either query or chemicals parameter must be provided.')
    body <- base::Filter(base::Negate(base::is.null), body)
    body <- .api_validation$body_value(body, SCHEMA)
    if (ARRAY) list(body) else body
  }), list(PRIMARY=primary, BODY=body, SCHEMA=schema, ARRAY=array))
}

# Unbatched legacy facades expose httr2's received status condition, including 401.
remaining_facade_response <- function(operation) {
  substitute(function(response, context, decode) {
    if (context$status >= 400L) httr2::resp_check_status(response)
    context$endpoint <- ENDPOINT
    .ct_chemi_result(response, context, decode, tidy = FALSE)
  }, list(ENDPOINT = sub('^/api/', '', operation$path)))
}
