#' Returns information on a batch of fact sheets specified by internal ID.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_ids List of fact sheet IDs to return information on.
#' @return Decoded JSON records or raw Excel workbook bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_retrieve_fact_sheets <- function(internal_ids = NULL) {
  params <- base::list("internal_ids" = internal_ids)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/retrieve_fact_sheets/",
    "path_params" = list(),
    "query" = list(),
    "body" = base::local({
      if (!length(params[["internal_ids"]])) {
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
          type = "object",
          properties = list(internal_ids = list(type = "array", items = list(type = "string"))),
          required = list("internal_ids")
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
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "amos/retrieve_fact_sheets/"
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
