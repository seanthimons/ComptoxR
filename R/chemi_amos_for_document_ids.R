#' Runs a search for document IDs that pass a list of submitted filters, including document metadata, substance
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type Record type to filter by.  Should be either 'Fact Sheet', 'Method', 'Product Declaration', or 'Safety Data Sheet' (capitalization included).
#' @param search_info Search query parameters.  Exact parameters are still in flux, but generally consist of database field names with values and flags for whether to perform exact matches or not.
#' @param record_info_fields List of field names in search_info that are fields in the record_info table in PostgreSQL.
#' @param table_fields List of field names in search_info that are fields in the fact_sheets table in PostgreSQL.
#' @return Decoded JSON records or raw Excel workbook bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_for_document_ids <- function(
  record_type,
  search_info = NULL,
  record_info_fields = NULL,
  table_fields = NULL
) {
  params <- base::list(
    "record_type" = record_type,
    "search_info" = search_info,
    "record_info_fields" = record_info_fields,
    "table_fields" = table_fields
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/search_for_document_ids/{record_type}",
    "path_params" = base::list("record_type" = params[["record_type"]]),
    "query" = list(),
    "body" = base::local({
      NULL
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
          properties = list(
            search_info = list(
              type = "object",
              additionalProperties = list(
                type = "object",
                properties = list(value = list(type = "string", nullable = TRUE), exact = list(type = "boolean"))
              ),
              properties = list(dtxsid = list(type = "string"), document_text = list(type = "string"))
            ),
            record_info_fields = list(
              oneOf = list(
                list(type = "array", items = list(type = "string")),
                list(type = "object", properties = structure(list(), names = character(0)), additionalProperties = TRUE)
              ),
              description = "Names of fields to filter using values in search_info. A legacy object whose keys are field names is also accepted.",
              example = list("source")
            ),
            table_fields = list(
              oneOf = list(
                list(type = "array", items = list(type = "string")),
                list(type = "object", properties = structure(list(), names = character(0)), additionalProperties = TRUE)
              ),
              description = "Names of fields to filter using values in search_info. A legacy object whose keys are field names is also accepted.",
              example = list("analyte")
            )
          ),
          required = list("search_info"),
          example = list(
            search_info = list(analyte = list(value = "benzene", exact = FALSE)),
            table_fields = list("analyte"),
            record_info_fields = list()
          )
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
      context$endpoint <- "amos/search_for_document_ids/{record_type}"
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
