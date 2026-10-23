.pubchem_valid_properties <- c("MolecularFormula", "MolecularWeight",
    "CanonicalSMILES", "IsomericSMILES", "InChI", "InChIKey",
    "IUPACName", "XLogP", "ExactMass", "MonoisotopicMass", "TPSA",
    "Complexity", "Charge", "HBondDonorCount", "HBondAcceptorCount",
    "RotatableBondCount", "HeavyAtomCount", "IsotopeAtomCount",
    "AtomStereoCount", "DefinedAtomStereoCount", "UndefinedAtomStereoCount",
    "BondStereoCount", "DefinedBondStereoCount", "UndefinedBondStereoCount",
    "CovalentUnitCount", "Volume3D", "XStericQuadrupole3D", "YStericQuadrupole3D",
    "ZStericQuadrupole3D", "FeatureCount3D", "FeatureAcceptorCount3D",
    "FeatureDonorCount3D", "FeatureAnionCount3D", "FeatureCationCount3D",
    "FeatureRingCount3D", "FeatureHydrophobeCount3D", "ConformerModelRMSD3D",
    "EffectiveRotorCount3D", "ConformerCount3D", "Fingerprint2D")
.pubchem_default_properties <- c("MolecularFormula", "MolecularWeight",
    "CanonicalSMILES", "InChI", "InChIKey", "XLogP", "TPSA",
    "HBondDonorCount", "HBondAcceptorCount", "Complexity", "ExactMass",
    "MonoisotopicMass", "HeavyAtomCount")
.ct_pc_type <- function(type) {
  match.arg(type, c('name', 'smiles', 'inchi', 'inchikey', 'formula'))
}
.ct_pc_query <- function(query) {
  if (
    !is.character(query) || length(query) != 1 || is.na(query) || !nzchar(query)
  ) {
    cli::cli_abort('{.arg query} must be a single non-empty character string.')
  }
  query
}
.ct_pc_properties <- function(properties) {
  if (is.null(properties)) {
    properties <- .pubchem_default_properties
  }
  invalid <- setdiff(properties, .pubchem_valid_properties)
  if (length(invalid) > 0) {
    cli::cli_abort('Invalid PubChem property name{?s}: {.val {invalid}}')
  }
  properties
}
.ct_pc_cid <- function(cid) {
  cid <- as.integer(cid)
  cid <- cid[!is.na(cid)]
  if (length(cid) == 0) {
    cli::cli_abort('{.arg cid} must contain at least one valid integer CID.')
  }
  cid
}
.ct_pc_search_key <- function(data) {
  paste0(data$params$type, ':', data$params$query)
}
.ct_pc_property_key <- function(data) {
  paste0(data$input, '|', paste(sort(data$params$properties), collapse = ','))
}
.ct_pc_synonym_key <- function(data) as.character(data$input)
.ct_pc_property_entries <- function(data) {
  if (!nrow(data$result)) {
    return(list())
  }
  out <- lapply(seq_len(nrow(data$result)), function(i) {
    data$result[i, , drop = FALSE]
  })
  names(out) <- paste0(
    data$result$CID,
    '|',
    paste(sort(data$params$properties), collapse = ',')
  )
  out
}
.ct_pc_synonym_entries <- function(data) {
  out <- data$result
  names(out) <- vapply(out, function(info) as.character(info$CID), '')
  out
}
.ct_pc_property_combine <- function(data) {
  dplyr::bind_rows(data$cached, data$result)
}
.ct_pc_synonym_combine <- function(data) c(data$cached, data$result)
.ct_pc_properties_result <- function(data) {
  if (length(data$pending) > 1L) {
    dplyr::bind_rows(purrr::compact(data$result))
  } else {
    data$result
  }
}
.ct_pc_synonyms_result <- function(data) {
  if (length(data$pending) > 1L) {
    purrr::list_flatten(data$result)
  } else {
    data$result
  }
}
.ct_pc_search_result <- function(data) {
  result <- data$result
  if (length(result) == 0) {
    cli::cli_warn(
      'No PubChem CIDs found for {.val {data$params$query}} (type: {data$params$type})'
    )
    return(tibble::tibble(cid = integer(0)))
  }
  cids <- as.integer(unlist(result))
  if (length(cids) > 10) {
    cli::cli_inform('{length(cids)} CIDs found for {.val {data$params$query}}')
  }
  tibble::tibble(cid = cids)
}
.ct_pc_synonyms_project <- function(data) {
  info <- data$result
  tidy <- data$params$tidy()
  if (length(info) == 0) {
    return(
      if (tidy) {
        tibble::tibble(cid = integer(0), synonym = character(0))
      } else {
        list()
      }
    )
  }
  if (!tidy) {
    return(info)
  }
  purrr::map_dfr(info, function(item) {
    synonyms <- item$Synonym %||% character(0)
    if (length(synonyms) == 0) {
      return(tibble::tibble(cid = integer(0), synonym = character(0)))
    }
    tibble::tibble(cid = as.integer(item$CID), synonym = as.character(synonyms))
  })
}
.ct_pc_response <- function(
  response,
  context,
  decode,
  operation,
  pluck_path,
  tidy
) {
  if (context$status == 401L) {
    return(decode())
  }
  empty <- function() if (tidy) tibble::tibble() else list()
  if (context$status < 200L || context$status >= 300L) {
    fault_body <- tryCatch(
      httr2::resp_body_json(response),
      error = function(e) NULL
    )
    if (!is.null(fault_body$Fault)) {
      cli::cli_warn(
        'PubChem [{fault_body$Fault$Code}]: {fault_body$Fault$Message}'
      )
    } else {
      cli::cli_warn('PubChem request failed with HTTP {context$status}')
    }
    return(empty())
  }
  body <- tryCatch(httr2::resp_body_json(response), error = function(e) {
    cli::cli_warn('Failed to parse PubChem response as JSON: {e$message}')
    NULL
  })
  if (is.null(body)) {
    return(empty())
  }
  if (!is.null(body$Fault)) {
    cli::cli_warn('PubChem [{body$Fault$Code}]: {body$Fault$Message}')
    return(empty())
  }
  result <- purrr::pluck(body, !!!pluck_path, .default = NULL)
  if (is.null(result)) {
    cli::cli_warn(
      'Unexpected PubChem response structure for {.val {operation}}'
    )
    return(empty())
  }
  if (!tidy) {
    return(result)
  }
  if (is.list(result) && length(result) > 0) {
    if (is.list(result[[1]])) {
      return(safe_tidy_bind(result))
    }
    return(tibble::tibble(value = unlist(result)))
  }
  if (is.atomic(result)) {
    return(tibble::tibble(value = result))
  }
  tibble::tibble()
}
.ct_pc_retry <- function(response) {
  httr2::resp_status(response) %in% c(429L, 500L, 503L, 504L)
}
.ct_pc_headers <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion('ComptoxR')),
    error = function(e) 'dev'
  )
  list(
    `User-Agent` = paste0(
      'ComptoxR/',
      version,
      ' (https://github.com/seanthimons/ComptoxR)'
    )
  )
}
