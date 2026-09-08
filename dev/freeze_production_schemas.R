# Acquire approved production inputs without changing generation or configuration.
freeze_production_schemas <- function(root = '.migration-evidence/production') {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  files <- list.files('schema', pattern = '^chemi-.*-prod[.]json$', full.names = FALSE)
  components <- sub('^chemi-(.*)-prod[.]json$', '\\1', files)
  ctx <- c('chemical', 'hazard', 'exposure', 'bioactivity')
  urls <- c(
    stats::setNames(paste0('https://comptox.epa.gov/ctx-api/docs/', ctx, '.json'), paste0('ctx-', ctx, '-prod.json')),
    stats::setNames(paste0('https://hcd.rtpnc.epa.gov/api/', components, '/api-docs'), files),
    'epi-suite-prod.json' = 'https://episuite.dev/api'
  )
  requests <- lapply(urls, function(url) {
    httr2::request(url) |> httr2::req_timeout(20) |> httr2::req_error(is_error = function(resp) FALSE)
  })
  responses <- httr2::req_perform_parallel(requests, on_error = 'continue', max_active = 4)
  report <- lapply(seq_along(urls), function(i) {
    response <- responses[[i]]
    status <- if (inherits(response, 'httr2_response')) httr2::resp_status(response) else NA_integer_
    schema <- if (identical(status, 200L)) {
      tryCatch(httr2::resp_body_json(response, simplifyVector = FALSE), error = function(e) NULL)
    } else {
      NULL
    }
    valid <- is.list(schema) && length(schema$paths) > 0L && (!is.null(schema$openapi) || !is.null(schema$swagger))
    path <- file.path(root, names(urls)[[i]])
    if (valid) {
      writeBin(httr2::resp_body_raw(response), path)
    }
    data.frame(
      file = names(urls)[[i]],
      url = urls[[i]],
      status = status,
      valid = valid,
      sha256 = if (valid) digest::digest(file = path, algo = 'sha256') else NA_character_
    )
  })
  report <- do.call(rbind, report)
  utils::write.csv(report, file.path(root, 'acquisition.csv'), row.names = FALSE)
  print(report[c('file', 'status', 'valid')], row.names = FALSE)
  invisible(report)
}

if (sys.nframe() == 0L) {
  freeze_production_schemas()
}
