# Bounded live calls through an isolated installed generated package; no localhost.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
library('ComptoxR', lib.loc = args[[1L]])
run <- function() {
  folder <- 'dev/specmill-rebuild/issue-353'
  origins <- c(development = 'https://cim-dev.sciencedataexperts.com',
    production = 'https://hcd.rtpnc.epa.gov')
  withr::local_envvar(c(batch_limit = '2', ctx_api_key = NA_character_))
  env <- get('.ComptoxREnv', asNamespace('ComptoxR'))
  old <- env$probe_observer
  on.exit(env$probe_observer <- old, add = TRUE)
  results <- list()
  for (environment in names(origins)) {
    options(ComptoxR.chemi_burl = origins[[environment]],
      comptoxr_native.request = list(max_retries = 0L, timeout = 30))
    observed <- list()
    env$probe_observer <- function(response) {
      observed[[length(observed) + 1L]] <<- list(url = response$url,
        status = httr2::resp_status(response))
    }
    result <- chemi_toxprints_bulk(c('CCO', 'CCCO', 'CCCCO', 'CCO', NA, ''))
    stopifnot(inherits(result, 'tbl_df'), nrow(result) == 3L,
      all(c('info', 'descriptors', 'smiles') %in% names(result)), length(observed) == 2L,
      all(vapply(observed, function(x) x$status == 200L, TRUE)))
    stopifnot(identical(result$smiles, c('CCO', 'CCCO', 'CCCCO')),
      is.list(result$descriptors),
      all(lengths(result$descriptors) == 729L),
      all(vapply(result$descriptors, is.numeric, TRUE)),
      all(vapply(result$info, function(x) identical(x$name, 'toxprints'), TRUE)))
    if (environment == 'development') {
      failure <- tryCatch(chemi_toxprints_bulk('DTXSID7020182'), error = identity)
      stopifnot(inherits(failure, 'httr2_http_400'))
      results$development_invalid_structure <- list(class = class(failure),
        message = conditionMessage(failure))
      partial <- withr::with_envvar(c(batch_limit = '1'),
        chemi_toxprints_bulk(c('CCO', 'DTXSID7020182')))
      stopifnot(nrow(partial) == 1L, identical(partial$smiles, 'CCO'))
      results$development_partial <- partial
    }
    results[[environment]] <- list(at = format(Sys.time(), tz = 'UTC', usetz = TRUE),
      observed = observed, result = result)
  }
  identifier <- chemi_toxprints_bulk('DTXSID7020182')
  stopifnot(nrow(identifier) == 1L,
    length(identifier$descriptors[[1L]]) == 729L)
  results$production_identifier <- identifier
  saveRDS(results, file.path(folder, 'installed-live.rds'))
  jsonlite::write_json(results, file.path(folder, 'installed-live.json'),
    auto_unbox = TRUE, pretty = TRUE, null = 'null')
  cat('Installed bulk wrapper: live cleanup, 2+1 chunking, descriptors and production DTXSID passed.\n')
}
run()
