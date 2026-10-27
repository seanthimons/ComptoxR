test_that("native MOL wrappers return captured CTX text without JSON parsing", {
  withr::local_envvar(ctx_api_key = "local-file-key")
  fixture <- readRDS(test_path("fixtures/native-file-media.rds"))
  for (i in seq_along(fixture)) local({
    response <- fixture[[i]]
    requests <- list()
    local_mocked_bindings(req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(status_code = response$status,
        headers = list(`Content-Type` = response$media), body = response$body)
    }, .package = "httr2")
    fn <- if (i == 1L) ct_chemical_file_mol_search_by_dtxsid else ct_chemical_file_mol_search_by_dtxcid
    ids <- if (i == 1L) c("DTXSID7020182", "DTXSID7020183") else c("DTXCID505", "DTXCID506")
    expect_identical(fn(ids[[1L]]), list(rawToChar(response$body)))
    expect_identical(fn(ids), rep(list(rawToChar(response$body)), 2L))
    expect_length(requests, 3L)
    expect_true(endsWith(requests[[3L]]$url, ids[[2L]]))
    expect_identical(httr2::url_parse(requests[[1L]]$url)$path,
      httr2::url_parse(response$url)$path)
  })
})
