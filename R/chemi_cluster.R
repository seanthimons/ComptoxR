# R/chemi_cluster.R
#' Get chemical similarity map
#'
#' @param chemicals vector of chemical names
#' @param sort boolean to sort or not
#' @param dry_run boolean to return the payload instead of sending the request
#' @param hclust_method character string indicating which clustering method to use in `hclust`.
#'   Defaults to "complete". See `?hclust` for available methods.
#'
#' @return List
#' @export

chemi_cluster <- function(
  chemicals,
  sort = TRUE,
  dry_run = FALSE,
  hclust_method = "complete"
) {
  if (is.null(sort) | missing(sort)) {
    cli::cli_abort('Missing sort!')
  }

  chemicals <- chemi_resolver(chemicals)

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
      req_body_json(
        list(
          'chemicals' = chemicals
        )
      )

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
    req_body_json(
      list(
        'chemicals' = chemicals
      )
    ) |>
    req_perform()

  parsed_resp <- resp |>
    resp_body_json()

  # Check if any data was found.
  if (length(parsed_resp) > 0) {
  } else {
    cli::cli_alert_danger('No data found!') # Display an error message if no data was found.
    return(NULL) # Return NULL if no data was found.
  }

  mol_names <- parsed_resp %>%
    pluck(., 'order') %>%
    map(., ~ pluck(.x, 'chemical')) %>%
    map(., ~ keep(.x, names(.x) %in% c('sid', 'name'))) %>%
    map(., as_tibble) %>%
    list_rbind()

  similarity <- parsed_resp %>%
    pluck(., 'similarity') %>%
    map(
      .,
      ~ map(., ~ discard_at(.x, 'cl')) %>%
        list_flatten() %>%
        unname() %>%
        list_c() %>%
        replace(., . == 0, 1)
    )

  hc <- matrix(unlist(similarity), nrow = length(similarity), byrow = TRUE) %>%
    `colnames<-`(mol_names$name) %>%
    `row.names<-`(mol_names$name) %>%
    # Creates Tanimoto matrix
    {
      1 - .
    } %>%
    as.dist(.) %>%
    hclust(method = hclust_method)
  list(
    mol_names = mol_names,
    similarity = similarity,
    hc = hc
  )
}
