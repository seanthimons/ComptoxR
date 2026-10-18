# Read-only deployed evidence, including raw status/body independent of decoding.
pkgload::load_all(quiet = TRUE)
root <- 'dev/specmill-rebuild/chet-chemical-dl'
url <- 'https://hcd.rtpnc.epa.gov/api/chet/chemicals/chemical_DL'
fetch <- function(body = NULL) {
  request <- httr2::request(url)
  if (!is.null(body)) request <- httr2::req_body_json(request, body, auto_unbox = TRUE)
  request <- httr2::req_method(request, 'GET')
  response <- httr2::req_perform(httr2::req_error(httr2::req_timeout(request, 60), is_error = function(r) FALSE))
  list(method = 'GET', url = url, body = if (is.null(body)) NULL else '{}',
    status = httr2::resp_status(response), media = httr2::resp_header(response, 'content-type'),
    bytes = httr2::resp_body_raw(response))
}
empty <- stats::setNames(list(), character())
evidence <- list(retrieved_utc = format(Sys.time(), tz = 'UTC', usetz = TRUE), omitted = fetch(), object = fetch(empty))
saveRDS(evidence, file.path(root, 'live.rds'))
stopifnot(evidence$omitted$status == 400L,
  grepl('Request body must not be empty', rawToChar(evidence$omitted$bytes), fixed = TRUE),
  evidence$object$status == 200L, startsWith(evidence$object$media, 'text/csv'))
text <- rawToChar(evidence$object$bytes)
connection <- textConnection(text)
counts <- utils::count.fields(connection, sep = ',', quote = '"', comment.char = '')
close(connection)
# The deployed CSV appends quoted empty records with only one field.
lines <- strsplit(text, '\n', fixed = TRUE)[[1L]]
trailer <- which(!is.na(counts) & counts != 6L)
stopifnot(length(trailer) > 0L, !anyNA(counts),
  identical(trailer, seq.int(min(trailer), length(counts))),
  all(counts[trailer] == 1L), all(lines[trailer] == '""'))
records <- utils::read.csv(text = text, check.names = FALSE, colClasses = 'character', fill = FALSE)
stopifnot(nrow(records) > 0L, identical(names(records),
  c('Name', 'DTXSID', 'SMILES', 'InChI Key', 'CASRN', 'Representative')),
  nrow(records) == sum(counts == 6L) - 1L,
  all(grepl('^DTXSID[0-9]+$', records$DTXSID)))
withr::local_options(list(comptoxr_native.request = list(timeout = 60, max_retries = 0)))
decoded <- chemi_chet_chemicals_chemical_dl(empty)
stopifnot(is.character(decoded), length(decoded) == 1L, identical(decoded, text))
decoded_records <- utils::read.csv(text = decoded, check.names = FALSE, colClasses = 'character')
stopifnot(identical(records, decoded_records))
summary <- list(retrieved_utc = evidence$retrieved_utc, omitted_status = evidence$omitted$status,
  omitted_body = rawToChar(evidence$omitted$bytes), object_status = evidence$object$status,
  media = evidence$object$media, bytes = length(evidence$object$bytes),
  sha256 = digest::digest(evidence$object$bytes, algo = 'sha256', serialize = FALSE),
  header = names(records), rows = nrow(records), columns = ncol(records),
  consistent_csv_field_counts = FALSE, trailing_quoted_empty_records = length(trailer),
  csv_limitation = 'Six-column chemical records followed by single-field quoted empty records; read.csv skips this trailer.',
  generated_binding_matches_capture = TRUE)
jsonlite::write_json(summary, file.path(root, 'live-summary.json'), pretty = TRUE, auto_unbox = TRUE)
print(summary)
