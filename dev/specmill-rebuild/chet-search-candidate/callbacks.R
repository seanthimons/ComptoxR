# Development-only projections for the held CheT search/page candidate.
chet_search_path <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  secondary <- operation$parameters[[2L]]$name
  endpoint <- sub('/\\{.*$', '', operation$path)
  substitute(base::local({
    trailing <- params[[SECONDARY]]
    if (length(trailing) && length(PRIMARY) > 1L)
      cli::cli_abort('Cannot use path_params with batching. Path parameter endpoints do not support batch queries.')
    paste0('/api/chet', ENDPOINT, '/{', NAME, '}',
      if (length(trailing)) paste0('/', paste(as.character(trailing), collapse = '/')) else '')
  }), list(PRIMARY = as.name(primary), NAME = primary, SECONDARY = secondary, ENDPOINT = endpoint))
}
chet_search_response <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  endpoint <- paste0('chet', sub('/\\{.*$', '/', operation$path))
  substitute(function(response, context, decode) {
    .ct_collect_response(response, context, decode, length(PRIMARY), ENDPOINT)
  }, list(PRIMARY = as.name(primary), ENDPOINT = endpoint))
}
