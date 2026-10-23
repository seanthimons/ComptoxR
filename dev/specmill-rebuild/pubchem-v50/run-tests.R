base <- '/home/sxthi/.cache/comptoxr-specmill-finish/release50-verification/pubchem-candidate'
stopifnot(!'specmill' %in% loadedNamespaces())
pkgload::load_all(file.path(base,'candidate-root'),quiet=TRUE)
r <- testthat::test_file(file.path(base,'candidate-root/tests/testthat/test-pubchem_native_http.R'),reporter='summary',stop_on_failure=FALSE)
d <- as.data.frame(r);saveRDS(r,file.path(base,'tests.rds'))
jsonlite::write_json(list(tests=nrow(d),passed=sum(d$passed),failed=sum(d$failed),errors=sum(d$error),warnings=sum(d$warning),skips=sum(d$skipped),specmill_runtime_loaded='specmill' %in% loadedNamespaces()),file.path(base,'tests.json'),auto_unbox=TRUE,pretty=TRUE)
stopifnot(!any(d$failed>0|d$error|d$warning),!'specmill' %in% loadedNamespaces())
