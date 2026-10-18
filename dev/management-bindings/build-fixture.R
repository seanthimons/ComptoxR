work <- 'dev/management-bindings'
rows <- jsonlite::read_json(file.path(work,'cases.json'))
cases <- list()
selected <- vapply(yaml::read_yaml('apis/chemi-management.yml')$operations, `[[`, '', 'name')
for(row in rows) {
  if (!row$name %in% selected) next
  method <- sub(' .*','',row$key); path <- sub('^[^ ]+ ','',row$key)
  args <- list(); query <- list()
  for(p in row$parameters) {
    value <- switch(p$name, id='report-123', name='report name', file='report.json',
      smiles='CCO', smirks='[C:1]>>[C:1]', profile='profile name', label='label name',
      format='SVG', width=240L, height=180L, freeze=FALSE, hierarchically=TRUE,
      stop(p$name))
    if(p$name=='id' && identical(p$schema$type,'integer')) value <- 7L
    args[[p$name]] <- value
    if(p[['in']]=='query') query[[p$name]] <- value
  }
  media <- NULL
  if(!is.null(row$requestBody)) {
    media <- names(row$requestBody$content)[[1L]]
    if(media=='multipart/form-data') {
      field <- if(grepl('/hazard/',path,fixed=TRUE)) 'hazardRequest' else 'alertRequest'
      request <- if (field == 'hazardRequest') {
        list(chemicals=list(list(rid='DTXSID7020182', ordinal=1L)),
          options=list(usePredictions=FALSE, cts=2L))
      } else {
        list(chemicals=list(list(sid='DTXSID7020182')),options=list(resolve=FALSE))
      }
      body <- stats::setNames(list(request), field)
      body$file <- as.raw(c(65,0,255,10,34,66))
    } else {
      ref <- row$requestBody$content[[media]]$schema[['$ref']]
      body <- switch(sub('.*/','',ref),
        ExportRequest=list(format='JSON',showDetails=TRUE,collapse=FALSE),
        LibraryGroup=list(name='reviewed group',description='quote " and newline\n',frozen=FALSE),
        HazardExportRequest=list(outputFormat='JSON',showImages=FALSE,report=list(name='reviewed report')),
        HazardReport=list(name='reviewed report',comment='quote " and newline\n'),
        ACL=list(access='PRIVATE',owner='owner name',read=list('reader'),write=list('writer')),
        Assay=list(name='reviewed assay',total=2L),
        ExportGeneratedRequest=list(format='JSON',sheet=1L,nChemical=2L),
        ExportGlobalAssaysRequest=list(format='JSON',sheet=1L,label='label name'),
        stop(ref))
    }
    args$body <- body
  }
  cases[[row$name]] <- list(method=method,path=gsub('{id}','report-123',path,fixed=TRUE),
    args=args,query=query,body_media=media,source=row$schema,
    source_sha256=digest::digest(file=row$schema,algo='sha256'))
}
stopifnot(length(cases)==24L)
saveRDS(cases, 'tests/testthat/fixtures/native-management.rds')
