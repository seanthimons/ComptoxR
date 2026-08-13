#!/usr/bin/env Rscript

recognized_api_stages <- c("public", "staging", "development")
protected_lifecycles <- c("stable", "maturing", "superseded", "deprecated", "defunct")

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

classify_chemi_file <- function(path) {
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

scan_experimental_chemi_files <- function(r_dir = "R") {
  files <- sort(list.files(r_dir, pattern = "^chemi_.*\\.R$", full.names = TRUE))
  if (length(files) == 0L) {
    return(data.frame(file = character(), status = character(), reason = character()))
  }

  classifications <- lapply(files, classify_chemi_file)
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
  unknown <- setdiff(args, c("--dry-run", "--apply", "--help", "-h"))
  if (length(unknown) > 0L) {
    stop("Unknown argument: ", unknown[[1]], call. = FALSE)
  }
  if (all(c("--dry-run", "--apply") %in% args)) {
    stop("Choose only one mode: --dry-run or --apply", call. = FALSE)
  }
  list(apply = "--apply" %in% args, help = any(args %in% c("--help", "-h")))
}

remove_experimental_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- parse_remove_args(args)
  if (parsed$help) {
    cat("Usage:\n  Rscript dev/remove_experimental.R --dry-run\n  Rscript dev/remove_experimental.R --apply\n")
    return(invisible(NULL))
  }

  report <- scan_experimental_chemi_files("R")
  print_removal_report(report)
  selected <- report$file[report$status == "selected"]

  if (!parsed$apply) {
    cat("\nDry run: no files were removed. Use --apply to remove selected files.\n")
    return(invisible(report))
  }

  removed <- file.remove(selected)
  if (any(!removed)) {
    stop("Failed to remove: ", paste(selected[!removed], collapse = ", "), call. = FALSE)
  }
  cat("\nRemoved ", length(selected), " generated Cheminformatics file(s).\n", sep = "")
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
