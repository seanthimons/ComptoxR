validate_endpoint_migration <- function(filter = 'endpoint_configuration') {
  devtools::test(filter = filter, stop_on_failure = TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args)) validate_endpoint_migration(args[[1]]) else validate_endpoint_migration()
}
