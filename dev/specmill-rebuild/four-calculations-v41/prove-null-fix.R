# Replay real production bytes through the client before and after the NULL guard.
pkgload::load_all('.',quiet=TRUE)
ns <- asNamespace('ComptoxR')
lines <- deparse(ns$format_descriptor_result,width.cutoff=500L)
keep <- !grepl('if (is.null(value))',lines,fixed=TRUE) & !grepl('^\\s*value <- NA$',lines)
stopifnot(sum(!keep)==2L)
legacy <- eval(parse(text=paste(lines[keep],collapse='\n')),ns)
archive <- readRDS('tests/testthat/fixtures/native-four-calculations-production.rds')
baseline <- readRDS('tests/testthat/fixtures/native-four-calculations-contracts.rds')
results <- list()
for (name in c('chemi_mordred','chemi_mordred_bulk')) {
  evidence <- archive$results[[name]]; response <- evidence$responses[[1L]]
  fn <- eval(baseline[[name]][[3L]],ns)
  mock <- function(req) httr2::response(status_code=response$status,
    headers=list(`Content-Type`=response$media),body=response$body)
  replay <- function(output) {
    args <- evidence$args; args$output <- output
    httr2::with_mocked_responses(mock,do.call(fn,args))
  }
  fixed <- replay('wide'); raw <- replay('raw')
  old <- testthat::with_mocked_bindings(list(wide=tryCatch(replay('wide'),error=identity),raw=replay('raw')),
    format_descriptor_result=legacy,.package='ComptoxR')
  stopifnot(nrow(fixed)==1L,identical(fixed$status,'ok'),
    inherits(old$wide,'error') || nrow(old$wide)!=1L,identical(old$raw,raw))
  results[[name]] <- list(fixed_rows=nrow(fixed),old_rows=if(!inherits(old$wide,'error')) nrow(old$wide),
    old_error=if(inherits(old$wide,'error')) conditionMessage(old$wide),raw_identical=TRUE)
}
saveRDS(results,'dev/specmill-rebuild/four-calculations-v41/null-fix-proof.rds',version=2)
print(results)
