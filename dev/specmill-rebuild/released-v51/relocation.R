out <- Sys.getenv('SPEC51_EVIDENCE')
stopifnot(nzchar(out), normalizePath('.') != Sys.getenv('SPEC51_ORIGINAL_ROOT'))
before <- readBin('.specmill/manifest.json', 'raw', n = file.info('.specmill/manifest.json')$size)
source('dev/generate_specmill.R')
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'relocated-fresh.rds'))
after <- readBin('.specmill/manifest.json', 'raw', n = file.info('.specmill/manifest.json')$size)
files <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(identical(before, after), length(files) == 715L,
  all(vapply(names(files), function(p) identical(specmill:::output_hash(p), files[[p]]$hash), FALSE)))
jsonlite::write_json(list(version = '0.1.51', sources = length(fresh$validation), owners = length(files),
  copied_checkout_fresh = TRUE, manifest_raw_bytes_unchanged = TRUE, validation = TRUE),
  file.path(out, 'relocation.json'), pretty = TRUE, auto_unbox = TRUE)
cat('PASS actual full project copied checkout freshness.\n')
