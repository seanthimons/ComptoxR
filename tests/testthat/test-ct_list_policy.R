test_that("Chemi list policy preserves object, array, scalar and envelope records", {
  cases <- list(
    '{"name":"one","optional":null}' = list(structure(list(name = "one", optional = NA), query = "_static_")),
    '[{"id":1},{"id":2}]' = list(list(id = 1L), list(id = 2L)),
    '{"results":[{"id":1}]}' = list(list(id = 1L)),
    '"release notes"' = list("release notes"),
    '[]' = list()
  )
  for (body in names(cases)) {
    response <- httr2::response(status_code = 200,
      headers = list(`Content-Type` = "application/json"), body = charToRaw(body))
    expect_identical(.ct_request_decode(response, response_policy = .ct_list), cases[[body]])
  }
})
