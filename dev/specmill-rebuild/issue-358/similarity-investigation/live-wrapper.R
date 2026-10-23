# Live calculation only; use an isolated installed package library as argument.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
library("ComptoxR", lib.loc = args[[1L]], character.only = TRUE)
folder <- 'dev/specmill-rebuild/issue-358/similarity-investigation'
origins <- c(development = 'https://cim-dev.sciencedataexperts.com',
  production = 'https://hcd.rtpnc.epa.gov')
results <- list()
for (environment in names(origins)) {
  options(ComptoxR.chemi_burl = origins[[environment]],
    comptoxr_native.request = list(max_retries = 0L, timeout = 30))
  query <- c('DTXSID7020182', 'DTXSID9020112')
  result <- chemi_resolver_getsimilaritylist(query = query, main = query[[1L]])
  stopifnot(is.list(result), length(result) == 1L,
    identical(result[[1L]]$chemical$sid, query[[2L]]),
    isTRUE(all.equal(result[[1L]]$similarity$sim, 0.138)))
  self <- chemi_resolver_getsimilaritylist(query = query[[1L]], main = query[[1L]])
  stopifnot(is.list(self), length(self) == 0L)
  results[[environment]] <- list(at = format(Sys.time(), tz = 'UTC', usetz = TRUE),
    origin = origins[[environment]], query = query, main = query[[1L]],
    result = result, self = self)
}
jsonlite::write_json(results, file.path(folder, 'installed-wrapper-live.json'),
  pretty = TRUE, auto_unbox = TRUE, null = 'null')
cat('Installed generated wrapper: development and production results and self exclusion passed.\n')
