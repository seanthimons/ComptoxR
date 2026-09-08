check_encoding_fidelity <- function() {
  root <- 'C:/Users/sxthi/Documents/ComptoxR/.worktrees/migration-coordination'
  input <- file.path(root, '.migration-evidence/ecotox-release-inputs')
  xlsx <- file.path(input, 'ecotox-terms-appendix.xlsx')
  con <- DBI::dbConnect(
    duckdb::duckdb(),
    dbdir = file.path(root, '.migration-evidence/source-only-installed/R/ComptoxR/ecotox.duckdb'),
    read_only = TRUE
  )
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  Sys.setlocale('LC_ALL', 'C')
  warnings <- character()
  sheets <- readxl::excel_sheets(xlsx)
  toc <- readxl::read_excel(xlsx, sheet = sheets[1], skip = 2)
  capture_clean <- function(x) {
    withCallingHandlers(janitor::make_clean_names(x), warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart('muffleWarning')
    })
  }
  table_names_c <- paste0('app_', capture_clean(toc$Title))
  expected <- lapply(sheets[-1], function(sheet) {
    data <- readxl::read_excel(xlsx, sheet = sheet, skip = 2)
    names(data) <- capture_clean(names(data))
    as.data.frame(data)
  })
  Sys.setlocale('LC_CTYPE', '.UTF-8')
  stopifnot(identical(table_names_c, paste0('app_', janitor::make_clean_names(toc$Title))))
  checks <- lapply(seq_along(expected), function(i) {
    raw <- readxl::read_excel(xlsx, sheet = sheets[i + 1L], skip = 2)
    stopifnot(identical(names(expected[[i]]), janitor::make_clean_names(names(raw))))
    actual <- DBI::dbReadTable(con, table_names_c[i])
    stopifnot(identical(names(actual), names(expected[[i]])))
    stopifnot(isTRUE(all.equal(actual, expected[[i]], check.attributes = FALSE)))
    data.frame(table = table_names_c[i], rows = nrow(actual), columns = ncol(actual), equal = TRUE)
  })
  archive <- file.path(input, 'ecotox_ascii_06_11_2026.zip')
  entries <- utils::unzip(archive, list = TRUE)$Name
  entry <- entries[grepl('(^|/)lifestage_codes[.]txt$', entries)]
  stopifnot(length(entry) == 1L)
  source <- readr::read_delim(
    unz(archive, entry),
    delim = '|',
    col_types = readr::cols(.default = readr::col_character()),
    na = c('', 'NA', 'NR', 'NC', '-', '--', 'NONE', 'UKN', 'UKS'),
    locale = readr::locale(encoding = 'latin1'),
    show_col_types = FALSE
  )
  source <- as.data.frame(janitor::remove_empty(source, which = 'cols'))
  actual <- DBI::dbReadTable(con, 'lifestage_codes')
  stopifnot(identical(source, actual))
  report <- do.call(rbind, checks)
  print(report)
  cat('Appendix tables:', nrow(report), 'total rows:', sum(report$rows), '\n')
  cat('Native lifestage rows identical:', nrow(actual), '\n')
  cat('C-locale setup warnings:', length(warnings), '\n')
  cat('Distinct exact messages:', length(unique(warnings)), '\n')
  print(warnings)
}
check_encoding_fidelity()
