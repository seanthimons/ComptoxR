#' Retrieve a specific safety section for a chemical compound from a remote API.
#'
#' This function queries an API to retrieve a specific safety section for a list
#' of chemical compounds identified by their DTXSID. It validates the section
#' request and provides informative messages about the process.
#'
#' @param query A character vector of DTXSIDs for the chemical compounds.
#' @param section A character string specifying the safety section to retrieve.
#'   Must be one of: 'GHS Classification', 'Regulatory Information',
#'   'Record Description', 'Regulatory Information', 'Accidental Release
#'   Measures', 'Fire Fighting', 'Transport Information', 'NFPA Hazard
#'   Classification', 'Other Safety Information', 'Stability and Reactivity'.
#'
#' @return A list where each element corresponds to a DTXSID in the `query`. Each
#'   element contains the retrieved data for the specified `section` as a list.
#'   If no data is found, the function returns `NULL` and displays an error message.
#'
#' @examples
#' \dontrun{
#' # Assuming the CHEMI_BURL environment variable is set correctly
#' # and the API is accessible.
#'
#' # Retrieve the GHS Classification for a single compound.
#' ghs_data <- chemi_safety_section(query = "DTXSID0000001", section = "GHS Classification")
#'
#' # Retrieve the Regulatory Information for multiple compounds.
#' regulatory_data <- chemi_safety_section(
#'   query = c("DTXSID0000001", "DTXSID0000002"),
#'   section = "Regulatory Information"
#' )
#'
#' # Handle cases where no data is found.
#' no_data <- chemi_safety_section(query = "DTXSID_INVALID", section = "GHS Classification")
#' if (is.null(no_data)) {
#'   cat("No data found for the specified query.\n")
#' }
#' }
#' @export
chemi_safety_section <- function(query, section = NULL) {
  if (is.null(section) | missing(section)) {
    cli::cli_abort('Missing section!')
  }

  if (
    !section %in%
      c(
        'GHS Classification',
        'Regulatory Information',
        'Record Description',
        'Regulatory Information',
        'Accidental Release Measures',
        'Fire Fighting',
        'Transport Information',
        'NFPA Hazard Classification',
        'Other Safety Information',
        'Stability and Reactivity'
      )
  ) {
    cli::cli_abort('Improper section request!')
  }

  if (is.null(query) | missing(query)) {
    cli::cli_abort('Request missing')
  }

  chemicals <- vector(mode = "list", length = length(query))

  cli_rule(left = "Safety section payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(query)}",
      "Section" = "{section}"
    )
  )
  cli_rule()
  cli_end()

  req_list <- map(
    query,
    ~ {
      request(
        base_url = Sys.getenv('chemi_burl')
      ) %>%
        req_url_path_append("api/resolver/pubchem-section") %>%
        req_url_query(query = .x) %>%
        req_url_query(idType = 'DTXSID') %>%
        req_url_query(section = section)
    }
  )

  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  df <- resps %>%
    set_names(query) %>%
    resps_successes() %>%
    resps_data(\(resp) resp_body_json(resp)) %>%
    map(
      .,
      ~ pluck(., 'swr') %>%
        list_flatten() %>%
        pluck(., 'section', 'Section')
    ) %>%
    map(
      .,
      ~ {
        # Iterate through each element in the list.
        # sublists names
        # Extract "TOCHeading" from each sublist within the current element.
        df <- map(
          .,
          ~ {
            headers <- pluck(.x, "TOCHeading")
          }
        ) %>%
          # Combine the extracted headers into a single vector.
          list_c()
        # Assign the extracted headers as names to the sublists in the current element.
        setNames(.x, df)
      }
    ) %>%
    map(
      .,
      ~ {
        map(., ~ pluck(.x, 'Information')) %>%
          map(
            .,
            ~ {
              list_flatten(.x) %>%
                keep_at(., names(.) %in% c('Value')) %>%
                list_flatten() %>%
                unname() %>%
                list_flatten() %>%
                list_flatten() %>%
                discard_at(., names(.) %in% c('Markup'))
            }
          )
      }
    )

  if (length(df) > 0) {
    return(df)
  } else {
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }
}
