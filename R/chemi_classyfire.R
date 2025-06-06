# R/chemi_amos.R
#' Get Classyfire classificaton for DTXSID
#'
#' This function retrieves Classyfire classificatons for a given DTXSID using the EPA's cheminformatics API.
#'
#' @param query A character vector of DTXSIDs to query.
#'
#' @return A list of Classyfire classificatons corresponding to the input DTXSIDs.
#'  Returns NA if the request fails for a given DTXSID.
#' @export
chemi_classyfire <- function(query, verbose = FALSE) {
  # Display debugging information before the request
  cli::cli_rule(left = "Classyfire classification payload options")
  cli::cli_dl(
    c(
      "Number of compounds" = "{length(query)}",
      "Verbose output" = "{verbose}"
    )
  )
  cli::cli_rule()
  cli::cli_end()

  safe_req_perform <- purrr::safely(httr2::req_perform)

  results <- query |>
    purrr::map(
      .f = function(q) {
        if (verbose) {
          cli::cli_alert_info("Querying DTXSID: {.val {q}}")
        }
        request <- tryCatch(
          {
            httr2::request(stringr::str_glue(
              "{Sys.getenv('chemi_burl')}api/amos/get_classification_for_dtxsid/{q}"
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
          if (verbose) {
            cli::cli_alert_danger(
              "Request failed for DTXSID {.val {q}}: {response$error$message}"
            )
          }
          return(NA) # Return NA if the request failed
        }

        if (!(httr2::resp_status(response$result) %in% 200:299)) {
          if (verbose) {
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
            if (verbose) {
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

  results <- set_names(results, query) %>%
    map_if(
      .,
      is.logical,
      ~ {
        list(
          kingdom = NA,
          klass = NA,
          subklass = NA,
          superklass = NA
        )
      }
    ) %>%
    map(., function(inner_list) {
      map(inner_list, function(x) {
        if (is.null(x)) {
          NA
        } else {
          x
        }
      })
    }) %>%
    map(., as_tibble) %>%
    list_rbind(names_to = 'dtxsid')

  return(results)
}
