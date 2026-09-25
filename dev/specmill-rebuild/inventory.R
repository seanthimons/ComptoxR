# Preservation inventory (#326). Run from the package root; read-only except outputs.
# Writes inventory.json (every top-level R definition) and removal-allowlist.json.
`%||%` <- function(a, b) if (is.null(a)) b else a
out <- 'dev/specmill-rebuild'
sha <- function(files) vapply(files, digest::digest, '', file = TRUE, algo = 'sha256')

# Mapped operations from the committed specmill configuration.
config <- yaml::read_yaml('specmill.yml')
ops <- do.call(rbind, lapply(config$services, function(path) {
  y <- yaml::read_yaml(path)
  do.call(rbind, lapply(names(y$operations), function(key) {
    o <- y$operations[[key]]
    data.frame(service = y$id, key = key, name = o$name, file = o$file, implementation = o$implementation)
  }))
}))
manifest <- jsonlite::read_json('.specmill/manifest.json')
exports <- parseNamespaceFile('.', '.')$exports
attempt <- jsonlite::read_json('dev/specmill-full/attempt-results.json')

runtime_files <- c(
  'R/z_generic_request.R', 'R/zzz.R', 'R/hook_registry.R', 'R/schema.R', 'R/service_endpoints.R',
  'R/mappings.R', 'R/roxy_apistage.R', 'R/utils-pipe.R', 'R/ComptoxR-package.R', 'R/data.R',
  'R/package_sitrep.R', 'R/probe_api_function.R', 'R/misc_functions.R'
)
sidecar <- '^R/(dss_|eco_|tox_|z_db_)'

# Every top-level assignment, with its roxygen lifecycle badge and formals.
definitions <- do.call(c, lapply(sort(Sys.glob('R/*.R')), function(file) {
  lines <- readLines(file, warn = FALSE)
  exprs <- parse(file, keep.source = TRUE)
  refs <- attr(exprs, 'srcref')
  lapply(seq_along(exprs), function(i) {
    e <- exprs[[i]]
    if (!(is.call(e) && as.character(e[[1]]) %in% c('<-', '=') && (is.symbol(e[[2]]) || is.character(e[[2]])))) {
      return(NULL)
    }
    name <- as.character(e[[2]])
    start <- refs[[i]][[1]]
    block <- if (start > 1L) {
      above <- rev(lines[seq_len(start - 1L)])
      rev(above[cumprod(grepl("^#'", above)) == 1L])
    } else character()
    badge <- regmatches(block, regexpr('lifecycle::badge\\("[a-z]+"\\)', block))
    value <- e[[3]]
    is_fn <- is.call(value) && identical(value[[1]], as.name('function'))
    op <- ops[ops$name == name, ]
    category <- if (nrow(op)) {
      if (op$implementation == 'generated') 'generated' else 'retained_mapped'
    } else if (file %in% runtime_files || startsWith(file, 'R/hooks_')) {
      'runtime'
    } else if (grepl(sidecar, file)) {
      'sidecar'
    } else if (!is.null(attempt[[name]]) && nzchar(attempt[[name]]$reason) &&
      grepl('^(ct_|chemi_|epi_)', name) && !identical(attempt[[name]]$reason, 'Outside CT/Chemi/EPI schema-wrapper scope')) {
      'unmapped_wrapper'
    } else {
      'utility'
    }
    list(
      name = name,
      file = file,
      exported = name %in% exports,
      category = category,
      review_reason = attempt[[name]]$reason %||% NULL,
      operation = if (nrow(op)) paste(op$service, op$key) else NULL,
      lifecycle = if (length(badge)) sub('.*"([a-z]+)".*', '\\1', badge[[1]]) else NULL,
      formals = if (is_fn) paste(deparse(value[[2]], width.cutoff = 500L), collapse = '') else NULL
    )
  })
}))
definitions <- Filter(Negate(is.null), definitions)
names(definitions) <- vapply(definitions, `[[`, '', 'name')

# A file is removable only if every top-level definition in it is generated and
# the manifest owns it. Grouped files with any retained neighbor stay.
by_file <- split(vapply(definitions, `[[`, '', 'category'), vapply(definitions, `[[`, '', 'file'))
generated_files <- sort(unique(ops$file[ops$implementation == 'generated']))
removable <- Filter(function(f) all(by_file[[f]] == 'generated') && !is.null(manifest$files[[f]]), generated_files)
blocked <- setdiff(generated_files, removable)
retained_files <- unique(ops$file[ops$implementation != 'generated'])
stopifnot(
  length(blocked) == 0L,
  !any(retained_files %in% removable),
  setequal(removable, grep('^R/', names(manifest$files), value = TRUE)),
  sum(ops$implementation == 'generated') == 101L,
  all(exports %in% names(definitions) | exports %in% c('%>%', '%ni%'))
)
generated_names <- ops$name[ops$implementation == 'generated']

missing <- setdiff(exports, names(definitions))
counts <- table(vapply(definitions[intersect(names(definitions), exports)], `[[`, '', 'category'))
jsonlite::write_json(
  list(
    commit = system('git rev-parse HEAD', intern = TRUE),
    toolkit = jsonlite::read_json('dev/specmill-lock.json'),
    exports = length(exports),
    exports_defined_elsewhere = as.list(missing),
    export_categories = as.list(counts),
    runtime_files = as.list(runtime_files),
    removable_files = length(removable),
    definitions = unname(definitions)
  ),
  file.path(out, 'inventory.json'), pretty = TRUE, auto_unbox = TRUE, null = 'null'
)
jsonlite::write_json(
  list(
    commit = system('git rev-parse HEAD', intern = TRUE),
    operations = length(generated_names),
    files = as.list(setNames(sha(removable), removable))
  ),
  file.path(out, 'removal-allowlist.json'), pretty = TRUE, auto_unbox = TRUE
)
cat(length(exports), 'exports;', length(definitions), 'definitions;', length(removable), 'removable files\n')
print(counts)
