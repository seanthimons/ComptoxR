# Find non-generated wrappers: bespoke API functions + convenience wrappers.
#
# Generated stubs = lifecycle::badge("experimental") + a single top-level
# function whose body is one generic_request()/generic_chemi_request() call.
# Everything else that touches the API or composes other wrappers is a
# candidate the stub generator does NOT own (e.g. the old chemi_cluster).
#
# Usage: Rscript dev/endpoint_eval/find_bespoke_wrappers.R  [pkg_dir]

classify_r_file <- function(path) {
  src <- paste(readLines(path, warn = FALSE), collapse = "\n")

  badge <- regmatches(src, regexpr('badge\\("[a-z]+', src))
  badge <- if (length(badge)) sub('badge\\("', "", badge) else "none"

  n_defs <- lengths(regmatches(src, gregexpr("<-\\s*function\\b", src)))
  direct_api <- grepl("generic_[a-z_]*request\\(", src)
  # raw httr2: httr2::, req_perform(), or a standalone request( NOT part of
  # generic_request( / generic_chemi_request(
  raw_httr2 <- grepl("httr2::|req_perform\\(|(?<![A-Za-z_])request\\(", src, perl = TRUE)

  # convenience wrapper: calls a ct_/chemi_/cc_ sibling other than itself
  self <- tools::file_path_sans_ext(basename(path))
  callees <- unique(unlist(regmatches(
    src,
    gregexpr("\\b(?:ct|chemi|cc)_[A-Za-z0-9_]+\\b", src)
  )))
  wraps_sibling <- length(setdiff(callees, self)) > 0

  generated_stub <- badge == "experimental" && n_defs == 1 && direct_api && !wraps_sibling && !raw_httr2

  kind <- if (generated_stub) {
    "generated_stub"
  } else if (raw_httr2) {
    "bespoke_httr2"
  } else if (direct_api && badge != "experimental") {
    "bespoke_api"
  } else if (wraps_sibling && !direct_api) {
    "convenience_wrapper"
  } else if (direct_api) {
    "customized_stub" # experimental badge but not a clean single-call stub
  } else {
    "other" # no API, no wrapping (helpers, utils, data docs)
  }

  data.frame(
    file = basename(path),
    kind = kind,
    badge = badge,
    n_defs = n_defs,
    direct_api = direct_api,
    raw_httr2 = raw_httr2,
    wraps_sibling = wraps_sibling,
    stringsAsFactors = FALSE
  )
}

main <- function(pkg_dir = "R") {
  files <- list.files(pkg_dir, pattern = "\\.R$", full.names = TRUE)
  files <- files[!grepl("^(zzz|z_|data)", basename(files))]
  res <- do.call(rbind, lapply(files, classify_r_file))

  # A function listed in hook_config.yml is generator-owned even when its stub
  # body is customized (request_template / request_override / hooks).
  hook_cfg <- file.path(dirname(pkg_dir), "inst", "hook_config.yml")
  hooked <- if (file.exists(hook_cfg)) {
    names(yaml::read_yaml(hook_cfg))
  } else {
    character()
  }
  res$fn <- tools::file_path_sans_ext(res$file)
  res$hook_owned <- res$fn %in% hooked

  # Candidates = not generator-owned AND (hits API or wraps a sibling).
  # Restrict to CompTox stub-gen targets (ct_/chemi_); this drops hooks_*,
  # util_*, and non-CompTox clients (eco_/tox_/epi_/pubchem_/genra_/schema/
  # package_).
  is_target <- grepl("^(ct|chemi)_", res$fn)
  cand <- res[!res$hook_owned & is_target & res$kind %in% c("bespoke_api", "bespoke_httr2", "convenience_wrapper"), ]
  cand <- cand[order(cand$kind, cand$file), ]

  out <- file.path(pkg_dir, "..", "dev", "endpoint_eval", "bespoke_wrappers.csv")
  utils::write.csv(res, out, row.names = FALSE)

  cat("\n== counts by kind ==\n")
  print(table(res$kind))
  cat("\n== hook_config-owned (generated, excluded from candidates):", sum(res$hook_owned), "==\n")
  cat("\n== candidates:", nrow(cand), "non-generated fns that hit the API or wrap siblings ==\n")
  print(cand[, c("fn", "kind", "badge")], row.names = FALSE)

  # Stable-badge audit: a clean stable wrapper is a single-function file whose
  # only API access is one generic_request()/generic_chemi_request() call. Flag
  # the ones "hiding" extra behaviour behind a stable badge.
  stable <- res[res$badge == "stable", ]
  stable$reason <- ifelse(
    stable$raw_httr2,
    "raw httr2",
    ifelse(
      stable$wraps_sibling & !stable$direct_api,
      "wraps sibling, no generic_request",
      ""
    )
  )
  notable <- stable[nzchar(stable$reason), ]
  notable <- notable[order(notable$reason, notable$fn), ]
  cat("\n== stable-badge functions:", nrow(stable), "(", sum(nzchar(stable$reason)), "notable ) ==\n")
  print(table(stable$kind))
  cat("\n== notable stable functions (extra behaviour behind a stable badge) ==\n")
  print(notable[, c("fn", "kind", "n_defs", "reason")], row.names = FALSE)

  cat("\nFull classification written to", normalizePath(out), "\n")
  invisible(res)
}

args <- commandArgs(trailingOnly = TRUE)
main(if (length(args)) args[1] else "R")
