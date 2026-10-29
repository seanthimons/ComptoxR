#' Fetch computed properties from PubChem
#'
#' @noMd
#' @description
#' Retrieve computed physico-chemical properties for one or more PubChem
#' Compound IDs (CIDs) via the PUG REST API.
#'
#' Property names are validated against PubChem's documented allowlist before
#' the request is made. Invalid property names cause an immediate error.
#'
#' For multiple CIDs, requests are batched at 100 CIDs per POST request
#' (PubChem's documented limit for list-based requests).
#'
#' Native credential and configuration errors stop the call; other PubChem Faults retain their warning and empty-result behavior.
#' @param cid Integer or character vector of PubChem CIDs. Does NOT accept
#'   compound names or DTXSIDs — use [pubchem_search()] first to resolve CIDs.
#' @param properties Character vector of property names to retrieve. If `NULL`
#'   (default), returns 13 core properties: MolecularFormula, MolecularWeight,
#'   CanonicalSMILES, InChI, InChIKey, XLogP, TPSA, HBondDonorCount,
#'   HBondAcceptorCount, Complexity, ExactMass, MonoisotopicMass, HeavyAtomCount.
#' @param cache Logical. If `TRUE` (default), results are cached in the session
#'   environment keyed by CID and property set, so repeated calls are instant.
#' @return A tibble with one row per CID and columns for each requested property
#'   plus a `CID` column. Returns an empty tibble if no results are found.
#' @seealso [pubchem_search()] to find CIDs by name/structure,
#'   [ct_chemical_property_summary_search()] for CompTox Dashboard properties.
#' @export
#' @examples
#' \dontrun{
#' pubchem_properties(cid = 2244L)
#' pubchem_properties(cid = 2244L, properties = "XLogP")
#' }
# Generated with specmill; do not edit by hand.
pubchem_properties <- function(cid, properties = NULL, cache = TRUE) {
  properties <- base::get(
    ".ct_pc_properties",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(properties)
  cid <- base::get(".ct_pc_cid", envir = base::parent.env(base::environment()), mode = "function", inherits = TRUE)(cid)
  params <- base::list("cid" = cid, "properties" = properties, "cache" = cache)
  cache_state <- base::list(
    params = params,
    enabled = params[["cache"]],
    cached = base::list(),
    pending = params[["cid"]]
  )
  if (cache_state$enabled) {
    cache_environment <- .ComptoxREnv
    if (!base::is.environment(cache_environment)) {
      base::stop("cache.environment must select an environment", call. = FALSE)
    }
    if (!base::exists("pubchem_props_cache", envir = cache_environment, inherits = FALSE)) {
      base::assign(
        "pubchem_props_cache",
        base::new.env(hash = TRUE, parent = base::emptyenv()),
        envir = cache_environment
      )
    }
    cache_state$store <- base::get("pubchem_props_cache", envir = cache_environment, inherits = FALSE)
    if (!base::is.environment(cache_state$store)) {
      base::stop("Named cache must be an environment", call. = FALSE)
    }
    cache_missing <- base::integer()
    for (cache_index in base::seq_along(cache_state$pending)) {
      cache_key <- base::get(
        ".ct_pc_property_key",
        envir = base::parent.env(base::environment()),
        mode = "function",
        inherits = FALSE
      )(base::list(input = cache_state$pending[[cache_index]], params = cache_state$params))
      if (
        !base::is.character(cache_key) ||
          base::length(cache_key) != 1L ||
          base::is.na(cache_key) ||
          !base::nzchar(cache_key)
      ) {
        base::stop("cache.key must return one nonempty string", call. = FALSE)
      }
      if (base::exists(cache_key, envir = cache_state$store, inherits = FALSE)) {
        cache_state$cached[base::length(cache_state$cached) + 1L] <- base::list(base::get(
          cache_key,
          envir = cache_state$store,
          inherits = FALSE
        ))
      } else {
        cache_missing <- base::c(cache_missing, cache_index)
      }
    }
    cache_state$pending <- cache_state$pending[cache_missing]
  }
  if (!base::length(cache_state$pending)) {
    result <- NULL
    result <- base::get(
      ".ct_pc_property_combine",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )(base::list(result = result, cached = cache_state$cached, params = cache_state$params))
    base::return(result)
  }
  params[["cid"]] <- cache_state$pending
  send <- function(params) {
    result <- .ct_request(
      "query" = list(),
      "headers" = .ct_pc_headers(),
      "server" = list(url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug"),
      "server_resolver" = list(name = ".ct_server_url", key = "pubchem_burl", relative = ""),
      "auth" = list(),
      "body_media" = "application/x-www-form-urlencoded",
      "request_controls" = list(
        timeout = Inf,
        max_retries = 3L,
        retry_writes = TRUE,
        retry_policy = ".ct_pc_retry",
        preserve_errors = TRUE,
        throttle = list(capacity = 4L, fill_time_s = 1)
      ),
      "method" = if (length(cache_state$pending) > 1L) "POST" else "GET",
      "path" = paste0(
        if (length(cache_state$pending) > 1L) {
          "/compound/cid/property/"
        } else {
          "/compound/cid/{cid}/property/"
        },
        paste(sort(params[["properties"]]), collapse = ","),
        "/JSON"
      ),
      "path_params" = if (length(cache_state$pending) > 1L) {
        list()
      } else {
        list(cid = as.character(params[["cid"]]))
      },
      "body" = if (length(cache_state$pending) > 1L) {
        list(cid = paste(params[["cid"]], collapse = ","))
      } else {
        NULL
      },
      "form_schema" = list(
        type = "object",
        properties = list(cid = list(type = "string")),
        additionalProperties = FALSE,
        required = list("cid")
      ),
      "response_policy" = function(response, context, decode) {
        .ct_pc_response(
          response,
          context,
          decode,
          paste0("property/", paste(sort(params[["properties"]]), collapse = ",")),
          c("PropertyTable", "Properties"),
          TRUE
        )
      }
    )
    result
  }
  if (base::length(cache_state$pending) > 1L) {
    cache_chunks <- base::split(cache_state$pending, base::ceiling(base::seq_along(cache_state$pending) / 100L))
    result <- base::tryCatch(
      purrr::map(cache_chunks, function(chunk) {
        params[["cid"]] <- chunk
        send(params)
      }),
      error = function(e) {
        if (base::inherits(e, "purrr_error_indexed") && base::inherits(e$parent, "specmill_call_error")) {
          base::stop(e$parent)
        }
        base::stop(e)
      }
    )
  } else {
    result <- send(params)
  }
  if (
    base::inherits(result, "httr2_request") ||
      (base::is.list(result) &&
        base::length(result) &&
        base::all(base::vapply(result, base::inherits, base::logical(1), "httr2_request")))
  ) {
    base::return(result)
  }
  params <- cache_state$params
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  result <- base::get(
    ".ct_pc_properties_result",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params, pending = cache_state$pending))
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  if (cache_state$enabled) {
    cache_entries <- base::get(
      ".ct_pc_property_entries",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )(base::list(result = result, params = cache_state$params))
    if (
      !base::is.list(cache_entries) ||
        (base::length(cache_entries) &&
          (base::is.null(base::names(cache_entries)) ||
            base::anyNA(base::names(cache_entries)) ||
            base::any(!base::nzchar(base::names(cache_entries)))))
    ) {
      base::stop("cache.entries must return a list with nonempty keys", call. = FALSE)
    }
    for (cache_index in base::seq_along(cache_entries)) {
      base::assign(base::names(cache_entries)[[cache_index]], cache_entries[[cache_index]], envir = cache_state$store)
    }
  }
  result <- base::get(
    ".ct_pc_property_combine",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, cached = cache_state$cached, params = cache_state$params))
  result
}
