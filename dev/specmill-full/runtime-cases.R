# Inserted into the existing installed-client localhost verifier before snapshots.
# Expectations use frozen original helper calls, never generated wrapper output.
full_failures <- list()
for (name in names(full_cases)) {
  item <- full_cases[[name]]
  failure <- tryCatch(
    {
      fun <- getExportedValue('ComptoxR', name)
      if (isTRUE(item$hook_owned)) {
        engine <- sub('^chemi_', '', sub('_bulk$', '', name))
        input <- names(formals(fun))[[1L]]
        supplied <- setNames(list('DTXSID7020182'), input)
        options <- switch(engine,
          padel = list(x2d = FALSE, x3d = TRUE, fp = TRUE, headers = TRUE, timeout = 30),
          rdkit = list(type = 'ecfp', radius = 2, bits = 2),
          mordred = list(headers = TRUE, inchi = FALSE),
          webtest = list(headers = TRUE),
          webtest_predict = if (endsWith(name, '_bulk')) list(endpoints = 'LC50', methods = 'consensus') else list(endpoint = 'LC50', method = 'consensus')
        )
        supplied <- c(supplied, options)
        response <- if (engine == 'webtest_predict') {
          '{"chemicals":[{"chemical":{"smiles":"CCO"},"endpoints":[{"endpoint":{"id":"LC50"},"predicted":[{"method":"consensus","value":3.241}]}]}]}'
        } else '{"headers":["a","b"],"chemicals":[{"smiles":"CCO","descriptors":[1,2]}]}'
        testthat::with_mocked_bindings({
          first <- length(results)
          probe(paste0(name, '-resolved-options'), do.call(fun, supplied), NULL, response)
          captured <- results[[length(results)]]$requests
          stopifnot(length(captured) == 1L,
            identical(captured[[1L]]$method, sub(' .*', '', item$key)),
            identical(captured[[1L]]$path, sub('^.* /api/', '/chemi/', item$key)))
          raw <- supplied
          raw$output <- 'raw'
          probe(paste0(name, '-raw'), do.call(fun, raw), NULL, response)
          if (engine == 'webtest_predict') {
            omitted <- supplied
            omitted[c('endpoint', 'endpoints')] <- NULL
            probe(paste0(name, '-missing-endpoint'), do.call(fun, omitted), list(), response, error = TRUE)
          }
          skipped <- supplied
          skipped[[input]] <- NA_character_
          probe(paste0(name, '-skip'), do.call(fun, skipped), list(), response)
          # Resolver failures must also skip transport and run the post chain.
          skipped[[input]] <- 'DTXSID0000000'
          probe(paste0(name, '-unresolved'), do.call(fun, skipped), list(), response)
          probe(paste0('invalid-missing-', name), do.call(fun, list()), error = TRUE)
          # Server provenance contains each process's random localhost port.
          normalize_server <- function(x) {
            if (is.character(x)) x[] <- gsub(base, 'http://localhost', x, fixed = TRUE)
            if (is.list(x)) x[] <- lapply(x, normalize_server)
            attributes(x) <- lapply(attributes(x), normalize_server)
            x
          }
          for (i in seq.int(first + 1L, length(results))) results[[i]]$value <- normalize_server(results[[i]]$value)
        }, chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
          lapply(ids, function(id) if (id == 'DTXSID0000000') list(result = 'NOT_FOUND') else
            list(result = 'FOUND', chemical = list(sid = id, canonicalSmiles = 'CCO')))
        }, .package = 'ComptoxR')
        next
      }
      arguments <- item$arguments
      supplied <- item$inputs
      observe <- isTRUE(item$observe)
      if (item$helper == 'generic_chemi_request' && is.null(arguments$query) && !observe) {
        probe(paste0(name, '-public-defaults'), do.call(fun, supplied), error = TRUE)
        supplied[[names(formals(fun))[[1L]]]] <- 'pilot-1'
        arguments$query <- 'pilot-1'
      }
      wire_for <- function(a) {
        if (observe) {
          return(NULL)
        }
        if (item$helper == 'generic_chemi_request') {
          stopifnot(identical(a$wrap, FALSE), identical(a$query, 'pilot-1'))
          return(list(expected('POST', paste0('/chemi/', a$endpoint), body = '[{"sid":"pilot-1"}]')))
        }
        server <- if (is.null(a$server)) 'ctx_burl' else a$server
        prefix <- switch(
          server,
          ctx_burl = '/ctx/',
          chemi_burl = '/chemi/',
          epi_burl = '/epi/',
          stop('Unreviewed server')
        )
        auth <- if (is.null(a$auth)) TRUE else a$auth
        method <- a$method
        stopifnot(method %in% c('GET', 'POST'))
        extra <- a[setdiff(names(a), names(formals(get('generic_request', asNamespace('ComptoxR')))))]
        has_query_arguments <- length(extra) > 0L
        extra <- extra[!vapply(extra, is.null, FALSE)]
        query <- paste(
          vapply(
            names(extra),
            function(key) {
              paste0(curl::curl_escape(key), '=', curl::curl_escape(as.character(extra[[key]])))
            },
            ''
          ),
          collapse = '&'
        )
        path <- paste0(prefix, a$endpoint)
        if (method == 'POST') {
          chunks <- split(unique(a$query), ceiling(seq_along(unique(a$query)) / a$batch_limit))
          return(unname(lapply(chunks, function(chunk) {
            expected(method, path, query, as.character(jsonlite::toJSON(unname(chunk), auto_unbox = FALSE)), auth)
          })))
        }
        if (a$batch_limit == 0) {
          return(list(expected(method, path, query, auth = auth)))
        }
        stopifnot(a$batch_limit == 1)
        lapply(unique(a$query), function(value) {
          encoded <- curl::curl_escape(value)
          # Existing httr2 query updates preserve a slash in the path when query parameters exist.
          if (has_query_arguments) {
            encoded <- gsub('%2F', '/', encoded, fixed = TRUE)
          }
          expected(method, paste0(sub('/$', '', path), '/', encoded), query, auth = auth)
        })
      }
      wire <- wire_for(arguments)
      response <- if (isTRUE(arguments$paginate)) '[]' else '[{"id":"pilot-response"}]'
      probe(paste0(name, '-minimal'), do.call(fun, supplied), wire, response)
      for (variant in names(item$variants)) {
        probe(paste0(name, '-', variant), do.call(fun, item$variants[[variant]]), NULL, response)
      }
      # Wrappers that fix max_pages internally cannot be bounded; the minimal probe covers page one.
      if (isTRUE(arguments$paginate) && 'max_pages' %in% names(formals(fun))) {
        bounded <- supplied
        bounded$max_pages <- 2
        second <- arguments
        second$pageNumber <- arguments$pageNumber + 1
        probe(
          paste0(name, '-pagination'),
          do.call(fun, bounded),
          c(wire, wire_for(second)),
          '[{"id":"pilot-response"}]'
        )
      }
      # Paginated helpers intentionally return collected results on request errors;
      # their retained behavior is exercised by the existing pagination suite.
      if (!isTRUE(arguments$paginate)) {
        probe(
          paste0(name, '-http-400'),
          do.call(fun, supplied),
          wire,
          '{"error":"pilot bad request"}',
          status = 400L,
          error = TRUE
        )
      }
      if (length(item$required)) {
        probe(paste0('invalid-missing-', name), do.call(fun, list()), error = TRUE)
      }
      if (item$helper == 'generic_request' && !is.null(arguments$query)) {
        query_parameter <- names(supplied)[vapply(supplied, identical, FALSE, arguments$query)]
        stopifnot(length(query_parameter) == 1L)
        empty <- supplied
        empty[[query_parameter]] <- character()
        probe(paste0('invalid-empty-', name), do.call(fun, empty), error = TRUE)
        encoded <- supplied
        encoded[[query_parameter]] <- 'caf\u00e9 +/&'
        a <- arguments
        a$query <- encoded[[query_parameter]]
        probe(paste0(name, '-encoding'), do.call(fun, encoded), wire_for(a), response)
        # The original paginated helper requests only the first query of a batch, so
        # batching is probed for non-paginated wrappers only.
        if (!isTRUE(arguments$paginate)) {
          batched <- supplied
          batched[[query_parameter]] <- c('record 1', 'record 2', 'record 1', 'record 3')
          a$query <- batched[[query_parameter]]
          probe(paste0(name, '-batches'), do.call(fun, batched), wire_for(a), response)
        }
      }
      NULL
    },
    error = identity
  )
  if (inherits(failure, 'error')) full_failures[[name]] <- conditionMessage(failure)
}
