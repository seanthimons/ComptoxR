# Aggregate GET also supports the existing delimited response contract.
descriptor_aggregate_get_response <- function(operation) quote(function(response, context, decode) {
  if (context$status >= 400L) decode()
  if (grepl('^text/(csv|tab-separated-values|tsv)', state$request$content_type, ignore.case = TRUE)) {
    observe_api_responses(list(response))
    return(if (!startsWith(tolower(state$request$content_type), context$media)) {
      parse_delimited_response(httr2::resp_body_string(response), state$request$content_type)
    } else .ct_response_delimited(response, context, decode))
  }
  .ct_static_json_result(response, context, decode, state$request$endpoint)
})
