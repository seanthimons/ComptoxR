# Check the same production schema routes used by the existing downloader.
production_fallbacks <- function(root = '.migration-evidence/production') {
  report <- utils::read.csv(file.path(root, 'acquisition.csv'))
  for (suffix in c('openapi.json', 'swagger.json', 'swagger.yaml', 'swagger.yml', 'swagger?format=json')) {
    pending <- which(!report$valid & startsWith(report$file, 'chemi-'))
    if (!length(pending)) {
      break
    }
    urls <- sub('api-docs$', suffix, report$url[pending])
    requests <- lapply(urls, function(url) {
      httr2::request(url) |> httr2::req_timeout(10) |> httr2::req_error(is_error = function(resp) FALSE)
    })
    responses <- httr2::req_perform_parallel(requests, on_error = 'continue', max_active = 4)
    for (j in seq_along(pending)) {
      response <- responses[[j]]
      if (!inherits(response, 'httr2_response') || httr2::resp_status(response) != 200L) {
        next
      }
      schema <- tryCatch(httr2::resp_body_json(response, simplifyVector = FALSE), error = function(e) NULL)
      if (!is.list(schema) || !length(schema$paths) || (is.null(schema$openapi) && is.null(schema$swagger))) {
        next
      }
      i <- pending[[j]]
      path <- file.path(root, report$file[[i]])
      writeBin(httr2::resp_body_raw(response), path)
      report$url[[i]] <- urls[[j]]
      report$status[[i]] <- 200L
      report$valid[[i]] <- TRUE
      report$sha256[[i]] <- digest::digest(file = path, algo = 'sha256')
    }
  }
  utils::write.csv(report, file.path(root, 'acquisition.csv'), row.names = FALSE)
  print(report[c('file', 'status', 'valid')], row.names = FALSE)
  invisible(report)
}

if (sys.nframe() == 0L) {
  production_fallbacks()
}
