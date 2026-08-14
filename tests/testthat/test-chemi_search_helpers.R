# Unit tests for the pure chemi_search parameter/validation helpers.

test_that("validate_search_inputs rejects bad inputs", {
  expect_error(validate_search_inputs("nonsense", "DTXSID1"), "Invalid search_type")
  expect_error(validate_search_inputs("exact", NULL), "requires a query")
  expect_error(validate_search_inputs("exact", ""), "requires a query")
  expect_error(
    validate_search_inputs("hazard", NULL, hazard_name = "not_a_hazard"),
    "Invalid hazard_name"
  )
  expect_error(
    validate_search_inputs("similar", "DTXSID1", min_similarity = 1.5),
    "between 0 and 1"
  )
  expect_true(validate_search_inputs("exact", "DTXSID1"))
})

test_that("build_search_params maps similar/hazard/mass params", {
  sim <- build_search_params(
    "similar",
    similarity_type = "tanimoto",
    min_similarity = 0.9
  )
  expect_identical(unname(sim[["similarity-type"]]), "tanimoto")
  expect_identical(sim[["min-similarity"]], 0.9)
  expect_identical(sim$limit, 50)

  haz <- build_search_params(
    "hazard",
    hazard_name = "cancer",
    min_toxicity = "H",
    min_authority = "auth"
  )
  expect_identical(unname(haz[["hazard-name"]]), "Carcinogenicity")
  expect_identical(haz[["min-toxicity"]], "H")
  expect_identical(unname(haz[["min-authority"]]), "Authoritative")

  mass <- build_search_params(
    "mass",
    mass_type = "mono",
    min_mass = 100,
    max_mass = 200
  )
  expect_identical(unname(mass[["mass-type"]]), "monoisotopic-mass")
  expect_identical(mass[["min-mass"]], 100)
  expect_identical(mass[["max-mass"]], 200)
})

test_that("build_search_params handles feature and element branches", {
  feat <- build_search_params(
    "features",
    filter_features = TRUE,
    feature_filters = c(stereo = TRUE, bogus = TRUE)
  )
  expect_true(feat[["filter-stereo"]])
  expect_false("filter-bogus" %in% names(feat))

  elem <- build_search_params(
    "features",
    element_include = c("C", "N"),
    element_exclude = c("Cl")
  )
  expect_identical(elem[["include-elements"]], "C,N")
  expect_identical(elem[["exclude-elements"]], "Cl")
})

test_that("expand_element_exclusion covers its three branches", {
  expect_null(expand_element_exclusion(NULL, NULL, FALSE))

  expect_identical(
    expand_element_exclusion(NULL, c("Cl", "Br"), FALSE),
    "Cl, Br"
  )

  all_others <- expand_element_exclusion(c("C", "H"), NULL, TRUE)
  expect_type(all_others, "character")
  excluded <- trimws(strsplit(all_others, ",")[[1]])
  expect_false("C" %in% excluded)
  expect_false("H" %in% excluded)
  expect_true("O" %in% excluded)
})

test_that("expand_element_exclusion returns NULL when exclude_all_others has no include", {
  # exclude_all_others = TRUE but element_include = NULL -> no basis to expand.
  expect_null(expand_element_exclusion(NULL, NULL, TRUE))
})

# --- Exhaustive enum sweeps -----------------------------------------------

test_that("validate_search_inputs accepts every hazard name", {
  for (hn in names(.hazard_name_map)) {
    expect_true(validate_search_inputs("hazard", NULL, hazard_name = hn))
  }
})

test_that("validate_search_inputs requires a query for query-required types", {
  for (st in c("exact", "substructure", "similar")) {
    expect_error(validate_search_inputs(st, NULL), "requires a query")
    expect_error(validate_search_inputs(st, ""), "requires a query")
  }
})

test_that("validate_search_inputs enforces min_similarity boundaries", {
  expect_true(validate_search_inputs("similar", "DTXSID1", min_similarity = 0))
  expect_true(validate_search_inputs("similar", "DTXSID1", min_similarity = 1))
  expect_error(
    validate_search_inputs("similar", "DTXSID1", min_similarity = -0.1),
    "between 0 and 1"
  )
  expect_error(
    validate_search_inputs("similar", "DTXSID1", min_similarity = 1.1),
    "between 0 and 1"
  )
})

test_that("build_search_params sweeps every enum map per owning type", {
  for (st in names(.similarity_type_map)) {
    p <- build_search_params("similar", similarity_type = st, min_similarity = 0.85)
    expect_identical(
      unname(p[["similarity-type"]]),
      unname(.similarity_type_map[st])
    )
  }

  for (mt in names(.mass_type_map)) {
    p <- build_search_params("mass", mass_type = mt)
    expect_identical(unname(p[["mass-type"]]), unname(.mass_type_map[mt]))
  }

  for (hn in names(.hazard_name_map)) {
    p <- build_search_params("hazard", hazard_name = hn)
    expect_identical(unname(p[["hazard-name"]]), unname(.hazard_name_map[hn]))
  }

  for (auth in names(.authority_map)) {
    p <- build_search_params("hazard", min_authority = auth)
    expect_identical(unname(p[["min-authority"]]), unname(.authority_map[auth]))
  }

  for (fn in .feature_filter_names) {
    p <- build_search_params(
      "features",
      filter_features = TRUE,
      feature_filters = stats::setNames(TRUE, fn)
    )
    expect_true(p[[paste0("filter-", fn)]])
  }
})

test_that("build_search_params gates params to their owning search type", {
  # Similarity params must not leak into a mass build.
  m <- build_search_params(
    "mass",
    similarity_type = "tanimoto",
    min_similarity = 0.9,
    mass_type = "mono"
  )
  expect_false("similarity-type" %in% names(m))
  expect_false("min-similarity" %in% names(m))

  # Hazard params must not leak into a similar build.
  s <- build_search_params(
    "similar",
    similarity_type = "tanimoto",
    hazard_name = "cancer",
    min_toxicity = "H",
    min_authority = "auth"
  )
  expect_false("hazard-name" %in% names(s))
  expect_false("min-toxicity" %in% names(s))
  expect_false("min-authority" %in% names(s))
})
