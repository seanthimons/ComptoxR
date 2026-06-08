# CTS-specific route filtering used by the development stub generator.
# @keywords internal
.cts_endpoint_blacklisted <- function(route) {
  route <- as.character(route)
  route <- stringr::str_remove(route, "^/+")

  metadata_routes <- c("", "cts", "swag", "swagger", "openapi", "docs")
  pchem_domains <- c("chemaxon", "epi", "test", "testws", "opera", "measured")

  route %in% metadata_routes |
    route == "envipath/run" |
    stringr::str_detect(route, paste0("^(", paste(pchem_domains, collapse = "|"), ")(/|$)"))
}

# @keywords internal
cts_extract_smiles <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(character())
  }

  if (is.data.frame(x)) {
    smiles <- character()

    if ("smiles" %in% names(x)) {
      smiles <- c(smiles, as.character(x$smiles))
    }

    if ("chemical" %in% names(x)) {
      smiles <- c(smiles, purrr::map_chr(as.character(x$chemical), function(chemical) {
        fields <- trimws(strsplit(chemical, ";", fixed = TRUE)[[1]])
        if (length(fields) >= 6) {
          fields[[6]]
        } else {
          NA_character_
        }
      }))
    }

    return(smiles)
  }

  if (!is.list(x)) {
    return(character())
  }

  if (!is.null(x$smiles)) {
    return(as.character(x$smiles))
  }

  unlist(purrr::map(x, cts_extract_smiles), use.names = FALSE)
}

# @keywords internal
cts_resolve_smiles <- function(query, id_type = "AnyId", resolve = TRUE) {
  if (is.null(query) || length(query) == 0) {
    cli::cli_abort("{.arg query} must contain at least one value.")
  }

  query <- as.character(query)
  if (any(is.na(query) | !nzchar(query))) {
    cli::cli_abort("{.arg query} must not contain missing or empty values.")
  }

  if (!isTRUE(resolve)) {
    return(stats::setNames(query, query))
  }

  smiles <- purrr::map_chr(query, function(q) {
    resolved <- chemi_resolver_lookup(query = q, idType = id_type, mol = FALSE)
    candidates <- cts_extract_smiles(resolved)
    candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])

    if (length(candidates) == 0) {
      cli::cli_abort("Could not resolve {.val {q}} to a SMILES string.")
    }

    if (length(candidates) > 1) {
      cli::cli_abort("Resolved {.val {q}} to multiple SMILES strings; provide a SMILES string with {.code resolve = FALSE}.")
    }

    candidates[[1]]
  })

  stats::setNames(smiles, query)
}

# @keywords internal
cts_scalar_chr <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NA_character_)
  }
  paste(as.character(unlist(x, use.names = FALSE)), collapse = "; ")
}

# @keywords internal
cts_scalar_num <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(x[[1]]))
}

# @keywords internal
cts_metabolizer_tree_root <- function(x) {
  if (!is.null(x$data) && !is.null(x$data$data) && !is.null(x$data$data$id)) {
    return(x$data$data)
  }

  if (!is.null(x$outputs) && !is.null(x$outputs$tree) && is.list(x$outputs$tree)) {
    return(x$outputs$tree)
  }

  if (!is.null(x$id) && !is.null(x$data)) {
    return(x)
  }

  x
}

#' Flatten a CTS metabolizer transformation tree
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Converts the nested CTS metabolizer tree into one row per node while
#' retaining parent and child identifiers.
#'
#' @param tree Parsed CTS metabolizer response or a metabolizer tree node.
#' @param query Optional source query label to add to the result.
#'
#' @return A tibble with node IDs, parent IDs, child IDs, generation, route,
#' likelihood, production, accumulation, and SMILES columns.
#' @export
#'
#' @examples
#' \dontrun{
#' raw <- cts_metabolizer_run("CCCC", resolve = FALSE)
#' cts_flatten_metabolizer_tree(raw)
#' }
cts_flatten_metabolizer_tree <- function(tree, query = NULL) {
  root <- cts_metabolizer_tree_root(tree)

  if (is.null(root) || !is.list(root) || is.null(root$id)) {
    cli::cli_abort("{.arg tree} does not look like a CTS metabolizer tree.")
  }

  flatten_node <- function(node, parent_id = NA_character_, depth = 0L) {
    children <- node$children
    if (is.null(children)) {
      children <- list()
    }

    child_ids <- purrr::map_chr(children, function(child) {
      as.character(child$id %||% NA_character_)
    })

    node_data <- node$data
    if (is.null(node_data) || !is.list(node_data)) {
      node_data <- list()
    }

    row <- tibble::tibble(
      query = query %||% NA_character_,
      node_id = as.character(node$id),
      parent_id = parent_id,
      child_ids = list(child_ids),
      generation = cts_scalar_num(node_data$generation %||% depth),
      routes = cts_scalar_chr(node_data$routes),
      likelihood = cts_scalar_chr(node_data$likelihood),
      production = cts_scalar_num(node_data$production),
      accumulation = cts_scalar_num(node_data$accumulation),
      global_accumulation = cts_scalar_num(node_data$globalAccumulation),
      smiles = cts_scalar_chr(node_data$smiles)
    )

    child_rows <- purrr::map(
      children,
      ~ flatten_node(.x, parent_id = as.character(node$id), depth = depth + 1L)
    )

    purrr::list_rbind(c(list(row), child_rows))
  }

  flatten_node(root)
}
