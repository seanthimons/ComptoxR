# Capture the task's committed baseline without evaluating wrappers.
folder <- 'dev/specmill-rebuild/released-facades-v42'
files <- c('R/chemi_chet_reaction_searchcounts.R',
 'R/chemi_chet_reaction_database_old_by_pagenum_and_searchterm.R',
 'R/chemi_stdizer_groups_recursive.R', 'R/chemi_stdizer_records.R',
 'R/chemi_resolver_resolve.R', 'R/chemi_toxprints_assays.R',
 'R/chemi_toxprints_chemicals_categories.R', 'R/chemi_toxprints_toxprints_categories.R', 'R/chemi_toxprints.R')
legacy <- list()
for (file in files) {
  code <- parse(text = system2('git', c('show', paste0('cd34efb4:', file)), stdout = TRUE))
  for (statement in code) if (is.call(statement) && identical(statement[[1]], as.name('<-')) &&
    is.call(statement[[3]]) && identical(statement[[3]][[1]], as.name('function')))
    legacy[[as.character(statement[[2]])]] <- statement[[3]]
}
saveRDS(legacy, 'tests/testthat/fixtures/released-facades-v42-legacy.rds')
