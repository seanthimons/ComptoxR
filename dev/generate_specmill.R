# Pilot maintenance. Run from the package root; no runtime dependency on specmill.
generate_specmill <- function(mode = c("check", "plan", "apply"), adopt = NULL, deferrals = NULL) {
  mode <- match.arg(mode)
  # Path policy lives in specmill.yml selection.exclude. Only method-specific bans remain here
  # (seanthimons/specmill#189), checked against explicit includes and operation mappings.
  banned <- unlist(jsonlite::read_json("dev/endpoint-policy.json")$banned_operations, use.names = FALSE)
  for (file in yaml::read_yaml("specmill.yml")$services) {
    service <- yaml::read_yaml(file)
    selected <- union(service$selection$include, names(service$operations))
    stopifnot(!any(selected %in% banned))
  }
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
  plan <- do.call(specmill::generate_client, args)
  print(plan)
  # An explicitly included or mapped operation that a policy rule drops is a configuration error;
  # other excluded operations (opt-out services) stay quietly excluded.
  configured <- unlist(lapply(yaml::read_yaml("specmill.yml")$services, function(file) {
    service <- yaml::read_yaml(file)
    paste(service$id, union(service$selection$include, names(service$operations)))
  }))
  stopifnot(!any(vapply(plan$excluded, function(x) x$id, "") %in% configured))
  # 'invalid' is allowed only because located errors become per-operation diagnostics that
  # deferral can absorb; document-level and unsupported findings still fail below.
  stopifnot(length(plan$validation) > 0L,
    all(vapply(plan$validation, function(report) report$status %in% c("passed", "invalid"), FALSE)))
  # Reviewed retained ToxPrint facade, not an assertion about server schema validity.
  # Any change to source, schema, mapping or diagnostics requires a new review.
  retained <- plan$retained_diagnostics
  if (length(retained)) {
    review <- jsonlite::read_json("dev/specmill-rebuild/wave-toxprint.json")
    hashes <- review$reviewed_contract_sha256
    actual <- lapply(names(hashes), function(path) digest::digest(file = path, algo = "sha256"))
    names(actual) <- names(hashes)
    normalized <- lapply(retained, function(d) {
      d$source <- sub(paste0(normalizePath("."), "/"), "", d$source, fixed = TRUE)
      d
    })
    stopifnot(identical(actual, hashes), identical(normalized, review$reviewed_retained_diagnostics))
    retained <- list()
  }
  if (
    length(plan$diagnostics) ||
      length(plan$mapping_diagnostics) ||
      length(retained) ||
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
  flags <- args[grepl("^--(enroll|clear)=", args)]
  args <- setdiff(args, flags)
  if (length(args) != 1L || !args %in% c("--plan", "--check", "--apply")) {
    stop("Usage: Rscript dev/generate_specmill.R --plan|--check|--apply [--enroll=<service METHOD path>=<reason>]... [--clear=<service METHOD path>]...")
  }
  enroll <- sub("^--enroll=", "", flags[startsWith(flags, "--enroll=")])
  split <- regexpr("=", enroll, fixed = TRUE)
  stopifnot(all(split > 1L))
  deferrals <- list(
    enroll = if (length(enroll)) stats::setNames(substring(enroll, split + 1L), substr(enroll, 1L, split - 1L)),
    clear = sub("^--clear=", "", flags[startsWith(flags, "--clear=")])
  )
  generate_specmill(sub("^--", "", args), deferrals = if (any(lengths(deferrals))) deferrals)
}
