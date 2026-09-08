record_endpoint_exports <- function() {
  exported <- function(lines) sub('^export\\((.*)\\)$', '\\1', grep('^export\\(', lines, value = TRUE))
  previous <- exported(system2('git', c('show', '516dfd4:NAMESPACE'), stdout = TRUE))
  current <- exported(readLines('NAMESPACE'))
  removed <- sort(setdiff(previous, current))
  replacement <- sub('_(staging|development)$', '', removed)
  replacement[!replacement %in% current] <- 'No production equivalent'
  replacement[removed == 'eco_lifestage_patch'] <- 'envharmonizer::harmonize_lifestage (explicit separate step)'
  result <- data.frame(removed = removed, replacement = replacement)
  utils::write.csv(result, 'dev/reports/migration/removed-exports.csv', row.names = FALSE)
  result
}
if (sys.nframe() == 0L) {
  print(record_endpoint_exports())
}
