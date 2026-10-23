# Handwritten frozen original contract for imported httr2 request helpers.
test_that('chemi_predict preserves the resolver and request-builder call sequence', {
  contract <- readRDS(test_path('fixtures/specmill-rebuild-contracts.rds'))$chemi_predict
  withr::local_envvar(unlist(contract$environment, use.names = TRUE))
  captured <- list()
  mock_for <- function(helper) {
    force(helper)
    function(...) {
      arguments <- list(...)
      index <- length(captured) + 1L
      captured[[index]] <<- list(helper = helper, arguments = arguments)
      contract$calls[[index]]$response
    }
  }
  helpers <- unique(vapply(contract$calls, `[[`, '', 'helper'))
  do.call(local_mocked_bindings, c(setNames(lapply(helpers, mock_for), helpers), list(.package = 'ComptoxR', .env = environment())))
  result <- suppressMessages(do.call(ComptoxR::chemi_predict, contract$inputs))
  expect_identical(captured, lapply(contract$calls, function(call) call[c('helper','arguments')]))
  expect_identical(result, contract$result)
})
