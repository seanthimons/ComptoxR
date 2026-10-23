# Real localhost behavior; private wrapper owners expose hook state without replacing transport.
ns<-asNamespace('ComptoxR');old<-new.env(parent=ns);candidate<-new.env(parent=ns)
sys.source(testthat::test_path('fixtures/chemi-search-legacy.R.txt'),old)
for(name in c('chemi_search','.ct_search_page_response','.ct_search_page_items','.ct_search_page_done','.ct_search_page_advance','.ct_search_result'))candidate[[name]]<-get(name,ns)
environment(candidate$chemi_search)<-candidate
trace<-list();state_override<-NULL;return_state<-FALSE
hook<-function(name,stage,data){
 trace[[length(trace)+1L]]<<-list(name=name,stage=stage,data=data)
 if(stage=='pre_request'&&!is.null(state_override))return(state_override)
 if(stage=='post_response'&&return_state)return(data)
 get('run_hook',ns)(name,stage,data)
}
old$run_hook<-candidate$run_hook<-hook
observed<-list();private_state<-get('.ComptoxREnv',ns)
previous_observer<-private_state$probe_observer
previous_debug<-private_state$run_debug
private_state$probe_observer<-function(response){observed[[length(observed)+1L]]<<-list(url=response$url,status=response$status_code)}

testthat::test_that('generated search preserves its public signature', {
 testthat::expect_identical(formals(old$chemi_search),formals(candidate$chemi_search))
})
testthat::test_that('search skip preserves original full state and laziness',{
 return_state<<-TRUE
 for(value in list('skip',NULL)){
  state_override<<-list(params=list(query='partial'),marker=structure('kept',class='sentinel'),request=list(body='kept'),skip_request=TRUE,result=value)
  trace<<-list();a<-old$chemi_search(all_pages=stop('forced'))
  testthat::expect_identical(vapply(trace,`[[`,'','stage'),c('pre_request','post_response'))
  trace<<-list();b<-candidate$chemi_search(all_pages=stop('forced'))
  testthat::expect_identical(vapply(trace,`[[`,'','stage'),c('pre_request','post_response'))
  testthat::expect_identical(names(trace[[1]]$data$params),setdiff(names(formals(old$chemi_search)),'all_pages'))
  testthat::expect_identical(a,b)
  if(is.null(value))testthat::expect_false('result'%in%names(b))
 }
 return_state<<-FALSE;state_override<<-NULL
})
directory<-tempfile('native-search-');dir.create(directory)
server<-callr::r_bg(function(directory){
 count<-0L;port<-httpuv::randomPort()
 httpuv::startServer('127.0.0.1',port,list(call=function(req){
  if(file.exists(file.path(directory,'reset'))){count<<-0L;unlink(file.path(directory,'reset'))}
  count<<-count+1L
  saveRDS(list(method=req$REQUEST_METHOD,path=req$PATH_INFO,query=req$QUERY_STRING,body=rawToChar(req$rook.input$read())),file.path(directory,paste0('wire-',count,'.rds')))
  scenario<-readRDS(file.path(directory,'scenario.rds'));response<-scenario[[min(count,length(scenario))]]
  list(status=response$status,headers=list('Content-Type'='application/json',Connection='close'),body=response$body)
 }))
 saveRDS(port,file.path(directory,'ready'));repeat httpuv::service(20)
},list(directory),supervise=TRUE)
for(i in 1:200){if(file.exists(file.path(directory,'ready')))break;Sys.sleep(.05)}
stopifnot(file.exists(file.path(directory,'ready')))
origin<-paste0('http://127.0.0.1:',readRDS(file.path(directory,'ready')))
previous_options<-options(ComptoxR.chemi_burl=paste0(origin,'/api'),comptoxr_native.request=list(max_retries=0L,timeout=2),comptoxr_native.dry_run=FALSE)
invoke<-function(env,scenario,args=list(),override=NULL,raw=FALSE){
 unlink(list.files(directory,pattern='^wire-',full.names=TRUE));saveRDS(scenario,file.path(directory,'scenario.rds'));file.create(file.path(directory,'reset'))
 trace<<-list();observed<<-list();state_override<<-override;return_state<<-raw
 warnings<-character()
 value<-withCallingHandlers(tryCatch(suppressMessages(do.call(env$chemi_search,args)),error=identity),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
 list(value=value,trace=trace,warnings=warnings,observed=observed,wires=lapply(list.files(directory,pattern='^wire-',full.names=TRUE),readRDS))
}
page<-function(offset,total=2)list(status=200L,body=jsonlite::toJSON(list(totalRecordsCount=total,recordsCount=1L,offset=offset,records=list(list(sid=paste0('sid',offset)))),auto_unbox=TRUE))
args<-list(search_type='mass',mass_type='mono',min_mass=100,max_mass=101,limit=1)
observations<-list()
testthat::test_that('unchanged real search hooks and localhost single/paged requests match',{
 for(paged in c(FALSE,TRUE)){
  a<-invoke(old,list(page(0),page(1)),c(args,list(all_pages=paged)))
  b<-invoke(candidate,list(page(0),page(1)),c(args,list(all_pages=paged)))
  observations[[paste0('search-',paged)]]<<-list(old=a,candidate=b)
  testthat::expect_identical(a$value,b$value)
  testthat::expect_identical(vapply(b$trace,`[[`,'','stage'),c('pre_request','post_response'))
  testthat::expect_length(b$wires,if(paged)2L else 1L)
  testthat::expect_identical(b$wires[[1]]$path,'/api/search')
  testthat::expect_identical(b$wires[[1]]$method,'POST')
  testthat::expect_identical(a$observed,b$observed)
  testthat::expect_length(b$observed,length(b$wires))
  ba<-lapply(a$wires,function(w)jsonlite::fromJSON(w$body,simplifyVector=FALSE));bb<-lapply(b$wires,function(w)jsonlite::fromJSON(w$body,simplifyVector=FALSE))
  if(!paged)testthat::expect_identical(ba,bb) else{
   testthat::expect_null(ba[[1]]$offset);testthat::expect_equal(bb[[1]]$offset,0);testthat::expect_equal(bb[[2]]$offset,1)
   bb[[1]]$offset<-NULL;testthat::expect_identical(ba,bb)
  }
 }
})
testthat::test_that('original and generated default/configured API dry-run URLs match',{
 for(base in list(NULL,paste0(origin,'/api'),paste0(origin,'/custom/base'))){
  withr::local_envvar(chemi_burl=NA);options(ComptoxR.chemi_burl=base)
  private_state$run_debug<-TRUE
  capture.output(a<-invoke(old,list(page(0)),args,raw=TRUE))
  private_state$run_debug<-FALSE;options(comptoxr_native.dry_run=TRUE)
  b<-invoke(candidate,list(page(0)),args)
  options(comptoxr_native.dry_run=FALSE)
  testthat::expect_type(a$value$result,'list')
  testthat::expect_s3_class(b$value,'httr2_request')
  testthat::expect_identical(a$value$result$method,b$value$method)
  testthat::expect_identical(a$value$result$path,httr2::url_parse(b$value$url)$path)
  testthat::expect_identical(httr2::req_url_path_append(httr2::request(get('.endpoint_url',ns)('chemi_burl')),'search')$url,b$value$url)
  observations[[paste0('dryrun-',if(is.null(base))'default'else base)]] <<-list(old=a,candidate=b)
  testthat::expect_identical(b$value$url,paste0(if(is.null(base))'https://hcd.rtpnc.epa.gov/api' else base,'/search'))
  testthat::expect_length(a$wires,0L);testthat::expect_length(b$wires,0L)
  testthat::expect_length(b$observed,0L)
 }
 options(ComptoxR.chemi_burl=paste0(origin,'/api'))
})
testthat::test_that('full hook state excludes paging override while retaining post state',{
 for(value in list(FALSE,NULL)){
  override<-list(params=list(query='changed',all_pages=value),marker='keep',request=list(body=list(searchType='MASS',params=list(limit=1)),options=list(limit=1)))
  a<-invoke(old,list(page(0),page(1)),list(all_pages=TRUE),override,TRUE)
  b<-invoke(candidate,list(page(0),page(1)),list(all_pages=TRUE),override,TRUE)
  testthat::expect_length(a$wires,2L);testthat::expect_length(b$wires,2L)
  testthat::expect_identical(a$value,b$value)
  testthat::expect_identical(b$value$params$all_pages,value)
  testthat::expect_identical(b$value$marker,'keep')
 }
})
testthat::test_that('received errors/partial pages preserve response observation and hard conditions',{
 for(paged in c(FALSE,TRUE))for(status in c(401L,404L,500L)){
  scenario<-if(paged)list(page(0),list(status=status,body='{"error":"sentinel"}')) else list(list(status=status,body='{"error":"sentinel"}'))
  a<-invoke(old,scenario,c(args,list(all_pages=paged)));b<-invoke(candidate,scenario,c(args,list(all_pages=paged)))
  observations[[paste(status,paged)]]<<-list(old=a,candidate=b)
  testthat::expect_length(b$wires,if(paged)2L else 1L)
  testthat::expect_length(b$observed,length(b$wires))
  testthat::expect_identical(vapply(b$observed,`[[`,0L,'status'),c(if(paged)200L,status))
  if(paged&&status!=401L)testthat::expect_identical(a$value,b$value) else testthat::expect_s3_class(b$value,'error')
  if(!paged&&status!=401L){testthat::expect_s3_class(b$value,paste0('httr2_http_',status));testthat::expect_identical(httr2::resp_body_string(b$value$resp),'{"error":"sentinel"}')}
  if(status==401L)testthat::expect_s3_class(b$value,'specmill_call_error')
 }
 for(paged in c(FALSE,TRUE)){
  b<-invoke(candidate,list(list(status=200L,body='{broken')),c(args,list(all_pages=paged)))
  testthat::expect_s3_class(b$value,'error');testthat::expect_length(b$wires,1L);testthat::expect_length(b$observed,1L)
 }
 options(comptoxr_native.request=list(timeout=-1));b<-invoke(candidate,list(page(0)),args)
 testthat::expect_s3_class(b$value,'specmill_call_error');testthat::expect_length(b$wires,0L);testthat::expect_length(b$observed,0L)
 options(comptoxr_native.request=list(max_retries=0L,timeout=2))
})
testthat::test_that('metadata and actual transport failures are preserved',{
 malformed<-list(status=200L,body='{"records":[{"sid":"one"}],"offset":"bad","recordsCount":1,"totalRecordsCount":2}')
 b<-invoke(candidate,list(malformed),c(args,list(all_pages=TRUE)))
 testthat::expect_s3_class(b$value,'error');testthat::expect_length(b$wires,1L);testthat::expect_length(b$observed,1L)
 options(ComptoxR.chemi_burl='http://127.0.0.1:9/api')
 b<-invoke(candidate,list(page(0)),args)
 testthat::expect_s3_class(b$value,'httr2_failure');testthat::expect_length(b$wires,0L);testthat::expect_length(b$observed,0L)
})
server$kill();private_state$probe_observer<-previous_observer;private_state$run_debug<-previous_debug
options(previous_options);unlink(directory,recursive=TRUE)
