# Offline CTX chemical API mock — identifier endpoints backed by local DSSTox
# -------------------------------------------------------------------
# Mirrors USEPA/ccte-api-chemical wire behaviour for detail, search and
# synonym routes so ct_*() functions work unchanged while CTX is down.
#
# Launch:
#   plumber::pr_run(plumber::pr("inst/plumber/ctx/plumber.R"), port = 5557)
# Point ComptoxR at it (any non-empty ctx_api_key works):
#   ctx_server("http://127.0.0.1:5557/")
#
# Configure DB path before launching (optional — defaults to dss_path()):
#   options(ComptoxR.dsstox_path = "/path/to/dsstox.duckdb")
#
# Only identifier fields exist locally; every other CTX field is null.
# Unsupported routes return 404 with an explanatory message.

library(ComptoxR)

# Build in-memory lookup tables once; the source file stays read-only.
.con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(
  .con,
  paste0("ATTACH '", gsub("'", "''", getOption("ComptoxR.dsstox_path", ComptoxR:::dss_path())), "' AS src (READ_ONLY)")
)

# Port of SearchChemicalService.preprocessingSearchWord; applied to both the
# stored values and the query word so they always normalize identically.
DBI::dbExecute(
  .con,
  "CREATE MACRO ctx_norm1(w) AS CASE
     WHEN regexp_full_match(w, '\\d{1,7}-\\d{2}-\\d') THEN w
     WHEN regexp_full_match(w, '[A-Z]{14}-[A-Z]{10}-[A-Z]') THEN w
     WHEN regexp_full_match(translate(w, '‐–—‒―−', '------'), '\\d{1,7}-\\d{2}-\\d')
       THEN translate(w, '‐–—‒―−', '------')
     WHEN regexp_full_match(replace(w, '-', ''), '\\d+') THEN w
     ELSE replace(w, '-', ' ') END"
)
DBI::dbExecute(
  .con,
  "CREATE MACRO ctx_norm0(w) AS CASE
     WHEN regexp_full_match(w, '\\d{3}-\\d{3}-\\d') THEN w
     WHEN regexp_full_match(w, '0*\\d{1,7}-?\\d{2}-?\\d') THEN ctx_norm1(regexp_replace(w, '^0+', ''))
     ELSE ctx_norm1(w) END"
)
DBI::dbExecute(
  .con,
  "CREATE MACRO ctx_norm(raw) AS ctx_norm0(trim(upper(raw)))"
)

DBI::dbExecute(
  .con,
  "CREATE TABLE chem AS
   SELECT DTXSID AS dtxsid,
     any_value(v) FILTER (WHERE parent_col = 'PREFERRED_NAME') AS preferredName,
     any_value(v) FILTER (WHERE parent_col = 'CASRN') AS casrn,
     any_value(v) FILTER (WHERE parent_col = 'MOLECULAR_FORMULA') AS molFormula,
     any_value(v) FILTER (WHERE parent_col = 'SMILES') AS smiles,
     any_value(v) FILTER (WHERE parent_col = 'INCHIKEY') AS inchikey,
     any_value(v) FILTER (WHERE parent_col = 'IUPAC_NAME') AS iupacName
   FROM (SELECT DTXSID, parent_col, nullif(nullif(values, 'NA'), '') AS v FROM src.dsstox WHERE sort_order < 7)
   GROUP BY DTXSID"
)

# ponytail: CTX's rank table lives in a DB view not in the repo. Only 1 (DTXSID)
# and 5 (CASRN) are confirmed; the rest are guesses kept below 16 so the
# rank filter never drops them. Re-check against live responses.
DBI::dbExecute(
  .con,
  "CREATE TABLE search AS
   WITH s AS (
     SELECT dtxsid, 'DSSTox_Substance_Id' AS searchName, 1 AS rank, dtxsid AS searchValue FROM chem
     UNION ALL
     SELECT DTXSID,
       CASE parent_col WHEN 'CASRN' THEN 'CASRN' WHEN 'PREFERRED_NAME' THEN 'Approved Name'
         WHEN 'IUPAC_NAME' THEN 'Systematic Name' WHEN 'INCHIKEY' THEN 'InChIKey' ELSE 'Synonym' END,
       CASE parent_col WHEN 'CASRN' THEN 5 WHEN 'PREFERRED_NAME' THEN 7
         WHEN 'IUPAC_NAME' THEN 9 WHEN 'INCHIKEY' THEN 9 ELSE 12 END,
       values
     FROM src.dsstox
     WHERE parent_col IN ('CASRN', 'PREFERRED_NAME', 'IUPAC_NAME', 'INCHIKEY', 'IDENTIFIER')
       AND values NOT IN ('NA', '')
   )
   SELECT s.*, ctx_norm(s.searchValue) AS modified_value FROM s"
)
DBI::dbExecute(.con, "DETACH src")

.batch_size <- 1000L
.cas_names <- c("CASRN")
.inchikey_names <- c("InChIKey")
.base_names <- c("DSSTox_Substance_Id", "CASRN", "Approved Name", "Systematic Name", "Synonym")

.fields <- local({
  std_head <- c(
    "id", "casrn", "compoundId", "genericSubstanceId", "preferredName", "activeAssays", "cpdataCount",
    "molFormula", "monoisotopicMass", "percentAssays", "pubchemCount", "pubmedCount", "sourcesCount",
    "qcLevel", "qcLevelDesc"
  )
  std_mid <- c(
    "isotope", "multicomponent", "totalAssays", "pubchemCid", "relatedSubstanceCount",
    "relatedStructureCount", "hasStructureImage", "iupacName", "smiles", "inchiString"
  )
  std_tail <- c(
    "inchikey", "qcNotes", "qsarReadySmiles", "msReadySmiles", "irisLink", "pprtvLink",
    "wikipediaArticle", "descriptorStringTsv", "isMarkush", "dtxsid", "dtxcid", "toxcastSelect"
  )
  ccd <- c(
    "id", "casrn", "compoundId", "genericSubstanceId", "preferredName", "activeAssays", "cpdataCount",
    "molFormula", "monoisotopicMass", "averageMass", "percentAssays", "pubchemCount", "pubmedCount",
    "stereo", "sourcesCount", "qcLevel", "qcLevelDesc", std_mid, setdiff(std_tail, "descriptorStringTsv")
  )
  list(
    chemicaldetailall = c(
      std_head, "stereo", std_mid, "averageMass", std_tail,
      "expocatMedianPrediction", "expocat", "nhanes", "toxvalData", "waterSolubilityTest",
      "waterSolubilityOpera", "viscosityCpCpTestPred", "vaporPressureMmhgTestPred",
      "vaporPressureMmhgOperaPred", "thermalConductivity", "tetrahymenaPyriformis", "surfaceTension",
      "soilAdsorptionCoefficient", "oralRatLd50Mol", "operaKmDaysOperaPred", "octanolWaterPartition",
      "octanolAirPartitionCoeff", "meltingPointDegcTestPred", "meltingPointDegcOperaPred",
      "hrFatheadMinnow", "hrDiphniaLc50", "henrysLawAtm", "flashPointDegcTestPred", "devtoxTestPred",
      "density", "boilingPointDegcTestPred", "boilingPointDegcOperaPred", "biodegradationHalfLifeDays",
      "bioconcentrationFactorTestPred", "bioconcentrationFactorOperaPred",
      "atmosphericHydroxylationRate", "amesMutagenicityTestPred", "pkaaOperaPred", "pkabOperaPred"
    ),
    chemicaldetailstandard = c(std_head, std_mid, std_tail),
    chemicalidentifier = c("casrn", "preferredName", "iupacName", "inchikey", "dtxsid", "dtxcid"),
    chemicalstructure = c(
      "id", "casrn", "preferredName", "hasStructureImage", "smiles", "inchiString", "inchikey",
      "qsarReadySmiles", "msReadySmiles", "dtxsid", "dtxcid"
    ),
    ntatoolkit = c(
      "casrn", "preferredName", "activeAssays", "cpdataCount", "molFormula", "monoisotopicMass",
      "percentAssays", "sourcesCount", "totalAssays", "smiles", "inchikey", "msReadySmiles", "dtxsid",
      "dtxcid", "expocatMedianPrediction", "expocat", "nhanes"
    ),
    compact = c("dtxsid", "casrn", "preferredName"),
    ccdchemicaldetails = ccd,
    ccdassaydetails = c(ccd, "top", "scaledTop", "ac50", "logAc50", "hitc")
  )
})

.search_fields <- c(
  "dtxsid", "dtxcid", "casrn", "smiles", "preferredName", "searchName", "searchValue", "rank",
  "hasStructureImage", "isMarkush"
)

# Spring ProblemDetail, the shape CTX returns for every 400.
.problem <- function(res, req, detail, title = "Bad Request", ...) {
  res$status <- 400L
  res$setHeader("Content-Type", "application/problem+json")
  c(list(type = "about:blank", title = title, status = 400L, detail = detail, instance = req$PATH_INFO), list(...))
}

# Widen a data frame to the projection's columns, filling unknown fields with NA (-> null).
.project <- function(df, cols) {
  for (col in setdiff(cols, names(df))) df[[col]] <- rep(NA, nrow(df))
  df[, cols, drop = FALSE]
}

# Spring decodes path variables; plumber hands them over percent-encoded.
.decode <- function(x) utils::URLdecode(x)

.query <- function(sql, ...) DBI::dbGetQuery(.con, sql, params = list(...))

# DuckDB binds an R character vector as a VARCHAR[] list via list(); unnest() it.
.chem_for <- function(ids) {
  .query(
    "SELECT * FROM chem WHERE dtxsid IN (SELECT unnest(?::VARCHAR[])) ORDER BY dtxsid",
    list(as.character(ids))
  )
}

.norm <- function(words) .query("SELECT ctx_norm(unnest(?::VARCHAR[])) AS w", list(as.character(words)))$w

.parse_ids <- function(req) {
  ids <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) NULL)
  if (!is.character(ids)) NULL else ids
}

# ---- search helpers (SearchChemicalService ports) ---------------------------

.is_cas <- function(w) grepl("^\\d{1,7}-\\d{2}-\\d$", w, perl = TRUE)
.is_dtxsid <- function(w) startsWith(toupper(w), "DTXSID")
.is_dtxcid <- function(w) startsWith(toupper(w), "DTXCID")

.cas_checksum_ok <- function(cas) {
  d <- rev(as.integer(strsplit(gsub("-", "", cas), "")[[1]]))
  sum(d[-1] * seq_along(d[-1])) %% 10 == d[1]
}

.error_msgs <- function(word) {
  found <- paste0("Found 0 results for '", word, "'.")
  if (.is_cas(word)) {
    msgs <- paste("Searched by CASRN:", found)
    if (!.cas_checksum_ok(word)) msgs <- c(msgs, "CAS number fails checksum.")
    msgs
  } else if (.is_dtxcid(word)) {
    paste("Searched by DTX Compound Id:", found)
  } else if (.is_dtxsid(word)) {
    paste("Searched by DTX Substance Id:", found)
  } else if (grepl("^[A-Z]{14}-[A-Z]{10}-[A-Z]$", word)) {
    paste("Searched by InChIKey:", found)
  } else if (grepl("^[A-Z]{14}$", word)) {
    paste("Searched by InChIKey Skeleton:", found)
  } else {
    paste("Searched by Synonym:", found)
  }
}

# ponytail: no spell-correction dictionary offline; CTX's suggestions are always null here.
.not_found <- function(res, req, word) {
  .problem(res, req, paste(.error_msgs(word), collapse = "\n"), suggestions = NULL)
}

# Search rows joined to chem columns. `where` is trusted SQL; values go through params.
.search_rows <- function(where, order, ..., names = NULL, top = 0L) {
  sql <- paste(
    "SELECT s.dtxsid, c.casrn, c.smiles, c.preferredName, s.searchName, s.searchValue, s.rank, s.modified_value",
    "FROM search s JOIN chem c USING (dtxsid) WHERE", where,
    if (!is.null(names)) "AND s.searchName IN (SELECT unnest(?::VARCHAR[]))",
    "ORDER BY", order,
    if (top > 0L) paste("LIMIT", as.integer(top))
  )
  params <- c(list(...), if (!is.null(names)) list(list(names)))
  DBI::dbGetQuery(.con, sql, params = params)
}

.dedup <- function(df) df[!duplicated(df$dtxsid), , drop = FALSE]

# applyStartWithRankFilter: keep ranks < 16 if any exist, else only rank 16.
.rank_filter <- function(df) {
  if (!nrow(df)) return(df)
  if (min(df$rank) < 16) df[df$rank < 16, , drop = FALSE] else df[df$rank == 16, , drop = FALSE]
}

.search_out <- function(df, projection = "chemicalsearchall") {
  if (projection == "dtxsidonly") return(df[, "dtxsid", drop = FALSE])
  .project(df, .search_fields)
}

.top <- function(top) {
  top <- suppressWarnings(as.integer(top))
  if (length(top) != 1L || is.na(top)) 0L else top
}

# ---- routes -----------------------------------------------------------------

#* @apiTitle CTX Chemical API (offline mock)
#* @apiDescription Identifier endpoints of the CTX chemical API served from local DSSTox

#* Return 404 for every route this mock does not implement
#* @plumber
function(pr) {
  plumber::pr_set_404(pr, function(req, res) {
    res$status <- 404L
    res$setHeader("Content-Type", "application/json")
    res$body <- jsonlite::toJSON(auto_unbox = TRUE, list(
      title = "Not Found",
      status = 404L,
      detail = paste(req$PATH_INFO, "is not available in the offline CTX mock (identifier endpoints only)."),
      instance = req$PATH_INFO
    ))
    res
  })
}

#* Restrict to localhost
#* @filter localhost_only
function(req, res) {
  ip <- req$REMOTE_ADDR %||% ""
  if (!grepl("^(127\\.0\\.0\\.1|::1|localhost)$", ip)) {
    res$status <- 403
    return(list(error = "Access restricted to localhost"))
  }
  plumber::forward()
}

#* Health check
#* @get /chemical/health
#* @head /chemical/health
function() {
  list(status = "UP")
}

#* Chemical detail by DTXSID
#* @get /chemical/detail/search/by-dtxsid/<dtxsid>
#* @serializer unboxedJSON list(na = "null", null = "null")
function(dtxsid, projection = "chemicaldetailall", req, res) {
  dtxsid <- .decode(dtxsid)
  cols <- .fields[[projection]]
  if (is.null(cols)) {
    return(.problem(res, req, paste0("Failed to convert 'projection' with value: '", projection, "'")))
  }
  df <- .chem_for(dtxsid)
  if (!nrow(df)) return(.problem(res, req, paste("dtxsid with value", dtxsid, "not found.")))
  as.list(.project(df, cols)[1, , drop = FALSE])
}

#* Chemical details for a batch of DTXSIDs (JSON array body)
#* @post /chemical/detail/search/by-dtxsid/
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(projection = "chemicaldetailall", req, res) {
  cols <- .fields[[projection]]
  if (is.null(cols)) {
    return(.problem(res, req, paste0("Failed to convert 'projection' with value: '", projection, "'")))
  }
  ids <- .parse_ids(req)
  if (is.null(ids)) return(.problem(res, req, "Request body is malformed.", title = "Invalid request body"))
  if (length(ids) > .batch_size) {
    # Argument order matches CTX's own (garbled) HigherNumberOfIdsException message.
    return(.problem(res, req, sprintf("System supports only '%d' '%d' at one time, 'dtxsid' are submitted.", .batch_size, length(ids))))
  }
  .project(.chem_for(ids), cols)
}

#* Exact search
#* @get /chemical/search/equal/<word>
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(word, projection = "chemicalsearchall", req, res) {
  word <- .decode(word)
  if (!projection %in% c("chemicalsearchall", "dtxsidonly")) return(.not_found(res, req, word))
  df <- .dedup(.search_rows("s.modified_value = ?", "s.rank, s.dtxsid", .norm(word)))
  if (projection == "chemicalsearchall") df <- .rank_filter(df)
  if (!nrow(df)) return(.not_found(res, req, word))
  .search_out(df, projection)
}

#* Starts-with search
#* @get /chemical/search/start-with/<word>
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(word, top = 500, req, res) {
  word <- .decode(word)
  top <- .top(top)
  w <- .norm(word)
  df <- .search_rows("s.modified_value IN (?, ?)", "s.rank, s.dtxsid", w, gsub(" ", "", w))
  more <- !(.is_dtxsid(w) || .is_dtxcid(w) || .is_cas(w)) && !(nrow(df) && df$searchName[1] %in% .cas_names)
  if (more) {
    names <- c(.base_names, .inchikey_names[nchar(w) > 13])
    df <- rbind(df, .search_rows("starts_with(s.modified_value, ?)", "s.rank, s.searchValue", w, names = names, top = top))
  }
  df <- .rank_filter(.dedup(df))
  if (!nrow(df)) return(.not_found(res, req, word))
  .search_out(if (top > 0L) utils::head(df, top) else df)
}

#* Contains search
#* @get /chemical/search/contain/<word>
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(word, top = 0, projection = "chemicalsearchall", req, res) {
  word <- .decode(word)
  if (!projection %in% c("chemicalsearchall", "dtxsidonly")) return(.not_found(res, req, word))
  w <- .norm(word)
  names <- c(.base_names, .inchikey_names[nchar(w) >= 13])
  df <- .search_rows("contains(s.modified_value, ?)", "s.rank, s.dtxsid", w, names = names, top = .top(top))
  if (projection == "chemicalsearchall") df <- .rank_filter(df)
  df <- .dedup(df)
  if (!nrow(df)) return(.not_found(res, req, word))
  .search_out(df, projection)
}

#* Batch exact search (newline-delimited text body)
#* @post /chemical/search/equal/
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(req, res) {
  words <- strsplit(req$postBody %||% "", "\n", fixed = TRUE)[[1]]
  if (!length(words)) return(list())
  processed <- .norm(words)
  hits <- .search_rows(
    "s.modified_value IN (SELECT unnest(?::VARCHAR[]))", "s.rank, s.dtxsid", list(unique(processed))
  )
  hits <- hits[hits$rank < 16, , drop = FALSE]
  seen <- character()
  rows <- lapply(seq_along(words), function(i) {
    best <- hits[hits$modified_value == processed[i], , drop = FALSE]
    if (grepl("^[A-Z]{14}$", words[i])) {
      sk <- .search_rows("starts_with(s.modified_value, ?)", "s.rank, s.searchValue", words[i], names = .inchikey_names, top = 1L)
      if (nrow(sk)) best <- transform(sk, searchName = "InChIKey Skeleton")
    }
    if (!nrow(best)) {
      return(list(
        dtxsid = NA, dtxcid = NA, casrn = NA, smiles = NA, preferredName = NA, searchName = NA,
        searchValue = words[i], rank = NA, hasStructureImage = NA, isMarkush = NA,
        searchMsgs = I(.error_msgs(words[i])), suggestions = NULL, isDuplicate = FALSE
      ))
    }
    b <- best[1, ]
    dup <- b$dtxsid %in% seen
    seen <<- c(seen, b$dtxsid)
    list(
      dtxsid = b$dtxsid, dtxcid = NA, casrn = b$casrn, smiles = b$smiles, preferredName = b$preferredName,
      searchName = b$searchName, searchValue = words[i], rank = b$rank, hasStructureImage = NA,
      isMarkush = NA, searchMsgs = NULL, suggestions = NULL, isDuplicate = dup
    )
  })
  rows
}

# ponytail: local DSSTox has no synonym quality buckets; every identifier lands in `valid`.
.synonyms_for <- function(ids) {
  df <- .query(
    "SELECT dtxsid, searchValue AS synonym FROM search
     WHERE searchName = 'Synonym' AND dtxsid IN (SELECT unnest(?::VARCHAR[]))
     ORDER BY dtxsid, searchValue",
    list(as.character(ids))
  )
  split(df$synonym, df$dtxsid)
}

.synonym_all <- function(dtxsid, valid) {
  list(
    dtxsid = dtxsid, valid = if (length(valid)) I(valid), good = NULL, other = NULL, deleted = NULL,
    beilstein = NULL, alternate = NULL, pcCode = NULL
  )
}

#* Synonyms by DTXSID
#* @get /chemical/synonym/search/by-dtxsid/<dtxsid>
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(dtxsid, projection = "", req, res) {
  dtxsid <- .decode(dtxsid)
  syn <- .synonyms_for(dtxsid)[[dtxsid]]
  if (identical(tolower(projection), "ccd-synonyms")) {
    return(data.frame(synonym = syn %||% character(), quality = rep("valid_synonym", length(syn))))
  }
  if (!nrow(.chem_for(dtxsid))) return(.problem(res, req, paste("DTXSID with value", dtxsid, "not found.")))
  .synonym_all(dtxsid, syn)
}

#* Synonyms for a batch of DTXSIDs (JSON array body)
#* @post /chemical/synonym/search/by-dtxsid/
#* @serializer json list(na = "null", null = "null", auto_unbox = TRUE)
function(req, res) {
  ids <- .parse_ids(req)
  if (is.null(ids)) return(.problem(res, req, "Request body is malformed.", title = "Invalid request body"))
  if (length(ids) > .batch_size) {
    return(.problem(res, req, sprintf("System supports only '%d' '%d' at one time, 'dtxsid' are submitted.", .batch_size, length(ids))))
  }
  found <- .chem_for(ids)$dtxsid
  syn <- .synonyms_for(found)
  unname(lapply(found, function(id) .synonym_all(id, syn[[id]])))
}
