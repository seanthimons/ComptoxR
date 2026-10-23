# Public calculation probes only; use direct SMILES and no CTX credentials.
probe_four <- function() {
  pkgload::load_all('.', quiet = TRUE)
  withr::local_options(list(ComptoxR.chemi_burl = 'https://hcd.rtpnc.epa.gov/api',
    comptoxr_native.request = list(max_retries = 0L, timeout = 30)))
  ns <- asNamespace('ComptoxR'); responses <- list()
  observer <- ns$observe_api_responses
  testthat::local_mocked_bindings(observe_api_responses = function(x) {
    responses <<- c(responses, lapply(x, function(response) list(
      status = httr2::resp_status(response), url = response$url,
      media = httr2::resp_header(response, 'content-type'), body = httr2::resp_body_raw(response))))
    observer(x)
  }, .package = 'ComptoxR')
  results <- list()
  for (name in c('chemi_mordred','chemi_mordred_bulk','chemi_webtest_predict','chemi_webtest_predict_bulk')) {
    fn <- get(name, ns)
    stopifnot(any(grepl('.ct_request', deparse(body(fn)), fixed = TRUE)))
    args <- list('CCO')
    if (grepl('predict',name)) args[[if(grepl('_bulk$',name)) 'endpoints' else 'endpoint']] <- 'LC50'
    responses <- list(); warnings <- character()
    value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity),
      warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning') })
    results[[name]] <- list(args = args, responses = responses, warnings = warnings,
      value = if (!inherits(value, 'error')) value,
      error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)))
    cat(name, ': ', if (inherits(value, 'error')) conditionMessage(value) else paste(nrow(value), 'rows', ncol(value)-10L, 'descriptors'),
      '; HTTP ', paste(vapply(responses, `[[`, 0L, 'status'), collapse = ','), '\n', sep = '')
  }
  saveRDS(list(time = format(Sys.time(),tz='UTC'), results = results),
    'dev/specmill-rebuild/four-calculations-v41/fresh-production.rds',version=2)
}
probe_four()
