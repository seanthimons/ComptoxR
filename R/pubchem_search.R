#' Search PubChem for compound CIDs
#'
#' @noMd
#' @description
#' Search the PubChem PUG REST API by compound name, SMILES, InChI, InChIKey,
#' or molecular formula and return matching PubChem Compound IDs (CIDs).
#'
#' SMILES and InChI inputs are automatically sent via POST to avoid URL encoding
#' issues with special characters (`/`, `#`, `+`).
#'
#' PubChem may return multiple CIDs for a single name query (e.g., different
#' stereoisomers). If more than 10 CIDs are returned, a message is displayed
#' with the count.
#'
#' For structure-based searches (SMILES, InChI), the query is sent as a POST
#' form body rather than in the URL path. This is required because
#' `httr2::req_url_path_append()` does not percent-encode path segments,
#' and characters like `/` and `#` in SMILES notation would corrupt the URL.
#'
#' Native credential and configuration errors stop the call; other PubChem Faults retain their warning and empty-result behavior.
#' @param query Character string. The search term (compound name, SMILES, InChI,
#'   InChIKey, or molecular formula).
#' @param type Character string. The type of identifier in `query`. One of
#'   `"name"` (default), `"smiles"`, `"inchi"`, `"inchikey"`, or `"formula"`.
#' @param cache Logical. If `TRUE` (default), results are cached in the session
#'   environment so repeated searches for the same query and type are instant.
#' @return A tibble with a single column `cid` containing integer PubChem CIDs.
#'   Returns a zero-row tibble if no matches are found.
#' @seealso [pubchem_properties()] to fetch properties for CIDs,
#'   [pubchem_synonyms()] to fetch synonym lists,
#'   [ct_chemical_detail_search()] for CompTox Dashboard chemical search.
#' @export
#' @examples
#' \dontrun{
#' pubchem_search(query = "aspirin")
#' pubchem_search(query = "CC(=O)O", type = "smiles")
#' }
# Generated with specmill; do not edit by hand.
pubchem_search <- function(query, type = c("name", "smiles", "inchi", "inchikey", "formula"), cache = TRUE) {
  type <- base::get(".ct_pc_type", envir = base::parent.env(base::environment()), mode = "function", inherits = TRUE)(
    type
  )
  query <- base::get(".ct_pc_query", envir = base::parent.env(base::environment()), mode = "function", inherits = TRUE)(
    query
  )
  params <- base::list("query" = query, "type" = type, "cache" = cache)
  cache_state <- base::list(params = params, enabled = params[["cache"]], cached = base::list())
  if (cache_state$enabled) {
    cache_environment <- .ComptoxREnv
    if (!base::is.environment(cache_environment)) {
      base::stop("cache.environment must select an environment", call. = FALSE)
    }
    if (!base::exists("pubchem_search_cache", envir = cache_environment, inherits = FALSE)) {
      base::assign(
        "pubchem_search_cache",
        base::new.env(hash = TRUE, parent = base::emptyenv()),
        envir = cache_environment
      )
    }
    cache_state$store <- base::get("pubchem_search_cache", envir = cache_environment, inherits = FALSE)
    if (!base::is.environment(cache_state$store)) {
      base::stop("Named cache must be an environment", call. = FALSE)
    }
    cache_key <- base::get(
      ".ct_pc_search_key",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )(base::list(params = cache_state$params))
    if (
      !base::is.character(cache_key) ||
        base::length(cache_key) != 1L ||
        base::is.na(cache_key) ||
        !base::nzchar(cache_key)
    ) {
      base::stop("cache.key must return one nonempty string", call. = FALSE)
    }
    cache_state$key <- cache_key
    if (base::exists(cache_key, envir = cache_state$store, inherits = FALSE)) {
      base::return(base::get(cache_key, envir = cache_state$store, inherits = FALSE))
    }
  }
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
    "method" = if (params[["type"]] %in% c("smiles", "inchi")) {
      "POST"
    } else {
      "GET"
    },
    "path" = if (params[["type"]] %in% c("smiles", "inchi")) {
      "/compound/{namespace}/cids/JSON"
    } else {
      "/compound/{namespace}/{query}/cids/JSON"
    },
    "path_params" = if (params[["type"]] %in% c("smiles", "inchi")) {
      list(namespace = params[["type"]])
    } else {
      list(namespace = params[["type"]], query = params[["query"]])
    },
    "body" = if (params[["type"]] %in% c("smiles", "inchi")) {
      stats::setNames(list(params[["query"]]), params[["type"]])
    } else {
      NULL
    },
    "form_schema" = list(
      type = "object",
      properties = list(smiles = list(type = "string"), inchi = list(type = "string")),
      additionalProperties = FALSE
    ),
    "response_policy" = function(response, context, decode) {
      .ct_pc_response(response, context, decode, "cids", c("IdentifierList", "CID"), FALSE)
    },
    "parameter_serialization" = if (params[["type"]] %in% c("smiles", "inchi")) {
      list()
    } else {
      list(list(
        name = "query",
        location = "path",
        style = "simple",
        explode = FALSE,
        schema = list(type = "string"),
        required = TRUE
      ))
    }
  )
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  result <- base::get(
    ".ct_pc_search_result",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params))
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  if (cache_state$enabled) {
    base::assign(cache_state$key, result, envir = cache_state$store)
  }
  result
}
