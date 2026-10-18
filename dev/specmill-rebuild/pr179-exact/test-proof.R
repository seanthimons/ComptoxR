root <- Sys.getenv('PR179_ROOT')
folder <- file.path(root, 'dev/specmill-rebuild/pr179-exact')
cache <- Sys.getenv('PR179_CACHE', path.expand('~/.cache/comptoxr-pr179'))
.libPaths(c(file.path(cache,'library'),.libPaths()))
pkgload::load_all(root, quiet = TRUE)
ns <- asNamespace('ComptoxR')
old <- new.env(parent = ns); candidate <- new.env(parent = ns)
for (name in c('chemi_search','chemi_resolver_getpubchemlist')) {
  sys.source(file.path(folder,paste0('old-', name,'.R.txt')),old)
  sys.source(file.path(cache,'project/R',paste0(name,'.R')),candidate)
}
sys.source(file.path(cache,'project/R/z_specmill_request.R'),candidate)
sys.source(file.path(folder,'policy.R'),candidate)
candidate$.ct_server_url <- get('.ct_server_url',ns)
# Runtime lookup requires the helper and policy functions in the same private owner env.
trace <- list(); state_override <- NULL; return_state <- FALSE
hook <- function(name, stage, data) {
  trace[[length(trace)+1L]] <<- list(name = name, stage = stage, data = data)
  if (stage == 'pre_request' && !is.null(state_override)) return(state_override)
  if (stage == 'post_response' && return_state) return(data)
  get('run_hook',ns)(name,stage,data)
}
old$run_hook <- candidate$run_hook <- hook

testthat::test_that('official generation is validated, fresh and owned', {
  p <- readRDS(file.path(folder,'generation.rds')); f <- readRDS(file.path(folder,'freshness.rds'))
  for (x in list(p,f)) {
    testthat::expect_length(x$diagnostics,0)
    testthat::expect_length(x$mapping_diagnostics,0)
    testthat::expect_length(x$retained_diagnostics,0)
    testthat::expect_length(x$drift,0)
    testthat::expect_true(all(vapply(x$validation,function(v) v$status == 'passed',logical(1))))
  }
  testthat::expect_true(all(vapply(f$files,function(x) x$action == 'unchanged',logical(1))))
  testthat::expect_true(readRDS(file.path(folder,'ownership.rds'))$owners > 0)
  for (n in c('chemi_search','chemi_resolver_getpubchemlist'))
    testthat::expect_identical(formals(old[[n]]),formals(candidate[[n]]))
})
testthat::test_that('search skip remains lazy but NULL result slot differs', {
  return_state <<- TRUE
  for (val in list('skip',NULL)) {
    state_override <<- list(params = list(query='partial'), marker = structure('kept',class='sentinel'),
      request = list(body='kept'), skip_request=TRUE, result=val)
    trace <<- list(); a <- old$chemi_search(all_pages=stop('forced'))
    testthat::expect_identical(vapply(trace,`[[`,'','stage'),c('pre_request','post_response'))
    trace <<- list(); b <- candidate$chemi_search(all_pages=stop('forced'))
    testthat::expect_identical(vapply(trace,`[[`,'','stage'),c('pre_request','post_response'))
    testthat::expect_identical(names(trace[[1]]$data$params),setdiff(names(formals(old$chemi_search)),'all_pages'))
    if (!is.null(val)) testthat::expect_identical(a,b) else {
      testthat::expect_false('result' %in% names(a))
      testthat::expect_true('result' %in% names(b))
      b$result <- NULL; testthat::expect_identical(a,b)
    }
  }
  return_state <<- FALSE; state_override <<- NULL
})

# Real HTTP server and the real httr2 sequential executor, with only localhost origins.
directory <- file.path(cache,'http'); dir.create(directory,showWarnings=FALSE)
unlink(list.files(directory,full.names=TRUE))
server <- callr::r_bg(function(directory) {
  count <- 0L; port <- httpuv::randomPort()
  httpuv::startServer('127.0.0.1',port,list(call=function(req) {
    if(file.exists(file.path(directory,'reset'))) {count <<- 0L; unlink(file.path(directory,'reset'))}
    count <<- count+1L
    saveRDS(list(method=req$REQUEST_METHOD,path=req$PATH_INFO,query=req$QUERY_STRING,
      body=rawToChar(req$rook.input$read())),file.path(directory,paste0('wire-',count,'.rds')))
    scenario <- readRDS(file.path(directory,'scenario.rds'))
    if(grepl('lookup',req$PATH_INFO)) return(list(status=200L,headers=list('Content-Type'='application/json'),
      body='[{"result":"FOUND","chemical":{"sid":"DTXSID7020182","name":"BPA"}}]'))
    response <- scenario[[min(count,length(scenario))]]
    list(status=response$status,headers=list('Content-Type'='application/json'),body=response$body)
  }))
  saveRDS(port,file.path(directory,'ready'))
  repeat httpuv::service(100)
},list(directory),supervise=TRUE)
for(i in 1:200) {if(file.exists(file.path(directory,'ready'))) break; Sys.sleep(.05)}
stopifnot(file.exists(file.path(directory,'ready')))
origin <- paste0('http://127.0.0.1:',readRDS(file.path(directory,'ready')))
options(ComptoxR.chemi_burl=origin,comptoxr_native.request=list(max_retries=0L,timeout=2))
invoke <- function(env,name='chemi_search',scenario,args=list(),override=NULL,raw=FALSE) {
  unlink(list.files(directory,pattern='^wire-',full.names=TRUE))
  saveRDS(scenario,file.path(directory,'scenario.rds')); file.create(file.path(directory,'reset'))
  trace <<- list(); state_override <<- override; return_state <<- raw
  warnings <- character()
  result <- withCallingHandlers(tryCatch(suppressMessages(do.call(env[[name]],args)),error=identity),
    warning=function(w) {warnings <<- c(warnings,conditionMessage(w)); invokeRestart('muffleWarning')})
  list(value=result,trace=trace,warnings=warnings,wires=lapply(list.files(directory,pattern='^wire-',full.names=TRUE),readRDS))
}
page <- function(offset,total=2) list(status=200L,body=jsonlite::toJSON(list(totalRecordsCount=total,
 recordsCount=1L,offset=offset,records=list(list(sid=paste0('sid',offset)))),auto_unbox=TRUE))
args <- list(search_type='mass',mass_type='mono',min_mass=100,max_mass=101,limit=1)
observations <- list()
testthat::test_that('actual search normalization and real single/paged requests are compared', {
  for(paged in c(FALSE,TRUE)) {
    a <- invoke(old,scenario=list(page(0),page(1)),args=c(args,list(all_pages=paged)))
    b <- invoke(candidate,scenario=list(page(0),page(1)),args=c(args,list(all_pages=paged)))
    observations[[paste0('search-',paged)]] <<- list(old=a,candidate=b)
    testthat::expect_identical(a$value,b$value)
    testthat::expect_identical(vapply(b$trace,`[[`,'','stage'),c('pre_request','post_response'))
    testthat::expect_length(b$wires,if(paged) 2L else 1L)
    testthat::expect_identical(b$wires[[1]]$path,'/search')
    testthat::expect_identical(b$wires[[1]]$method,'POST')
    ba <- lapply(a$wires,function(w) jsonlite::fromJSON(w$body,simplifyVector=FALSE))
    bb <- lapply(b$wires,function(w) jsonlite::fromJSON(w$body,simplifyVector=FALSE))
    if(!paged) testthat::expect_identical(ba,bb) else {
      testthat::expect_null(ba[[1]]$offset)
      testthat::expect_equal(bb[[1]]$offset,0)
      testthat::expect_equal(bb[[2]]$offset,1)
      bb[[1]]$offset <- NULL
      testthat::expect_identical(ba,bb)
    }
  }
})
testthat::test_that('full returned search state and hook transport override expose exact regression', {
  override <- list(params=list(query='changed',all_pages=FALSE),marker='keep',
    request=list(body=list(searchType='MASS',params=list(limit=1)),options=list(limit=1)))
  a <- invoke(old,scenario=list(page(0),page(1)),args=list(all_pages=TRUE),override=override,raw=TRUE)
  b <- invoke(candidate,scenario=list(page(0),page(1)),args=list(all_pages=TRUE),override=override,raw=TRUE)
  observations$partial_control <<- list(old=a,candidate=b)
  testthat::expect_length(a$wires,2L)
  testthat::expect_s3_class(b$value,'error')
  testthat::expect_match(conditionMessage(b$value),'attempt to apply non-function')
  testthat::expect_length(b$wires,0L)
  override$params$all_pages <- NULL
  a <- invoke(old,scenario=list(page(0),page(1)),args=list(all_pages=TRUE),override=override,raw=TRUE)
  b <- invoke(candidate,scenario=list(page(0),page(1)),args=list(all_pages=TRUE),override=override,raw=TRUE)
  testthat::expect_identical(a$value,b$value)
})
testthat::test_that('received errors, malformed JSON, dryrun and invalid config are recorded', {
  for(paged in c(FALSE,TRUE)) for(status in c(401L,404L,500L)) {
    scenario <- if(paged) list(page(0),list(status=status,body='{"error":"sentinel"}')) else list(list(status=status,body='{"error":"sentinel"}'))
    a <- invoke(old,scenario=scenario,args=c(args,list(all_pages=paged)))
    b <- invoke(candidate,scenario=scenario,args=c(args,list(all_pages=paged)))
    observations[[paste(status,paged)]] <<- list(old=a,candidate=b)
    testthat::expect_length(b$wires,if(paged) 2L else 1L)
    if(paged && status!=401L) testthat::expect_identical(a$value,b$value) else testthat::expect_s3_class(b$value,'error')
    if(!paged && status!=401L) {
      testthat::expect_s3_class(b$value,paste0('httr2_http_',status))
      testthat::expect_identical(httr2::resp_body_string(b$value$resp),'{"error":"sentinel"}')
    }
    if(status==401L) testthat::expect_s3_class(b$value,'specmill_call_error')
  }
  for(paged in c(FALSE,TRUE)) {
    b <- invoke(candidate,scenario=list(list(status=200L,body='{broken')),args=c(args,list(all_pages=paged)))
    testthat::expect_s3_class(b$value,'error')
    testthat::expect_length(b$wires,1L)
  }
  options(comptoxr_native.dry_run=TRUE)
  b <- invoke(candidate,scenario=list(page(0)),args=c(args,list(all_pages=TRUE)))
  observations$dryrun <<- b
  testthat::expect_s3_class(b$value,'httr2_request'); testthat::expect_length(b$wires,0L)
  testthat::expect_length(b$trace,1L)
  options(comptoxr_native.dry_run=FALSE,comptoxr_native.request=list(timeout=-1))
  b <- invoke(candidate,scenario=list(page(0)),args=args)
  testthat::expect_s3_class(b$value,'specmill_call_error'); testthat::expect_length(b$wires,0L)
  options(comptoxr_native.request=list(max_retries=0L,timeout=2))
})
testthat::test_that('PubChem exact dynamic limit is rejected; fixed-limit diagnostic retains source defect', {
  e <- readRDS(file.path(folder,'pubchem-dynamic-max-pages.rds'))
  testthat::expect_s3_class(e,'error')
  testthat::expect_match(conditionMessage(e),'request.pagination.max_pages must be a positive integer')
  override <- list(params=list(chemicals=list(list(chemical=list(sid='DTXSID7020182')))))
  for(paged in c(FALSE,TRUE)) {
    a <- invoke(old,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query=c('','x','x',NA),all_pages=paged),override)
    b <- invoke(candidate,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query=c('','x','x',NA),all_pages=paged),override)
    observations[[paste0('pubchem-',paged)]] <<- list(old=a,candidate=b)
    testthat::expect_identical(a$value,b$value)
    testthat::expect_length(b$trace,1L)
    testthat::expect_length(b$wires,if(paged) 2L else 1L)
  }
  # Actual service contract uses items/total, not the legacy records envelope.
  service <- list(status=200L,body='{"total":2,"items":[{"sid":"one"}]}')
  b <- invoke(candidate,'chemi_resolver_getpubchemlist',list(service),list(query='x'),override)
  testthat::expect_identical(b$value,list()); testthat::expect_length(b$wires,1L)
  skip <- list(params=list(query='x'),skip_request=TRUE,result=NULL,marker='kept')
  for(env in list(old,candidate)) {
    b <- invoke(env,'chemi_resolver_getpubchemlist',list(service),list(query='x'),skip)
    testthat::expect_null(b$value); testthat::expect_length(b$trace,1L); testthat::expect_length(b$wires,0L)
  }
})
testthat::test_that('PubChem normalization and real resolver hook run once', {
  for (override in list(NULL, list(params=list(query=c('','x','x',NA))))) {
    a <- invoke(old,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query='x',all_pages=FALSE),override)
    b <- invoke(candidate,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query='x',all_pages=FALSE),override)
    observations[[if(is.null(override)) 'pubchem-real-hook' else 'pubchem-normalized']] <<- list(old=a,candidate=b)
    testthat::expect_identical(a$value,b$value)
    testthat::expect_identical(a$wires,b$wires)
    testthat::expect_length(b$trace,1L)
  }
  override <- list(params=list(query=c('',NA)))
  for(env in list(old,candidate)) {
    b <- invoke(env,'chemi_resolver_getpubchemlist',list(page(0)),list(query='x'),override)
    testthat::expect_s3_class(b$value,'rlang_error'); testthat::expect_length(b$wires,0L)
  }
  override <- list(params=list(chemicals=list(list(sid='one'))))
  a <- invoke(old,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query='x',max_pages=1),override)
  b <- invoke(candidate,'chemi_resolver_getpubchemlist',list(page(0),page(1)),list(query='x',max_pages=1),override)
  observations$pubchem_limit <<- list(old=a,candidate=b)
  testthat::expect_length(a$wires,1L); testthat::expect_length(b$wires,2L)
  testthat::expect_length(a$value,1L); testthat::expect_length(b$value,2L)
})
testthat::test_that('metadata and transport conditions are exercised', {
  malformed <- list(status=200L,body='{"records":[{"sid":"one"}],"offset":"bad","recordsCount":1,"totalRecordsCount":2}')
  b <- invoke(candidate,scenario=list(malformed),args=c(args,list(all_pages=TRUE)))
  observations$metadata <<- b
  testthat::expect_s3_class(b$value,'error'); testthat::expect_length(b$wires,1L)
  options(ComptoxR.chemi_burl='http://127.0.0.1:9')
  b <- invoke(candidate,scenario=list(page(0)),args=args)
  observations$transport <<- b
  testthat::expect_s3_class(b$value,'error'); testthat::expect_length(b$wires,0L)
  options(ComptoxR.chemi_burl=origin)
})
server$kill()
saveRDS(observations,file.path(folder,'runtime.rds'))
