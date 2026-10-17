test_that("Chemi list policy preserves object, array, scalar and envelope records", {
  cases <- list(
    '{"name":"one","optional":null}' = list(structure(list(name = "one", optional = NA), query = "_static_")),
    '[{"id":1},{"id":2}]' = list(list(id = 1L), list(id = 2L)),
    '{"results":[{"id":1}]}' = list(list(id = 1L)),
    '"release notes"' = list("release notes"),
    '{}' = list(structure(setNames(list(), character()), query = "_static_")),
    '[]' = list()
  )
  for (body in names(cases)) {
    response <- httr2::response(status_code = 200,
      headers = list(`Content-Type` = "application/json"), body = charToRaw(body))
    expect_identical(.ct_request_decode(response, response_policy = .ct_list), cases[[body]])
  }
})


test_that("static list policy preserves attribution with a sole URL query", {
  response <- httr2::response(status_code = 200,
    headers = list(`Content-Type` = "application/json"), body = charToRaw('{"id":1}'))
  expect_identical(.ct_request_decode(response, response_policy = .ct_static_list, policy_query = "carbon"),
    list(structure(list(id = 1L), query = "_static_")))
  expect_identical(.ct_request_decode(response, response_policy = .ct_list, policy_query = "group-one"),
    list(structure(list(id = 1L), query = "group-one")))
})
