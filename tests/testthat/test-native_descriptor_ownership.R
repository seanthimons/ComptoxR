testthat::test_that('released ownership declarations preserve real descriptor behavior',{
 ns<-asNamespace('ComptoxR');old<-new.env(parent=ns)
 frozen<-readRDS(testthat::test_path('fixtures/native-ownership-contracts.rds'))
 for(name in names(frozen))old[[name]]<-eval(frozen[[name]][[3L]],ns)
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))testthat::expect_identical(formals(get(name,ns)),formals(old[[name]]))
 directory<-tempfile('ownership49-');dir.create(directory);on.exit(unlink(directory,recursive=TRUE),add=TRUE)
 reply<-list(status=200L,media='application/json',body=charToRaw('{"chemicals":[{"smiles":"CCO","ordinal":0,"descriptors":[1,2]}],"headers":["a","b"]}'))
 saveRDS(reply,file.path(directory,'reply.rds'))
 server<-callr::r_bg(function(directory){count<-0L;port<-httpuv::randomPort();httpuv::startServer('127.0.0.1',port,list(call=function(req){
  if(file.exists(file.path(directory,'reset'))){count<<-0L;unlink(file.path(directory,'reset'))};count<<-count+1L
  saveRDS(list(method=req$REQUEST_METHOD,path=req$PATH_INFO,query=req$QUERY_STRING,accept=req$HTTP_ACCEPT,content_type=req$CONTENT_TYPE,body=req$rook.input$read()),file.path(directory,paste0('wire-',count,'.rds')))
  r<-readRDS(file.path(directory,'reply.rds'));list(status=r$status,headers=list('Content-Type'=r$media,Connection='close'),body=r$body)
 }));saveRDS(port,file.path(directory,'ready'));repeat httpuv::service(20)},list(directory),supervise=TRUE)
 on.exit(server$kill(),add=TRUE)
 for(i in 1:400){if(file.exists(file.path(directory,'ready')))break;Sys.sleep(.05)}
 testthat::expect_true(file.exists(file.path(directory,'ready')))
 base<-paste0('http://127.0.0.1:',readRDS(file.path(directory,'ready')),'/api')
 withr::local_options(list(ComptoxR.chemi_burl=base,comptoxr_native.request=list(timeout=3,max_retries=0L)))
 observed<-list();state<-get('.ComptoxREnv',ns);prior<-state$probe_observer;on.exit(state$probe_observer<-prior,add=TRUE)
 state$probe_observer<-function(response){observed[[length(observed)+1L]]<<-list(status=response$status_code,url=response$url)}
 invoke<-function(fn,args){unlink(list.files(directory,pattern='^wire-',full.names=TRUE));file.create(file.path(directory,'reset'));observed<<-list();warnings<-character()
  value<-withCallingHandlers(tryCatch(do.call(fn,args),error=identity),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
  list(value=value,warnings=warnings,observed=observed,wires=lapply(list.files(directory,pattern='^wire-',full.names=TRUE),readRDS))}
 observations<-list()
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))for(output in c('wide','raw')){
  args<-list('CCO',type='padel',output=output)
  a<-invoke(old[[name]],args);b<-invoke(get(name,ns),args)
  observations[[paste(name,output)]]<-list(old=a,candidate=b)
  testthat::expect_false(inherits(b$value,'error'))
  testthat::expect_identical(a$value,b$value)
  testthat::expect_identical(a$warnings,b$warnings)
  testthat::expect_identical(a$wires,b$wires)
  testthat::expect_identical(a$observed,b$observed)
  testthat::expect_length(b$wires,1L)
  testthat::expect_identical(b$wires[[1]]$path,'/api/descriptors')
  testthat::expect_identical(b$wires[[1]]$method,if(name=='chemi_descriptors')'GET'else'POST')
 }
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))for(format in c('CSV','TSV')){
  separator<-if(format=='CSV')','else'\t'
  r<-list(status=200L,media=if(format=='CSV')'text/csv'else'text/tab-separated-values',body=charToRaw(paste0(paste(c('Ordinal','SMILES','InChI','InChIKey','exact Header'),collapse=separator),'\n',paste(c('0','CCO','mock-inchi','mock-key','1.5'),collapse=separator))))
  saveRDS(r,file.path(directory,'reply.rds'));args<-list('CCO',type='padel',format=format)
  a<-invoke(old[[name]],args);b<-invoke(get(name,ns),args)
  observations[[paste(name,format)]]<-list(old=a,candidate=b)
  signature<-function(x)list(class=class(x),message=conditionMessage(x),parent_class=class(x$parent),parent_message=conditionMessage(x$parent))
  testthat::expect_s3_class(a$value,'comptoxr_post_response_hook_error');testthat::expect_identical(signature(a$value),signature(b$value));testthat::expect_identical(a$wires,b$wires)
  testthat::expect_match(conditionMessage(b$value$parent),'undefined columns selected',fixed=TRUE)
 }
 saveRDS(reply,file.path(directory,'reply.rds'))
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))for(input in list(c(NA_character_,''),character(),NULL)){
  args<-list(type='padel');args[if(name=='chemi_descriptors')'smiles'else'query']<-list(input)
  a<-invoke(old[[name]],args);b<-invoke(get(name,ns),args)
  if(inherits(a$value,'error')) {testthat::expect_s3_class(b$value,class(a$value)[1L]);testthat::expect_identical(conditionMessage(a$value),conditionMessage(b$value))} else testthat::expect_identical(a$value,b$value)
  testthat::expect_length(a$wires,0L);testthat::expect_length(b$wires,0L)
 }
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))for(status in c(404L,500L,401L)){
  r<-list(status=status,media='application/json',body=charToRaw('{"error":"sentinel"}'));saveRDS(r,file.path(directory,'reply.rds'))
  b<-invoke(get(name,ns),list('CCO',type='padel'))
  testthat::expect_s3_class(b$value,if(status==401L)'specmill_call_error'else paste0('httr2_http_',status));testthat::expect_length(b$wires,1L)
  if(status!=401L)testthat::expect_identical(httr2::resp_body_raw(b$value$resp),r$body)
 }
 # Evaluate the unchanged pre-hook chain on the production default without HTTP.
 local({withr::local_envvar(chemi_burl=NA);withr::local_options(list(ComptoxR.chemi_burl=NULL))
  for(name in c('chemi_descriptors','chemi_descriptors_bulk')){
   params<-list(type='rdkit',headers=FALSE,format='JSON',timeout=NULL,output=c('wide','raw'))
   params[if(name=='chemi_descriptors')'smiles'else'query']<-list('CCO')
   if(name=='chemi_descriptors_bulk')params$chemIdType<-'AnyId'
   testthat::expect_warning(pre<-get('run_hook',ns)(name,'pre_request',list(params=params)),'dedicated RDKit')
   testthat::expect_identical(pre$request$endpoint,'rdkit');testthat::expect_identical(pre$request$server,'https://hcd.rtpnc.epa.gov/api')
   testthat::expect_true(pre$params$.route$fallback_used);testthat::expect_identical(pre$params$.engine_options$bits,1024L)
  }
 })
 withr::local_options(list(comptoxr_native.request=list(timeout=0)))
 for(name in c('chemi_descriptors','chemi_descriptors_bulk')){b<-invoke(get(name,ns),list('CCO',type='padel'));testthat::expect_s3_class(b$value,'specmill_call_error');testthat::expect_length(b$wires,0L)}
 options(comptoxr_native.request=list(timeout=1,max_retries=0L));server$kill()
 for(name in c('chemi_descriptors','chemi_descriptors_bulk'))testthat::expect_error(do.call(get(name,ns),list('CCO',type='padel')),class='httr2_failure')
})
