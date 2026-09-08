wrapmaint::bind_tools("ast", environment())
# Metadata extraction from exported wrapper functions.

tg_read_hook_config <- function(root = ".") {
  hook_config_path <- tg_file_path(root, "inst/hook_config.yml")
  if (!file.exists(hook_config_path)) {
    return(list())
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    return(list())
  }

  yaml::read_yaml(hook_config_path)
}

tg_metadata_for_wrapper <- function(record, helper_names = tg_config$helper_names, hook_config = list()) {
  helper_calls <- tg_find_calls(record$expr, helper_names)
  if (length(helper_calls) == 0) {
    return(NULL)
  }

  primary_call <- helper_calls[[1]]
  helper_name <- tg_call_name(primary_call)
  fn_hook_config <- hook_config[[record$function_name]]
  pre_request_hooks <- fn_hook_config$pre_request %tg||% character(0)
  uses_resolve_query_hook <- "resolve_query_to_chemical_records" %in% pre_request_hooks
  uses_resolve_smiles_hook <- "resolve_smiles_identifier" %in% pre_request_hooks
  hook_resolver_helpers <- if (uses_resolve_query_hook || uses_resolve_smiles_hook) {
    "chemi_resolver_lookup_bulk"
  } else {
    character(0)
  }
  resolver_helpers <- unique(c(intersect(tg_config$resolver_helper_names, record$call_names), hook_resolver_helpers))

  list(
    function_name = record$function_name,
    file = record$file,
    file_path = record$file_path,
    helper_name = helper_name,
    helper_calls = helper_calls,
    helper_call = primary_call,
    helper_args = tg_named_call_args(primary_call),
    formals = tg_formal_records(record$expr),
    call_names = record$call_names,
    resolver_helpers = resolver_helpers,
    uses_resolve_query_hook = uses_resolve_query_hook,
    uses_resolve_smiles_hook = uses_resolve_smiles_hook
  )
}

tg_collect_wrapper_metadata <- function(root = ".") {
  wrappers <- tg_inventory_wrappers(root)
  hook_config <- tg_read_hook_config(root)
  metadata <- lapply(wrappers, tg_metadata_for_wrapper, hook_config = hook_config)
  metadata <- metadata[!vapply(metadata, is.null, logical(1))]
  metadata[sort(names(metadata))]
}

tg_bespoke_contracts <- function(root = ".") {
  config <- tg_read_hook_config(root)
  suites <- lapply(config, `[[`, "bespoke_test")
  suites <- suites[!vapply(suites, is.null, logical(1))]
  vapply(suites, as.character, character(1))
}

tg_validate_bespoke_contracts <- function(metadata, root = ".") {
  suites <- tg_bespoke_contracts(root)
  errors <- character()

  for (wrapper in names(suites)) {
    suite <- suites[[wrapper]]
    path <- tg_file_path(root, suite)
    if (!wrapper %in% names(metadata)) {
      errors <- c(errors, paste0(wrapper, ": configured bespoke wrapper was not found"))
      next
    }
    if (!file.exists(path)) {
      errors <- c(errors, paste0(wrapper, ": bespoke suite is missing: ", suite))
      next
    }
    text <- tg_read_text(path)
    if (!grepl("\\btest_that\\s*\\(", text, perl = TRUE)) {
      errors <- c(errors, paste0(wrapper, ": bespoke suite has no real test_that() contract: ", suite))
    }
    wrapper_pattern <- paste0("(?<![A-Za-z0-9_.])", wrapper, "(?![A-Za-z0-9_.])")
    if (!grepl(wrapper_pattern, text, perl = TRUE)) {
      errors <- c(errors, paste0(wrapper, ": bespoke suite does not reference the wrapper: ", suite))
    }
  }

  list(valid = length(errors) == 0, errors = errors, suites = suites)
}
