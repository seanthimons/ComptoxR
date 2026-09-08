# Explicit maintenance callbacks; never sourced by the installed client.
batch_limit_100 <- function(operation) {
  quote(as.numeric(Sys.getenv('batch_limit', '100')))
}

batch_limit_1000 <- function(operation) {
  quote(as.numeric(Sys.getenv('batch_limit', '1000')))
}
