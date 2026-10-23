.ct_prediction <- function(response, context, decode) {
  observe_api_responses(list(response))
  body <- .ct_response_json(response)
  if (!length(body)) list() else body
}
