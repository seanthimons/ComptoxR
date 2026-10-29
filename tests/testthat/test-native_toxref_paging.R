# #329: every study type is paged to its last page, not only the first.
test_that('toxref study-type wrappers page through every requested study type', {
  withr::local_envvar(c(ctx_api_key = 'offline'))
  withr::local_options(list(ComptoxR.ctx_burl = 'http://ctx.test',
    comptoxr_native.request = list(max_retries = 0L)))
  for (name in paste0('ct_hazard_toxref_', c('data', 'effects', 'observations'), '_search_by_study_type')) {
    seen <- character()
    httr2::local_mocked_responses(function(req) {
      seen <<- c(seen, req$url)
      type <- sub('.*/by-study-type/([^?]+).*', '\\1', req$url)
      page <- as.integer(sub('.*pageNumber=', '', req$url))
      httr2::response_json(body = list(pageNumber = page, totalPages = 2L,
        data = list(list(studyType = type, page = page))))
    })
    result <- get(name, asNamespace('ComptoxR'))(c('CHR', 'DEV'))
    expect_setequal(sub('^.*by-study-type/', '', seen),
      c('CHR?pageNumber=1', 'CHR?pageNumber=2', 'DEV?pageNumber=1', 'DEV?pageNumber=2'))
    expect_equal(nrow(result), 4L, info = name)
    expect_setequal(paste(result$studyType, result$page), c('CHR 1', 'CHR 2', 'DEV 1', 'DEV 2'))
  }
})
