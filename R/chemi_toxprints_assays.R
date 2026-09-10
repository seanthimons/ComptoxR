#' Toxprints Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param category Optional parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_assays <- function(category = NULL, label = NULL) {
  params <- list("category" = category, "label" = label)
  result <- generic_request(
    "endpoint" = "toxprints/assays",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("category" = params[["category"]], "label" = params[["label"]]))
      if (length(.body)) .body else list()
    })
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
  params <- list(
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
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "actives" = params[["actives"]],
          "category" = params[["category"]],
          "chemicals" = params[["chemicals"]],
          "id" = params[["id"]],
          "labels" = params[["labels"]],
          "metrics" = params[["metrics"]],
          "name" = params[["name"]],
          "options" = local({
            .body <- Filter(
              Negate(is.null),
              list(
                "actives" = params[["actives"]],
                "category" = params[["category"]],
                "chemicals" = params[["chemicals"]],
                "id" = params[["id"]],
                "labels" = params[["labels"]],
                "metrics" = params[["metrics"]],
                "name" = params[["name"]]
              )
            )
            if (length(.body)) .body else list()
          }),
          "total" = params[["total"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
