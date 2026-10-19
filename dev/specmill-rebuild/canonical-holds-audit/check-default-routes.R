literal <- function(x) {
 if(missing(x))return(FALSE)
 if(is.null(x)||is.atomic(x))return(TRUE)
 if(is.name(x))return(as.character(x)%in%c('NULL','NA','TRUE','FALSE'))
 if(!is.call(x))return(FALSE)
 head<-paste(deparse(x[[1L]]),collapse='')
 head%in%c('list','base::list')&&all(vapply(as.list(x)[-1L],literal,TRUE))
}
found<-list();seen<-0L;all_calls<-0L
visit<-function(x,file){
 if(missing(x))return(invisible(NULL))
 if(!is.call(x)&&!is.expression(x))return(invisible(NULL))
 if(is.call(x)&&identical(x[[1L]],as.name('.ct_request'))){
  all_calls<<-all_calls+1L
  args<-as.list(x)[-1L];server<-args$server;resolver<-args$server_resolver;path<-args$path
  if(!is.null(server)&&!is.null(resolver)&&literal(server)&&literal(resolver)&&is.character(path)&&length(path)==1L){
   s<-eval(server,baseenv());r<-eval(resolver,baseenv());seen<<-seen+1L
   if(is.list(s)&&is.list(r)&&identical(r$key,'chemi_burl')&&!is.null(s$url)&&is.null(r$relative)&&startsWith(path,'/api/'))found[[file]]<<-list(path=path,server=s,resolver=r)
  }
 }
 for(child in as.list(x))visit(child,file)
}
stopifnot(literal(quote(list(url='https://example.invalid'))),!literal(quote(Sys.getenv('KEY'))))
visit(quote(.ct_request(path='/api/x',server=list(url='https://example.invalid'),server_resolver=list(key='chemi_burl'))),'fixture')
visit(quote(x[,,1]),'missing-argument-fixture')
stopifnot(length(found)==1L,identical(found$fixture$path,'/api/x'))
found<-list();seen<-0L;all_calls<-0L
for(file in list.files('R',pattern='[.]R$',full.names=TRUE))visit(parse(file),file)
jsonlite::write_json(list(native_calls=all_calls,native_literal_requests=seen,default_api_prefix_candidates=found),
 'dev/specmill-rebuild/canonical-holds-audit/default-route-audit.json',pretty=TRUE,auto_unbox=TRUE)
print(list(native_calls=all_calls,native_literal_requests=seen,candidates=found))

stopifnot(!length(found))
