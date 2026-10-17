#' Toxprints Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param category category
#' @param label label
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_assays()
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_assays <- function(category = NULL, label = NULL) {
  .api_validation$parameter_values(
    base::list("category" = category, "label" = label),
    list(category = list(type = "string"), label = list(type = "string")),
    .api_validation$body_value,
    c(category = "query", label = "query")
  )
  params <- base::list("category" = category, "label" = label)
  if (base::is.character(params[["category"]]) && base::any(!base::nzchar(params[["category"]]))) {
    base::stop("Empty query parameter: category")
  }
  if (base::is.character(params[["label"]]) && base::any(!base::nzchar(params[["label"]]))) {
    base::stop("Empty query parameter: label")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/toxprints/assays",
    path_params = base::list(),
    query = base::list("category" = params[["category"]], "label" = params[["label"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}

#' Toxprints Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param acl Optional parameter
#' @param actives Optional parameter
#' @param category Optional parameter
#' @param chemicals Optional parameter
#' @param id Optional parameter
#' @param labels Optional parameter
#' @param metrics Optional parameter
#' @param name Optional parameter
#' @param options Optional parameter
#' @param total Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk(acl = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_assays_bulk <- function(
  acl = NULL,
  actives = NULL,
  category = NULL,
  chemicals = NULL,
  id = NULL,
  labels = NULL,
  metrics = NULL,
  name = NULL,
  options = NULL,
  total = NULL
) {
  params <- base::list(
    "acl" = acl,
    "actives" = actives,
    "category" = category,
    "chemicals" = chemicals,
    "id" = id,
    "labels" = labels,
    "metrics" = metrics,
    "name" = name,
    "options" = options,
    "total" = total
  )
  result <- generic_chemi_request(
    "query" = params[["acl"]],
    "endpoint" = "toxprints/assays",
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list(
          "actives" = params[["actives"]],
          "category" = params[["category"]],
          "chemicals" = params[["chemicals"]],
          "id" = params[["id"]],
          "labels" = params[["labels"]],
          "metrics" = params[["metrics"]],
          "name" = params[["name"]],
          "options" = params[["options"]],
          "total" = params[["total"]]
        )
      )
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
