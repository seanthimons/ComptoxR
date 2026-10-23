Sys.setenv(PR179_ROOT = normalizePath('.'))
folder <- 'dev/specmill-rebuild/pr179-exact'
r <- testthat::test_file(file.path(folder,'test-proof.R'), reporter = 'summary', stop_on_failure = FALSE)
saveRDS(r,file.path(folder,'tests.rds'))
d <- as.data.frame(r)
jsonlite::write_json(list(tests=nrow(d),passed=sum(d$passed),failed=sum(d$failed),errors=sum(d$error),
 warnings=sum(d$warning),skipped=sum(d$skipped)),file.path(folder,'test-totals.json'),auto_unbox=TRUE,pretty=TRUE)
if(any(d$failed > 0 | d$error)) quit(status=1)
