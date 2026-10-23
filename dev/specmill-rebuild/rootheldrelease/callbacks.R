# Development-only projections for the held CheT search/page candidate.
chet_search_path <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  secondary <- operation$parameters[[2L]]$name
  endpoint <- sub('/\\{.*$', '', operation$path)
  substitute(base::local({
    req <- httr2::request(paste0('https://projection.invalid/api/chet', ENDPOINT, '/{', NAME, '}'))
    for (pp in c(params[[SECONDARY]]))
      req <- httr2::req_url_path_append(req, as.character(pp))
    substring(req$url, nchar('https://projection.invalid') + 1L)
  }), list(NAME = primary, SECONDARY = secondary, ENDPOINT = endpoint))
}
chet_search_response <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  endpoint <- paste0('chet', sub('/\\{.*$', '/', operation$path))
  substitute(function(response, context, decode) {
    .ct_collect_response(response, context, decode, length(PRIMARY), ENDPOINT)
  }, list(PRIMARY = as.name(primary), ENDPOINT = endpoint))
}
