# Development-only PubChem request and cache bindings; runtime policy is client-owned.
pc_owner <- function(operation) quote(.ComptoxREnv)
pc_headers <- function(operation) quote(.ct_pc_headers())
pc_search_method <- function(operation) {
  quote(
    if (
      params[["type"]] %in%
        c("smiles", "inchi")
    ) {
      "POST"
    } else {
      "GET"
    }
  )
}
pc_search_path <- function(operation) {
  quote(
    if (
      params[["type"]] %in%
        c("smiles", "inchi")
    ) {
      "/compound/{namespace}/cids/JSON"
    } else {
      "/compound/{namespace}/{query}/cids/JSON"
    }
  )
}
pc_search_path_params <- function(operation) {
  quote(
    if (
      params[["type"]] %in%
        c("smiles", "inchi")
    ) {
      list(namespace = params[["type"]])
    } else {
      list(namespace = params[["type"]], query = params[["query"]])
    }
  )
}
pc_search_body <- function(operation) {
  quote(
    if (
      params[["type"]] %in%
        c("smiles", "inchi")
    ) {
      stats::setNames(list(params[["query"]]), params[["type"]])
    } else {
      NULL
    }
  )
}
pc_search_parameters <- function(operation) {
  quote(
    if (
      params[["type"]] %in%
        c("smiles", "inchi")
    ) {
      list()
    } else {
      list(list(
        name = "query",
        location = "path",
        style = "simple",
        explode = FALSE,
        schema = list(type = "string"),
        required = TRUE
      ))
    }
  )
}
pc_items_method <- function(operation) {
  quote(if (length(cache_state$pending) > 1L) "POST" else "GET")
}
pc_properties_path <- function(operation) {
  quote(paste0(
    if (length(cache_state$pending) > 1L) {
      "/compound/cid/property/"
    } else {
      "/compound/cid/{cid}/property/"
    },
    paste(sort(params[["properties"]]), collapse = ","),
    "/JSON"
  ))
}
pc_synonyms_path <- function(operation) {
  quote(
    if (length(cache_state$pending) > 1L) {
      "/compound/cid/synonyms/JSON"
    } else {
      "/compound/cid/{cid}/synonyms/JSON"
    }
  )
}
pc_items_path_params <- function(operation) {
  quote(
    if (length(cache_state$pending) > 1L) {
      list()
    } else {
      list(cid = as.character(params[["cid"]]))
    }
  )
}
pc_items_body <- function(operation) {
  quote(
    if (length(cache_state$pending) > 1L) {
      list(cid = paste(params[["cid"]], collapse = ","))
    } else {
      NULL
    }
  )
}
pc_search_response <- function(operation) {
  quote(function(response, context, decode) {
    .ct_pc_response(
      response,
      context,
      decode,
      "cids",
      c("IdentifierList", "CID"),
      FALSE
    )
  })
}
pc_properties_response <- function(operation) {
  quote(function(response, context, decode) {
    .ct_pc_response(
      response,
      context,
      decode,
      paste0("property/", paste(sort(params[["properties"]]), collapse = ",")),
      c("PropertyTable", "Properties"),
      TRUE
    )
  })
}
pc_synonyms_response <- function(operation) {
  quote(function(response, context, decode) {
    .ct_pc_response(
      response,
      context,
      decode,
      "synonyms",
      c("InformationList", "Information"),
      FALSE
    )
  })
}
preserve_pubchem_docs <- function(operation) {
  operation <- preserve_choice_defaults(operation)
  operation$markdown <- TRUE
  operation
}
