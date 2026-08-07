# Bespoke contract tests for the composed, hook-based chemi_search().
# Replaces the generated stub contract test.

test_that("chemi_search builds the search body and passes pagination args", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(
        totalRecordsCount = 1,
        records = list(list(sid = "DTXSID7020182"))
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(chemi_search("DTXSID7020182", "exact"))

  expect_identical(captured$endpoint, "search")
  expect_identical(captured$tidy, FALSE)
  expect_identical(captured$paginate, FALSE)
  expect_identical(captured$pagination_strategy, "offset_limit")

  body <- captured$body
  expect_identical(body$inputType, "MOL")
  expect_identical(body$searchType, "EXACT")
  expect_identical(body$query, "MOCK\nM  END\n")
  expect_identical(body$params$limit, 50)
  expect_identical(captured$options$limit, 50)

  expect_s3_class(result, "tbl_df")
})

test_that("chemi_search all_pages = TRUE requests offset/limit pagination", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  suppressMessages(chemi_search("DTXSID7020182", "exact", all_pages = TRUE))

  expect_identical(captured$paginate, TRUE)
  expect_identical(captured$pagination_strategy, "offset_limit")
})

test_that("chemi_search tags similarity results with relationship", {
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      list(
        totalRecordsCount = 2,
        records = list(
          list(sid = "DTXSID7020182", similarity = 1.0),
          list(sid = "DTXSID1024122", similarity = 0.9)
        )
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(chemi_search("DTXSID7020182", "similar"))

  expect_s3_class(result, "tbl_df")
  expect_true("relationship" %in% names(result))
  expect_identical(
    result$relationship,
    c("parent", "child")
  )
})

# --- Per-type body construction -------------------------------------------

test_that("chemi_search exact: fetches MOL exactly once for a DTXSID query", {
  n_fetch <- 0
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) {
      n_fetch <<- n_fetch + 1
      "MOCK\nM  END\n"
    },
    generic_chemi_request = function(...) {
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  suppressWarnings(suppressMessages(chemi_search("DTXSID7020182", "exact")))
  expect_identical(n_fetch, 1)
})

test_that("chemi_search substructure: resolves query to MOL", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  suppressWarnings(suppressMessages(chemi_search("DTXSID7020182", "substructure")))
  expect_identical(captured$body$inputType, "MOL")
  expect_identical(captured$body$searchType, "SUBSTRUCTURE")
  expect_identical(captured$body$query, "MOCK\nM  END\n")
})

test_that("chemi_search similar: maps all similarity types and min-similarity", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  for (st in names(.similarity_type_map)) {
    suppressWarnings(suppressMessages(
      chemi_search("DTXSID7020182", "similar", similarity_type = st)
    ))
    expect_identical(captured$body$searchType, "SIMILAR")
    expect_identical(
      unname(captured$body$params[["similarity-type"]]),
      unname(.similarity_type_map[st])
    )
    # Default threshold when not supplied.
    expect_identical(captured$body$params[["min-similarity"]], 0.85)
  }

  suppressWarnings(suppressMessages(
    chemi_search("DTXSID7020182", "similar", min_similarity = 0.5)
  ))
  expect_identical(captured$body$params[["min-similarity"]], 0.5)
})

test_that("chemi_search similar: tags parent/child from response similarity", {
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      list(
        totalRecordsCount = 2,
        records = list(
          list(sid = "DTXSID7020182", similarity = 1.0),
          list(sid = "DTXSID1024122", similarity = 0.9)
        )
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(chemi_search("DTXSID7020182", "similar"))
  expect_identical(result$relationship, c("parent", "child"))
})

test_that("chemi_search mass: drops query, maps all mass types, carries range + elements", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  for (mt in names(.mass_type_map)) {
    suppressWarnings(suppressMessages(
      chemi_search(
        query = NULL,
        search_type = "mass",
        mass_type = mt,
        min_mass = 100,
        max_mass = 200,
        element_include = c("C", "H")
      )
    ))
    expect_identical(captured$body$searchType, "MASS")
    # query = NULL -> body carries no query field.
    expect_false("query" %in% names(captured$body))
    expect_identical(
      unname(captured$body$params[["mass-type"]]),
      unname(.mass_type_map[mt])
    )
    expect_identical(captured$body$params[["min-mass"]], 100)
    expect_identical(captured$body$params[["max-mass"]], 200)
    expect_identical(captured$body$params[["include-elements"]], "C,H")
  }
})

test_that("chemi_search hazard: empty MOL, maps all names/toxicity/authority", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  for (hn in names(.hazard_name_map)) {
    suppressWarnings(suppressMessages(
      chemi_search(query = NULL, search_type = "hazard", hazard_name = hn)
    ))
    expect_identical(captured$body$searchType, "HAZARD")
    expect_identical(captured$body$query, .empty_mol_string)
    expect_identical(
      unname(captured$body$params[["hazard-name"]]),
      unname(.hazard_name_map[hn])
    )
  }

  for (mt in c("VH", "H", "M", "L", "A")) {
    suppressWarnings(suppressMessages(
      chemi_search(
        query = NULL,
        search_type = "hazard",
        hazard_name = "cancer",
        min_toxicity = mt
      )
    ))
    expect_identical(captured$body$params[["min-toxicity"]], mt)
  }

  for (auth in names(.authority_map)) {
    suppressWarnings(suppressMessages(
      chemi_search(
        query = NULL,
        search_type = "hazard",
        hazard_name = "cancer",
        min_authority = auth
      )
    ))
    expect_identical(
      unname(captured$body$params[["min-authority"]]),
      unname(.authority_map[auth])
    )
  }
})

test_that("chemi_search features: empty MOL, sweeps feature filters, element filters", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  for (fn in .feature_filter_names) {
    suppressWarnings(suppressMessages(
      chemi_search(
        query = NULL,
        search_type = "features",
        filter_features = TRUE,
        feature_filters = stats::setNames(TRUE, fn)
      )
    ))
    expect_identical(captured$body$searchType, "FEATURES")
    expect_identical(captured$body$query, .empty_mol_string)
    expect_true(captured$body$params[[paste0("filter-", fn)]])
  }

  suppressWarnings(suppressMessages(
    chemi_search(
      query = NULL,
      search_type = "features",
      element_include = c("C", "N", "O"),
      exclude_all_others = TRUE
    )
  ))
  expect_identical(captured$body$params[["include-elements"]], "C,N,O")
  expect_gt(nchar(captured$body$params[["exclude-elements"]]), 0)
})

# --- Cross-cutting ---------------------------------------------------------

test_that("chemi_search: limit feeds both body params and pagination options", {
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  suppressWarnings(suppressMessages(chemi_search("DTXSID7020182", "exact", limit = 25)))
  expect_identical(captured$body$params$limit, 25)
  expect_identical(captured$options$limit, 25)
})

test_that("chemi_search: does not re-fetch a query that is already a MOL", {
  n_fetch <- 0
  captured <- NULL
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) {
      n_fetch <<- n_fetch + 1
      "FETCHED\nM  END\n"
    },
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  mol <- "custom\nM  END\n"
  suppressWarnings(suppressMessages(chemi_search(mol, "exact")))
  expect_identical(n_fetch, 0)
  expect_identical(captured$body$query, mol)
})

test_that("chemi_search: empty response warns and returns a 0-row tibble", {
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  # process_search_response signals "No compounds found" via cli_alert_warning,
  # which is a message condition (not an R warning).
  expect_message(
    result <- chemi_search("DTXSID7020182", "exact"),
    "No compounds found"
  )
  expect_s3_class(result, "tbl_df")
  expect_identical(nrow(result), 0L)
})

test_that("chemi_search: validation failures surface as wrapped pre-request hook errors", {
  local_mocked_bindings(
    ct_chemical_file_mol_search = function(...) "MOCK\nM  END\n",
    generic_chemi_request = function(...) {
      list(totalRecordsCount = 0, records = list())
    },
    .package = "ComptoxR"
  )

  # run_hook() wraps hook errors, so assert on the wrapper class, not a message.
  expect_error(
    suppressMessages(
      chemi_search(query = NULL, search_type = "hazard", hazard_name = "not_a_hazard")
    ),
    class = "comptoxr_pre_request_hook_error"
  )
  expect_error(
    suppressMessages(chemi_search(query = NULL, search_type = "exact")),
    class = "comptoxr_pre_request_hook_error"
  )
  expect_error(
    suppressMessages(
      chemi_search(query = "DTXSID7020182", search_type = "similar", min_similarity = 1.5)
    ),
    class = "comptoxr_pre_request_hook_error"
  )
})
