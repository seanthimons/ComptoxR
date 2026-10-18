#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id_list Array of record IDs.
#' @return Decoded JSON records or raw Excel workbook bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_substances_for_ids <- function(internal_id_list = NULL) {
  params <- base::list("internal_id_list" = internal_id_list)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/substances_for_ids/",
    "path_params" = list(),
    "query" = list(),
    "body" = base::local({
      if (!length(params[["internal_id_list"]])) {
        cli::cli_abort("Supply at least one identifier.")
      }
      body <- Filter(Negate(is.null), params[setdiff(names(params), "record_type")])
      for (field in intersect(
        names(body),
        c("ids", "internal_ids", "internal_id_list", "record_info_fields", "table_fields")
      )) {
        body[[field]] <- as.list(body[[field]])
      }
      body <- .api_validation$body_value(
        body,
        list(
          properties = list(
            internal_id_list = list(
              description = "Array of record IDs.",
              example = list("GJ-004", "FS-26369", "1CGr7ZTsFv4"),
              items = list(type = "string"),
              type = "array"
            )
          ),
          type = "object",
          required = list("internal_id_list")
        )
      )
      for (field in intersect(
        names(body),
        c("ids", "internal_ids", "internal_id_list", "record_info_fields", "table_fields")
      )) {
        body[[field]] <- I(body[[field]])
      }
      body
    }),
    "headers" = list(
      Accept = "application/json, application/vnd.ms-excel, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/substances_for_ids/"
      if (context$status < 200L || context$status >= 300L || grepl("(/json|\\+json)$", context$media)) {
        return(.ct_chemi_result(response, context, decode, tidy = FALSE))
      }
      observe_api_responses(list(response))
      decode()
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
