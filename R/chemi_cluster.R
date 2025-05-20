# R/chemi_cluster.R
#' Get chemical similarity map
#'
#' @param chemicals vector of chemical names
#' @param sort boolean to sort or not
#' @param dry_run boolean to return the payload instead of sending the request
#'
#' @return
#' @export
#'
#' @examples
chemi_cluster <- function(chemicals, sort = TRUE, dry_run = FALSE) {
  if (is.null(sort) | missing(sort)) {
    cli::cli_abort('Missing sort!')
  }

  body_data <- list(
    chemicals = map(chemicals, ~ list(sid = .x))
  )

  cli_rule(left = "Similarity payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(chemicals)}",
      "Sort" = "{sort}"
    )
  )
  cli_rule()
  cli_end()

  if (dry_run) {
    req <- request(
      Sys.getenv('chemi_burl')
    ) |>
      req_method("POST") |>
      req_url_path_append("api/resolver/getsimilaritymap") |>
      req_url_query(sort = tolower(as.character(sort))) |>
      req_headers(
        accept = "application/json, text/plain, */*"
      ) |>
      req_body_json(body_data)

    return(list(payload = body_data, request = req))
  }

  resp <- request(
    Sys.getenv('chemi_burl')
  ) |>
    req_method("POST") |>
    req_url_path_append("api/resolver/getsimilaritymap") |>
    req_url_query(sort = tolower(as.character(sort))) |>
    req_headers(
      accept = "application/json, text/plain, */*"
    ) |>
    req_body_json(body_data) |>
    req_perform()

  parsed_resp <- resp |>
    resp_body_json()

  return(parsed_resp)
}
