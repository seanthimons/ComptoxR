# Freeze production payloads and independently replay both old and held native definitions.
pkgload::load_all('.', quiet = TRUE)
withr::local_options(list(ComptoxR.chemi_burl = 'https://hcd.rtpnc.epa.gov/api'))
held <- readRDS('dev/specmill-rebuild/calculation-facades/held-candidates.rds')
live <- readRDS('dev/specmill-rebuild/calculation-facades/initial-candidates-live.rds')
results <- list()
for (name in names(held$original)) {
  evidence <- live$results[[name]]
  response <- evidence$responses[[1L]]
  mock <- function(req) httr2::response(status_code = response$status,
    headers = list(`Content-Type` = response$media), body = response$body)
  replay <- function(definition) {
    fn <- eval(definition[[3L]], asNamespace('ComptoxR'))
    value <- httr2::with_mocked_responses(mock, tryCatch(do.call(fn, evidence$args), error = identity))
    if (inherits(value, 'error')) return(list(class = class(value), message = conditionMessage(value)))
    list(value = value)
  }
  old <- replay(held$original[[name]]); candidate <- replay(held$candidate[[name]])
  stopifnot(identical(candidate, old))
  body <- jsonlite::fromJSON(rawToChar(response$body), simplifyVector = FALSE)
  if (grepl('mordred', name)) {
    stopifnot(nrow(old$value) == 0L, length(body$chemicals) == 1L,
      any(vapply(body$chemicals[[1L]]$descriptors, is.null, FALSE)))
    defect <- 'One returned chemical and NULL descriptor slots collapse the existing wide result to zero rows.'
  } else {
    missing <- which(vapply(body$chemicals[[1L]]$endpoints, function(x) is.null(x$endpoint$id), FALSE))
    stopifnot(length(missing) > 0L, 'comptoxr_post_response_hook_error' %in% old$class,
      grepl('endpoint is missing its endpoint id', old$message, fixed = TRUE))
    defect <- paste('Production response endpoint entries without IDs:', paste(missing, collapse = ', '))
  }
  results[[name]] <- list(equal = TRUE, defect = defect, old = old)
  cat(name, ': ', defect, '\n', sep = '')
}
saveRDS(results, 'dev/specmill-rebuild/calculation-facades/source-defect-replay.rds', version = 2)
