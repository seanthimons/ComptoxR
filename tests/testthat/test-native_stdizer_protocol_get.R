testthat::test_that('reviewed protocol GET preserves schema boolean and paging wire contracts', {
  fn <- chemi_stdizer_protocols_by_id_get
  flags <- c('hidden','components','changed','failed','passed')
  testthat::expect_identical(names(formals(fn)),c('id',flags,'page','size','sort'))
  directory <- tempfile('protocol-get-');dir.create(directory)
  on.exit(unlink(directory,recursive=TRUE),add=TRUE)
  reply <- list(status=200L,media='application/json',body=charToRaw('{"id":"protocol","filteredNumber":1,"records":[{"id":"one"}]}'))
  saveRDS(reply,file.path(directory,'reply.rds'))
  server <- callr::r_bg(function(directory){
    count <- 0L;port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1',port,list(call=function(req){
      count <<- count+1L
      saveRDS(list(method=req$REQUEST_METHOD,path=req$PATH_INFO,query=req$QUERY_STRING,body=req$rook.input$read()),file.path(directory,paste0(count,'.rds')))
      r <- readRDS(file.path(directory,'reply.rds'))
      list(status=r$status,headers=list(`Content-Type`=r$media,Connection='close'),body=r$body)
    }))
    saveRDS(port,file.path(directory,'ready.rds'));repeat httpuv::service(20)
  },args=list(directory),supervise=TRUE)
  on.exit(server$kill(),add=TRUE)
  for(i in seq_len(400L)){if(file.exists(file.path(directory,'ready.rds'))||!server$is_alive())break;Sys.sleep(.05)}
  testthat::expect_true(file.exists(file.path(directory,'ready.rds')),info=server$read_error())
  url <- paste0('http://127.0.0.1:',readRDS(file.path(directory,'ready.rds')))
  withr::local_options(list(ComptoxR.chemi_burl=paste0(url,'/api'),comptoxr_native.request=list(timeout=3,max_retries=0L)))
  count <- 0L
  invoke <- function(args){value <- tryCatch(do.call(fn,args),error=identity);count <<- count+1L;value}
  wire <- function(){value <- readRDS(file.path(directory,paste0(count,'.rds')));value$query <- sub('^\\?','',if(is.null(value$query)) '' else value$query);value}
  decoded <- jsonlite::fromJSON(rawToChar(reply$body),simplifyVector=FALSE)
  testthat::expect_identical(invoke(list(id='protocol')),decoded)
  testthat::expect_identical(wire()$method,'GET')
  testthat::expect_identical(wire()$path,'/api/stdizer/protocols/protocol')
  testthat::expect_identical(wire()$query,'')
  testthat::expect_length(wire()$body,0L)
  local({
    withr::local_envvar(chemi_burl=NA)
    withr::local_options(list(ComptoxR.chemi_burl=NULL,comptoxr_native.dry_run=TRUE))
    request <- fn('protocol',hidden=FALSE,passed=TRUE)
    testthat::expect_s3_class(request,'httr2_request')
    testthat::expect_identical(request$url,'https://hcd.rtpnc.epa.gov/api/stdizer/protocols/protocol?hidden=false&passed=true')
  })
  grid <- expand.grid(rep(list(c(FALSE,TRUE)),length(flags)));names(grid)<-flags
  for(i in seq_len(nrow(grid))){
    values <- as.list(grid[i,,drop=FALSE]);args <- c(list(id='protocol'),values,list(page=0L,size=1L,sort=c('type,asc','id,desc')))
    testthat::expect_identical(invoke(args),decoded)
    expected <- paste0('page=0&size=1&',paste(paste0(flags,'=',tolower(as.character(unlist(values)))),collapse='&'),'&sort=type%2Casc&sort=id%2Cdesc')
    testthat::expect_identical(wire()$query,expected)
    testthat::expect_length(wire()$body,0L)
  }
  for(flag in flags){
    values <- setNames(rep(list(TRUE),length(flags)),flags);values[flag]<-list(NULL)
    testthat::expect_identical(invoke(c(list(id='protocol'),values)),decoded)
    testthat::expect_identical(wire()$query,paste(paste0(setdiff(flags,flag),'=true'),collapse='&'))
  }
  for(sort in list(character(),NULL,'','id,desc&size=999')){
    testthat::expect_identical(invoke(list(id='protocol',sort=sort)),decoded)
    expected <- if(is.null(sort)||!length(sort)) '' else if(sort=='') 'sort=' else 'sort=id%2Cdesc%26size%3D999'
    testthat::expect_identical(wire()$query,expected)
  }
  invalid <- list(list(),list(id=1L),list(id=c('one','two')),list(id='protocol',page=-1L),list(id='protocol',size=0L),list(id='protocol',page=1.5),list(id='protocol',sort=1L),list(id='protocol',sort=c('id',NA)))
  for(flag in flags) for(value in list('true',0L,c(TRUE,FALSE),NA)) invalid[[length(invalid)+1L]]<-c(list(id='protocol'),setNames(list(value),flag))
  for(args in invalid){
    testthat::expect_error(do.call(fn,args))
    testthat::expect_false(file.exists(file.path(directory,paste0(count+1L,'.rds'))))
  }
  for(status in c(400L,404L,500L,401L)){
    failed <- list(status=status,media='application/problem+json',body=charToRaw('{"error":"fixture"}'))
    saveRDS(failed,file.path(directory,'reply.rds'))
    value <- invoke(list(id='protocol'))
    testthat::expect_s3_class(value,if(status==401L)'specmill_call_error' else paste0('httr2_http_',status))
    if(status!=401L)testthat::expect_identical(httr2::resp_body_raw(value$resp),failed$body)
  }
  saveRDS(list(status=204L,media='application/json',body=raw()),file.path(directory,'reply.rds'))
  testthat::expect_null(invoke(list(id='protocol')))
  withr::local_options(list(comptoxr_native.request=list(timeout=0)))
  testthat::expect_error(fn('protocol'),class='specmill_call_error')
  testthat::expect_false(file.exists(file.path(directory,paste0(count+1L,'.rds'))))
  options(comptoxr_native.request=list(timeout=1,max_retries=0L));server$kill()
  testthat::expect_error(fn('protocol'),class='httr2_failure')
})
