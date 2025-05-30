#' EPI Suite searching for Analysis function
#'
#' @param query A vector
#'
#' @returns tibble

epi_suite_search <- function(query) {
  req_list <- map(
    query,
    ~ {
      request(
        base_url = Sys.getenv('epi_burl')
      ) %>%
        req_url_path_append("/search") %>%
        req_url_query(query = .x)
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
      ~ map(
        .x,
        ~ if (is.null(.x)) {
          NA
        } else {
          .x
        }
      ) %>%
        as_tibble
    ) %>%
    compact()

  {
    cli::cli_rule(left = 'EPI Suite compound searching')
    cli::cli_dl()
    cli::cli_li(
      c('Compounds requested' = "{length(query)}")
    )
    cli::cli_li(
      c('Compounds found' = "{length(df)}")
    )
    cli::cli_end()
    cli::cat_line()
  }

  if (length(df) > 0) {
    return(df)
  } else {
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }
}

epi_suite_analysis <- function(query) {
  query_list <- unique(as.vector(query)) %>%
    as.list() %>%
    set_names(., unique(as.vector(query)))

  #Chose to have the data be pulled as a tibble rather than a list for diagnositic purposes

  query_list <- epi_suite_search(query_list) %>%
    map(., ~ pull(.x, 'cas'))

  req_list <- map(
    query_list,
    ~ {
      request(base_url = Sys.getenv('epi_burl')) %>%
        req_url_path_append("/submit") %>%
        req_url_query(cas = .x)
    }
  )

  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  df <- resps %>%
    set_names(query_list) %>%
    resps_successes() %>%
    map(., ~ resp_body_json(.x))

  return(df)
}

#' Title
#'
#' @param response
#' @param endpoints
#'
#' @returns
#' @export

epi_suite_pull_data <- function(epi_obj, endpoints = NULL) {
  if (missing(epi_obj)) {
    cli::cli_abort('Please provide raw analysis object')
  }
  if (missing(endpoints) | is.null(endpoints)) {
    cli::cli_abort("Missing aggregaion endpoint")
  }

  df <- switch(
    endpoints,
    'eco' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c("ecosar")) %>%
              pluck(., 'ecosar', 'modelResults') %>%
              map(
                .,
                ~ modify_in(
                  .,
                  'flags',
                  ~ list_simplify(.x) %>%
                    paste(., collapse = " ")
                )
              ) %>%
              map(., as_tibble) %>%
              list_rbind() %>%
              mutate(
                across(everything(), as.character),
                across(everything(), ~ na_if(.x, ""))
              )
          }
        ) %>%
        list_rbind(names_to = 'raw_search')
    },
    'fate' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c(""))
          }
        )
    },
    'transport' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c(""))
          }
        )
    },
    'treatment' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c(""))
          }
        )
    },
    'analogs' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c("analogs"))
          }
        )
    },
    'water' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c(""))
          }
        )
    },
    'air' = {
      epi_obj %>%
        map(
          .,
          ~ {
            keep(., names(.x) %in% c(""))
          }
        )
    }
  )

  return(df)
}

#q3 <- epi_suite_pull_data(epi_obj = q2, endpoints = 'eco')
#q3 <- epi_suite_pull_data(epi_obj = q2, endpoints = 'analogs')
