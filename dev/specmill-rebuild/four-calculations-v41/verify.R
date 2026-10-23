# Portable owner, public interface, fixture-retirement and hook checks.
.libPaths(c(Sys.getenv('SPECMILL_LIB', '/tmp/chet-specmill41-library'), .libPaths()))
pkgload::load_all('.', quiet=TRUE)
names4 <- c('chemi_mordred','chemi_mordred_bulk','chemi_webtest_predict','chemi_webtest_predict_bulk')
ns <- asNamespace('ComptoxR')
manifest <- jsonlite::read_json('.specmill/manifest.json')
hashes <- vapply(names(manifest$files), function(path) {
  actual <- digest::digest(paste(readLines(path,warn=FALSE,encoding='UTF-8'),collapse='\n'),
    algo='sha256',serialize=FALSE)
  identical(actual,manifest$files[[path]]$hash)
}, FALSE)
stopifnot(all(hashes))
baseline <- readRDS('tests/testthat/fixtures/native-four-calculations-contracts.rds')
for (name in names4) {
  fn <- get(name,ns)
  stopifnot(identical(formals(fn),formals(eval(baseline[[name]][[3L]],ns))),
    grepl('.ct_request(',paste(deparse(body(fn)),collapse='\n'),fixed=TRUE),
    name %in% getNamespaceExports('ComptoxR'),file.exists(paste0('man/',name,'.Rd')))
  tools::parse_Rd(paste0('man/',name,'.Rd'))
}
stopifnot(system2('git',c('diff','--exit-code','341b8526','--','NAMESPACE',paste0('man/',names4,'.Rd')))==0L)
config <- ns$read_hook_configs('inst/hook_config.yml','inst/hook_config_generated.yml')
hooks <- specmill::validate_hooks(config[names4],setNames(lapply(names4,get,envir=ns),names4),ns)
stopifnot(isTRUE(hooks$valid))
fixture <- readRDS('tests/testthat/fixtures/specmill-rebuild-contracts.rds')
# Compare every non-retired fixture entry to this worktree's fixed base commit.
original_path <- tempfile(fileext='.rds')
stopifnot(system2('git', c('show','341b8526:tests/testthat/fixtures/specmill-rebuild-contracts.rds'), stdout=original_path)==0L)
original <- readRDS(original_path); unlink(original_path)
stopifnot(identical(fixture,original[setdiff(names(original),names4)]))
retired <- paste0('tests/testthat/test-contract-',names4,'.R')
stopifnot(!any(file.exists(retired)),!any(retired %in% names(manifest$files)))
provenance <- as.list(utils::packageDescription('specmill'))
result <- list(owned_files=length(hashes),all_owner_hashes_match=all(hashes),hooks=hooks,
  toolkit=provenance[c('Version','Config/specmill/source-commit','Config/specmill/source-archive-sha256')],
  loaded_library=getNamespaceInfo(asNamespace('specmill'),'path'),
  fixture_keys_preserved=TRUE, signatures_exports_docs=TRUE)
saveRDS(result,'dev/specmill-rebuild/four-calculations-v41/verification.rds',version=2)
print(result)
