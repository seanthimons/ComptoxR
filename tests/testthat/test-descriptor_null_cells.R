test_that("NULL descriptor cells retain every chemical and raw payload", {
  payloads <- list(
    list(list(NULL)),
    list(list(NULL, NULL)),
    list(list(NULL, NULL), list(NULL, NULL), list(NULL, NULL)),
    list(list(NULL, 2), list(3, NULL), list(NULL, 4))
  )
  for (values in payloads) {
    count <- length(values)
    headers <- paste0("d", seq_along(values[[1L]]))
    payload <- descriptor_contract_response(
      lapply(seq_along(values), function(i) descriptor_contract_record(
        smiles = c("CCO", "CCC", "CCCC")[[i]], descriptors = values[[i]], ordinal = i - 1L)),
      headers = headers)
    local_mocked_bindings(.ct_request = function(...) payload, .package = "ComptoxR")
    inputs <- c("CCO", "CCC", "CCCC")[seq_len(count)]
    fn <- eval_baseline_facade(readRDS(test_path("fixtures/native-four-calculations-contracts.rds"))$chemi_mordred_bulk[[3L]])
    result <- fn(inputs)
    expect_identical(nrow(result), count)
    expect_identical(result$query, inputs)
    expect_identical(result$status, rep("ok", count))
    for (j in seq_along(headers)) {
      expected <- vapply(values, function(row) if (is.null(row[[j]])) NA_real_ else row[[j]], 0)
      expect_equal(as.numeric(result[[headers[[j]]]]), expected)
    }
    raw <- fn(inputs, output = "raw")
    expect_identical(raw[names(payload)], payload)
    expect_identical(attr(raw, "source_endpoint"), "mordred")
    expect_identical(length(attr(raw, "input_map")), count)
  }
})
