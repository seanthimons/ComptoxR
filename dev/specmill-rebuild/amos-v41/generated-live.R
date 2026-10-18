# Three production GETs through the final generated wrappers, no session changes.
pkgload::load_all(quiet=TRUE)
withr::local_options(list(ComptoxR.chemi_burl='https://hcd.rtpnc.epa.gov',comptoxr_native.request=list(max_retries=0L,timeout=30)))
values <- list(
 sources=chemi_amos_additional_sources_for_substance('DTXSID7020182'),
 metadata=chemi_amos_get_pdf_metadata('Fact Sheet','FS-10313'),
 workbook=chemi_amos_get_substance_file_for_record('FS-10313'))
stopifnot(length(values$sources)>0L,all(vapply(values$sources,function(x)identical(x$dtxsid,'DTXSID7020182')&&nzchar(x$link),logical(1))),
 is.character(values$metadata$pdf_name),nzchar(values$metadata$pdf_name),length(values$metadata$metadata_rows)>0L,is.raw(values$workbook))
p <- tempfile(fileext='.xlsx'); writeBin(values$workbook,p)
stopifnot(all(c('xl/workbook.xml','xl/worksheets/sheet1.xml') %in% utils::unzip(p,list=TRUE)$Name))
contents <- paste(readLines(unz(p,'xl/worksheets/sheet1.xml'),warn=FALSE),collapse='')
stopifnot(grepl('DTXSID7020182',contents,fixed=TRUE))
unlink(p)
saveRDS(list(time=format(Sys.time(),tz='UTC'),origin='https://hcd.rtpnc.epa.gov',values=values),'dev/specmill-rebuild/amos-v41/generated-live.rds')
cat('PASS three generated production GETs; populated links, PDF metadata and workbook\n')
