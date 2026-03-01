#' PubChem Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Search the PubChem database for chemical compounds using various input types.
#' This function provides access to PubChem's PUG REST API for single compound searches.
#'
#' @param query Required parameter - the search term (e.g., compound name, CID, SMILES, InChI)
#' @param input_type Type of input provided. Options: name (default), cid, smiles, inchi, inchikey, formula
#' @param output Format for results. Options: property (default), synonyms, cids, aids, sids, description, classification, conformers
#' @param properties Optional character vector of properties to retrieve when output="property". 
#'        If NULL, returns CID by default. Common properties: MolecularFormula, MolecularWeight, 
#'        CanonicalSMILES, IsomericSMILES, InChI, InChIKey, IUPACName, XLogP, TPSA, Complexity
#' @return Returns a tibble with results. For property output, returns requested properties. 
#'         For other outputs, returns the specific data type requested.
#' @export
#'
#' @examples
#' \dontrun{
#' # Search by compound name
#' pubchem_search(query = "aspirin")
#' 
#' # Search by CID with properties
#' pubchem_search(query = "2244", input_type = "cid", 
#'                properties = c("MolecularFormula", "MolecularWeight"))
#' 
#' # Search by SMILES
#' pubchem_search(query = "CC(=O)OC1=CC=CC=C1C(=O)O", input_type = "smiles")
#' }
pubchem_search <- function(query, 
                          input_type = "name", 
                          output = "property",
                          properties = NULL) {
  
  # Input validation
  if (is.null(query) || length(query) == 0 || query == "") {
    cli::cli_abort("query must be a non-empty value")
  }
  
  # Validate input_type
  valid_input_types <- c("name", "cid", "smiles", "inchi", "inchikey", "formula")
  if (!input_type %in% valid_input_types) {
    cli::cli_abort("input_type must be one of: {paste(valid_input_types, collapse = ', ')}")
  }
  
  # Validate output
  valid_outputs <- c("property", "synonyms", "cids", "aids", "sids", "description", 
                    "classification", "conformers")
  if (!output %in% valid_outputs) {
    cli::cli_abort("output must be one of: {paste(valid_outputs, collapse = ', ')}")
  }
  
  # Build the endpoint path
  endpoint_parts <- c("compound", input_type)
  
  # Handle SMILES with special characters - use POST for complex SMILES
  if (input_type == "smiles" && grepl("[/\\\\]", query)) {
    # For SMILES with special characters, we'll use the query parameter approach
    use_post <- TRUE
  } else {
    use_post <- FALSE
    endpoint_parts <- c(endpoint_parts, utils::URLencode(query, reserved = TRUE))
  }
  
  # Add output type to endpoint
  if (output == "property") {
    endpoint_parts <- c(endpoint_parts, "property")
    # Add properties if specified
    if (!is.null(properties) && length(properties) > 0) {
      endpoint_parts <- c(endpoint_parts, paste(properties, collapse = ","))
    } else {
      # Default to CID if no properties specified
      endpoint_parts <- c(endpoint_parts, "cid")
    }
  } else {
    endpoint_parts <- c(endpoint_parts, output)
  }
  
  # Add JSON output format
  endpoint_parts <- c(endpoint_parts, "JSON")
  
  endpoint <- paste(endpoint_parts, collapse = "/")
  
  # Build query parameters for special cases (SMILES with special characters)
  query_params <- list()
  if (use_post && input_type == "smiles") {
    query_params[[input_type]] <- query
    # Remove the encoded query from endpoint since we're using query parameter
    endpoint <- gsub(paste0("/", utils::URLencode(query, reserved = TRUE)), "", endpoint)
  }
  
  # Make the request using generic_request
  # Pass query parameters via ... ellipsis (will be handled as query string parameters)
  result <- tryCatch({
    do.call(
      generic_request,
      c(
        list(
          query = NULL,  # We don't use query batching for external API
          endpoint = endpoint,
          method = "GET",
          batch_limit = 0,  # Static endpoint
          server = "https://pubchem.ncbi.nlm.nih.gov/rest/pug",
          auth = FALSE,
          tidy = TRUE
        ),
        query_params  # Add query parameters dynamically
      )
    )
  }, error = function(e) {
    cli::cli_warn("PubChem search failed: {e$message}")
    return(tibble::tibble())
  })
  
  # Post-process the result
  if (!is.null(result) && nrow(result) > 0) {
    # PubChem returns nested structures, try to flatten if needed
    if ("PropertyTable" %in% names(result)) {
      result <- result$PropertyTable
      if ("Properties" %in% names(result)) {
        result <- result$Properties[[1]]
        if (is.list(result)) {
          result <- tibble::as_tibble(result)
        }
      }
    } else if ("InformationList" %in% names(result)) {
      # Handle other output types
      result <- result$InformationList
      if ("Information" %in% names(result)) {
        info_list <- result$Information[[1]]
        if (is.list(info_list) && length(info_list) > 0) {
          result <- purrr::map_dfr(info_list, tibble::as_tibble)
        }
      }
    } else if ("IdentifierList" %in% names(result)) {
      # Handle identifier lists (CID, etc.)
      result <- result$IdentifierList
      id_field <- paste0(toupper(substring(output, 1, 1)), substring(output, 2))
      if (id_field %in% names(result)) {
        ids <- result[[id_field]][[1]]
        result <- tibble::tibble(!!output := ids)
      }
    }
  }
  
  return(result)
}


#' PubChem Bulk Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Perform bulk searches on the PubChem database for multiple chemical compounds.
#' This function provides batch querying capability for PubChem's PUG REST API.
#'
#' @param queries Required parameter - character vector of search terms
#' @param input_type Type of input provided. Options: name (default), cid, smiles, inchi, inchikey, formula
#' @param output Format for results. Options: property (default), synonyms, cids, aids, sids
#' @param properties Optional character vector of properties to retrieve when output="property". 
#'        If NULL, returns CID by default. Common properties: MolecularFormula, MolecularWeight, 
#'        CanonicalSMILES, IsomericSMILES, InChI, InChIKey, IUPACName, XLogP, TPSA, Complexity
#' @return Returns a tibble with results for all queries. Includes a query column to track input.
#' @export
#'
#' @examples
#' \dontrun{
#' # Search multiple compounds by name
#' pubchem_search_bulk(queries = c("aspirin", "caffeine", "glucose"))
#' 
#' # Search multiple CIDs with properties
#' pubchem_search_bulk(queries = c("2244", "2519", "5793"), 
#'                     input_type = "cid",
#'                     properties = c("MolecularFormula", "MolecularWeight"))
#' }
pubchem_search_bulk <- function(queries, 
                               input_type = "name", 
                               output = "property",
                               properties = NULL) {
  
  # Input validation
  if (is.null(queries) || length(queries) == 0) {
    cli::cli_abort("queries must be a non-empty character vector")
  }
  
  # Validate input_type
  valid_input_types <- c("name", "cid", "smiles", "inchi", "inchikey", "formula")
  if (!input_type %in% valid_input_types) {
    cli::cli_abort("input_type must be one of: {paste(valid_input_types, collapse = ', ')}")
  }
  
  # Validate output
  valid_outputs <- c("property", "synonyms", "cids", "aids", "sids")
  if (!output %in% valid_outputs) {
    cli::cli_abort("output must be one of: {paste(valid_outputs, collapse = ', ')}")
  }
  
  # Remove duplicates and empty values (including whitespace-only strings)
  queries <- unique(queries[!is.na(queries) & trimws(queries) != ""])
  
  if (length(queries) == 0) {
    cli::cli_warn("No valid queries provided after filtering")
    return(tibble::tibble())
  }
  
  # For bulk searches, we use POST with listkey mechanism or individual searches
  # PubChem's bulk API is complex, so we'll use individual searches with rate limiting
  
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))
  
  if (run_verbose) {
    cli::cli_alert_info("Performing bulk search for {length(queries)} compounds...")
  }
  
  # Perform individual searches with progress tracking
  results <- purrr::map_dfr(queries, function(q) {
    # Add small delay to respect PubChem rate limits 
    # (max 5 requests per second = 0.2s per request, using 0.21s for safety margin)
    Sys.sleep(0.21)
    
    result <- pubchem_search(
      query = q,
      input_type = input_type,
      output = output,
      properties = properties
    )
    
    # Add query identifier
    if (!is.null(result) && nrow(result) > 0) {
      result <- dplyr::mutate(result, query_input = q, .before = 1)
    } else {
      # Return empty row with query identifier if no results
      result <- tibble::tibble(query_input = q)
    }
    
    return(result)
  }, .progress = run_verbose)
  
  return(results)
}
