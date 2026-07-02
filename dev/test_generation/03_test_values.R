# Test value selection for generated wrapper calls.

tg_r_literal <- function(value) {
  if (is.null(value)) {
    return("NULL")
  }
  paste(deparse(value, width.cutoff = 500), collapse = " ")
}

tg_value_for_param <- function(param_name) {
  name <- tolower(param_name)

  if (name %in% c("query", "queries", "id", "ids", "dtxsid", "sid", "gsid")) {
    return("DTXSID7020182")
  }
  if (name %in% c("dtxcid", "cid_dtxcid")) {
    return("DTXCID30182")
  }
  if (name %in% c("cas", "casrn", "cas_rn", "rn")) {
    return("80-05-7")
  }
  if (name %in% c("smiles", "structure")) {
    return("CCCC")
  }
  if (name %in% c("inchi")) {
    return("InChI=1S/C4H10/c1-3-4-2/h3-4H2,1-2H3")
  }
  if (name %in% c("inchikey")) {
    return("IJDNQMDRQITEOD-UHFFFAOYSA-N")
  }
  if (name %in% c("formula", "exact_formula", "msready_formula")) {
    return("C6H6")
  }
  if (name %in% c("cid")) {
    return(2244L)
  }
  if (grepl("mass|weight|logp|ws|similarity|threshold|score", name)) {
    return(1.2)
  }
  if (grepl("limit|offset|page|size|count|top|skip|start|end|aeid|m4id|spid|id$", name)) {
    return(1L)
  }
  if (grepl("full|labels|empty|inclusive|sort|coerce|extract|return|resolve|cache|tidy|all_pages", name)) {
    return(FALSE)
  }
  if (name %in% c("params", "options", "extra_options", "body")) {
    return(list())
  }
  if (name %in% c("idtype", "ids_type", "id_type", "idstype")) {
    return("AnyId")
  }
  if (name %in% c("projection")) {
    return("chemicaldetailall")
  }
  if (name %in% c("property_name", "property", "properties")) {
    return("MolecularWeight")
  }
  if (name %in% c("list_name", "listname")) {
    return("PRODWATER")
  }
  if (name %in% c("medium")) {
    return("water")
  }
  if (name %in% c("study_id", "studyid")) {
    return("12345")
  }
  if (name %in% c("study_type", "studytype")) {
    return("acute")
  }
  if (name %in% c("category", "supercategory", "domain", "section", "profile", "model", "methodology")) {
    return("general")
  }
  if (name %in% c("search_type", "input_type", "namespace", "operation", "output", "report")) {
    return("JSON")
  }

  "DTXSID7020182"
}

tg_build_wrapper_call_args <- function(metadata) {
  args <- list()
  values <- list()

  for (formal in metadata$formals) {
    if (!isTRUE(formal$required) || identical(formal$name, "...")) {
      next
    }

    value <- tg_value_for_param(formal$name)
    values[[formal$name]] <- value
    args[[formal$name]] <- tg_r_literal(value)
  }

  # PubChem wrappers contain conditional GET/POST branches. Metadata extraction
  # records the first helper call in the function body, so choose inputs that
  # exercise that branch in the generated offline contract.
  if (metadata$function_name %in% c("pubchem_properties", "pubchem_synonyms") && "cid" %in% names(metadata$formals)) {
    values[["cid"]] <- c(2244L, 6623L)
    args[["cid"]] <- "c(2244L, 6623L)"
  }
  if (identical(metadata$function_name, "pubchem_search")) {
    values[["query"]] <- "CCCC"
    args[["query"]] <- "\"CCCC\""
    values[["type"]] <- "smiles"
    args[["type"]] <- "\"smiles\""
  }

  # Safety toggles that prevent generated tests from using live resolver/cache paths.
  if ("resolve" %in% names(metadata$formals) && !"resolve" %in% names(args)) {
    values[["resolve"]] <- FALSE
    args[["resolve"]] <- "FALSE"
  }
  if ("cache" %in% names(metadata$formals) && !"cache" %in% names(args)) {
    values[["cache"]] <- FALSE
    args[["cache"]] <- "FALSE"
  }

  list(args = args, values = values)
}

tg_render_wrapper_call <- function(function_name, call_args) {
  if (length(call_args$args) == 0) {
    return(paste0(function_name, "()"))
  }

  rendered_args <- sprintf("%s = %s", names(call_args$args), unlist(call_args$args, use.names = FALSE))
  paste0(function_name, "(", paste(rendered_args, collapse = ", "), ")")
}
