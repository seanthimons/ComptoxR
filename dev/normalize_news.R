normalize_news_text <- function(x) {
  x <- gsub("\u2018", "'", x, fixed = TRUE)
  x <- gsub("\u2019", "'", x, fixed = TRUE)
  replacements <- c(
    "depreciated" = "deprecated",
    "docuementation" = "documentation",
    "developement" = "development",
    "calculatiosn" = "calculations",
    "debuggin" = "debugging"
  )
  for (from in names(replacements)) {
    x <- gsub(from, replacements[[from]], x, fixed = TRUE)
  }
  x
}

normalize_autonewsmd_repo_list <- function(an) {
  text_columns <- c("summary", "message", "clean_summary")

  for (tag in names(an$repo_list)) {
    commits <- an$repo_list[[tag]]$commits
    for (column in intersect(text_columns, names(commits))) {
      commits[[column]] <- normalize_news_text(commits[[column]])
    }
    an$repo_list[[tag]]$commits <- commits
  }

  invisible(an)
}

# autonewsmd rewrites all of NEWS.md from git history, which would drop any
# hand-written text. read_release_notes() collects it before generation: the
# "## Unreleased" section, and every version's "#### Release notes" block.
# insert_release_notes() puts each block back under its version, and the
# Unreleased notes under the new (first) version.
release_notes_heading <- "#### Release notes"
release_notes_end <- "<!-- end release notes -->"

news_version <- function(heading) sub("^## (\\S+).*$", "\\1", heading)

trim_blank_lines <- function(x) {
  kept <- which(nzchar(trimws(x)))
  if (!length(kept)) character() else x[min(kept):max(kept)]
}

read_release_notes <- function(path = "NEWS.md") {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  heads <- which(startsWith(lines, "## "))
  ends <- c(heads[-1] - 1L, length(lines))
  notes <- list()
  for (i in seq_along(heads)) {
    body <- lines[seq.int(heads[[i]] + 1L, length.out = ends[[i]] - heads[[i]])]
    version <- news_version(lines[[heads[[i]]]])
    if (version != "Unreleased") {
      from <- match(release_notes_heading, body)
      to <- match(release_notes_end, body)
      if (is.na(from) || is.na(to) || to < from) {
        next
      }
      body <- body[seq.int(from + 1L, length.out = to - from - 1L)]
    }
    body <- trim_blank_lines(body)
    if (length(body)) {
      notes[[version]] <- body
    }
  }
  notes
}

insert_release_notes <- function(notes, path = "NEWS.md") {
  if (!length(notes)) {
    return(invisible(path))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  heads <- which(startsWith(lines, "## "))
  if (!length(heads)) {
    stop("No version heading in ", path, "; cannot restore release notes.", call. = FALSE)
  }
  versions <- news_version(lines[heads])
  if (!is.null(notes$Unreleased)) {
    notes[[versions[[1]]]] <- c(notes[[versions[[1]]]], if (!is.null(notes[[versions[[1]]]])) "", notes$Unreleased)
  }
  # Insert from the bottom up so earlier line numbers stay valid.
  for (i in rev(seq_along(heads))) {
    block <- notes[[versions[[i]]]]
    if (is.null(block)) {
      next
    }
    at <- heads[[i]]
    lines <- c(
      lines[seq_len(at)],
      "", release_notes_heading, "", block, "", release_notes_end,
      lines[-seq_len(at)]
    )
  }
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

normalize_news_file <- function(path = "NEWS.md") {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  writeLines(normalize_news_text(lines), path, useBytes = TRUE)
  invisible(path)
}
