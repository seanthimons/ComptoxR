# The service answers an unknown search_type with [] and a missing one with 404.
test_that('chemi_chet_reaction_searchcounts requires a known search_type and fans out search_input', {
  withr::local_options(list(ComptoxR.chemi_burl = 'http://chet.test/api',
    comptoxr_native.request = list(max_retries = 0L)))
  urls <- character()
  httr2::local_mocked_responses(function(req) {
    urls <<- c(urls, req$url)
    httr2::response(if (grepl('/bad/', req$url)) 500L else 200L,
      headers = list(`Content-Type` = 'application/json'), body = charToRaw('[{"count":3}]'))
  })
  expect_error(chemi_chet_reaction_searchcounts('1'), 'search_type')
  expect_error(chemi_chet_reaction_searchcounts('1', 'Lib_id'), 'search_type')
  expect_error(chemi_chet_reaction_searchcounts('1', c('lib_id', 'reaction_type')), 'search_type')
  expect_length(urls, 0L)

  one <- chemi_chet_reaction_searchcounts('Hydrolysis', 'reaction_type')
  expect_identical(urls, 'http://chet.test/api/chet/reaction/searchcounts/Hydrolysis/reaction_type')
  expect_identical(one[[1L]]$count, 3L)

  urls <- character()
  chemi_chet_reaction_searchcounts('a b/c', 'reaction_type')
  expect_identical(urls, 'http://chet.test/api/chet/reaction/searchcounts/a%20b%2Fc/reaction_type')

  urls <- character()
  both <- chemi_chet_reaction_searchcounts(c('1', '2'), 'lib_id')
  expect_identical(urls, paste0('http://chet.test/api/chet/reaction/searchcounts/', 1:2, '/lib_id'))
  expect_length(both, 2L)

  # A failing element in a batch leaves NULL in its slot; the rest are kept.
  urls <- character()
  mixed <- suppressWarnings(chemi_chet_reaction_searchcounts(c('1', 'bad', '2'), 'lib_id'))
  expect_length(urls, 3L)
  expect_null(mixed[[2L]])
  expect_identical(mixed[-2L], both)
})
