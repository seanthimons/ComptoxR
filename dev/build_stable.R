#!/usr/bin/env Rscript
# ==============================================================================
# Build a "stable-only" package variant
# ==============================================================================
# Rewrites NAMESPACE in place, dropping export() lines for functions whose
# roxygen block carries a non-public lifecycle marker, and removes the now
# orphaned man/*.Rd. Then run `R CMD build .` to produce the stripped tarball.
#
# Intended for a disposable CI clone or a git worktree — it edits tracked files.
# Pure base R (no devtools/roxygen dependency).
#
# Usage:
#   Rscript dev/build_stable.R            # apply
#   Rscript dev/build_stable.R --dry-run  # preview only, change nothing
#
# ------------------------------------------------------------------------------
# WHAT COUNTS AS "PUBLIC"
# ------------------------------------------------------------------------------
# Public == lifecycle badge "stable" OR the custom `@apiStage public` tag written
# by the stub generator (dev/endpoint_eval/07_stub_generation.R). Functions whose
# only stage marker is a non-public `@apiStage` (staging/development) are dropped
# from the public build; `@apiStage public` and unmarked functions are kept.
# To extend: add a BADGE stage to KEEP_STAGES, or a custom TAG regex to
# STAGE_REGEX (capture group 1 = stage). A function with NO stage marker is kept.
# ==============================================================================

# --- config -------------------------------------------------------------------
KEEP_STAGES <- c("stable", "public") # stages kept exported in the public build
STAGE_REGEX <- c(
  'lifecycle::badge\\("([a-z]+)"\\)', # standard inline lifecycle badge
  "@apiStage\\s+([a-z]+)" # custom @apiStage provenance tag (public/staging/development)
  # , "@lifecycle\\s+([a-z]+)"        # <- custom @lifecycle tag; enable when it exists
)

dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

def_regex <- "^\\s*[a-zA-Z.][a-zA-Z0-9._]*\\s*<-\\s*function"

# --- collect exported functions and their lifecycle stages --------------------
fn_records <- function(path) {
  lines <- readLines(path, warn = FALSE)
  block <- character()
  out <- list()
  for (ln in lines) {
    if (grepl("^\\s*#'", ln)) {
      block <- c(block, ln)
      next
    }
    if (grepl(def_regex, ln)) {
      name <- sub("^\\s*([a-zA-Z.][a-zA-Z0-9._]*)\\s*<-.*", "\\1", ln)
      stages <- unlist(lapply(STAGE_REGEX, function(rx) {
        m <- regmatches(block, regexec(rx, block))
        vapply(m, function(x) if (length(x) >= 2) x[[2]] else NA_character_, "")
      }))
      out[[length(out) + 1L]] <- list(
        name = name,
        exported = any(grepl("@export\\b", block)),
        stages = stages[!is.na(stages)]
      )
    }
    block <- character() # any non-roxygen line clears the pending block
  }
  out
}

records <- unlist(lapply(list.files("R", "\\.R$", full.names = TRUE), fn_records), recursive = FALSE)

# strip an exported fn only when it is explicitly badged non-public
stripped <- vapply(
  records,
  function(r) {
    r$exported && length(r$stages) > 0 && !any(r$stages %in% KEEP_STAGES)
  },
  logical(1)
)
strip_names <- unique(vapply(records[stripped], `[[`, "", "name"))

cat(sprintf(
  "Exported functions: %d | keep: %d | strip: %d\n",
  sum(vapply(records, `[[`, logical(1), "exported")),
  sum(vapply(records, `[[`, logical(1), "exported")) - length(strip_names),
  length(strip_names)
))
if (!length(strip_names)) {
  cat("Nothing to strip.\n")
  quit(status = 0)
}

# --- rewrite NAMESPACE --------------------------------------------------------
ns <- readLines("NAMESPACE", warn = FALSE)
drop_lines <- sprintf("export(%s)", strip_names)
kept_ns <- ns[!ns %in% drop_lines]

# --- find orphaned man pages (every \alias in the Rd is being stripped) --------
aliases_of <- function(rd) {
  txt <- readLines(rd, warn = FALSE)
  al <- unlist(regmatches(txt, gregexpr("\\\\alias\\{([^}]+)\\}", txt)))
  sub("\\\\alias\\{([^}]+)\\}", "\\1", al)
}
orphan_rd <- Filter(
  function(rd) {
    al <- aliases_of(rd)
    length(al) > 0 && all(al %in% strip_names)
  },
  list.files("man", "\\.Rd$", full.names = TRUE)
)

# --- report / apply -----------------------------------------------------------
cat(sprintf(
  "NAMESPACE export() lines removed: %d\nman/*.Rd removed: %d\n",
  length(ns) - length(kept_ns),
  length(orphan_rd)
))
cat(
  "Stripped:",
  paste(head(sort(strip_names), 20), collapse = ", "),
  if (length(strip_names) > 20) sprintf("... (+%d more)", length(strip_names) - 20) else "",
  "\n"
)

if (dry_run) {
  cat("\nDRY RUN: no files changed.\n")
  quit(status = 0)
}

writeLines(kept_ns, "NAMESPACE")
if (length(orphan_rd)) {
  file.remove(orphan_rd)
}
cat("\nDone. NAMESPACE and man/ updated in place — run `R CMD build .`\n")
