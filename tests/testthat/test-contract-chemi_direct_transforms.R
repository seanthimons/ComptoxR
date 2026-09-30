# Handwritten fixed contracts for imported httr2 transport, unsupported by the toolkit renderer.
for (name in c('chemi_functional_use', 'chemi_safety_section')) {
  local({
    wrapper <- name
    testthat::test_that(paste(wrapper, 'preserves its direct fixed call sequence'), {
      contract <- readRDS(testthat::test_path('fixtures/specmill-rebuild-contracts.rds'))[[wrapper]]
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
      mocks <- setNames(
        lapply(unique(vapply(contract$calls, `[[`, '', 'helper')), mock_for),
        unique(vapply(contract$calls, `[[`, '', 'helper'))
      )
      do.call(testthat::local_mocked_bindings, c(mocks, list(.package = 'ComptoxR', .env = environment())))
      result <- suppressMessages(do.call(getExportedValue('ComptoxR', wrapper), contract$inputs))
      expect_identical(captured, lapply(contract$calls, function(call) call[c('helper', 'arguments')]))
      expect_identical(result, contract$result)
    })
  })
}
