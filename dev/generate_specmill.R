# Pilot maintenance. Run from the package root; no runtime dependency on specmill.
generate_specmill <- function(mode = c("check", "plan", "apply"), adopt = NULL) {
  mode <- match.arg(mode)
  source("dev/install_specmill.R", local = TRUE)
  verify_specmill()
  callbacks <- new.env(parent = baseenv())
  sys.source("dev/specmill_callbacks.R", envir = callbacks)
  args <- list(
    root = ".",
    config = "specmill.yml",
    callbacks = callbacks,
    mode = "plan",
    artifacts = c("wrappers", "tests")
  )
  if (!is.null(adopt)) {
    args$adopt <- adopt
  }
  plan <- do.call(specmill::generate_client, args)
  print(plan)
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
  if (mode == "check" && any(actions %in% c("write", "remove"))) {
    stop("Pilot generated output is not current.")
  }
  if (mode == "apply") {
    args$mode <- "apply"
    return(invisible(do.call(specmill::generate_client, args)))
  }
  invisible(plan)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  if (length(args) != 1L || !args %in% c("--plan", "--check", "--apply")) {
    stop("Usage: Rscript dev/generate_specmill.R --plan|--check|--apply")
  }
  generate_specmill(sub("^--", "", args))
}
