unit_test_readiness_audit_script <- testthat::test_path("..", "..", "dev", "unit_test_readiness_audit.R")
if (!file.exists(unit_test_readiness_audit_script)) {
  testthat::skip(
    "Maintainer-only test requires dev/unit_test_readiness_audit.R; dev/ is excluded from CRAN source tarballs"
  )
}
source(unit_test_readiness_audit_script)

make_audit_repo <- function() {
  root <- tempfile("unit-test-audit-")
  dir.create(root, recursive = TRUE)
  root
}

write_audit_file <- function(root, rel_path, lines) {
  path <- file.path(root, rel_path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
  path
}

records_by_export <- function(comparison) {
  stats::setNames(
    comparison$export_inventory,
    vapply(comparison$export_inventory, `[[`, character(1), "export")
  )
}

make_vcr_classification <- function(
  classifications = list(),
  artifact_schema = "vcr_test_classification/v1",
  allowed_tiers = c("replay_fixture_integration", "live_only", "recorder_only")
) {
  list(
    artifact_schema = artifact_schema,
    issue = list(
      github_issue = 202,
      bean = "ComptoxR-uvdd",
      title = "VCR Test Classification Gate"
    ),
    allowed_tiers = allowed_tiers,
    required_fields = c("test_file", "tier", "reason", "owner", "issue"),
    classifications = classifications
  )
}

test_that("namespace export parsing excludes operators and S3 methods from function-export gaps", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "NAMESPACE",
    c(
      "S3method(print,thing)",
      "export(\"%>%\")",
      "export('%ni%')",
      "export(alpha)",
      "export(beta)"
    )
  )

  namespace <- audit_parse_namespace(root)

  expect_equal(namespace$operator_exports, c("%>%", "%ni%"))
  expect_equal(namespace$s3_methods, "print,thing")
  expect_equal(namespace$function_exports, c("alpha", "beta"))
  expect_false("%>%" %in% namespace$function_exports)
})

test_that("named test files and literal references classify exports separately", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(root, "tests/testthat/test-alpha.R", "test_that('alpha works', { alpha() })")
  write_audit_file(root, "tests/testthat/test-beta-name.R", "test_that('named file only', { expect_true(TRUE) })")
  write_audit_file(root, "tests/testthat/test-unrelated.R", "test_that('gamma referenced', { gamma_value <- gamma() })")

  comparison <- classify_exports_against_tests(
    c("alpha", "beta_name", "gamma"),
    sort(c(
      "tests/testthat/test-alpha.R",
      "tests/testthat/test-beta-name.R",
      "tests/testthat/test-unrelated.R"
    )),
    root
  )
  records <- records_by_export(comparison)

  expect_true(records$alpha$named_test_file)
  expect_true(records$alpha$literal_test_reference)
  expect_true(records$beta_name$named_test_file)
  expect_false(records$beta_name$literal_test_reference)
  expect_false(records$gamma$named_test_file)
  expect_true(records$gamma$literal_test_reference)
  expect_equal(comparison$export_gaps, "beta_name")
})

test_that("export exclusions require export reason owner and issue fields", {
  bad <- list(
    artifact_schema = "export_test_exclusions/v1",
    exclusions = list(list(export = "alpha", reason = "covered elsewhere"))
  )
  good <- list(
    artifact_schema = "export_test_exclusions/v1",
    exclusions = list(list(
      export = "alpha",
      reason = "covered by integration-only fixture",
      owner = "release",
      issue = "#190"
    ))
  )

  expect_false(validate_export_exclusions(bad, known_exports = "alpha")$valid)
  expect_true(validate_export_exclusions(good, known_exports = "alpha")$valid)
})

test_that("retired manifest is reported as non-authoritative", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "dev/test_manifest.json",
    c(
      "{",
      '  "artifact_schema": "test_manifest_retired/v1",',
      '  "retired": true,',
      '  "authority": false,',
      '  "replacement": "dev/reports/unit_test_readiness_audit.json",',
      '  "legacy_manifest": { "files_total": 45 }',
      "}"
    )
  )

  status <- audit_manifest_status(root)

  expect_true(status$retired)
  expect_false(status$authoritative)
  expect_equal(status$replacement, "dev/reports/unit_test_readiness_audit.json")
  expect_equal(status$legacy_files_total, 45)
})

test_that("absent manifest is the normal retired state", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  status <- audit_manifest_status(root)

  expect_false(status$exists)
  expect_true(status$retired)
  expect_false(status$authoritative)
  expect_equal(status$replacement, "dev/reports/unit_test_readiness_audit.json")
  expect_equal(status$legacy_files_total, 0)
})

test_that("generated-test static counters require a top-of-file generated header", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "tests/testthat/test-alpha.R",
    c(
      "# Generated by dev/generate_tests.R; do not edit by hand.",
      "test_that('alpha passes request metadata', {",
      "  local_mocked_bindings(alpha = function() TRUE)",
      "})"
    )
  )
  write_audit_file(
    root,
    "tests/testthat/test-generator-fixture.R",
    c(
      "test_that('fixture text is not a generated test', {",
      "  marker <- '# Generated using metadata-based test generator'",
      "  call <- '`ct_chemical_by-dtxcid`()'",
      "  expect_true(nzchar(marker))",
      "  expect_true(nzchar(call))",
      "})"
    )
  )

  style <- audit_test_style(root)

  expect_equal(style$generated_header_test_files, 1)
  expect_equal(style$generated_backticked_endpoint_call_files, 0)
  expect_equal(style$non_generated_backticked_endpoint_call_files, 1)
  expect_equal(style$files_using_mocked_bindings, 1)
})

test_that("generated audit keeps schema unit_test_readiness_audit/v1", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(root, "NAMESPACE", "export(alpha)")
  write_audit_file(root, "tests/testthat/test-alpha.R", "test_that('alpha works', { alpha() })")
  write_audit_file(
    root,
    "dev/export_test_exclusions.json",
    c(
      "{",
      '  "artifact_schema": "export_test_exclusions/v1",',
      '  "required_fields": ["export", "reason", "owner", "issue"],',
      '  "exclusions": []',
      "}"
    )
  )

  output <- file.path(root, "dev/reports/unit_test_readiness_audit.json")
  report <- write_unit_test_readiness_audit(root, output)
  parsed <- jsonlite::fromJSON(output, simplifyVector = FALSE)

  expect_equal(report$artifact_schema, "unit_test_readiness_audit/v1")
  expect_equal(parsed$artifact_schema, "unit_test_readiness_audit/v1")
})

test_that("empty VCR classification file passes when no tests use VCR", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "dev/vcr_test_classification.json",
    c(
      "{",
      '  "artifact_schema": "vcr_test_classification/v1",',
      '  "issue": { "github_issue": 202, "bean": "ComptoxR-uvdd", "title": "VCR Test Classification Gate" },',
      '  "allowed_tiers": ["replay_fixture_integration", "live_only", "recorder_only"],',
      '  "required_fields": ["test_file", "tier", "reason", "owner", "issue"],',
      '  "classifications": []',
      "}"
    )
  )
  write_audit_file(root, "tests/testthat/test-alpha.R", "test_that('alpha works', { expect_true(TRUE) })")

  classification <- read_vcr_test_classification(root)
  style <- audit_test_style(root)
  validation <- validate_vcr_test_classification(
    classification,
    current_vcr_test_files = style$files_using_vcr_names,
    current_test_files = audit_list_files(root, "tests/testthat", "^test-.*\\.R$")
  )

  expect_true(validation$valid)
  expect_equal(validation$status, "ok")
  expect_equal(validation$current_vcr_test_files_total, 0)
})

test_that("VCR tests must be present in the classification file", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "tests/testthat/test-alpha.R",
    c(
      "test_that('alpha records', {",
      paste0("  vcr::use_", "cassette('alpha', { expect_true(TRUE) })"),
      "})"
    )
  )

  style <- audit_test_style(root)
  validation <- validate_vcr_test_classification(
    make_vcr_classification(),
    current_vcr_test_files = style$files_using_vcr_names,
    current_test_files = audit_list_files(root, "tests/testthat", "^test-.*\\.R$")
  )

  expect_false(validation$valid)
  expect_equal(validation$status, "gaps")
  expect_equal(validation$unclassified_files, "tests/testthat/test-alpha.R")
})

test_that("classified VCR tests pass with a valid tier", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(
    root,
    "tests/testthat/test-alpha.R",
    c(
      "test_that('alpha replays fixture', {",
      paste0("  vcr::use_", "cassette('alpha', { expect_true(TRUE) })"),
      "})"
    )
  )

  style <- audit_test_style(root)
  validation <- validate_vcr_test_classification(
    make_vcr_classification(list(list(
      test_file = "tests/testthat/test-alpha.R",
      tier = "replay_fixture_integration",
      reason = "replays a committed fixture",
      owner = "release",
      issue = "#202"
    ))),
    current_vcr_test_files = style$files_using_vcr_names,
    current_test_files = audit_list_files(root, "tests/testthat", "^test-.*\\.R$")
  )

  expect_true(validation$valid)
  expect_equal(validation$status, "ok")
  expect_equal(validation$classified_files, "tests/testthat/test-alpha.R")
})

test_that("stale VCR classification entries fail when files disappear or stop using VCR", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(root, "tests/testthat/test-stale.R", "test_that('now unit only', { expect_true(TRUE) })")

  validation <- validate_vcr_test_classification(
    make_vcr_classification(list(
      list(
        test_file = "tests/testthat/test-stale.R",
        tier = "live_only",
        reason = "formerly used live API behavior",
        owner = "release",
        issue = "#202"
      ),
      list(
        test_file = "tests/testthat/test-missing.R",
        tier = "recorder_only",
        reason = "formerly used cassette recording",
        owner = "release",
        issue = "#202"
      )
    )),
    current_vcr_test_files = character(0),
    current_test_files = audit_list_files(root, "tests/testthat", "^test-.*\\.R$")
  )

  expect_false(validation$valid)
  expect_equal(validation$status, "gaps")
  expect_equal(
    validation$stale_classification_files,
    c(
      "tests/testthat/test-missing.R",
      "tests/testthat/test-stale.R"
    )
  )
  expect_true(any(grepl(
    "not a current",
    vapply(validation$stale_classification_entries, `[[`, character(1), "reason")
  )))
  expect_true(any(grepl(
    "no longer uses",
    vapply(validation$stale_classification_entries, `[[`, character(1), "reason")
  )))
})

test_that("invalid VCR classification schema tiers and required fields are rejected", {
  invalid_schema <- validate_vcr_test_classification(
    make_vcr_classification(artifact_schema = "vcr_test_classification/v0")
  )
  invalid_tier <- validate_vcr_test_classification(
    make_vcr_classification(list(list(
      test_file = "tests/testthat/test-alpha.R",
      tier = "replay",
      reason = "bad tier",
      owner = "release",
      issue = "#202"
    ))),
    current_vcr_test_files = "tests/testthat/test-alpha.R",
    current_test_files = "tests/testthat/test-alpha.R"
  )
  missing_field <- validate_vcr_test_classification(
    make_vcr_classification(list(list(
      test_file = "tests/testthat/test-alpha.R",
      tier = "live_only",
      reason = "missing owner and issue"
    ))),
    current_vcr_test_files = "tests/testthat/test-alpha.R",
    current_test_files = "tests/testthat/test-alpha.R"
  )

  expect_false(invalid_schema$valid)
  expect_equal(invalid_schema$status, "invalid")
  expect_match(invalid_schema$errors[[1]], "artifact_schema")
  expect_false(invalid_tier$valid)
  expect_equal(invalid_tier$status, "invalid")
  expect_match(invalid_tier$errors[[1]], "invalid tier")
  expect_false(missing_field$valid)
  expect_equal(missing_field$status, "invalid")
  expect_match(missing_field$errors[[1]], "missing required field")
})

test_that("readiness audit reports the three test tiers", {
  root <- make_audit_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  write_audit_file(root, "NAMESPACE", "export(alpha)")
  write_audit_file(root, "tests/testthat/test-alpha.R", "test_that('alpha works', { alpha() })")
  write_audit_file(
    root,
    "dev/export_test_exclusions.json",
    c(
      "{",
      '  "artifact_schema": "export_test_exclusions/v1",',
      '  "required_fields": ["export", "reason", "owner", "issue"],',
      '  "exclusions": []',
      "}"
    )
  )

  report <- build_unit_test_readiness_audit(root)

  expect_equal(
    names(report$test_tiers),
    c("cran_safe_unit_contract", "replay_fixture_integration", "live_recording")
  )
  expect_true(any(grepl("No real ctx_api_key", report$test_tiers$cran_safe_unit_contract$requirements)))
  expect_true(any(grepl("Committed fixtures only", report$test_tiers$replay_fixture_integration$requirements)))
  expect_true(any(grepl("Explicit opt-in only", report$test_tiers$live_recording$requirements)))
  expect_true(any(grepl("CRAN-safe unit/contract tests", report$cran_readiness_criteria)))
})
