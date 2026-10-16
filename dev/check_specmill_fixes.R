# Acceptance checks for specmill#100-#102. Run from the package root after re-pinning:
#   Rscript dev/check_specmill_fixes.R [--live]
# Offline checks mock HTTP, so they exercise the generated wrapper and the emitted helper.
check_specmill_fixes <- function(live = FALSE) {
  pkgload::load_all(".", quiet = TRUE)
  ns <- asNamespace("ComptoxR")
  withr::local_envvar(ctx_api_key = Sys.getenv("ctx_api_key", "offline"))
  json <- function(x) {
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
    )
  }
  results <- list()
  check <- function(issue, name, ok, detail = "") {
    results[[length(results) + 1]] <<- data.frame(issue = issue, check = name, pass = isTRUE(ok), detail = detail)
  }
  uses_ct_request <- function(fn) any(grepl(".ct_request", deparse(get(fn, ns)), fixed = TRUE))

  # specmill#100: each chunk's records must keep their types after combining.
  # One-record chunks with sex "F" and "M" become logical FALSE/NA if the policy type-converts per chunk.
  rows <- list(
    DTXSID1 = list(list(dtxsid = "DTXSID1", sex = "F", doseLevel = 1, note = NULL)),
    DTXSID2 = list(list(dtxsid = "DTXSID2", sex = "M", doseLevel = 2.5, note = "x"))
  )
  out <- httr2::with_mocked_responses(
    function(req) json(rows[[basename(req$url)]]),
    ns$ct_hazard_toxref_effects_search(c("DTXSID1", "DTXSID2"))
  )
  check(100, "fan-out keeps character values", identical(out$sex, c("F", "M")), paste(out$sex, collapse = ","))
  check(100, "fan-out keeps numeric values", is.numeric(out$doseLevel), class(out$doseLevel)[1])
  if (live) {
    live_out <- ns$ct_hazard_toxref_effects_search(c("DTXSID1037806", "DTXSID7020182"))
    counts <- table(live_out$sex)
    expected <- c(F = 70L, M = 25L, MF = 135L)
    check(100, "live toxref sex counts", identical(as.integer(counts[names(expected)]), unname(expected)) && !"FALSE" %in% live_out$sex,
      paste(names(counts), counts, sep = "=", collapse = " "))
  }

  # specmill#101: a generated wrapper fetches every page by default and stops on an empty page.
  fn <- "ct_hazard_toxref_data_search_by_study_type"
  check(101, "paginated wrapper is generated with .ct_request", uses_ct_request(fn))
  pages <- list(
    list(list(studyType = "DEV", sex = "F"), list(studyType = "DEV", sex = "F")),
    list(list(studyType = "DEV", sex = "M")),
    list()
  )
  requested <- integer()
  mock_pages <- function(req) {
    page <- as.integer(httr2::url_parse(req$url)$query$pageNumber %||% 1)
    requested <<- c(requested, page)
    json(if (page <= length(pages)) pages[[page]] else list())
  }
  out <- httr2::with_mocked_responses(mock_pages, ns[[fn]]("DEV"))
  check(101, "fetches all pages by default", NROW(out) == 3 && identical(requested, 1:3), paste("pages", paste(requested, collapse = ",")))
  check(101, "keeps types across pages", identical(out$sex, c("F", "F", "M")), paste(out$sex, collapse = ","))
  if ("all_pages" %in% names(formals(ns[[fn]]))) {
    requested <- integer()
    out <- httr2::with_mocked_responses(mock_pages, ns[[fn]]("DEV", all_pages = FALSE))
    check(101, "all_pages = FALSE fetches one page", NROW(out) == 2 && identical(requested, 1L))
  } else {
    check(101, "all_pages = FALSE fetches one page", FALSE, "no all_pages argument")
  }

  # specmill#102: group totals count every operation in the schemas their services reference.
  policy <- yaml::read_yaml("dev/coverage.yml")
  services <- lapply(Sys.glob("apis/*.yml"), yaml::read_yaml)
  report <- utils::capture.output(cov <- source("dev/update_coverage.R")$value)
  for (group in names(policy$groups)) {
    members <- Filter(function(s) grepl(policy$groups[[group]]$services, s$id), services)
    files <- unique(unlist(lapply(members, function(s) s$schemas$files)))
    ops <- unique(unlist(lapply(files, function(f) {
      paths <- jsonlite::read_json(f)$paths
      unlist(lapply(names(paths), function(p) {
        methods <- intersect(names(paths[[p]]), c("get", "post", "put", "delete", "patch"))
        if (length(methods)) paste(toupper(methods), p)
      }))
    })))
    exclude <- unlist(policy$groups[[group]]$exclude)
    if (length(exclude)) ops <- ops[!grepl(paste(exclude, collapse = "|"), ops)]
    total <- cov$baseline[[paste0(group, "_endpoints")]]
    check(102, paste(group, "total counts all schema operations"), identical(as.integer(total), length(ops)),
      sprintf("report %s, schemas %d", total, length(ops)))
  }

  results <- do.call(rbind, results)
  print(results, right = FALSE)
  invisible(results)
}

if (sys.nframe() == 0L) {
  res <- check_specmill_fixes(live = "--live" %in% commandArgs(TRUE))
  quit(status = if (all(res$pass)) 0L else 1L)
}
