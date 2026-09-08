# Explicit roots are supplied by comptox_tools(); this fallback preserves source().
if (!exists('toolkit_root', inherits = FALSE)) {
  toolkit_root <- here::here()
}
client_path <- function(...) file.path(toolkit_root, ...)
wrapmaint::bind_tools("runner", environment())
formals(run_generator)$pkg_dir <- quote(client_path("R"))
formals(endpoint_coverage)$pkg_dir <- quote(client_path("R"))
# ==============================================================================
# Stub Specs & Endpoint Coverage (sourceable module, no side effects)
# ==============================================================================
#
# Shared by:
#   - dev/generate_stubs.R    -> stub generation (run_generator + ct/chemi specs)
#   - dev/calculate_coverage.R -> operation-level API coverage (endpoint_coverage)
#
# Sourcing this file only LOADS utilities and DEFINES objects (configs, specs,
# helpers). It does not generate stubs, reset tracking state, or write files, so
# it is safe to source from any consumer. The per-API build_endpoints() closures
# are the single source of truth for how (route, method) pairs map to file/fn
# names, so coverage is measured against the exact same endpoint set the stub
# generator builds.

# Load required packages

# ==============================================================================
# Configuration
# ==============================================================================

# CompTox (ct_*) function generation configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Cheminformatics (chemi_*) function generation configuration
chemi_config <- list(
  wrapper_function = "generic_chemi_request",
  param_strategy = "options",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# EPI Suite (epi_*) function generation configuration. Unauthenticated GET
# endpoints on epi_burl; routes through generic_request like ct_* (see the
# ^epi_ server/auth branch in 07_stub_generation.R that emits server="epi_burl").
epi_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "50-00-0",
  lifecycle_badge = "experimental"
)

# ==============================================================================
# Load Utilities
# ==============================================================================

cli_alert_info("Loading endpoint evaluation utilities...")

# Source the modular utilities
utils_dir <- client_path("dev", "endpoint_eval")

sys.source(file.path(utils_dir, "00_config.R"), envir = environment())
sys.source(file.path(utils_dir, "01_schema_resolution.R"), envir = environment())
sys.source(file.path(utils_dir, "02_path_utils.R"), envir = environment())
sys.source(file.path(utils_dir, "03_codebase_search.R"), envir = environment())
sys.source(file.path(utils_dir, "04_openapi_parser.R"), envir = environment())
sys.source(file.path(utils_dir, "05_file_scaffold.R"), envir = environment())
sys.source(file.path(utils_dir, "06_param_parsing.R"), envir = environment())
sys.source(file.path(utils_dir, "07_stub_generation.R"), envir = environment())
sys.source(file.path(utils_dir, "08_drift_detection.R"), envir = environment())
sys.source(client_path("R", "hook_registry.R"), envir = environment())

# ==============================================================================
# Generic Runner
# ==============================================================================
# The active APIs (ct/chemi) share one pipeline. Only three things vary per
# API: which schema files to read, how routes map to file/fn names, and an
# optional route filter. Those live in each spec's `build_endpoints()` closure
# (preserved verbatim from the original per-API functions). Everything from
# usage detection onward is identical and lives here, in run_generator().
#
# Note: select_schema_files() lives in dev/endpoint_eval/01_schema_resolution.R
# for shared use between generate_stubs.R and diff_schemas.R.

# ==============================================================================
# Collision-only disambiguation (issue #214)
# ==============================================================================
# The route -> file/fn derivation strips distinguishing tokens (summary,
# by-dtxsid, trailing-slash, path-params), so several DISTINCT (route, method)
# pairs can collapse to one file + fn. The append-only scaffold then writes all
# defs and the LAST one wins, silently dropping the earlier, richer definitions.
#
# Fix: compute BOTH the existing "short" file/fn and a "full" file/fn that keeps
# the distinguishing tokens. Where a short fn is unique we keep it (idempotent);
# only the rows whose short fn collides (>= 2 distinct route+method map to it)
# fall back to the full name so every endpoint gets a unique file + fn.

#' Derive the per-row function name from a file column using the existing
#' bulk/method-suffix convention (grouped per file). Returns a character vector
#' aligned with the input rows.

#' Collision-only fallback. Expects columns file_short/file_full/fn_short/fn_full.
#' Keeps the short names where the short fn is unique; rows whose short fn
#' collides fall back to the full file/fn. Drops all helper columns (file_short,
#' file_full, fn_short, fn_full, and any starting with ".").

#' Run the shared stub-generation pipeline for one API spec.
#' @param spec list with prefix, heading, build_endpoints(), config, and
#'   optional post() hook.
#' @param pkg_dir Directory containing the R source files (default R/).
#' @return list(scaffold = <scaffold tibble>, drift = <drift tibble>)

# ==============================================================================
# Per-API Specs
# ==============================================================================
# Each build_endpoints() is the original per-API function's parse + derive logic
# verbatim; it returns the endpoints tibble (or NULL when no schemas/endpoints).

ct_spec <- list(
  prefix = "ct",
  heading = "CompTox Dashboard (ct_*)",
  config = ct_config,
  build_endpoints = function() {
    ctx_schema_files <- list.files(
      path = client_path('schema'),
      pattern = "^ctx-.*-prod\\.json$",
      full.names = FALSE
    )

    if (length(ctx_schema_files) == 0) {
      cli_alert_warning("No ctx schema files found, skipping ct_* generation")
      return(NULL)
    }

    cli_alert_info("Found {length(ctx_schema_files)} ctx schema file(s)")

    endpoints <- map(
      ctx_schema_files,
      ~ {
        openapi <- jsonlite::fromJSON(client_path('schema', .x), simplifyVector = FALSE)
        openapi_to_spec(openapi)
      },
      .progress = FALSE
    ) %>%
      list_rbind() %>%
      mutate(
        route = strip_curly_params(route, leading_slash = 'remove'),
        domain = route %>% str_extract("^[^/]+"),
        # ctx schemas are prod-only, so every ct_* function is public-stage.
        schema_stage = "public",
        # "short" core: strips domain-ish noise AND the distinguishing tokens
        # (summary, by-dtxsid). This is today's logic, kept for idempotency.
        .core_short = route %>%
          str_remove_all(regex(
            "(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|summary|by[/_-]dtxsid)(?=$|[/_-])"
          )) %>%
          str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
          str_replace_all("[/]+", " ") %>%
          str_squish() %>%
          str_replace_all("\\s", "_") %>%
          str_replace_all("-", "_"),
        # "full" core: strips ONLY the domain-ish noise, retaining the
        # distinguishing tokens (summary, by-dtxsid, by-aeid) so colliding
        # endpoints get unique names.
        .core_full = route %>%
          str_remove_all(regex(
            "(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies))(?=$|[/_-])"
          )) %>%
          str_replace_all("[/]+", " ") %>%
          str_squish() %>%
          str_replace_all("\\s", "_") %>%
          str_replace_all("-", "_"),
        file_short = paste0("ct_", domain, "_", .core_short, ".R"),
        file_full = paste0("ct_", domain, "_", .core_full, ".R"),
        batch_limit = case_when(
          method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
          method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
          .default = NULL
        )
      ) %>%
      arrange(forcats::fct_inorder(domain), route, factor(method, levels = c('POST', 'GET'))) %>%
      distinct(route, method, .keep_all = TRUE)

    endpoints$fn_short <- derive_fn_from_file(endpoints, "file_short")
    endpoints$fn_full <- derive_fn_from_file(endpoints, "file_full")
    endpoints <- resolve_collisions(endpoints)

    cli_alert_info("Parsed {nrow(endpoints)} endpoint(s) from schemas")
    endpoints
  }
)

prepare_chemi_operations <- function(endpoints) {
  endpoints %>%
    mutate(
      schema_stage = 'public',
      operation_key = paste(service_slug, route, method, sep = '\034')
    ) %>%
    distinct(operation_key, .keep_all = TRUE)
}

name_chemi_endpoints <- function(endpoints) {
  naming <- endpoints[!duplicated(endpoints$operation_key), , drop = FALSE] %>%
    mutate(
      route_clean = strip_curly_params(route, leading_slash = "remove"),
      domain = if_else(
        str_starts(route_clean, "api/"),
        route_clean %>% str_remove("^api/") %>% str_extract("^[^/]+"),
        service_slug
      ),
      name = route_clean %>%
        str_remove_all("^api/") %>%
        str_remove_all(regex("(?i)(?:^|[/_-])(?:chemi|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")) %>%
        str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
        str_replace_all("[/]+", " ") %>%
        str_squish() %>%
        str_replace_all("\\s", "_") %>%
        str_replace_all("-", "_"),
      path_marker = purrr::map_chr(
        str_extract_all(route, "(?<=\\{)[^}]+"),
        ~ paste(.x, collapse = "_and_")
      ) %>%
        str_replace_all("[^A-Za-z0-9]+", "_") %>%
        str_to_lower(),
      name_full = if_else(
        num_path_params > 0 & nzchar(path_marker),
        paste0(name, "_by_", path_marker),
        name
      ),
      file_short = case_when(
        nchar(name) == 0 ~ paste0("chemi_", domain, ".R"),
        str_detect(name, fixed(domain)) ~ paste0("chemi_", name, ".R"),
        .default = paste0("chemi_", domain, "_", name, ".R")
      ),
      file_full = case_when(
        nchar(name_full) == 0 ~ paste0("chemi_", domain, ".R"),
        str_detect(name_full, fixed(domain)) ~ paste0("chemi_", name_full, ".R"),
        .default = paste0("chemi_", domain, "_", name_full, ".R")
      ),
      batch_limit = 0
    )

  naming$fn_short <- derive_fn_from_file(naming, "file_short")
  naming$fn_full <- derive_fn_from_file(naming, "file_full")
  naming <- resolve_collisions(naming) %>% select(operation_key, file, fn)

  endpoints %>%
    left_join(naming, by = "operation_key") %>%
    mutate(
      route = strip_curly_params(route, leading_slash = "remove") %>% str_remove_all("^api/")
    )
}

write_generated_hook_config <- function(
  endpoints,
  path = client_path('inst', 'hook_config_generated.yml'),
  implemented_only = FALSE
) {
  # No public operation changes its configured host through generated metadata.
  yaml::write_yaml(list(), path)
  invisible(list())
}

chemi_spec <- list(
  prefix = "chemi",
  heading = "Cheminformatics (chemi_*)",
  config = chemi_config,
  build_endpoints = function() {
    chemi_schema_files <- sort(list.files(
      path = client_path("schema"),
      pattern = "^chemi-.*-prod\\.json$",
      full.names = FALSE
    ))
    chemi_schema_files <- chemi_schema_files[!grepl("ui", chemi_schema_files, ignore.case = TRUE)]

    if (length(chemi_schema_files) == 0) {
      cli_alert_warning("No chemi schema files found, skipping chemi_* generation")
      return(NULL)
    }

    cli_alert_info("Found {length(chemi_schema_files)} chemi schema file(s)")

    # openapi_to_spec handles both Swagger 2.0 (amos, rdkit, mordred) and OpenAPI 3.0,
    # the same way generate_ct_stubs and generate_cc_stubs do (v1.6 UNIFY-CHEMI).
    chemi_endpoints <- tryCatch(
      {
        ep <- map(
          chemi_schema_files,
          ~ {
            openapi <- jsonlite::fromJSON(client_path('schema', .x), simplifyVector = FALSE)
            spec <- openapi_to_spec(openapi)
            spec$source_file <- .x
            spec$service_slug <- sub(
              "^chemi-(.*)-prod\\.json$",
              "\\1",
              .x
            )
            spec
          },
          .progress = FALSE
        ) %>%
          list_rbind() %>%
          filter(
            str_detect(method, 'GET|POST'),
            !str_detect(route, ENDPOINT_PATTERNS_TO_EXCLUDE) # Exclude admin/UI routes
          ) %>%
          mutate(batch_limit = 0)

        ep %>% prepare_chemi_operations() %>% name_chemi_endpoints()
      },
      error = function(e) {
        cli_alert_warning("Error parsing chemi schemas: {e$message}")
        return(tibble())
      }
    )

    if (nrow(chemi_endpoints) == 0) {
      cli_alert_warning("No chemi endpoints parsed")
      return(NULL)
    }

    cli_alert_info("Parsed {nrow(chemi_endpoints)} endpoint(s) from schemas")
    chemi_endpoints
  },
  prepare = function(endpoints) {
    write_generated_hook_config(endpoints)
  },
  finalize = function(endpoints) {
    write_generated_hook_config(endpoints, implemented_only = TRUE)
  },
  # Aggregate by file (multiple functions per file) before scaffolding.
  post = function(spec_with_text) {
    spec_with_text %>%
      group_by(file) %>%
      summarise(
        text = paste0(
          paste(sub("[\r\n]+\\z", "", text, perl = TRUE), collapse = "\n\n"),
          "\n"
        ),
        .groups = "drop"
      )
  }
)

epi_spec <- list(
  prefix = "epi",
  heading = "EPI Suite (epi_*)",
  config = epi_config,
  build_endpoints = function() {
    epi_schema_files <- select_schema_files(
      pattern = "^epi-.*-prod\\.json$",
      exclude_pattern = NULL,
      stage_priority = "prod"
    )

    if (length(epi_schema_files) == 0) {
      cli_alert_warning("No epi schema files found, skipping epi_* generation")
      return(NULL)
    }

    cli_alert_info("Found {length(epi_schema_files)} epi schema file(s)")

    # Routes we deliberately drop: the self-referential /api spec doc, the CLI
    # JAR download, the SVG structure renderer, and the ecosar health check.
    # None return chemical data; everything else generates as an epi_* wrapper.
    # Matched against the api-relative route (leading slash removed).
    epi_exclude <- "^api$|^api/download|^api/draw-chemical|^api/ecosar/test"

    epi_endpoints <- tryCatch(
      {
        ep <- map(
          epi_schema_files,
          ~ {
            openapi <- jsonlite::fromJSON(client_path('schema', .x), simplifyVector = FALSE)
            spec <- openapi_to_spec(openapi)
            spec$source_file <- .x
            spec
          },
          .progress = FALSE
        ) %>%
          list_rbind() %>%
          mutate(route = strip_curly_params(route, leading_slash = 'remove')) %>%
          filter(
            str_detect(method, 'GET|POST'),
            !str_detect(route, epi_exclude)
          ) %>%
          mutate(
            # epi schema is prod-only, so every epi_* function is public-stage.
            schema_stage = "public",
            # Endpoint path is api-relative (epi_burl already ends in /api).
            # Strip the trailing slash left by a removed {type} path param so the
            # route stays clean and generic_request appends path params without a
            # double slash (e.g. ecosar/surfactant + type -> .../surfactant/anionic).
            route = route %>% str_remove("^api/") %>% str_remove("/+$"),
            name = route %>%
              str_replace_all("[/]+", "_") %>%
              str_replace_all("-", "_"),
            file_short = paste0("epi_", name, ".R"),
            file_full = file_short,
            batch_limit = case_when(
              method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
              method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
              .default = NULL
            )
          ) %>%
          distinct(route, method, .keep_all = TRUE)

        ep$fn_short <- derive_fn_from_file(ep, "file_short")
        ep$fn_full <- derive_fn_from_file(ep, "file_full")
        resolve_collisions(ep)
      },
      error = function(e) {
        cli_alert_warning("Error parsing epi schemas: {e$message}")
        return(tibble())
      }
    )

    if (nrow(epi_endpoints) == 0) {
      cli_alert_warning("No epi endpoints parsed")
      return(NULL)
    }

    cli_alert_info("Parsed {nrow(epi_endpoints)} endpoint(s) from schemas")
    epi_endpoints
  }
)

api_specs <- list(ct = ct_spec, chemi = chemi_spec, epi = epi_spec)

# ==============================================================================
# Operation-level Coverage
# ==============================================================================
# Coverage = (implemented operations) / (total operations), where an "operation"
# is one (route, method) row from a spec's build_endpoints(). Because that set is
# the exact input the stub generator builds against, coverage is a subset over
# its superset and therefore always <= 100% (no artificial cap needed). GET and
# POST on the same route are distinct operations with distinct fn names
# (base vs *_bulk), so they are counted per row by the operation's own fn.

#' Is a single (route, method) operation implemented?
#'
#' True when the expected wrapper file exists and defines the expected function.
#' Mirrors the file-existence + function-definition check that
#' find_endpoint_usages_base() uses as its fallback, applied per operation so
#' GET/POST wrappers sharing one file are distinguished by their fn name.
#'
#' @param file Expected wrapper filename (basename, e.g. "ct_chemical_detail_search.R")
#' @param fn Expected function name (e.g. "ct_chemical_detail_search" or "..._bulk")
#' @param pkg_dir Directory containing the R source files
#' @return Logical scalar

#' Operation-level coverage for one API spec.
#'
#' @param spec One of ct_spec / chemi_spec.
#' @param pkg_dir Directory containing the R source files (default R/).
#' @return list(total = <int>, covered = <int>)
