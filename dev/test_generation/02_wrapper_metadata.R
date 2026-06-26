# Metadata extraction from exported wrapper functions.

tg_find_calls <- function(expr, names) {
  hits <- list()

  visit <- function(node) {
    if (is.call(node)) {
      call_name <- tg_call_name(node)
      if (identical(call_name, "function")) {
        visit(node[[3]])
        return(invisible(NULL))
      }
      if (!is.na(call_name) && call_name %in% names) {
        hits[[length(hits) + 1]] <<- node
      }
      for (i in seq_along(node)[-1]) {
        visit(node[[i]])
      }
    } else if (is.pairlist(node) || is.list(node)) {
      for (item in as.list(node)) {
        visit(item)
      }
    }
  }

  visit(expr)
  hits
}

tg_deparse_expr <- function(expr) {
  paste(deparse(expr, width.cutoff = 500), collapse = " ")
}

tg_literal_value <- function(expr) {
  if (is.character(expr) || is.numeric(expr) || is.integer(expr) || is.logical(expr) || is.null(expr)) {
    return(list(is_literal = TRUE, value = expr))
  }

  list(is_literal = FALSE, value = NULL)
}

tg_symbol_value <- function(expr) {
  if (is.symbol(expr)) {
    return(as.character(expr))
  }
  NULL
}

tg_call_args <- function(call) {
  args <- as.list(call)[-1]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }

  records <- vector("list", length(args))
  for (i in seq_along(args)) {
    lit <- tg_literal_value(args[[i]])
    records[[i]] <- list(
      name = arg_names[[i]],
      expr = args[[i]],
      expr_text = tg_deparse_expr(args[[i]]),
      literal = lit$is_literal,
      literal_value = lit$value,
      symbol = tg_symbol_value(args[[i]])
    )
  }

  records
}

tg_named_call_args <- function(call) {
  args <- tg_call_args(call)
  named <- args[nzchar(vapply(args, `[[`, character(1), "name"))]
  stats::setNames(named, vapply(named, `[[`, character(1), "name"))
}

tg_formal_records <- function(fn_expr) {
  if (!is.call(fn_expr) || !identical(fn_expr[[1]], as.name("function"))) {
    return(list())
  }

  fn <- eval(fn_expr)
  formals_list <- as.list(formals(fn))
  if (length(formals_list) == 0) {
    return(list())
  }

  formal_names <- names(formals_list)
  records <- vector("list", length(formals_list))
  for (i in seq_along(formals_list)) {
    missing_default <- alist(x = )
    names(missing_default) <- formal_names[[i]]
    is_dots <- identical(formal_names[[i]], "...")
    required <- identical(formals_list[i], missing_default) && !is_dots
    default <- if (required || is_dots) NULL else formals_list[[i]]
    records[[i]] <- list(
      name = formal_names[[i]],
      required = required,
      default = if (required) NULL else default,
      default_text = if (required) NULL else tg_deparse_expr(default)
    )
  }
  names(records) <- formal_names
  records
}

tg_metadata_for_wrapper <- function(record, helper_names = tg_config$helper_names) {
  helper_calls <- tg_find_calls(record$expr, helper_names)
  if (length(helper_calls) == 0) {
    return(NULL)
  }

  primary_call <- helper_calls[[1]]
  helper_name <- tg_call_name(primary_call)
  resolver_helpers <- intersect(tg_config$resolver_helper_names, record$call_names)

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
    resolver_helpers = resolver_helpers
  )
}

tg_collect_wrapper_metadata <- function(root = ".") {
  wrappers <- tg_inventory_wrappers(root)
  metadata <- lapply(wrappers, tg_metadata_for_wrapper)
  metadata <- metadata[!vapply(metadata, is.null, logical(1))]
  metadata[sort(names(metadata))]
}
