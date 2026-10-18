# Generated with specmill; do not edit by hand.
chemi_resolver_getpubchemlist <- function(query, idType = "AnyId", section = NULL, all_pages = TRUE, max_pages = 100) {
  params <- base::c(base::list("query" = query, "idType" = idType, "section" = section, "all_pages" = all_pages, "max_pages" = max_pages), list(chemicals = NULL))
  state <- run_hook("chemi_resolver_getpubchemlist", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) base::return(state$result)
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  .paging_arguments <- base::list(method = "POST", path = "/resolver/getpubchemlist", 
    path_params = list(), query = list(), body = local({
        chemicals <- params[["chemicals"]]
        if (!is.list(chemicals) || !length(chemicals)) {
            query <- unique(as.vector(params[["query"]]))
            query <- query[!is.na(query) & query != ""]
            if (!length(query)) 
                cli::cli_abort("Either query or chemicals parameter must be provided.")
            chemicals <- lapply(query, function(id) list(sid = id))
        }
        options <- structure(list(), names = character())
        if (!is.null(params[["section"]])) 
            options$section <- params[["section"]]
        list(chemicals = chemicals, options = options)
    }), body_media = "application/json", headers = list(Accept = "application/json"), 
    server = list(url = "http://127.0.0.1:9"), server_resolver = list(name = ".ct_server_url", 
        key = "chemi_burl", relative = "/"), auth = list(), response_policy = "proof_page_response", 
    request_controls = list(preserve_errors = TRUE))
  if (params[["all_pages"]] && TRUE) {
    result <- .ct_request_pages(function(page) base::do.call(base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), utils::modifyList(.paging_arguments, page, keep.null = TRUE), quote = TRUE),
      parameter = c("body", "offset"), start = 0, max_pages = params[["max_pages"]],
      mode = "offset", size_parameter = c("body", "options", "limit"), page_size = 100,
      items = base::get("proof_page_items", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), completed = base::get("proof_page_done", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), advance = base::get("proof_page_advance", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE),
      error_policy = "partial", warn_limits = FALSE, warn_errors = FALSE, stop_on_empty = FALSE)
    if (!base::inherits(result, "httr2_request") && !base::is.null(result)) base::attr(result, "pagination") <- NULL
  } else {
    result <- base::do.call(base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE), .paging_arguments, quote = TRUE)
  }
  result
  if (base::inherits(result, "httr2_request")) base::return(result)
  base::get("proof_pubchem_result", envir = base::parent.env(base::environment()), mode = "function", inherits = FALSE)(base::list(result = result, params = params))
}
