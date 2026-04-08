# DSSTox Local Database — Query Functions
# ------------------------------------------
# All SQL uses parameterized queries or temp-table + JOIN patterns.
# Zero string interpolation of user-supplied values in SQL.

# Column allowlist for validation
.DSS_VALID_COLS <- c(
  "PREFERRED_NAME", "CASRN", "IDENTIFIER",
  "SMILES", "MOLECULAR_FORMULA", "INCHIKEY", "IUPAC_NAME"
)

#' Validate column names against the DSSTox allowlist
#' @param cols Character vector of column names to validate.
#' @return `cols` (invisibly) if valid; aborts otherwise.
#' @keywords internal
.dss_validate_cols <- function(cols) {
  bad <- setdiff(cols, .DSS_VALID_COLS)
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "Invalid column name{?s}: {.val {bad}}.",
      "i" = "Allowed columns: {.val {(.DSS_VALID_COLS)}}"
    ))
  }
  invisible(cols)
}

#' Query the DSSTox database by exact value match
#'
#' Performs exact matching of one or more values against the DSSTox `values`
#' column. Uses a temporary table + JOIN for safe bulk lookups.
#'
#' @param query A character vector of values to search for (names, CASRNs,
#'   SMILES, DTXSIDs, etc.).
#' @param con An optional `DBI::DBIConnection`. If `NULL`, uses the cached
#'   connection via `dss_get_con()`.
#' @return A tibble of matching rows with columns: DTXSID, parent_col, values,
#'   sort_order.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_query("Formaldehyde")
#' dss_query(c("Formaldehyde", "Benzene"))
#' }
dss_query <- function(query, con = NULL) {
  con <- dss_get_con(con)
  query <- unique(as.character(query))
  input_df <- data.frame(value = query, stringsAsFactors = FALSE)

  DBI::dbWriteTable(con, "dss_query_input", input_df,
    temporary = TRUE, overwrite = TRUE
  )
  on.exit(
    tryCatch(
      DBI::dbExecute(con, "DROP TABLE IF EXISTS dss_query_input"),
      error = function(e) NULL
    ),
    add = TRUE
  )

  result <- DBI::dbGetQuery(con,
    "SELECT d.DTXSID, d.parent_col, d.values, d.sort_order
     FROM dss_query_input i
     INNER JOIN dsstox d ON d.values = i.value"
  )

  tibble::as_tibble(result)
}

#' Get all synonyms for one or more DTXSIDs
#'
#' Returns all records (identifiers, names, SMILES, etc.) associated with
#' the given DTXSID(s).
#'
#' @param query A character vector of DTXSIDs.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of all matching rows.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_synonyms("DTXSID7020637")
#' dss_synonyms(c("DTXSID7020637", "DTXSID7020182"))
#' }
dss_synonyms <- function(query, con = NULL) {
  con <- dss_get_con(con)
  query <- unique(as.character(query))
  input_df <- data.frame(dtxsid = query, stringsAsFactors = FALSE)

  DBI::dbWriteTable(con, "dss_syn_input", input_df,
    temporary = TRUE, overwrite = TRUE
  )
  on.exit(
    tryCatch(
      DBI::dbExecute(con, "DROP TABLE IF EXISTS dss_syn_input"),
      error = function(e) NULL
    ),
    add = TRUE
  )

  result <- DBI::dbGetQuery(con,
    "SELECT d.DTXSID, d.parent_col, d.values, d.sort_order
     FROM dss_syn_input i
     INNER JOIN dsstox d ON d.DTXSID = i.dtxsid
     ORDER BY d.DTXSID, d.sort_order"
  )

  tibble::as_tibble(result)
}

#' Resolve chemical identifiers to DTXSIDs
#'
#' Takes a vector of chemical names, CAS numbers, SMILES, or any identifier
#' and returns a tibble mapping each input to its DTXSID and preferred name.
#' Unmatched inputs are included with `NA` values.
#'
#' @param query A character vector of values to resolve.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble with columns: input, DTXSID, PREFERRED_NAME, CASRN,
#'   matched_on.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_resolve(c("Formaldehyde", "7440-38-2", "DTXSID7020637"))
#' }
dss_resolve <- function(query, con = NULL) {
  con <- dss_get_con(con)
  query <- unique(as.character(query))
  input_df <- data.frame(input = query, stringsAsFactors = FALSE)

  DBI::dbWriteTable(con, "dss_resolve_input", input_df,
    temporary = TRUE, overwrite = TRUE
  )
  on.exit(
    tryCatch(
      DBI::dbExecute(con, "DROP TABLE IF EXISTS dss_resolve_input"),
      error = function(e) NULL
    ),
    add = TRUE
  )

  result <- DBI::dbGetQuery(con,
    "WITH matched AS (
       SELECT i.input, d.DTXSID, d.parent_col
       FROM dss_resolve_input i
       INNER JOIN dsstox d ON d.values = i.input
       UNION
       SELECT DISTINCT i.input, d.DTXSID, 'DTXSID' AS parent_col
       FROM dss_resolve_input i
       INNER JOIN dsstox d ON d.DTXSID = i.input
     ),
     enriched AS (
       SELECT DISTINCT
         m.input,
         m.DTXSID,
         m.parent_col,
         pn.values AS PREFERRED_NAME,
         cas.values AS CASRN
       FROM matched m
       LEFT JOIN dsstox pn
         ON pn.DTXSID = m.DTXSID AND pn.parent_col = 'PREFERRED_NAME'
       LEFT JOIN dsstox cas
         ON cas.DTXSID = m.DTXSID AND cas.parent_col = 'CASRN'
     )
     SELECT
       i.input,
       e.DTXSID,
       e.PREFERRED_NAME,
       e.CASRN,
       e.parent_col AS matched_on
     FROM dss_resolve_input i
     LEFT JOIN enriched e ON i.input = e.input
     ORDER BY i.input, e.DTXSID"
  )

  tibble::as_tibble(result)
}

#' Look up CAS numbers or DTXSIDs
#'
#' Convenience wrapper: given CAS numbers, return DTXSIDs (and vice versa).
#'
#' @param query A character vector of CAS numbers or DTXSIDs.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble with columns: query, DTXSID, PREFERRED_NAME, CASRN.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_cas("50-00-0")
#' dss_cas(c("50-00-0", "7440-38-2"))
#' dss_cas("DTXSID7020637")
#' }
dss_cas <- function(query, con = NULL) {
  con <- dss_get_con(con)
  query <- unique(as.character(query))
  input_df <- data.frame(input = query, stringsAsFactors = FALSE)

  DBI::dbWriteTable(con, "dss_cas_input", input_df,
    temporary = TRUE, overwrite = TRUE
  )
  on.exit(
    tryCatch(
      DBI::dbExecute(con, "DROP TABLE IF EXISTS dss_cas_input"),
      error = function(e) NULL
    ),
    add = TRUE
  )

  result <- DBI::dbGetQuery(con,
    "WITH
     by_value AS (
       SELECT DISTINCT i.input, d.DTXSID
       FROM dss_cas_input i
       INNER JOIN dsstox d ON d.values = i.input AND d.parent_col = 'CASRN'
     ),
     by_dtxsid AS (
       SELECT DISTINCT i.input, d.DTXSID
       FROM dss_cas_input i
       INNER JOIN dsstox d ON d.DTXSID = i.input
     ),
     all_matches AS (
       SELECT * FROM by_value
       UNION
       SELECT * FROM by_dtxsid
     )
     SELECT DISTINCT
       m.input AS query,
       m.DTXSID,
       pn.values AS PREFERRED_NAME,
       cas.values AS CASRN
     FROM all_matches m
     LEFT JOIN dsstox pn
       ON pn.DTXSID = m.DTXSID AND pn.parent_col = 'PREFERRED_NAME'
     LEFT JOIN dsstox cas
       ON cas.DTXSID = m.DTXSID AND cas.parent_col = 'CASRN'
     ORDER BY m.input"
  )

  tibble::as_tibble(result)
}

#' Search DSSTox by pattern
#'
#' SQL `ILIKE` pattern search against the `values` column. Supports `%`
#' wildcards for partial matching and optional column filtering.
#'
#' @param pattern A string with SQL ILIKE wildcards. Case-insensitive.
#' @param cols Optional character vector of `parent_col` values to search
#'   within. Validated against an internal allowlist. `NULL` searches all
#'   columns.
#' @param limit Maximum number of rows to return. Default 100.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of matching rows with DTXSID, parent_col, values.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_search("Benz%")
#' dss_search("%chloro%", cols = "PREFERRED_NAME")
#' dss_search("50-%", cols = "CASRN", limit = 10)
#' }
dss_search <- function(pattern, cols = NULL, limit = 100L, con = NULL) {
  con <- dss_get_con(con)
  limit <- as.integer(limit)

  if (!is.null(cols)) {
    .dss_validate_cols(cols)
    # Build safe col filter — values are from the allowlist, not user input
    col_list <- paste0("'", cols, "'", collapse = ", ")
    col_clause <- paste0(" AND parent_col IN (", col_list, ")")
  } else {
    col_clause <- ""
  }

  # Pattern is bound via parameterized query
  sql <- paste0(
    "SELECT DTXSID, parent_col, values FROM dsstox ",
    "WHERE values ILIKE ?",
    col_clause,
    " ORDER BY sort_order, values",
    " LIMIT ", limit
  )

  result <- DBI::dbGetQuery(con, sql, params = list(pattern))
  tibble::as_tibble(result)
}

#' Fuzzy search DSSTox by string similarity
#'
#' Finds approximate matches for chemical names using DuckDB's native string
#' distance functions. Searches are length-blocked to keep performance
#' reasonable against the 15M-row table.
#'
#' @param query A single character string to fuzzy-match.
#' @param method Distance method. One of `"jaro_winkler"` (default),
#'   `"levenshtein"`, `"damerau_levenshtein"`, or `"jaccard"`.
#' @param threshold Similarity/distance cutoff. For jaro_winkler and jaccard,
#'   a minimum similarity (0–1, default 0.85). For levenshtein and
#'   damerau_levenshtein, a maximum edit distance (default 3).
#' @param cols Which `parent_col` values to search. Defaults to
#'   `"PREFERRED_NAME"`. Set to `NULL` to search all columns (slower).
#' @param limit Maximum results to return. Default 20.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble with DTXSID, parent_col, values, and a similarity or
#'   distance score column, ordered by best match first.
#' @export
#' @family dsstox
#' @examples
#' \dontrun{
#' dss_fuzzy("Atrazin")
#' dss_fuzzy("Clorpyrifos", threshold = 0.75)
#' dss_fuzzy("CC(=O)O", method = "levenshtein", cols = "SMILES", threshold = 2)
#' }
dss_fuzzy <- function(query,
                      method = c(
                        "jaro_winkler", "levenshtein",
                        "damerau_levenshtein", "jaccard"
                      ),
                      threshold = NULL,
                      cols = "PREFERRED_NAME",
                      limit = 20L,
                      con = NULL) {
  con <- dss_get_con(con)
  method <- match.arg(method)

  if (!is.character(query) || length(query) != 1L || !nzchar(query)) {
    cli::cli_abort("{.arg query} must be a single non-empty character string.")
  }

  if (!is.null(cols)) {
    .dss_validate_cols(cols)
  }

  limit <- as.integer(limit)

  # Default thresholds per method
  if (is.null(threshold)) {
    threshold <- switch(method,
      jaro_winkler = 0.85,
      jaccard = 0.85,
      levenshtein = 3L,
      damerau_levenshtein = 3L
    )
  }
  threshold <- as.numeric(threshold)

  # Map method to DuckDB function name (hardcoded — no user input in SQL)
  sql_fn <- switch(method,
    jaro_winkler       = "jaro_winkler_similarity",
    jaccard            = "jaccard",
    levenshtein        = "levenshtein",
    damerau_levenshtein = "damerau_levenshtein"
  )

  is_similarity <- method %in% c("jaro_winkler", "jaccard")
  filter_op     <- if (is_similarity) ">=" else "<="
  order_dir     <- if (is_similarity) "DESC" else "ASC"
  score_alias   <- if (is_similarity) "similarity" else "distance"

  qlen <- nchar(query)

  # Length blocking — computed integers, safe for interpolation
  if (is_similarity) {
    len_min <- max(1L, qlen %/% 3L)
    len_max <- qlen * 3L
  } else {
    len_min <- max(1L, qlen - as.integer(threshold))
    len_max <- qlen + as.integer(threshold)
  }

  # Column filter — from validated allowlist
  if (!is.null(cols)) {
    col_list <- paste0("'", cols, "'", collapse = ", ")
    col_clause <- paste0("AND parent_col IN (", col_list, ")")
  } else {
    col_clause <- ""
  }

  # Build SQL with CTE. The query value is bound via `?` parameter.
  # All other interpolated values are computed integers/numerics or
  # hardcoded function/column names.
  sql <- paste0(
    "WITH scored AS (\n",
    "  SELECT DTXSID, parent_col, values,\n",
    "         ", sql_fn, "(LOWER(values), LOWER(?)) AS ", score_alias, "\n",
    "  FROM dsstox\n",
    "  WHERE 1=1 ", col_clause, "\n",
    "    AND LENGTH(values) BETWEEN ", len_min, " AND ", len_max, "\n",
    ")\n",
    "SELECT * FROM scored\n",
    "WHERE ", score_alias, " ", filter_op, " ", threshold, "\n",
    "ORDER BY ", score_alias, " ", order_dir, "\n",
    "LIMIT ", limit
  )

  result <- DBI::dbGetQuery(con, sql, params = list(query))
  tibble::as_tibble(result)
}
