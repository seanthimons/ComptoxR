# Pilot maintenance. Run from the package root; no runtime dependency on specmill.
generate_specmill <- function(mode = c("check", "plan", "apply"), adopt = NULL, deferrals = NULL, prune = NULL) {
  mode <- match.arg(mode)
  source("dev/install_specmill.R", local = TRUE)
  verify_specmill()
  callbacks <- new.env(parent = baseenv())
  for (file in yaml::read_yaml("specmill.yml")$callback_files) {
    sys.source(file, envir = callbacks)
  }
  args <- list(
    root = ".",
    config = "specmill.yml",
    callbacks = callbacks,
    mode = "plan",
    artifacts = c("wrappers", "tests"),
    validation = TRUE
  )
  if (!is.null(adopt)) {
    args$adopt <- adopt
  }
  if (!is.null(deferrals)) {
    args$deferrals <- deferrals
  }
  if (!is.null(prune)) {
    # Opt-in removal of a retired operation's owned output; --plan previews, --apply removes.
    args$prune <- prune
  }
  plan <- do.call(specmill::generate_client, args)
  print(plan)
  # An explicitly included or mapped operation that a policy rule drops is a configuration error;
  # other excluded operations (opt-out services) stay quietly excluded.
  # Each API file's group key is the service id.
  configured <- unlist(lapply(yaml::read_yaml("specmill.yml")$services, function(file) {
    groups <- yaml::read_yaml(file)$groups
    lapply(names(groups), function(id) {
      paste(id, union(unlist(groups[[id]]$selection$include), names(groups[[id]]$operations)))
    })
  }))
  stopifnot(!any(vapply(plan$excluded, function(x) x$id, "") %in% configured))
  # 'invalid' is allowed only because located errors become per-operation diagnostics that
  # deferral can absorb; document-level and unsupported findings still fail below.
  stopifnot(length(plan$validation) > 0L,
    all(vapply(plan$validation, function(report) report$status %in% c("passed", "invalid"), FALSE)))
  if (
    length(plan$diagnostics) ||
      length(plan$mapping_diagnostics) ||
      length(plan$retained_diagnostics) ||
      length(plan$drift)
  ) {
    stop("Pilot contract drift or unsupported operation: review the plan before applying.")
  }
  actions <- vapply(plan$files, `[[`, character(1), "action")
  if (mode != "plan" && any(actions == "protected")) {
    stop("Protected pilot output: review changes and supply exact adoption hashes once.")
  }
  if (mode == "check") {
    # Specmill's own check: stale output, schema-change warnings, uncertain deferrals.
    args$mode <- "check"
    return(invisible(do.call(specmill::generate_client, args)))
  }
  if (mode == "apply") {
    args$mode <- "apply"
    return(invisible(do.call(specmill::generate_client, args)))
  }
  invisible(plan)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  flags <- args[grepl("^--(enroll|clear|prune)=", args)]
  args <- setdiff(args, flags)
  if (length(args) != 1L || !args %in% c("--plan", "--check", "--apply")) {
    stop("Usage: Rscript dev/generate_specmill.R --plan|--check|--apply [--enroll=<service METHOD path>=<reason>]... [--clear=<service METHOD path>]... [--prune=<service METHOD path>]...")
  }
  enroll <- sub("^--enroll=", "", flags[startsWith(flags, "--enroll=")])
  split <- regexpr("=", enroll, fixed = TRUE)
  stopifnot(all(split > 1L))
  deferrals <- list(
    enroll = if (length(enroll)) stats::setNames(substring(enroll, split + 1L), substr(enroll, 1L, split - 1L)),
    clear = sub("^--clear=", "", flags[startsWith(flags, "--clear=")])
  )
  prune <- sub("^--prune=", "", flags[startsWith(flags, "--prune=")])
  generate_specmill(sub("^--", "", args), deferrals = if (any(lengths(deferrals))) deferrals,
    prune = if (length(prune)) prune)
}
