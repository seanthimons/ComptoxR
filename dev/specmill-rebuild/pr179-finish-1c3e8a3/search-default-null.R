# Generated with specmill; do not edit by hand.
chemi_search <- function(query = NULL, search_type = c("exact", "substructure", "similar", "mass", "hazard", "features"), similarity_type = c("tanimoto", "euclid", "tversky"), min_similarity = 0.85, hazard_name = NULL, min_toxicity = c("VH", "H", "M", "L", "A"), min_authority = c("auth", "screen", "qsar"), mass_type = c("mono", "mw", "abu"), min_mass = NULL, max_mass = NULL, filter_features = FALSE, feature_filters = NULL, element_include = NULL, element_exclude = NULL, exclude_all_others = FALSE, limit = 50, all_pages = FALSE) {
  params <- base::list("query" = query, "search_type" = search_type, "similarity_type" = similarity_type, "min_similarity" = min_similarity, "hazard_name" = hazard_name, "min_toxicity" = min_toxicity, "min_authority" = min_authority, "mass_type" = mass_type, "min_mass" = min_mass, "max_mass" = max_mass, "filter_features" = filter_features, "feature_filters" = feature_filters, "element_include" = element_include, "element_exclude" = element_exclude, "exclude_all_others" = exclude_all_others, "limit" = limit, "all_pages" = function() all_pages)
  state <- run_hook("chemi_search", "pre_request", base::list(params = params[c("query", "search_type", "similarity_type", "min_similarity", "hazard_name", "min_toxicity", "min_authority", "mass_type", "min_mass", "max_mass", "filter_features", "feature_filters", "element_include", "element_exclude", "exclude_all_others", "limit")]))
  changed <- base::intersect(base::names(params), base::names(state$params))
  changed <- base::intersect(changed, c("query", "search_type", "similarity_type", "min_similarity", "hazard_name", "min_toxicity", "min_authority", "mass_type", "min_mass", "max_mass", "filter_features", "feature_filters", "element_include", "element_exclude", "exclude_all_others", "limit"))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    .paging_arguments <- base::list(method = "POST", path = "/search", path_params = list(), 
    query = list(), body = state[["request"]][["body"]], body_media = "application/json", 
    headers = list(Accept = "application/json"), server = list(url = "http://127.0.0.1:9"), 
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", 
        relative = "/"), auth = list(), response_policy = "proof_page_response", 
    request_controls = list(preserve_errors = TRUE))
    if (params[["all_pages"]]() && TRUE) {
      result <- .ct_request_pages(function(page) base::do.call(base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), utils::modifyList(.paging_arguments, page, keep.null = TRUE), quote = TRUE),
        parameter = c("body", "offset"), start = 0, max_pages = 100L,
        mode = "offset", size_parameter = c("body", "params", "limit"), page_size = state[["request"]][["options"]][["limit"]],
        items = base::get("proof_page_items", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), completed = base::get("proof_page_done", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), advance = base::get("proof_page_advance", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE),
        error_policy = "partial", warn_limits = FALSE, warn_errors = FALSE, stop_on_empty = FALSE)
      if (!base::inherits(result, "httr2_request") && !base::is.null(result)) base::attr(result, "pagination") <- NULL
    } else {
      result <- base::do.call(base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), .paging_arguments, quote = TRUE)
    }
  }
  result
  if (base::inherits(result, "httr2_request")) base::return(result)
  if (!base::isTRUE(state$skip_request))   result <- base::get("proof_search_result", envir = base::parent.env(base::environment()), mode = "function", inherits = FALSE)(base::list(result = result, params = params))
  if (base::inherits(result, "httr2_request")) base::return(result)
  state["result"] <- base::list(result)
  result <- run_hook("chemi_search", "post_response", state)
  result
}
