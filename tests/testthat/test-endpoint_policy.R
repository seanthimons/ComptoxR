test_that('banned endpoints cannot be selected or exported', {
  root <- test_path('../..')
  skip_if_not(file.exists(file.path(root, 'dev/endpoint-policy.json')))
  policy <- jsonlite::read_json(file.path(root, 'dev/endpoint-policy.json'), simplifyVector = TRUE)
  config <- yaml::read_yaml(file.path(root, 'specmill.yml'))
  excluded <- function(path) {
    vapply(path, function(p) any(vapply(config$selection$exclude, grepl, NA, p, perl = TRUE)), NA)
  }
  expect_setequal(config$selection$methods, c('GET', 'POST'))
  for (file in config$services) {
    service <- yaml::read_yaml(file.path(root, file))
    selected <- union(service$selection$include, names(service$operations))
    expect_true(all(sub(' .*', '', selected) %in% config$selection$methods), info = file)
    expect_false(any(selected %in% unlist(policy$banned_operations, use.names = FALSE)), info = file)
    expect_false(any(excluded(sub('^[^ ]+ ', '', selected))), info = file)
  }
  expect_false(any(excluded(c('/api/alerts', '/api/alerts/metadata', '/api/alerts/version'))))
  expect_true(all(excluded(c('/api/alerts/groups', '/api/alerts/export', '/api/alerts/render'))))
  expect_setequal(grep('^chemi_alerts', getNamespaceExports('ComptoxR'), value = TRUE),
    c('chemi_alerts', 'chemi_alerts_metadata', 'chemi_alerts_version'))
  expect_length(grep('^chemi_stdizer_groups', getNamespaceExports('ComptoxR')), 0L)
  # Path-only excludes cannot ban POST alone (seanthimons/specmill#189), so the local ban remains.
  expect_identical(policy$banned_operations[['schema/chemi-stdizer-prod.json']], 'POST /api/stdizer')
  expect_false(excluded('/api/stdizer'))
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
  expect_true(all(c('chemi_amos', 'chemi_amos_analytical_qc_keyset_pagination_bulk') %in%
    getNamespaceExports('ComptoxR')))
  expect_true(excluded('/api/resolver/getpubchemlist'))
  expect_false(excluded('/api/resolver/getsimilaritylist'))
  removed <- c(
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-358/removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-357/removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-354/removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-355/removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-356/alerts-removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-356/stdizer-management-removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-356/stdizer-upload-removed-bindings.json')))
  for (binding in removed) {
    expect_false(binding$name %in% getNamespaceExports('ComptoxR'))
    expect_false(file.exists(file.path(root, binding$file)))
    expect_false(file.exists(file.path(root, 'man', paste0(binding$name, '.Rd'))))
  }
})
