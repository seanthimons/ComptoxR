base_request <- function(
  query_list,
  base_url,
  path,
  endpoint,
  verbose
) {
  # Display debugging information before the request
  cli::cli_rule(left = "{endpoint} payload options")
  cli::cli_dl(
    c(
      "Number of compounds" = "{length(query_list)}",
    )
  )
  cli::cli_rule()
  cli::cli_end()

  safe_req_perform <- purrr::safely(httr2::req_perform)

  results <- query_list |>
    purrr::map(
      .f = function(q) {
        if (Sys.getenv('run_verbose')) {
          cli::cli_alert_info("Querying DTXSID: {.val {q}}")
        }
        request <- tryCatch(
          {
            httr2::request(stringr::str_glue(
              "{base_url}{path}{q}"
            ))
          },
          error = function(e) {
            cli::cli_abort(
              "Error creating request for DTXSID {.val {q}}: {e$message}"
            )
            return(NULL)
          }
        )

        if (is.null(request)) {
          return(NA) # Return NA if the request object is NULL
        }

        response <- safe_req_perform(request)

        if (!is.null(response$error)) {
          if (Sys.getenv('run_verbose')) {
            cli::cli_alert_danger(
              "Request failed for DTXSID {.val {q}}: {response$error$message}"
            )
          }
          return(NA) # Return NA if the request failed
        }

        if (!(httr2::resp_status(response$result) %in% 200:299)) {
          if (Sys.getenv('run_verbose')) {
            cli::cli_alert_warning(
              "Unexpected status code {.val {httr2::resp_status(response$result)}} for DTXSID {.val {q}}"
            )
          }
          return(NA) # Return NA for non-200 status codes
        }

        tryCatch(
          {
            httr2::resp_body_json(response$result)
          },
          error = function(e) {
            if (Sys.getenv('run_verbose')) {
              cli::cli_alert_danger(
                "Failed to parse JSON response for DTXSID {.val {q}}: {e$message}"
              )
            }
            return(NA) # Return NA if JSON parsing fails
          }
        )
      },
      .progress = TRUE
    )
}
