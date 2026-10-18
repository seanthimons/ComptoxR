pkgload::load_all('.',quiet=TRUE)
results<-list()
for(base in c('https://cim.sciencedataexperts.com','https://hcd.rtpnc.epa.gov')) {
 result<-withr::with_options(list(ComptoxR.chemi_burl=base,comptoxr_native.request=list(max_retries=0L,timeout=20)),
  chemi_resolver_safety_flags_bulk(additionalProps=list(source='ComptoxR'),sid='DTXSID7020182'))
 stopifnot(is.list(result),length(result$flags)>0L)
 results[[base]]<-list(result=result,input=list(additionalProps=list(source='ComptoxR'),sid='DTXSID7020182'))
}
saveRDS(list(wrapper_sha256 = digest::digest(file='R/chemi_resolver_safety_flags.R',algo='sha256'), results=results),'dev/specmill-rebuild/remaining-facades/native-safety-live.rds')
cat('Generated safety facade returned nonempty flags on production and staging.\n')
