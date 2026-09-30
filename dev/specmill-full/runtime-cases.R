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
      # #337: valid transport stays identical; schema validation corrects invalid queries.
      if (name %in% c('chemi_resolver_lookup', 'chemi_resolver_lookupCASRN')) {
        endpoint <- sub('^.* /api/', '/chemi/', item$key)
        query <- 'DTXSID7020182'
        suffix <- if (name == 'chemi_resolver_lookup') '&idType=AnyId&fuzzy=Not&mol=FALSE' else ''
        for (value in c(query, 'caf\u00e9 +/&')) {
          probe(paste0(name, if (value == query) '-minimal' else '-encoding'),
            fun(value), list(expected('GET', endpoint, paste0('query=', curl::curl_escape(value), suffix))))
        }
        if (name == 'chemi_resolver_lookup') {
          probe(paste0(name, '-options'), fun(query, idType = 'DTXSID', fuzzy = 'Start', mol = TRUE),
            list(expected('GET', endpoint, paste0('query=', query, '&idType=DTXSID&fuzzy=Start&mol=TRUE'))))
          probe(paste0(name, '-null-options'), fun(query, idType = NULL, fuzzy = NULL, mol = NULL),
            list(expected('GET', endpoint, paste0('query=', query))))
        }
        invalid <- list(missing = list(), null = list(query = NULL), empty = list(query = character()),
          blank = list(query = ''), na = list(query = NA_character_), multiple = list(query = c('one', 'two')))
        for (variant in names(invalid)) {
          probe(paste0('corrected-', name, '-', variant), do.call(fun, invalid[[variant]]), wire = NULL, error = NULL)
        }
        next
      }
      # #337: observe the unchanged helper payload layout with corrected caller options.
      if (name %in% c('chemi_stdizer_records', 'chemi_toxprints_assays_bulk')) {
        supplied <- if (name == 'chemi_stdizer_records') {
          list(full = 'pilot-1', records = list(list(sid = 'record-1')))
        } else {
          list(acl = 'pilot-1', actives = 0, category = 'category', chemicals = list(list(sid = 'record-1')),
            id = 'id', labels = c('one', 'two'), metrics = list(score = 0), name = 'assay', total = 0)
        }
        variants <- list(omitted = supplied)
        values <- list(null = NULL, empty = list(), nested = list(flag = FALSE, count = 0, nested = list(label = 'caf\u00e9 +/&')),
          false = FALSE, zero = 0)
        for (variant in names(values)) {
          inputs <- supplied
          inputs['options'] <- values[variant]
          variants[[variant]] <- inputs
        }
        for (variant in names(variants)) {
          probe(paste0('corrected-options-', name, '-', variant), do.call(fun, variants[[variant]]), NULL)
        }
        probe(paste0('corrected-options-', name, '-http-400'), do.call(fun, variants$nested), NULL,
          '{"error":"pilot bad request"}', status = 400L, error = TRUE)
        probe(paste0(name, '-public-defaults'), fun(), error = TRUE)
        next
      }
      if (isTRUE(item$prediction_body)) {
        opera <- name == 'chemi_opera_bulk'
        inputs <- if (opera) list() else list(model_id = 1065L)
        chemicals <- list(list(id = 1L, smiles = 'CCO'), list(id = 'ext-2', smiles = 'CCCC'))
        variants <- list(smiles = c(inputs, list(smiles = c('CCO', 'CCCC'))),
          chemicals = c(inputs, list(chemicals = chemicals)),
          encoding = c(inputs, list(smiles = 'caf\u00e9 +/&')))
        for (shape in c('smiles', 'chemicals')) {
          for (value in list(empty = list(), false = FALSE, zero = 0)) {
            variant <- c(inputs, setNames(list(value), shape))
            suffix <- if (is.list(value)) 'empty' else if (identical(value, FALSE)) 'false' else 'zero'
            variants[[paste(shape, suffix, sep = '-')]] <- variant
          }
        }
        if (opera) {
          variants$options <- c(variants$smiles, list(cache_only = TRUE, format = 'csv', standardize = TRUE))
          variants$null_options <- variants$chemicals
          variants$null_options[c('cache_only', 'format', 'standardize')] <- list(NULL)
        }
        request_for <- function(supplied) {
          defaults <- if (opera) list(cache_only = FALSE, smiles = NULL, chemicals = NULL, format = 'json', standardize = FALSE) else
            list(model_id = 1065L, smiles = NULL, chemicals = NULL)
          defaults[names(supplied)] <- supplied
          body <- defaults[if (opera) c('cache_only', 'smiles', 'chemicals') else c('model_id', 'smiles', 'chemicals')]
          body <- Filter(Negate(is.null), body)
          query <- if (opera) defaults[c('format', 'standardize')] else list()
          query <- Filter(Negate(is.null), query)
          query <- paste(vapply(names(query), function(key) paste0(key, '=', curl::curl_escape(as.character(query[[key]]))), ''), collapse = '&')
          list(expected('POST', paste0('/chemi/', item$arguments$endpoint), query,
            as.character(jsonlite::toJSON(body, auto_unbox = TRUE))))
        }
        for (variant in names(variants)) {
          probe(paste0(name, '-', variant), do.call(fun, variants[[variant]]), request_for(variants[[variant]]))
        }
        invalid <- list(neither = inputs, both = c(inputs, list(smiles = 'CCO', chemicals = chemicals)),
          null = c(inputs, list(smiles = NULL, chemicals = NULL)))
        if (!opera) {
          invalid$null_model <- list(model_id = NULL, smiles = 'CCO')
          invalid$missing_model <- list(smiles = 'CCO')
        }
        for (variant in names(invalid)) {
          probe(paste0(name, '-', variant), do.call(fun, invalid[[variant]]), list(), error = TRUE)
        }
        probe(paste0(name, '-http-400'), do.call(fun, variants$smiles), request_for(variants$smiles),
          '{"error":"pilot bad request"}', status = 400L, error = TRUE)
        probe(paste0('invalid-missing-', name), fun(), list(), error = TRUE)
        next
      }
      arguments <- item$arguments
      supplied <- item$inputs
      observe <- isTRUE(item$observe)
      if (item$helper == 'generic_chemi_request' && is.null(arguments[['query']]) && !observe) {
        probe(paste0(name, '-public-defaults'), do.call(fun, supplied), error = TRUE)
        supplied[[names(formals(fun))[[1L]]]] <- 'pilot-1'
        arguments[['query']] <- 'pilot-1'
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
        if (!is.null(a$query_params)) extra <- c(extra, a$query_params)
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
            if (identical(a$body_type, 'raw_text')) {
              request <- expected(method, path, query, paste(chunk, collapse = '\n'), auth)
              request$content_type <- 'text/plain'
              return(request)
            }
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
      if (name == 'ct_bioactivity_assay_search_by_endpoint') {
        encoded <- list(endpoint = 'caf\u00e9 +/&')
        a <- arguments
        a$query_params <- encoded
        probe(paste0(name, '-encoding'), do.call(fun, encoded), wire_for(a), response)
        a$query_params <- list(endpoint = NULL)
        probe(paste0(name, '-null'), fun(NULL), wire_for(a), response)
      }
      if (name == 'ct_chemical_search_equal_bulk') {
        # With the environment unset, 1001 unique values must produce two text requests.
        values <- sprintf('record-%04d', seq_len(1001L))
        a <- arguments
        a$query <- values
        a$batch_limit <- 1000
        withr::with_envvar(c(batch_limit = NA_character_), {
          probe(paste0(name, '-default-batches'), fun(values), wire_for(a), response)
        })
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
      if (item$helper == 'generic_request' && !is.null(arguments[['query']])) {
        query_parameter <- names(supplied)[vapply(supplied, identical, FALSE, arguments[['query']])]
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
