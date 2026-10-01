# Explicit live check; never run by the offline test suite.
options(ComptoxR.run_verbose = FALSE)
pkgload::load_all('.', quiet = TRUE)
perform <- httr2::req_perform
results <- list()
for (format in c('png', 'svg', 'pdf')) {
  response <- NULL
  testthat::with_mocked_bindings(
    {
      result <- chemi_chet_chemicals_image(1L, format = format)
    },
    req_perform = function(req, ...) {
      response <<- perform(httr2::req_timeout(req, 30), ...)
      response
    },
    .package = 'httr2'
  )
  expected_media <- switch(format, png = 'image/png', svg = 'image/svg+xml', pdf = 'application/pdf')
  stopifnot(httr2::resp_status(response) == 200L, httr2::resp_header(response, 'content-type') == expected_media)
  if (format == 'pdf') {
    stopifnot(is.raw(result), startsWith(rawToChar(result[1:5]), '%PDF-'))
  } else {
    stopifnot(inherits(result, 'magick-image'), length(result) == 1L)
  }
  results[[format]] <- list(
    status = 200L,
    media = expected_media,
    classes = class(result),
    response_bytes = length(httr2::resp_body_raw(response)),
    image = if (format != 'pdf') as.list(magick::image_info(result)) else NULL
  )
}
report <- list(
  checked_at = format(Sys.time(), tz = 'UTC', usetz = TRUE),
  endpoint = 'https://hcd.rtpnc.epa.gov/api/chet/chemicals/1/image',
  magick = as.character(utils::packageVersion('magick')),
  results = results
)
jsonlite::write_json(report, 'dev/specmill-342/image-results.json', pretty = TRUE, auto_unbox = TRUE, null = 'null')
print(results)
