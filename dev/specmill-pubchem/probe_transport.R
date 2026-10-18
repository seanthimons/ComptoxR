# Usage: Rscript dev/specmill-pubchem/probe_transport.R /path/to/official-v41-library
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
library(specmill, lib.loc = args[[1L]])
stopifnot(utils::packageDescription('specmill')[['Config/specmill/source-commit']] ==
  '05862bee1804806cea157ff1962300d741516301')
pkgload::load_all('.', quiet = TRUE)
frozen <- readRDS('tests/testthat/fixtures/pubchem-retained-originals.rds')
env <- new.env(parent = asNamespace('ComptoxR'))
env$.ComptoxREnv <- new.env(parent = emptyenv())
old <- eval(frozen$functions$generic_pubchem_request, env)
request <- NULL
testthat::with_mocked_bindings({
  old(query = 'aspirin', namespace = 'name', operation = 'cids', tidy = FALSE)
}, req_perform = function(req) {
  request <<- req
  # Success mock, subject to the same status policy as the real performer.
  response <- httr2::response(status_code = 200L, url = req$url,
    headers = list(`content-type` = 'application/json'), body = charToRaw('{"IdentifierList":{"CID":[2244]}}'))
  policy <- req$policies$error_is_error
  if (is.null(policy) || policy(response)) httr2::resp_check_status(response)
  response
}, .package = 'httr2')
native <- new.env(parent = baseenv())
scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
  'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
eval(parse(text = scaffold$code), native)
new_request <- withr::with_options(list(comptoxr_native.dry_run = TRUE),
  native$.ct_request('GET', '/compound/name/{query}/cids/JSON', list(query = 'aspirin'), list(), NULL,
    server = list(url = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug'),
    request_controls = list(timeout = Inf, max_retries = 3L, retry_writes = TRUE)))
throttle_attempt <- tryCatch(withr::with_options(list(comptoxr_native.dry_run = TRUE),
  native$.ct_request('GET', '/compound/name/{query}/cids/JSON', list(query = 'aspirin'), list(), NULL,
    request_controls = list(throttle = list(capacity = 4L, fill_time_s = 1)))), error = identity)
print(names(request$policies))
print(names(new_request$policies))
stopifnot(inherits(throttle_attempt, 'httr2_request'),
  !any(grepl('throttle', names(throttle_attempt$policies))))
stopifnot(any(grepl('throttle', names(request$policies))), !any(grepl('throttle', names(new_request$policies))))
result <- list(original_policy_names = names(request$policies),
  native_policy_names = names(new_request$policies), unsupported_throttle_attempt = list(class = class(throttle_attempt),
    policies = names(throttle_attempt$policies)),
  old_url = request$url, new_url = new_request$url)
saveRDS(result, 'dev/specmill-pubchem/transport-evidence.rds')
print(result)
