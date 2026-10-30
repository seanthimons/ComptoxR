test_that('banned endpoints cannot be selected or exported', {
  root <- test_path('../..')
  skip_if_not(file.exists(file.path(root, 'specmill.yml')), 'needs the source checkout; specmill.yml is not in the built package')
  config <- yaml::read_yaml(file.path(root, 'specmill.yml'))
  excluded <- function(path, method = NA_character_) {
    vapply(path, function(p) any(vapply(config$selection$exclude, function(rule) {
      m <- regmatches(rule, regexec('^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE) (.+)$', rule))[[1]]
      if (length(m)) !is.na(method) && m[2] == method && grepl(m[3], p, perl = TRUE) else grepl(rule, p, perl = TRUE)
    }, NA)), NA)
  }
  expect_setequal(config$selection$methods, c('GET', 'POST'))
  for (file in config$services) {
    for (service in yaml::read_yaml(file.path(root, file))$groups) {
      selected <- union(unlist(service$selection$include), c(names(service$operations), names(service$names)))
      expect_true(all(sub(' .*', '', selected) %in% config$selection$methods), info = file)
      expect_false(any(mapply(excluded, sub('^[^ ]+ ', '', selected), sub(' .*', '', selected))), info = file)
    }
  }
  expect_false(any(excluded(c('/api/alerts', '/api/alerts/metadata', '/api/alerts/version'))))
  expect_true(all(excluded(c('/api/alerts/groups', '/api/alerts/export', '/api/alerts/render'))))
  expect_setequal(grep('^chemi_alerts', getNamespaceExports('ComptoxR'), value = TRUE),
    c('chemi_alerts', 'chemi_alerts_metadata', 'chemi_alerts_version'))
  expect_length(grep('^chemi_stdizer_groups', getNamespaceExports('ComptoxR')), 0L)
  expect_true(excluded('/api/stdizer', 'POST'))
  expect_false(excluded('/api/stdizer', 'GET'))
  expect_true(all(c('chemi_stdizer', 'chemi_stdizer_chemicals', 'chemi_stdizer_records') %in%
    getNamespaceExports('ComptoxR')))
  expect_true(all(excluded(
    c('/api/stdizer/groups', '/api/stdizer/groups/one',
      '/api/stdizer/groups/one/recursive', '/api/stdizer/groups/preflight'))))
  expect_false(any(excluded(
    c('/api/stdizer', '/api/stdizer/metadata', '/api/stdizer/version',
      '/api/stdizer/workflows', '/api/stdizer/operations', '/api/stdizer/protocols/one'))))
  expect_true(all(excluded(
    c('/api/alerts/groups/1/add', '/api/stdizer/groups/1/replace',
      '/api/resolver/casharvest', '/api/resolver/universalharvest',
      '/api/services/caspreflight', '/api/services/files'))))
  expect_false(any(excluded(
    c('/api/stdizer',
      '/api/resolver/universalharvest_cart', '/api/services/preflight'))))
  expect_true(all(excluded(
    c('/auth/login', '/auth/new-route', '/admin/new-route', '/chemicals/chemdelete'))))
  expect_false(any(excluded(
    c('/chemicals/chemical_DL', '/curators/login', '/chemicals/chemdelete-other'))))
  expect_true(all(excluded(c('/api/amos/analytical_qc_batch_search', '/api/amos/batch_search'))))
  expect_true(all(c('chemi_amos_search', 'chemi_amos_analytical_qc_keyset_pagination_bulk') %in%
    getNamespaceExports('ComptoxR')))
  expect_true(all(excluded(
    c('/chemicals/database-old', '/reaction/database_old', '/reaction/database-old/1/x'))))
  expect_false(any(excluded(
    c('/chemicals/database', '/chemicals/database/stats', '/reaction/database', '/reaction/database/stats'))))
  expect_true(excluded('/api/toxprints/assays', 'POST'))
  expect_false(excluded('/api/toxprints/assays', 'GET'))
  expect_true(excluded('/api/resolver/getpubchemlist'))
  expect_false(excluded('/api/resolver/getsimilaritylist'))
  removed <- do.call(c,
    lapply(list.files(test_path('fixtures/removed-bindings'), full.names = TRUE), jsonlite::read_json))
  for (binding in removed) {
    expect_false(binding$name %in% getNamespaceExports('ComptoxR'))
    expect_false(file.exists(file.path(root, binding$file)))
    expect_false(file.exists(file.path(root, 'man', paste0(binding$name, '.Rd'))))
  }
})

# Runs under R CMD check too: needs only the installed namespace and fixtures.
test_that('removed and banned wrappers are not exported', {
  exports <- getNamespaceExports('ComptoxR')
  removed <- do.call(c,
    lapply(list.files(test_path('fixtures/removed-bindings'), full.names = TRUE), jsonlite::read_json))
  expect_gt(length(removed), 0L)
  for (binding in removed) {
    expect_false(binding$name %in% exports, info = binding$name)
  }
  expect_setequal(grep('^chemi_alerts', exports, value = TRUE),
    c('chemi_alerts', 'chemi_alerts_metadata', 'chemi_alerts_version'))
  expect_length(grep('^chemi_stdizer_groups', exports), 0L)
})
