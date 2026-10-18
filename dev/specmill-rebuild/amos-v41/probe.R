# Read-only deployed controls; no cookies, credentials or state changes.
cases <- c(additional_sources='/api/amos/additional_sources_for_substance/DTXSID7020182',pdf_metadata='/api/amos/get_pdf_metadata/Fact%20Sheet/FS-10313',substance_file='/api/amos/get_substance_file_for_record/FS-10313')
evidence <- lapply(cases,function(path) {
 req <- httr2::req_error(httr2::req_timeout(httr2::request(paste0('https://hcd.rtpnc.epa.gov',path)),30),is_error=function(resp)FALSE)
 resp <- httr2::req_perform(req)
 list(path=path,status=httr2::resp_status(resp),media=httr2::resp_header(resp,'content-type'),bytes=httr2::resp_body_raw(resp))
})
saveRDS(list(time=format(Sys.time(),tz='UTC'),origin='https://hcd.rtpnc.epa.gov',evidence=evidence),'dev/specmill-rebuild/amos-v41/live.rds')
print(lapply(evidence,function(x)list(path=x$path,status=x$status,media=x$media,bytes=length(x$bytes),preview=if(length(x$bytes)<4000)rawToChar(x$bytes) else NULL)))
