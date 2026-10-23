source('dev/install_specmill.R');verify_specmill()
root <- '/home/sxthi/.cache/comptoxr-chet-options/project'
p <- specmill::generate_client(root=root,config='specmill.yml',mode='apply',artifacts=c('wrappers','documentation'),validation=TRUE)
stopifnot(length(p$diagnostics)==0L,length(p$mapping_diagnostics)==0L,length(p$retained_diagnostics)==0L,length(p$drift)==0L,length(p$operations)==2L)
fresh <- specmill::generate_client(root=root,config='specmill.yml',mode='check',artifacts=c('wrappers','documentation'),validation=TRUE)
stopifnot(all(vapply(fresh$files,`[[`,'','action')=='unchanged'))
m <- jsonlite::read_json(file.path(root,'.specmill/manifest.json'))$files
stopifnot(all(vapply(names(m),function(file) identical(specmill:::output_hash(file.path(root,file)),m[[file]]$hash),FALSE)))
saveRDS(fresh,'/home/sxthi/.cache/comptoxr-chet-options/generation-check.rds')
cat('Two OPTIONS operations generated, full validation/freshness/owner hashes PASS\n')
