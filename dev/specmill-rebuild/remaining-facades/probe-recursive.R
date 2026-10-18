library(httr2)
groups <- request('https://cim.sciencedataexperts.com/api/stdizer/groups') |> req_timeout(20) |> req_perform()
g <- resp_body_json(groups, simplifyVector = FALSE)[[1]]$id
out<-list(id=g)
for(p in c(paste0('/api/stdizer/groups/recursive/',g),paste0('/api/stdizer/groups/',g,'/recursive'))) {
 r<-request(paste0('https://cim.sciencedataexperts.com',p)) |> req_error(is_error=function(r)FALSE) |> req_timeout(20) |> req_perform()
 out[[p]]<-list(status=resp_status(r),body=resp_body_string(r))
}
saveRDS(out,'dev/specmill-rebuild/remaining-facades/recursive-live.rds');str(out,max.level=2)
