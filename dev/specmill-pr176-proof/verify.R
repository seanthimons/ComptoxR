# Run through run.sh; the production library and client are never loaded.
cache <- Sys.getenv('PROOF_CACHE', path.expand('~/.cache/comptoxr-pr176-exact'))
out <- 'dev/specmill-pr176-proof'
sha <- 'a656ce446fd2f4fe28184e3cad69da02e209ef26'
archive <- 'ba5e8d3cd205cb0eba35d463db3f70394cac0b32f9629dfd5741319ce4eb104e'
loadNamespace('specmill', lib.loc = file.path(cache, 'lib'))
d <- utils::packageDescription('specmill')
stopifnot(
  d[['Config/specmill/source-commit']] == sha,
  d[['Config/specmill/source-archive-sha256']] == archive,
  normalizePath(getNamespaceInfo(asNamespace('specmill'), 'path')) == normalizePath(file.path(cache, 'lib/specmill'))
)
hash <- function(path) digest::digest(file = path, algo = 'sha256')
stopifnot(hash(file.path(cache, 'exact-source.tar')) == archive)
# Freeze all tracked production inputs before proof generation.
tracked <- system2('git', c('ls-files'), stdout = TRUE)
protected <- tracked[!startsWith(tracked, paste0(out, '/')) & file.exists(tracked)]
before <- setNames(vapply(protected, hash, ''), protected)
work <- file.path(cache, 'project')
unlink(work, recursive = TRUE)
for (dir in c('R', 'apis', 'schema', 'inst', '.specmill/helpers')) {
  dir.create(file.path(work, dir), recursive = TRUE)
}
inputs <- list.files(file.path(out, 'inputs'), full.names = TRUE)
stopifnot(all(file.copy(inputs, file.path(work, 'apis'))))
schemas <- paste0('schema/chemi-', c('alerts', 'stdizer', 'resolver', 'opera'), '-prod.json')
stopifnot(all(file.copy(schemas, file.path(work, 'schema'))))
file.copy(c('DESCRIPTION', 'air.toml'), file.path(work), overwrite = TRUE)
file.copy('R/service_endpoints.R', file.path(work, 'R'))
writeLines('{}', file.path(work, 'inst/hook_config.yml'))
settings <- jsonlite::read_json('.specmill/helpers/.ct_request.json')$settings
settings$companions <- unlist(settings$companions)
scaffold <- do.call(getFromNamespace('request_helper_scaffold', 'specmill'), settings)
writeLines(scaffold$code, file.path(work, 'R/z_specmill_request.R'))
writeLines(scaffold$provenance, file.path(work, '.specmill/helpers/.ct_request.json'))
writeLines(
  c(
    'config_version: 1',
    'package: ComptoxR',
    'formatter:',
    '  name: air',
    '  version: 0.11.0',
    'services:',
    paste0('- apis/', basename(inputs))
  ),
  file.path(work, 'specmill.yml')
)
gen_args <- list(root = work, config = 'specmill.yml', validation = TRUE, artifacts = 'wrappers')
cat('Generating five actual held routes with validation TRUE.\n')
apply <- do.call(specmill::generate_client, c(gen_args, list(mode = 'apply')))
fresh <- do.call(specmill::generate_client, c(gen_args, list(mode = 'check')))
stopifnot(
  length(fresh$operations) == 5L,
  !length(fresh$diagnostics),
  !length(fresh$mapping_diagnostics),
  !length(fresh$retained_diagnostics),
  !length(fresh$drift),
  all(vapply(fresh$files, function(f) f$action %in% c('unchanged', 'retained'), TRUE))
)
manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
for (file in names(manifest$files)) {
  stopifnot(identical(
    digest::digest(
      paste(readLines(file.path(work, file), warn = FALSE), collapse = '\n'),
      algo = 'sha256',
      serialize = FALSE
    ),
    manifest$files[[file]]$hash
  ))
}
stopifnot(identical(
  readLines(file.path(work, 'R/z_specmill_request.R')),
  strsplit(scaffold$code, '\n', fixed = TRUE)[[1]]
))
env <- new.env(parent = baseenv())
for (file in c('z_specmill_request.R', 'api_validation.R', 'service_endpoints.R')) {
  sys.source(file.path(work, 'R', file), env)
}
names <- c(
  'chemi_alerts_groups_freeze_by_id',
  'chemi_stdizer_groups_by_id_freeze_patch',
  'chemi_resolver_exportsimilaritylist',
  'chemi_resolver_exportsimilaritymap',
  'chemi_opera_file'
)
for (name in names) {
  sys.source(file.path(work, 'R', paste0(name, '.R')), env)
}
cat('Validated five wrappers; initial apply/check and all owner hashes passed.\n')
# Export exact official outputs as reviewable text, never active client R files.
dir.create(file.path(out, 'generated'), showWarnings = FALSE)
for (file in list.files(file.path(work, 'R'), full.names = TRUE)) {
  file.copy(file, file.path(out, 'generated', paste0(basename(file), '.txt')), overwrite = TRUE)
}
# Same localhost/httpuv and httr2 pool seams as upstream tests/request-throttle.R.
wire_dir <- file.path(cache, 'wire')
unlink(wire_dir, recursive = TRUE)
dir.create(wire_dir)
server <- callr::r_bg(
  function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer(
      '127.0.0.1',
      port,
      list(call = function(req) {
        count <<- count + 1L
        wire <- list(
          method = req$REQUEST_METHOD,
          path = req$PATH_INFO,
          query = sub('^\\?', '', req$QUERY_STRING),
          content_type = req$CONTENT_TYPE,
          body = rawToChar(req$rook.input$read())
        )
        saveRDS(wire, file.path(directory, sprintf('%04d.rds', count)))
        reply <- if (file.exists(file.path(directory, 'reply.rds'))) {
          readRDS(file.path(directory, 'reply.rds'))
        } else {
          list(status = 200L, body = '{"ok":true}')
        }
        list(
          status = reply$status,
          headers = list(`Content-Type` = 'application/json', Connection = 'close'),
          body = reply$body
        )
      })
    )
    saveRDS(port, file.path(directory, 'port.rds'))
    repeat {
      httpuv::service(100)
    }
  },
  args = list(wire_dir),
  supervise = TRUE
)
checks <- 0L
check <- function(...) {
  checks <<- checks + 1L
  stopifnot(...)
}
tryCatch(
  {
    for (i in seq_len(200L)) {
      if (file.exists(file.path(wire_dir, 'port.rds'))) {
        break
      }
      if (!server$is_alive()) {
        server$get_result()
      }
      Sys.sleep(0.05)
    }
    check(file.exists(file.path(wire_dir, 'port.rds')))
    origin <- paste0('http://127.0.0.1:', readRDS(file.path(wire_dir, 'port.rds')))
    options(
      ComptoxR.chemi_burl = origin,
      comptoxr_native.dry_run = FALSE,
      comptoxr_native.request = list(base_url = origin, timeout = 5, max_retries = 0L, preserve_errors = TRUE)
    )
    count <- function() length(list.files(wire_dir, pattern = '^\\d{4}\\.rds$'))
    received <- function() readRDS(file.path(wire_dir, sprintf('%04d.rds', count())))
    complex_list <- list(
      chemicals = list(list(
        chemical = list(smiles = 'CCO', name = 'ethanol'),
        confidence = 0.9,
        resolvedBy = 'SMILES',
        result = 'FOUND'
      )),
      main = list(smiles = 'CCO'),
      rdkitBits = 1024L,
      padelCompute2D = FALSE,
      padelCompute3D = TRUE,
      fingerprintName = 'Morgan'
    )
    complex_map <- list(
      chemicals = list(list(smiles = 'CCO', name = 'ethanol'), list(smiles = 'O', name = 'water')),
      section = 'properties'
    )
    bodies <- list(NULL, NULL, complex_list, complex_map, list(file = charToRaw('CCO ethanol\n')))
    base <- list(
      list(id = 'report-123'),
      list(id = 'group-123'),
      list(format = 'JSON', body = complex_list),
      list(format = 'JSON', sort = FALSE, showImage = TRUE, limit = 'All', body = complex_map),
      list(body = bodies[[5]])
    )
    flags <- list(
      c('freeze', 'hierarchically'),
      c('freeze', 'hierarchically'),
      'showImage',
      c('sort', 'showImage'),
      'standardize'
    )
    paths <- c(
      '/api/alerts/groups/report-123/freeze',
      '/api/stdizer/groups/group-123/freeze',
      '/api/resolver/exportsimilaritylist',
      '/api/resolver/exportsimilaritymap',
      '/api/opera/file'
    )
    methods <- c('PATCH', 'PATCH', 'POST', 'POST', 'POST')
    defaults <- c(
      'freeze=true&hierarchically=false',
      'freeze=true&hierarchically=true',
      'format=JSON&limit=All&showImage=true',
      'format=JSON&limit=All&sort=false&showImage=true',
      'format=json&standardize=false'
    )
    invoke <- function(i, args = base[[i]]) do.call(env[[names[[i]]]], args)
    evidence <- list()
    for (i in seq_along(names)) {
      for (value in c(FALSE, TRUE)) {
        args <- base[[i]]
        args[flags[[i]]] <- rep(list(value), length(flags[[i]]))
        invoke(i, args)
        sent <- received()
        expected <- switch(
          i,
          paste0('freeze=', tolower(value), '&hierarchically=', tolower(value)),
          paste0('freeze=', tolower(value), '&hierarchically=', tolower(value)),
          paste0('format=JSON&limit=All&showImage=', tolower(value)),
          paste0('format=JSON&limit=All&sort=', tolower(value), '&showImage=', tolower(value)),
          paste0('format=json&standardize=', tolower(value))
        )
        check(identical(sent$method, methods[[i]]), identical(sent$path, paths[[i]]), identical(sent$query, expected))
        if (i %in% c(3L, 4L)) {
          check(identical(jsonlite::fromJSON(sent$body, simplifyVector = FALSE), bodies[[i]]))
        }
        if (i == 5L) {
          check(
            grepl('^multipart/form-data; boundary=', sent$content_type),
            grepl('name="file"', sent$body, fixed = TRUE),
            grepl('CCO ethanol\n', sent$body, fixed = TRUE)
          )
        }
        evidence[[paste(names[[i]], value)]] <- sent
      }
      invoke(i)
      check(identical(received()$query, defaults[[i]]))
      args <- base[[i]]
      args[flags[[i]]] <- rep(list(NULL), length(flags[[i]]))
      start <- count()
      result <- tryCatch(invoke(i, args), error = identity)
      if (i == 4L) {
        check(inherits(result, 'error'), count() == start)
      } else {
        check(
          !inherits(result, 'error'),
          count() == start + 1L,
          identical(received()$query, c('', '', 'format=JSON&limit=All', NA, 'format=json')[[i]])
        )
      }
      for (flag in flags[[i]]) {
        for (value in list('false', 1, NA, c(TRUE, FALSE), list(FALSE))) {
          args <- base[[i]]
          args[flag] <- list(value)
          start <- count()
          error <- tryCatch(invoke(i, args), error = identity)
          check(inherits(error, 'error'), count() == start)
        }
      }
    }
    # Actual form_file upload preserves filename, content type and bytes on localhost.
    upload <- file.path(wire_dir, 'molecules.smi')
    writeBin(charToRaw('CCO ethanol\nO water\n'), upload)
    invoke(
      5L,
      list(standardize = TRUE, body = list(file = curl::form_file(upload)))
    )
    sent <- received()
    check(
      sent$query == 'format=json&standardize=true',
      grepl('filename="molecules.smi"', sent$body, fixed = TRUE),
      grepl('Content-Type: application/octet-stream', sent$body, fixed = TRUE),
      grepl('CCO ethanol\nO water\n', sent$body, fixed = TRUE)
    )
    evidence$form_file <- sent
    # Complex body validation fails before HTTP, including nested scalars and binary parts.
    for (case in list(
      list(i = 3L, body = list(rdkitBits = 'wrong')),
      list(i = 3L, body = list(main = list(smiles = 42))),
      list(i = 4L, body = list(chemicals = list(list(smiles = 42)))),
      list(i = 5L, body = list(file = 42))
    )) {
      args <- base[[case$i]]
      args$body <- case$body
      start <- count()
      check(inherits(tryCatch(invoke(case$i, args), error = identity), 'error'), count() == start)
    }
    for (i in c(1L, 2L, 4L)) {
      for (values in list(c(FALSE, TRUE), c(TRUE, FALSE))) {
        args <- base[[i]]
        args[flags[[i]]] <- as.list(values)
        invoke(i, args)
        expected <- if (i == 4L) {
          paste0('format=JSON&limit=All&sort=', tolower(values[[1]]), '&showImage=', tolower(values[[2]]))
        } else {
          paste0('freeze=', tolower(values[[1]]), '&hierarchically=', tolower(values[[2]]))
        }
        check(received()$query == expected)
        evidence[[paste(names[[i]], paste(values, collapse = '-'))]] <- received()
      }
    }
    for (flag in flags[[4]]) {
      args <- base[[4]]
      args[[flag]] <- NULL
      start <- count()
      check(inherits(tryCatch(invoke(4L, args), error = identity), 'error'), count() == start)
    }
    for (i in 3:5) {
      args <- base[[i]]
      args$body <- NULL
      start <- count()
      check(inherits(tryCatch(invoke(i, args), error = identity), 'error'), count() == start)
    }
    # Native typed HTTP errors and hard 401 remain hard under batch-drop policy.
    for (status in c(400L, 404L, 500L, 401L)) {
      saveRDS(list(status = status, body = '{"error":"local fixture"}'), file.path(wire_dir, 'reply.rds'))
      for (i in seq_along(names)) {
        start <- count()
        error <- tryCatch(invoke(i), error = identity)
        check(inherits(error, 'error'), count() == start + 1L)
        if (status == 401L) {
          check(inherits(error, 'specmill_call_error'))
          error <- tryCatch(env$.ct_request_each(function(x) invoke(i), 'one', 1L, on_error = 'drop'), error = identity)
          check(inherits(error, 'specmill_call_error'))
        } else {
          check(
            inherits(error, 'httr2_http'),
            httr2::resp_status(error$resp) == status,
            httr2::resp_body_string(error$resp) == '{"error":"local fixture"}'
          )
        }
      }
    }
    unlink(file.path(wire_dir, 'reply.rds'))
    # No throttle means no policy and no pool change.
    options(comptoxr_native.dry_run = TRUE)
    baseline <- invoke(1L)
    check(is.null(baseline$policies$throttle_realm))
    # Same hostname, no explicit realm: the real httr2 pool spans calls and batches.
    throttle <- list(capacity = 100L, fill_time_s = 1e9)
    controls <- list(base_url = origin, timeout = 5, max_retries = 0L, preserve_errors = TRUE, throttle = throttle)
    options(comptoxr_native.request = controls)
    req <- invoke(1L)
    native <- httr2::req_throttle(httr2::request(origin), capacity = 100L, fill_time_s = 1e9)
    check(identical(req$policies$throttle_realm, native$policies$throttle_realm))
    realm <- req$policies$throttle_realm
    options(comptoxr_native.dry_run = FALSE)
    pool <- function(realm) {
      state <- httr2::throttle_status()
      state[state$realm == realm, , drop = FALSE]
    }
    request <- function(method = 'GET', path = '/pool', body = NULL) {
      env$.ct_request(method, path, list(), list(), body, request_controls = list(throttle = throttle))
    }
    request()
    first <- pool(realm)
    check(nrow(first) == 1L, first$capacity == 100, abs(first$tokens - 99) < 0.01)
    request('POST', body = list(value = 'post'))
    invoke(5L)
    second <- pool(realm)
    check(abs(second$tokens - 97) < 0.01)
    batch1 <- env$.ct_request_each(function(x) request(path = paste0('/pool/', x)), c('one', 'two'), 1L)
    batch2 <- env$.ct_request_each(
      function(x) request('POST', paste0('/pool/', x), list(value = x)),
      c('three', 'four'),
      1L
    )
    after <- pool(realm)
    check(length(batch1) == 2L, length(batch2) == 2L, abs(after$tokens - 93) < 0.01)
    # Custom realm and runtime override still use httr2's real pool.
    custom <- throttle
    custom$realm <- 'comptoxr-pr176-private-custom'
    controls$throttle <- custom
    options(comptoxr_native.request = controls)
    request()
    check(abs(pool(custom$realm)$tokens - 99) < 0.01, abs(pool(realm)$tokens - 93) < 0.01)
    controls$throttle <- NULL
    options(comptoxr_native.request = controls, comptoxr_native.dry_run = TRUE)
    check(is.null(invoke(5L)$policies$throttle_realm))
    options(comptoxr_native.dry_run = FALSE)
    invoke(5L)
    check(abs(pool(realm)$tokens - 93) < 0.01)
    invalid <- list(
      list(),
      list(capacity = 0, fill_time_s = 1),
      list(capacity = 1.5, fill_time_s = 1),
      list(capacity = 4, fill_time_s = 0),
      list(capacity = Inf, fill_time_s = 1),
      list(capacity = 4, fill_time_s = NA_real_),
      list(capacity = c(1, 2), fill_time_s = 1),
      list(capacity = 4, fill_time_s = 1, realm = ''),
      list(capacity = 4, fill_time_s = 1, unknown = TRUE)
    )
    for (value in invalid) {
      bad <- controls
      bad$throttle <- value
      options(comptoxr_native.request = bad)
      for (i in seq_along(names)) {
        start <- count()
        error <- tryCatch(
          env$.ct_request_each(function(x) invoke(i), c('one', 'two'), 1L, on_error = 'drop'),
          error = identity
        )
        check(inherits(error, 'specmill_call_error'), count() == start)
      }
      check(inherits(
        tryCatch(
          getFromNamespace('validate_settings', 'specmill')(list(request_controls = list(throttle = value)), 'bad'),
          error = identity
        ),
        'error'
      ))
    }
    options(comptoxr_native.request = controls)
    # Declarative throttle must survive native wrapper rendering, not just runtime options.
    for (i in seq_along(inputs)) {
      config <- yaml::read_yaml(inputs[[i]])
      config$schemas$files <- as.list(config$schemas$files)
      config$selection$include <- as.list(config$selection$include)
      config$defaults <- list(request_controls = list(throttle = throttle))
      yaml::write_yaml(config, file.path(work, 'apis', basename(inputs[[i]])))
    }
    cat('Wire, validation, native errors and real pool checks passed; checking declarative throttle generation.\n')
    declared <- do.call(specmill::generate_client, c(gen_args, list(mode = 'apply')))
    declared_fresh <- do.call(specmill::generate_client, c(gen_args, list(mode = 'check')))
    check(
      !length(declared_fresh$diagnostics),
      !length(declared_fresh$mapping_diagnostics),
      !length(declared_fresh$drift),
      all(vapply(declared_fresh$files, function(f) f$action %in% c('unchanged', 'retained'), TRUE))
    )
    declared_manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
    for (file in names(declared_manifest$files)) {
      check(identical(
        digest::digest(
          paste(readLines(file.path(work, file), warn = FALSE), collapse = '\n'),
          algo = 'sha256',
          serialize = FALSE
        ),
        declared_manifest$files[[file]]$hash
      ))
    }
    dir.create(file.path(out, 'generated-throttle'), showWarnings = FALSE)
    for (name in names) {
      file <- paste0(name, '.R')
      file.copy(
        file.path(work, 'R', file),
        file.path(out, 'generated-throttle', paste0(file, '.txt')),
        overwrite = TRUE
      )
      sys.source(file.path(work, 'R', file), env)
    }
    options(comptoxr_native.dry_run = TRUE)
    for (i in seq_along(names)) {
      check(identical(invoke(i)$policies$throttle_realm, realm))
    }
    options(comptoxr_native.dry_run = FALSE)
    for (i in seq_along(names)) {
      invoke(i)
    }
    check(abs(pool(realm)$tokens - 88) < 0.01)
    # Official helper remains byte-identical before and after both generations.
    check(identical(
      readLines(file.path(work, 'R/z_specmill_request.R')),
      strsplit(scaffold$code, '\n', fixed = TRUE)[[1]]
    ))
    check(identical(before, setNames(vapply(protected, hash, ''), protected)))
    template_files <- list.files(file.path(cache, 'source/inst/templates'), recursive = TRUE, full.names = TRUE)
    template_hashes <- setNames(
      vapply(template_files, hash, ''),
      sub(paste0(cache, '/source/'), '', template_files, fixed = TRUE)
    )
    for (file in names(template_hashes)) {
      check(identical(hash(file.path(cache, 'lib/specmill', sub('^inst/', '', file))), template_hashes[[file]]))
    }
    production_record <- jsonlite::read_json('.specmill/helpers/.ct_request.json')
    production_baseline <- sub(
      '[ \t]+$',
      '',
      strsplit(gsub("#' @export", "#' @noRd", production_record$baseline, fixed = TRUE), '\n', fixed = TRUE)[[1]]
    )
    check(identical(readLines('R/z_specmill_request.R'), production_baseline))
    saveRDS(evidence, file.path(out, 'wire.rds'), version = 2)
    jsonlite::write_json(
      list(
        source_commit = sha,
        source_archive_sha256 = archive,
        private_library = getNamespaceInfo(asNamespace('specmill'), 'path'),
        schema_sha256 = setNames(vapply(schemas, hash, ''), schemas),
        template_sha256 = template_hashes,
        helper_sha256 = hash(file.path(work, 'R/z_specmill_request.R')),
        scaffold_settings = settings,
        production_helper_matches_own_scaffold = TRUE,
        installed_templates_match_exact_source = TRUE,
        validation = fresh$validation,
        operations = 5L,
        assertions = checks,
        localhost_requests = count(),
        baseline_owners = manifest$files,
        throttle_owners = declared_manifest$files,
        all_owner_hashes_match = TRUE,
        fresh_baseline = TRUE,
        fresh_declarative_throttle = TRUE,
        production_files_unchanged = TRUE,
        throttle_pool = list(first = first, after_post = second, after_two_batches = after),
        pubchem_high_level = 'held: cache lifecycle #174; no migration claim'
      ),
      file.path(out, 'results.json'),
      auto_unbox = TRUE,
      pretty = TRUE,
      null = 'null'
    )
    cat(
      'PASS:',
      checks,
      'assertion groups;',
      count(),
      'localhost requests; 5 actual wrappers; both private manifests current.\n'
    )
  },
  finally = server$kill()
)
