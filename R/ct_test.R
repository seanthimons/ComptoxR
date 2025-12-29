#TEST----
#' Retrieve results from TEST QSAR model.
#'
#' Returns queries from TEST QSAR models with the consensus model or the most likely model being returned.
#' Calls `ct_details()` and selects the QSAR-ready SMILES formula before requesting the results. Compounds without QSAR-ready SMILES will be dropped out. Compounds where the models are unable to make a predictions will be dropped as well.
#'
#' Please refer to the TEST QSAR documentation for further details.
#'
#' @param query A list of DTXSIDs to be queried.
#' @param debug Flag to show API calls
#' @return A tibble of results.
#' @export

ct_test <- function(query, debug = FALSE) {
  df_pre <- ct_details(query) %>% dplyr::select(dtxsid, qsarReadySmiles)

  # Removes bad/ no SMILES compounds
  cat('\nRemoving bad/ no SMILES compounds\n\n')
  df <- df_pre %>% dplyr::filter(!is.na(qsarReadySmiles))
  cat('\nDropped', nrow(df_pre) - nrow(df), 'compounds.\n')

  # Converts symbols (URL encoding for SMILES)
  cat('\nConverting SMILES strings\n')
  for (i in 1:length(df$qsarReadySmiles)) {
    df$qsarReadySmiles[i] <-
      stringr::str_replace_all(df$qsarReadySmiles[i], '\\[', '%5B') %>%
      stringr::str_replace_all(., '\\]', '%5D') %>%
      stringr::str_replace_all(., '\\@', '%40') %>%
      stringr::str_replace_all(., '\\=', '%3D') %>%
      stringr::str_replace_all(., '\\.', '%2E') %>%
      stringr::str_replace_all(., '\\+', '%2B') %>%
      stringr::str_replace_all(., '\\-', '%2D') %>%
      stringr::str_replace_all(., '\\#', '%23')
  }

  url <- 'https://comptox.epa.gov/dashboard/web-test/'

  endpoints <- list(
    'LC50', #96 hour fathead minnow
    'LC50DM', #48 hour D. magna
    'IGC50', #48 hour T. pyriformis
    'LD50', #Oral rat
    'BCF', #Bioconcentration factor
    'DevTox', #Developmental toxicity
    'ER_LogRBA', #Estrogen Receptor RBA
    'ER_Binary', #Estrogen Receptor Binding
    'Mutagenicity', #Ames mutagenicity
    'BP', #Normal boiling point,
    'FP' #Flashpoint
  )

  grid <- expand.grid(endpoints, df$qsarReadySmiles) %>%
    dplyr::rename(end = Var1, sm = Var2)

  urls <- paste0(url, grid$end, '?smiles=', grid$sm)

  cat('Sending T.E.S.T request\n')

  df <- purrr::map_dfr(
    urls,
    ~ {
      if (debug == TRUE) {
        cat(.x, "\n")
      }

      # Build and perform request
      req <- httr2::request(.x) %>%
        httr2::req_method("GET")

      resp <- httr2::req_perform(req)

      # Parse JSON response
      body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
      purrr::compact(body)
    }
  )

  if ('predictions' %in% colnames(df)) {
    df <- df %>%
      tidyr::unnest(cols = predictions, names_repair = 'universal') %>%
      dplyr::filter(is.na(errorCode)) %>%
      dplyr::filter(!is.na(preferredName)) %>%
      dplyr::filter(!is.na(predValMass) | !is.na(message)) %>%
      dplyr::arrange(
        dtxsid,
        endpoint,
        factor(method, levels = c('consensus', 'hc', 'sm', 'gc', 'nn'))
      ) %>%
      dplyr::distinct(endpoint, dtxsid, .keep_all = TRUE) %>%
      dplyr::rename(compound = dtxsid)
  } else {
    df
  }

  cat('\nT.E.S.T. request complete!\n')

  return(df)
}


#' Retrieve results from OPERA QSAR model (legacy)
#'
#' Similar to ct_test but with different endpoint selection.
#'
#' @param query A list of DTXSIDs to be queried.
#' @return A tibble of results.
#' @export
ct_opera <- function(query) {
  df_pre <- ct_details(query) %>% dplyr::select(dtxsid, qsarReadySmiles)

  # Removes bad/ no SMILES compounds
  cat('Removing bad/ no SMILES compounds\n')
  df <- df_pre %>% dplyr::filter(!is.na(qsarReadySmiles))
  cat('\nDropped', nrow(df_pre) - nrow(df), 'compounds.\n')

  # Converts symbols (URL encoding for SMILES)
  cat('\nConverting SMILES strings\n')
  for (i in 1:length(df$qsarReadySmiles)) {
    df$qsarReadySmiles[i] <-
      stringr::str_replace_all(df$qsarReadySmiles[i], '\\[', '%5B') %>%
      stringr::str_replace_all(., '\\]', '%5D') %>%
      stringr::str_replace_all(., '\\@', '%40') %>%
      stringr::str_replace_all(., '\\=', '%3D') %>%
      stringr::str_replace_all(., '\\.', '%2E') %>%
      stringr::str_replace_all(., '\\+', '%2B') %>%
      stringr::str_replace_all(., '\\-', '%2D') %>%
      stringr::str_replace_all(., '\\#', '%23')
  }

  url <- 'https://comptox.epa.gov/dashboard/web-test/'

  endpoints <- list(
    'LC50', #96 hour fathead minnow
    'LC50DM', #48 hour D. magna
    'IGC50', #48 hour T. pyriformis
    'LD50', #Oral rat
    'BCF', #Bioconcentration factor
    'DevTox', #Developmental toxicity
    'ER_LogRBA', #Estrogen Receptor RBA
    'ER_Binary', #Estrogen Receptor Binding
    'Mutagenicity' #Ames mutagenicity
  )

  grid <- expand.grid(endpoints, df$qsarReadySmiles) %>%
    dplyr::rename(end = Var1, sm = Var2)

  urls <- paste0(url, grid$end, '?smiles=', grid$sm)

  cat('Sending T.E.S.T request\n')

  df <- purrr::map_dfr(
    urls,
    ~ {
      # Build and perform request
      req <- httr2::request(.x) %>%
        httr2::req_method("GET")

      resp <- httr2::req_perform(req)

      # Parse JSON response
      body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
      purrr::compact(body)
    }
  )

  if ('predictions' %in% colnames(df)) {
    df <- df %>%
      tidyr::unnest(cols = predictions, names_repair = 'universal') %>%
      dplyr::filter(is.na(errorCode)) %>%
      dplyr::filter(!is.na(preferredName)) %>%
      dplyr::select(
        molarLogUnits:preferredName,
        predValMolarLog:predValMass,
        expValMolarLog:expActive
      ) %>%
      dplyr::filter(!is.na(predValMass) | !is.na(message)) %>%
      dplyr::arrange(
        dtxsid,
        factor(endpoint, levels = endpoints),
        factor(method, levels = c('consensus', 'hc', 'sm', 'gc', 'nn'))
      ) %>%
      dplyr::distinct(endpoint, dtxsid, .keep_all = TRUE) %>%
      dplyr::rename(compound = dtxsid)
  } else {
    df
  }

  cat('\nT.E.S.T. request complete!\n')

  return(df)
}
