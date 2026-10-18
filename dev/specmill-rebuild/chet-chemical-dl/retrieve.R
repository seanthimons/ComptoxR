url <- 'https://hcd.rtpnc.epa.gov/api/chet/openapi.json'
r <- httr2::req_perform(httr2::req_timeout(httr2::request(url), 30))
bytes <- httr2::resp_body_raw(r)
s <- jsonlite::fromJSON(rawToChar(bytes), simplifyVector=FALSE)
stopifnot(length(s$paths) > 0L, !is.null(s$paths[['/chemicals/chemical_DL']]$get))
writeBin(bytes, 'dev/specmill-rebuild/chet-chemical-dl/deployed-source.json')
canonicalize <- function(x) {
  if (!is.list(x)) return(x)
  if (!is.null(names(x))) x <- x[sort(names(x))]
  lapply(x, canonicalize)
}
jsonlite::write_json(list(sourceURL=url, retrieved_utc=format(Sys.time(), tz='UTC', usetz=TRUE), status=httr2::resp_status(r), media=httr2::resp_header(r, 'content-type'), sha256=digest::digest(bytes, algo='sha256', serialize=FALSE), selected_operation_matches_canonical=identical(canonicalize(s$paths[['/chemicals/chemical_DL']]$get), canonicalize(jsonlite::read_json('schema/chemi-chet-prod.json')$paths[['/chemicals/chemical_DL']]$get))), 'dev/specmill-rebuild/chet-chemical-dl/retrieval.json', pretty=TRUE, auto_unbox=TRUE)
