library(httr2)
results <- list()
for(base in c('https://cim.sciencedataexperts.com','https://hcd.rtpnc.epa.gov')) {
 for(mode in c('legacy','declared')) {
  req <- request(paste0(base,'/api/resolver/getpubchemlist'))
  body <- if(mode=='legacy') list(chemicals=list(list(chemical=list(sid='DTXSID7020182'))), options=list()) else list(chemicals=list(list(sid='DTXSID7020182')))
  if(mode=='declared') req <- req_url_query(req,page=0,itemsPerPage=10,search='',linkBy='',report='')
  req <- req_body_json(req,body)
  result <- tryCatch(req_perform(req_timeout(req_error(req,is_error=function(resp) FALSE),20)),error=function(e) list(error=conditionMessage(e)))
  if(inherits(result,'httr2_response')) result <- list(status=resp_status(result),body=resp_body_string(result),url=result$url,request=list(method='POST',url=req$url,body=body))
  results[[paste(base,mode)]] <- result
 }
}
saveRDS(results,'dev/specmill-rebuild/remaining-facades/pubchem-live.rds')
for(n in names(results)) {cat(n,'\n');str(results[[n]],max.level=1)}
