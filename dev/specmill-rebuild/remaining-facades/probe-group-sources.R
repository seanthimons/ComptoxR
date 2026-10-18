# Read service declarations only; this never invokes a group mutation.
results <- list()
for (base in c('https://hcd.rtpnc.epa.gov', 'https://cim.sciencedataexperts.com')) {
  for (service in c('stdizer', 'alerts')) {
    url <- paste0(base, '/api/', service, '/api-docs')
    request <- httr2::request(url) |> httr2::req_error(is_error = function(response) FALSE) |> httr2::req_timeout(20)
    response <- tryCatch(httr2::req_perform(request), error = identity)
    record <- if (inherits(response, 'error')) list(url = url, error = conditionMessage(response)) else
      list(url = url, status = httr2::resp_status(response), body = httr2::resp_body_string(response))
    results[[url]] <- record
    if (!is.null(record$status) && record$status == 200L) {
      document <- jsonlite::fromJSON(record$body, simplifyVector = FALSE)
      operation <- document$paths[[paste0('/api/', service, '/groups')]]$post
      cat(url, '\n'); str(operation$parameters, max.level = 2)
    }
  }
}
saveRDS(results, 'dev/specmill-rebuild/remaining-facades/group-source-review.rds')
