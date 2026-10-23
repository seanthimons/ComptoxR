library(httr2)
r<-list()
for(base in c('https://cim.sciencedataexperts.com','https://hcd.rtpnc.epa.gov')) {
 req<-request(paste0(base,'/api/resolver/safety-flags')) |> req_body_json(list(list(sid='DTXSID7020182',additionalProps=list(source='ComptoxR')))) |> req_error(is_error=function(resp)FALSE) |> req_timeout(20)
 res<-tryCatch(req_perform(req),error=function(e) list(error=conditionMessage(e)))
 r[[base]]<-if(inherits(res,'httr2_response'))list(status=resp_status(res),body=resp_body_string(res),request=list(method='POST',url=req$url,body=req$body$data)) else res
}
saveRDS(r,'dev/specmill-rebuild/remaining-facades/safety-live.rds');str(r)
