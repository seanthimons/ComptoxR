# Run from the package root. Never changes the package toolkit pin/library.
source('dev/install_specmill.R')
directory <- 'dev/specmill-rebuild/rootheldrelease'
install_specmill(lib = file.path(directory, '.toolkit-library'),
  source_repo = Sys.getenv('SPECMILL_SOURCE_REPO', '../specmill'),
  lock = file.path(directory, 'toolkit-lock.json'))
