#!/usr/bin/env Rscript
# Verify all R files parse cleanly

files <- list.files('R', full.names=TRUE, pattern='\\.R$')
errors <- character()

for(f in files) {
  tryCatch(
    parse(file=f),
    error=function(e) {
      errors <<- c(errors, paste(f, ':', e$message))
    }
  )
}

if(length(errors) > 0) {
  cat('PARSE ERRORS:\n')
  cat(errors, sep='\n')
  quit(status=1)
} else {
  cat(length(files), 'files parse OK\n')
}
