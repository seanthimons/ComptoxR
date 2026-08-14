#!/usr/bin/env Rscript

# ==============================================================================
# Remove Experimental Endpoint Wrappers
# ==============================================================================
#
# This maintainer tool removes generated endpoint wrapper files so that they can
# be rebuilt from their schemas. It scans one literal filename prefix at a time.
# The default prefix is "chemi". Use --prefix to work on another endpoint family,
# service, or individual endpoint. Prefix matching uses filename boundaries, so
# "ct" matches ct_*.R but does not match cts_*.R.
#
# Examples:
#   Rscript dev/remove_experimental.R --dry-run
#   Rscript dev/remove_experimental.R --dry-run --prefix=ct
#   Rscript dev/remove_experimental.R --apply --prefix=chemi_amos
#   Rscript dev/remove_experimental.R --apply --prefix=chemi_amos_method_list
#
# Safety:
#   - Dry-run is the default. Files are deleted only with --apply.
#   - Each exported function is checked in its own roxygen block.
#   - A file is selected only when all exports are experimental and have a
#     recognized @apiStage tag.
#   - Stable, maturing, mixed, untagged, and invalid files are not removed.
#   - Selected, protected, and invalid files are printed before removal.
#
# Source this file to use parse_exported_roxygen(), classify_experimental_file(),
# or scan_experimental_files() without running the command-line entry point.
#
# ==============================================================================

# Configuration defaults -------------------------------------------------------

default_endpoint_prefix <- "chemi"
default_target_dir <- "R"

recognized_api_stages <- c("public", "staging", "development")
protected_lifecycles <- c("stable", "maturing", "superseded", "deprecated", "defunct")

normalize_endpoint_prefix <- function(prefix) {
  if (length(prefix) != 1L || is.na(prefix)) {
    stop("--prefix must be one non-empty value", call. = FALSE)
  }
  prefix <- sub("_+$", "", prefix)
  if (!nzchar(prefix)) {
    stop("--prefix must be non-empty", call. = FALSE)
  }
  if (!grepl("^[A-Za-z][A-Za-z0-9._]*$", prefix)) {
    stop("--prefix can contain only letters, numbers, periods, and underscores", call. = FALSE)
  }
  prefix
}

parse_exported_roxygen <- function(path) {
  lines <- readLines(path, warn = FALSE)
  definitions <- grep(
    "^\\s*`?([A-Za-z.][A-Za-z0-9._]*)`?\\s*<-\\s*function\\s*\\(",
    lines,
    perl = TRUE
  )

  records <- lapply(definitions, function(line_number) {
    block_end <- line_number - 1L
    while (block_end > 0L && !nzchar(trimws(lines[[block_end]]))) {
      block_end <- block_end - 1L
    }
    block_start <- block_end
    while (block_start > 0L && grepl("^\\s*#'", lines[[block_start]])) {
      block_start <- block_start - 1L
    }
    block <- if (block_end > block_start) {
      lines[seq.int(block_start + 1L, block_end)]
    } else {
      character()
    }
    if (!any(grepl("^\\s*#'\\s*@export(?:\\s|$)", block, perl = TRUE))) {
      return(NULL)
    }

    name <- sub(
      "^\\s*`?([A-Za-z.][A-Za-z0-9._]*)`?\\s*<-.*$",
      "\\1",
      lines[[line_number]],
      perl = TRUE
    )
    lifecycle_matches <- regmatches(
      block,
      gregexpr("lifecycle::badge\\([\\\"']([^\\\"']+)[\\\"']\\)", block, perl = TRUE)
    )
    lifecycles <- unique(sub(
      ".*lifecycle::badge\\([\\\"']([^\\\"']+)[\\\"']\\).*$",
      "\\1",
      unlist(lifecycle_matches, use.names = FALSE),
      perl = TRUE
    ))
    lifecycles <- lifecycles[nzchar(lifecycles)]
    stage_lines <- grep("^\\s*#'\\s*@apiStage\\s+", block, value = TRUE, perl = TRUE)
    stages <- unique(sub("^.*@apiStage\\s+(\\S+).*$", "\\1", stage_lines, perl = TRUE))

    list(name = name, lifecycles = lifecycles, stages = stages)
  })

  Filter(Negate(is.null), records)
}

classify_experimental_file <- function(path) {
  exports <- parse_exported_roxygen(path)
  if (length(exports) == 0L) {
    return(list(status = "invalid", reason = "no exported roxygen function"))
  }

  invalid <- vapply(
    exports,
    function(record) {
      length(record$lifecycles) != 1L ||
        length(record$stages) != 1L ||
        !record$stages %in% recognized_api_stages
    },
    logical(1)
  )
  if (any(invalid)) {
    names <- vapply(exports[invalid], `[[`, character(1), "name")
    return(list(
      status = "invalid",
      reason = paste0("missing, mixed, or unrecognized tags: ", paste(names, collapse = ", "))
    ))
  }

  lifecycles <- vapply(exports, function(record) record$lifecycles[[1]], character(1))
  if (all(lifecycles == "experimental")) {
    return(list(status = "selected", reason = "all exports are experimental"))
  }

  reason <- if (all(lifecycles %in% protected_lifecycles)) {
    paste0("protected lifecycle: ", paste(unique(lifecycles), collapse = ", "))
  } else {
    paste0("mixed or protected lifecycles: ", paste(unique(lifecycles), collapse = ", "))
  }
  list(status = "protected", reason = reason)
}

scan_experimental_files <- function(
  r_dir = default_target_dir,
  prefix = default_endpoint_prefix
) {
  prefix <- normalize_endpoint_prefix(prefix)
  files <- sort(list.files(r_dir, pattern = "\\.R$", full.names = TRUE))
  stems <- tools::file_path_sans_ext(basename(files))
  files <- files[stems == prefix | startsWith(stems, paste0(prefix, "_"))]
  if (length(files) == 0L) {
    return(data.frame(file = character(), status = character(), reason = character()))
  }

  classifications <- lapply(files, classify_experimental_file)
  data.frame(
    file = files,
    status = vapply(classifications, `[[`, character(1), "status"),
    reason = vapply(classifications, `[[`, character(1), "reason"),
    stringsAsFactors = FALSE
  )
}

print_removal_report <- function(report) {
  for (status in c("selected", "protected", "invalid")) {
    rows <- report[report$status == status, , drop = FALSE]
    cat("\n", tools::toTitleCase(status), " (", nrow(rows), "):\n", sep = "")
    if (nrow(rows) == 0L) {
      cat("  none\n")
    } else {
      for (i in seq_len(nrow(rows))) {
        cat("  ", rows$file[[i]], " - ", rows$reason[[i]], "\n", sep = "")
      }
    }
  }
}

parse_remove_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  prefix_args <- grep("^--prefix=", args, value = TRUE)
  known <- args %in% c("--dry-run", "--apply", "--help", "-h") | grepl("^--prefix=", args)
  unknown <- args[!known]
  if (length(unknown) > 0L) {
    stop("Unknown argument: ", unknown[[1]], call. = FALSE)
  }
  if (length(prefix_args) > 1L) {
    stop("Use --prefix only once", call. = FALSE)
  }
  if (all(c("--dry-run", "--apply") %in% args)) {
    stop("Choose only one mode: --dry-run or --apply", call. = FALSE)
  }

  prefix <- if (length(prefix_args) == 1L) {
    sub("^--prefix=", "", prefix_args[[1]])
  } else {
    default_endpoint_prefix
  }
  prefix <- normalize_endpoint_prefix(prefix)

  list(
    apply = "--apply" %in% args,
    help = any(args %in% c("--help", "-h")),
    prefix = prefix
  )
}

remove_experimental_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- parse_remove_args(args)
  if (parsed$help) {
    cat(
      "Remove generated experimental endpoint wrappers.\n\n",
      "Usage:\n",
      "  Rscript dev/remove_experimental.R [--dry-run] [--prefix=PREFIX]\n",
      "  Rscript dev/remove_experimental.R --apply [--prefix=PREFIX]\n\n",
      "Options:\n",
      "  --dry-run       Print the report without deleting files (default).\n",
      "  --apply         Delete selected files.\n",
      "  --prefix=VALUE  Match an endpoint filename prefix (default: chemi).\n",
      "  --help, -h      Show this help.\n\n",
      "Examples:\n",
      "  --prefix=ct                  matches ct_*.R, not cts_*.R\n",
      "  --prefix=chemi_amos          matches the AMOS service\n",
      "  --prefix=chemi_amos_method   matches that endpoint and variants\n",
      sep = ""
    )
    return(invisible(NULL))
  }

  cat("Scanning endpoint prefix: ", parsed$prefix, "\n", sep = "")
  report <- scan_experimental_files(default_target_dir, parsed$prefix)
  print_removal_report(report)
  selected <- report$file[report$status == "selected"]

  if (!parsed$apply) {
    cat("\nDry run: no files were removed. Use --apply to remove selected files.\n")
    return(invisible(report))
  }

  removed <- file.remove(selected)
  if (!all(removed)) {
    stop("Failed to remove: ", paste(selected[!removed], collapse = ", "), call. = FALSE)
  }
  cat("\nRemoved ", length(selected), " generated endpoint file(s).\n", sep = "")
  invisible(report)
}

remove_experimental_is_entrypoint <- function() {
  file_args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  length(file_args) > 0L &&
    identical(
      basename(sub("^--file=", "", file_args[[length(file_args)]])),
      "remove_experimental.R"
    )
}

if (remove_experimental_is_entrypoint()) {
  remove_experimental_main()
}
