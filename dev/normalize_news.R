normalize_news_text <- function(x) {
  x <- gsub("\u2018", "'", x, fixed = TRUE)
  x <- gsub("\u2019", "'", x, fixed = TRUE)
  gsub("depreciated", "deprecated", x, fixed = TRUE)
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

normalize_news_file <- function(path = "NEWS.md") {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  writeLines(normalize_news_text(lines), path, useBytes = TRUE)
  invisible(path)
}
