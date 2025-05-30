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
  # Check if the section is missing. If so, abort with an error message.
  if (is.null(section) | missing(section)) {
    cli::cli_abort('Missing section!')
  }

  # Check if the requested section is valid. If not, abort with an error message.
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

  # Check if the query is missing. If so, abort with an error message.
  if (is.null(query) | missing(query)) {
    cli::cli_abort('Request missing')
  }

  # Initialize a list to store the results for each chemical compound.
  chemicals <- vector(mode = "list", length = length(query))

  # Display information about the safety section payload options.
  cli_rule(left = "Safety section payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(query)}",
      "Section" = "{section}"
    )
  )
  cli_rule()
  cli_end()

  # Create a list of API requests for each DTXSID in the query.
  req_list <- map(
    query,
    ~ {
      request(
        base_url = Sys.getenv('chemi_burl') # Get the base URL from the environment variable.
      ) %>%
        req_url_path_append("api/resolver/pubchem-section") %>% # Append the API endpoint.
        req_url_query(query = .x) %>% # Add the DTXSID as a query parameter.
        req_url_query(idType = 'DTXSID') %>% # Specify the ID type as DTXSID.
        req_url_query(section = section) # Add the requested section as a query parameter.
    }
  )

  # Perform the API requests sequentially, continuing on error, and displaying a progress bar.
  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  # Process the API responses.
  df <- resps %>%
    set_names(query) %>% # Set the names of the responses to the DTXSIDs.
    resps_successes() %>% # Filter out unsuccessful responses.
    resps_data(\(resp) resp_body_json(resp)) %>% # Extract the JSON data from the successful responses.
    map(
      .,
      ~ pluck(., 'swr') %>% # Extract the 'swr' element from each response.
        list_flatten() %>% # Flatten the list.
        pluck(., 'section', 'Section') # Extract the 'Section' element.
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
        map(., ~ pluck(.x, 'Information')) %>% # Extract the 'Information' element.
          map(
            .,
            ~ {
              list_flatten(.x) %>% # Flatten the list.
                keep_at(., names(.) %in% c('Value')) %>% # Keep only the elements named 'Value'.
                list_flatten() %>% # Flatten the list.
                unname() %>% # Remove names from elements.
                list_flatten() %>% # Flatten the list.
                list_flatten() %>% # Flatten the list.
                discard_at(., names(.) %in% c('Markup')) # Discard the elements named 'Markup'.
            }
          )
      }
    )

  # Check if any data was found.
  if (length(df) > 0) {
    return(df) # Return the extracted data.
  } else {
    cli::cli_alert_danger('No data found!') # Display an error message if no data was found.
    return(NULL) # Return NULL if no data was found.
  }
}
