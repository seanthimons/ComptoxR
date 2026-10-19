work <- path.expand('~/.cache/comptoxr-specmill-finish/package-check-v50')
source <- file.path(work,'source/ComptoxR'); output <- file.path(work,'check')
keys <- names(Sys.getenv()); keys <- keys[grepl('key|token|secret|password|credential',keys,ignore.case=TRUE)]
env <- c(`_R_CHECK_FORCE_SUGGESTS_`='false',`_R_CHECK_CRAN_INCOMING_REMOTE_`='false',`_R_CHECK_CRAN_INCOMING_`='false',R_ENVIRON_USER='/dev/null',R_PROFILE_USER='/dev/null',R_ENVIRON='/dev/null',R_PROFILE='/dev/null',TMPDIR=file.path(work,'tmp'),http_proxy='http://127.0.0.1:9',https_proxy='http://127.0.0.1:9',HTTP_PROXY='http://127.0.0.1:9',HTTPS_PROXY='http://127.0.0.1:9',ALL_PROXY='http://127.0.0.1:9',all_proxy='http://127.0.0.1:9',NO_PROXY='',no_proxy='',ctx_api_key='',CTX_API_KEY='')
env <- c(env,setNames(rep('',length(setdiff(keys,names(env)))),setdiff(keys,names(env))))
r <- file.path(R.home('bin'),'R')
build_args <- c('CMD','build','--no-build-vignettes','--no-manual',source)
check_args <- c('CMD','check','--no-manual','--no-vignettes','--no-tests','--no-examples',file.path(output,'ComptoxR_3.0.0.tar.gz'))
result <- list(snapshot=source,environment=as.list(env),limitations='Bounded package snapshot check only. No schema/dev/tests/vignettes. Tests, examples, vignette rebuilding and PDF manual disabled; optional Suggests relaxed; external HTTP directed to closed loopback proxy; inherited credential-like environment variables blanked. Not a full strict check.',build_command=c(r,build_args),check_command=c(r,check_args),build_timeout_ms=180000,check_timeout_ms=900000)
build <- processx::run(r,build_args,wd=output,env=c('current',env),timeout=180000,error_on_status=FALSE,stdout=file.path(output,'build.log'),stderr_to_stdout=TRUE)
result$build_status <- build$status
if(build$status==0L){
 check <- processx::run(r,check_args,wd=output,env=c('current',env),timeout=900000,error_on_status=FALSE,stdout=file.path(output,'check.log'),stderr_to_stdout=TRUE)
 result$check_status <- check$status
 logpath <- file.path(output,'ComptoxR.Rcheck/00check.log')
 log <- if(file.exists(logpath))readLines(logpath,warn=FALSE)else readLines(file.path(output,'check.log'),warn=FALSE)
 result$status <- grep('^Status:',log,value=TRUE)
 starts <- grep('^\\* checking',log)
 result$findings <- lapply(starts[grepl('(ERROR|WARNING|NOTE|INFO)$',log[starts])],function(i){nexts<-which(seq_along(log)>i&grepl('^\\* ',log));log[i:if(length(nexts))nexts[1L]-1L else length(log)]})
 result$full_check_log <- log
}
jsonlite::write_json(result,file.path(work,'summary.json'),pretty=TRUE,auto_unbox=TRUE)
saveRDS(result,file.path(work,'summary.rds'))
cat('Build:',result$build_status,'Check:',result$check_status,'\n',result$status,'\n')
