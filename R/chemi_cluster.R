# R/chemi_cluster.R
#' Get chemical similarity map
#'
#' @param chemicals vector of chemical names
#' @param sort boolean to sort or not
#' @param hclust_method character string indicating which clustering method to use in `hclust`.
#'   Defaults to "complete". See `?hclust` for available methods.
#'
#' @return A list with `mol_names`, `similarity`, and `hc`. `mol_names` includes
#'   a `dtxsid` column when the API response provides identifiers.
#' @export

chemi_cluster <- function(
  chemicals,
  sort = TRUE,
  hclust_method = "complete"
) {
  if (is.null(sort)) {
    cli::cli_abort('Missing sort!')
  }

  cli_rule(left = "Similarity payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(chemicals)}",
      "Sort" = "{sort}"
    )
  )
  cli_rule()
  cli_end()

  parsed_resp <- chemi_resolver_getsimilaritymap(
    query = chemicals,
    idType = "DTXSID",
    sort = sort
  )

  chemi_cluster_parse_similarity_map(parsed_resp, hclust_method = hclust_method)
}

chemi_cluster_parse_similarity_map <- function(parsed_resp, hclust_method = "complete") {
  if (is.null(parsed_resp) || length(parsed_resp) == 0) {
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }

  mol_names <- chemi_cluster_mol_names(purrr::pluck(parsed_resp, 'order', .default = list()))
  similarity <- chemi_cluster_similarity(purrr::pluck(parsed_resp, 'similarity', .default = list()))

  if (nrow(mol_names) == 0 || length(similarity) == 0) {
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }

  # ! NOTE removed the %>% replace(., . == 0, 1), as that was giving false positives.

  hc <- matrix(unlist(similarity), nrow = length(similarity), byrow = TRUE) %>%
    `colnames<-`(mol_names$name) %>%
    `row.names<-`(mol_names$name) %>%
    # Creates Tanimoto matrix
    {
      1 - .
    } %>%
    stats::as.dist(.) %>%
    stats::hclust(method = hclust_method)

  # Final output -----------------------------------------------------------

  list(
    mol_names = mol_names,
    similarity = similarity,
    hc = hc
  )
}

chemi_cluster_mol_names <- function(order) {
  chemicals <- purrr::map(order, ~ purrr::pluck(.x, 'chemical', .default = list()))
  names <- purrr::map_chr(chemicals, ~ chemi_cluster_scalar(.x$name))
  dtxsids <- purrr::map_chr(chemicals, ~ chemi_cluster_scalar(.x$sid %||% .x$dtxsid %||% .x$chemId))

  if (any(!is.na(dtxsids))) {
    return(tibble::tibble(dtxsid = dtxsids, name = names))
  }

  tibble::tibble(name = names)
}

chemi_cluster_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NA_character_)
  }

  as.character(x[[1]])
}

chemi_cluster_similarity <- function(similarity) {
  purrr::map(similarity, ~ purrr::map_dbl(.x, chemi_cluster_similarity_value))
}

chemi_cluster_similarity_value <- function(cell) {
  if (!is.list(cell)) {
    return(as.numeric(cell))
  }

  if ("value" %in% names(cell)) {
    return(as.numeric(cell$value))
  }

  cell <- cell[setdiff(names(cell), "cl")]
  if (length(cell) == 0) {
    return(NA_real_)
  }

  as.numeric(unlist(cell, use.names = FALSE)[[1]])
}

#' Create a similarity list from chemical cluster data
#'
#' @description Converts a similarity matrix into a long-format data frame.
#'
#' @param chemi_cluster_data A list object containing chemical cluster data, including `mol_names` and a `similarity` matrix.
#'
#' @returns A tibble with columns for parent and child chemical identifiers, their names, and the similarity value between them. The function will error if `chemi_cluster_data` is `NULL` or missing.
#'
#' @export
chemi_cluster_sim_list <- function(chemi_cluster_data) {
  if (missing(chemi_cluster_data) || is.null(chemi_cluster_data)) {
    cli::cli_abort("Missing chemi_cluster_data!")
  }

  mol_names <- chemi_cluster_data$mol_names
  similarity <- chemi_cluster_data$similarity

  sim_list <- similarity %>%
    set_names(., mol_names$name) %>%
    map(., ~ set_names(.x, mol_names$name)) %>%
    map(., ~ enframe(.x, name = 'child', value = 'value')) %>%
    list_rbind(., names_to = 'parent') %>%
    # ! NOTE Removes perfect correlations
    filter(parent != child) #%>%
  # ! NOTE Commented out due to DTXSID not always being present.
  # left_join(., mol_names, join_by('parent' == 'name')) %>%
  # left_join(., mol_names, join_by('child' == 'name')) %>%
  # select(
  # 	parent,
  # 	parent_name = name.x,
  # 	child,
  # 	child_name = name.y,
  # 	value
  # )
  return(sim_list)
}
