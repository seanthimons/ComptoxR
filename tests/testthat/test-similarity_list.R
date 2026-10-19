# chemi_resolver_getsimilaritylist hook checks; live wrapper replay is in dev/specmill-rebuild/issue-358/similarity-investigation/live-wrapper.R.
test_that('similarity inputs resolve independently into flat chemicals', {
  calls <- list()
  local_mocked_bindings(chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
    calls[[length(calls) + 1L]] <<- list(ids = ids, type = idsType)
    lapply(ids, function(id) list(result = if (id == 'missing') 'NOT_FOUND' else 'FOUND',
      chemical = list(chemId = id, canonicalSmiles = 'CCO')))
  })
  data <- list(params = list(main = 'reference', query = c('one', 'missing', 'two'),
    idType = 'AnyId', fingerprintName = 'indigo', scoreName = 'tanimoto'))
  data <- resolve_similarity_reference(data)
  data <- resolve_similarity_candidates(data)
  expect_identical(calls, list(list(ids = 'reference', type = 'AnyId'),
    list(ids = c('one', 'missing', 'two'), type = 'AnyId')))
  expect_identical(data$params$reference_chemical$sid, 'reference')
  expect_identical(vapply(data$params$candidate_chemicals, `[[`, '', 'sid'), c('one', 'two'))
  expect_true(all(vapply(data$params$candidate_chemicals, function(x) is.null(x$chemical), TRUE)))
  data$params$main <- 'missing'
  expect_error(resolve_similarity_reference(data), 'exactly one')
  data$params$query <- 'missing'
  expect_warning(empty <- resolve_similarity_candidates(data), 'No candidate')
  expect_true(empty$skip_request)
  expect_null(empty$result)
})

test_that('invalid similarity inputs fail before resolution and skips stay lazy', {
  local_mocked_bindings(chemi_resolver_lookup_bulk = function(...) stop('unexpected lookup'))
  valid <- list(main = 'reference', query = 'candidate', idType = 'AnyId',
    fingerprintName = 'indigo', scoreName = 'tanimoto')
  for (value in list(NULL, character(), c('one', 'two'), NA_character_, '')) {
    params <- valid
    params['main'] <- list(value)
    expect_error(resolve_similarity_reference(list(params = params)), 'main must')
  }
  for (value in list(NULL, character(), rep('one', 1001L), NA_character_, '')) {
    params <- valid
    params['query'] <- list(value)
    expect_error(resolve_similarity_reference(list(params = params)), 'query must')
  }
  for (field in c('fingerprintName', 'scoreName')) {
    params <- valid
    params[[field]] <- ''
    expect_error(resolve_similarity_reference(list(params = params)), field)
  }
  skipped <- list(skip_request = TRUE, result = 'skipped')
  expect_identical(resolve_similarity_reference(skipped), skipped)
  expect_identical(resolve_similarity_candidates(skipped), skipped)
})
