chet_options_paths <- c(chemi_chet_reaction_batchsearch_options='/api/chet/reaction/batchsearch', chemi_chet_reaction_map_dl_options='/api/chet/reaction/map_DL')
test_that('released native OPTIONS wrappers send and decode actual localhost requests', {
 skip_if_not_installed('httpuv');skip_if_not_installed('callr')
 expect_true(all(names(chet_options_paths) %in% getNamespaceExports('ComptoxR')))
 directory <- tempfile('chet-options-');dir.create(directory);on.exit(unlink(directory,recursive=TRUE),add=TRUE)
 saveRDS(list(status=200L,body=''),file.path(directory,'response.rds'))
 server <- callr::r_bg(function(directory) {
  port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1',port,list(call=function(request) {
   saveRDS(list(method=request$REQUEST_METHOD,path=request$PATH_INFO,query=request$QUERY_STRING,body=rawToChar(request$rook.input$read())),file.path(directory,'request.rds'))
   response <- readRDS(file.path(directory,'response.rds'))
   list(status=response$status,headers=list('Content-Type'='application/json',Connection='close'),body=response$body)
  }))
  saveRDS(port,file.path(directory,'ready.rds'));repeat httpuv::service(50)
 },args=list(directory),supervise=TRUE)
 on.exit(server$kill(),add=TRUE)
 for(i in seq_len(400L)) {if(file.exists(file.path(directory,'ready.rds')) || !server$is_alive()) break;Sys.sleep(.05)}
 expect_true(file.exists(file.path(directory,'ready.rds')))
 withr::local_options(list(ComptoxR.chemi_burl=paste0('http://127.0.0.1:',readRDS(file.path(directory,'ready.rds'))),comptoxr_native.request=list(max_retries=0L,timeout=5)))
 local_mocked_bindings(is_transient_error=function(...) FALSE,.package='ComptoxR')
 for(name in names(chet_options_paths)) {
  fn <- getExportedValue('ComptoxR',name);expect_length(formals(fn),0L)
  if (file.exists(test_path('..', '..', 'specmill.yml'))) {
    expect_true(file.exists(test_path('../..','man',paste0(name,'.Rd'))))
  }
  for(reply in list(list(status=200L,body='',value=NULL),list(status=204L,body='',value=NULL),list(status=200L,body='{"preflight":true}',value=list(preflight=TRUE)))) {
   saveRDS(reply,file.path(directory,'response.rds'));expect_identical(fn(),reply$value)
   expect_identical(readRDS(file.path(directory,'request.rds')),list(method='OPTIONS',path=unname(chet_options_paths[[name]]),query='',body=''))
  }
  for(status in c(400L,404L,500L,401L)) {
   saveRDS(list(status=status,body='{"error":"wire"}'),file.path(directory,'response.rds'))
   error <- tryCatch(fn(),error=identity)
   if(status==401L) expect_s3_class(error,'specmill_call_error') else {
    expect_s3_class(error,paste0('httr2_http_',status));expect_identical(httr2::resp_status(error$resp),status)
    expect_identical(httr2::resp_body_string(error$resp),'{"error":"wire"}')
   }
  }
 }
})
test_that('OPTIONS preserves original transport identity and rejects invalid controls before HTTP', {
 calls <- 0L
 original <- structure(list(message='transport sentinel',call=NULL),class=c('httr2_failure','httr2_error','rlang_error','error','condition'))
 local_mocked_bindings(req_perform=function(...) {calls <<- calls+1L;stop(original)},.package='httr2')
 for(name in names(chet_options_paths)) {
  fn <- getExportedValue('ComptoxR',name)
  expect_identical(tryCatch(fn(),error=identity),original)
  withr::with_options(list(comptoxr_native.request=list(timeout=-1)),expect_error(fn(),class='specmill_call_error'))
  expect_error(fn(unexpected=1),'unused argument')
 }
 expect_identical(calls,2L)
})
