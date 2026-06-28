#!/usr/bin/env Rscript

cran_readiness_env_flag <- function(value) {
  tolower(trimws(value)) %in% c("1", "true", "yes", "y")
}

cran_readiness_parse_cpus <- function(value) {
  value <- trimws(value)
  if (!nzchar(value)) {
    return(NA_integer_)
  }

  cpus <- suppressWarnings(as.integer(value))
  if (is.na(cpus) || cpus < 1L) {
    return(NA_integer_)
  }
  cpus
}

cran_readiness_default_cpus <- function() {
  detected <- parallel::detectCores(logical = TRUE)
  if (is.na(detected)) {
    detected <- parallel::detectCores(logical = FALSE)
  }
  if (is.na(detected)) {
    detected <- 2L
  }

  max(1L, min(12L, as.integer(ceiling(detected * 0.75))))
}

cran_readiness_test_cpus <- function() {
  explicit <- cran_readiness_parse_cpus(Sys.getenv("COMPTOXR_CRAN_READINESS_CPUS", unset = ""))
  if (!is.na(explicit)) {
    return(explicit)
  }

  existing <- cran_readiness_parse_cpus(Sys.getenv("TESTTHAT_CPUS", unset = ""))
  if (!is.na(existing)) {
    return(existing)
  }

  cran_readiness_default_cpus()
}

cran_readiness_set_env <- function() {
  cpus <- cran_readiness_test_cpus()
  parallel <- cpus > 1L && !cran_readiness_env_flag(Sys.getenv("COMPTOXR_CRAN_READINESS_SEQUENTIAL", unset = ""))

  Sys.setenv(
    COMPTOXR_CRAN_SAFE_TESTS = "true",
    NOT_CRAN = "false",
    TESTTHAT_CPUS = as.character(if (parallel) cpus else 1L),
    TESTTHAT_PARALLEL = if (parallel) "TRUE" else "FALSE"
  )
  Sys.unsetenv("ctx_api_key")

  missing_db_dir <- file.path(tempdir(), "comptoxr-cran-readiness-missing-dbs")
  options(
    ComptoxR.dsstox_path = file.path(missing_db_dir, "dsstox.duckdb"),
    ComptoxR.ecotox_path = file.path(missing_db_dir, "ecotox.duckdb"),
    ComptoxR.toxval_path = file.path(missing_db_dir, "toxval.duckdb")
  )

  invisible(list(cpus = as.integer(Sys.getenv("TESTTHAT_CPUS")), parallel = parallel))
}

cran_readiness_run <- function(label, command, args = character()) {
  cat(sprintf("\n==> %s\n", label))
  status <- system2(command, args = args)
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed with status %s", label, status), call. = FALSE)
  }
  invisible(TRUE)
}

cran_readiness_set_test_parallel <- function(cpus) {
  cpus <- as.integer(cpus)
  Sys.setenv(
    TESTTHAT_CPUS = as.character(cpus),
    TESTTHAT_PARALLEL = if (cpus > 1L) "TRUE" else "FALSE"
  )
  invisible(cpus)
}

cran_readiness_test_attempts <- function(cpus) {
  attempts <- unique(c(cpus, floor(cpus / 2L), 4L, 2L, 1L))
  attempts[attempts >= 1L & attempts <= cpus]
}

cran_readiness_is_worker_start_error <- function(error) {
  message <- conditionMessage(error)
  grepl("subprocess failed to start", message, fixed = TRUE) ||
    grepl("testthat subprocess exited", message, fixed = TRUE) ||
    grepl("R session crashed", message, fixed = TRUE)
}

cran_readiness_sequential_test_filter <- function() {
  paste0(
    "^(",
    paste(
      c(
        "eco_lifestage_gate",
        "genra_predict",
        "cts",
        "util_pubchem_resolve_dtxsid"
      ),
      collapse = "|"
    ),
    ")$"
  )
}

cran_readiness_test_dir <- function(label, cpus, filter = NULL, invert = FALSE) {
  cpus <- cran_readiness_set_test_parallel(cpus)
  worker_label <- if (identical(cpus, 1L)) "worker" else "workers"

  cat(sprintf(
    "\n==> %s (%s test %s)\n",
    label,
    cpus,
    worker_label
  ))

  testthat::test_dir(
    "tests/testthat",
    package = "ComptoxR",
    filter = filter,
    invert = invert,
    stop_on_failure = TRUE,
    load_package = "source",
    shuffle = FALSE
  )
  invisible(TRUE)
}

cran_readiness_run_tests_once <- function(cpus) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("The devtools package is required to run CRAN readiness tests.", call. = FALSE)
  }
  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("The testthat package is required to run CRAN readiness tests.", call. = FALSE)
  }

  sequential_filter <- cran_readiness_sequential_test_filter()
  cran_readiness_test_dir(
    "Run CRAN-safe tests in parallel",
    cpus = cpus,
    filter = sequential_filter,
    invert = TRUE
  )
  cran_readiness_test_dir(
    "Run state-sensitive CRAN-safe tests sequentially",
    cpus = 1L,
    filter = sequential_filter
  )
  invisible(TRUE)
}

cran_readiness_test <- function() {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("The devtools package is required to run CRAN readiness tests.", call. = FALSE)
  }

  cpus <- as.integer(Sys.getenv("TESTTHAT_CPUS", unset = "1"))
  attempts <- cran_readiness_test_attempts(cpus)

  for (i in seq_along(attempts)) {
    error <- tryCatch(
      {
        cran_readiness_run_tests_once(attempts[[i]])
        NULL
      },
      error = function(e) e
    )

    if (is.null(error)) {
      return(invisible(TRUE))
    }

    if (!cran_readiness_is_worker_start_error(error) || i == length(attempts)) {
      stop(error)
    }

    cat(sprintf(
      "\nTestthat could not start a worker with %s process(es); retrying with %s.\n",
      attempts[[i]],
      attempts[[i + 1L]]
    ))
  }

  invisible(TRUE)
}

cran_readiness_main <- function() {
  cran_readiness_set_env()

  cran_readiness_run(
    "Check generated wrapper tests",
    "Rscript",
    c("dev/generate_tests.R", "--check")
  )
  cran_readiness_run(
    "Run unit-test readiness audit",
    "Rscript",
    c("dev/unit_test_readiness_audit.R", "--check-exports", "--fail-on-gaps")
  )
  cran_readiness_test()

  cat("\nCRAN readiness checks passed.\n")
  invisible(TRUE)
}

if (!interactive()) {
  cran_readiness_main()
}
