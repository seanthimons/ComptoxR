#' chemi_resolver_getsimilaritymap
#'
#' @noMd
#' @param query query
#' @param idType idType
#' @param section section
#' @param sort sort
#' @param hclust_method hclust_method
#' @param format format
#' @return Decoded response returned by the client request helper.
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_getsimilaritymap <- function(
  query,
  idType = "AnyId",
  section = NULL,
  sort = FALSE,
  hclust_method = "complete",
  format = c("cluster", "long", "raw")
) {
  params <- base::c(
    base::list(
      "query" = query,
      "idType" = idType,
      "section" = section,
      "sort" = sort,
      "hclust_method" = hclust_method,
      "format" = format
    ),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_resolver_getsimilaritymap", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/getsimilaritymap",
    "path_params" = structure(list(), names = character(0)),
    "query" = list(sort = if (!is.null(params[["sort"]])) tolower(as.character(params[["sort"]])) else NULL),
    "body" = base::local({
      chemicals <- params[["chemicals"]]
      if (!is.list(chemicals) || !length(chemicals)) {
        chemicals <- lapply(.ct_toxprint_query(params[["query"]]), function(id) list(sid = id))
      }
      c(
        list(
          chemicals = lapply(chemicals, function(record) {
            if (is.list(record) && !is.null(record$chemical)) record$chemical else record
          })
        ),
        Filter(Negate(is.null), base::list(section = params[["section"]]))
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "resolver/getsimilaritymap"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result <- run_hook(
    "chemi_resolver_getsimilaritymap",
    "post_response",
    base::list(result = result, params = params[c("query", "idType", "section", "sort", "hclust_method", "format")])
  )
  result
}
