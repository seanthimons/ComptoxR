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
      # #337: preserve explicit objects, including the EPI schema-array discrepancy.
      if (isTRUE(item$request_body)) {
        epi <- name == 'epi_submit_batch'
        fields <- names(item$variants$explicit)
        required <- if (epi) 'modules' else c('error', 'masses')
        minimal <- if (epi) list(modules = c('logKow', 'physicalProperties')) else list(error = 0, masses = c(200.9, 200.95))
        variants <- list(minimal = minimal, explicit = item$variants$explicit)
        for (variant in c('null', 'false', 'zero', 'empty', 'encoding')) {
          value <- switch(variant, null = NULL, false = FALSE, zero = 0, empty = list(), encoding = 'caf\u00e9 +/&')
          variants[[variant]] <- setNames(rep(list(value), length(fields)), fields)
        }
        wire_for_body <- function(inputs) {
          body <- if (epi) list(modules = NULL, vaporPressureTemperatureC = 25) else list()
          body[names(inputs)] <- inputs
          body <- Filter(Negate(is.null), body[intersect(fields, names(body))])
          list(expected('POST', paste0('/ctx/', item$arguments$endpoint),
            body = as.character(jsonlite::toJSON(if (length(body)) body else list(), auto_unbox = TRUE, digits = 22)), auth = TRUE))
        }
        for (variant in names(variants)) {
          probe(paste0(name, '-', variant), do.call(fun, variants[[variant]]), wire_for_body(variants[[variant]]))
        }
        for (setting in c(NA_character_, '2', '0', '1001')) {
          withr::with_envvar(c(batch_limit = setting), {
            probe(paste0(name, '-batch-limit-', if (is.na(setting)) 'default' else setting),
              do.call(fun, minimal), wire_for_body(minimal))
          })
        }
        for (field in required) {
          inputs <- minimal
          inputs[[field]] <- NULL
          probe(paste0(name, '-missing-', field), do.call(fun, inputs), list(), error = TRUE)
        }
        probe(paste0(name, '-missing-all'), fun(), list(), error = TRUE)
        probe(paste0(name, '-http-400'), do.call(fun, minimal), wire_for_body(minimal),
          '{"error":"pilot bad request"}', status = 400L, error = TRUE)
        next
      }
      if (isTRUE(item$mass_range)) {
        endpoint <- '/ctx/chemical/msready/search/by-mass/'
        for (variant in c('omitted', 'null', 'explicit', 'false', 'zero', 'vector')) {
          end <- switch(variant, omitted =, null = NULL, explicit = 200.95, false = FALSE, zero = 0, vector = c(201, 202))
          inputs <- list(start = 200.9)
          if (variant != 'omitted') inputs['end'] <- list(end)
          suffix <- if (is.null(end)) '' else paste0('/', paste(end, collapse = '/'))
          probe(paste0(name, '-', variant), do.call(fun, inputs),
            list(expected('GET', paste0(endpoint, '200.9', suffix), auth = TRUE)))
        }
        probe(paste0(name, '-start-encoding'), fun('caf\u00e9 +/&'), NULL)
        probe(paste0(name, '-end-encoding'), fun(200.9, 'end +/&'), list(), error = TRUE)
        probe(paste0(name, '-null-start'), fun(NULL), list(), error = TRUE)
        probe(paste0(name, '-empty-start'), fun(character()), list(), error = TRUE)
        probe(paste0(name, '-missing-start'), fun(), list(), error = TRUE)
        probe(paste0(name, '-batched-end'), fun(c(200, 201), 202), list(), error = TRUE)
        probe(paste0(name, '-http-400'), fun(200.9), list(expected('GET', paste0(endpoint, '200.9'), auth = TRUE)),
          '{"error":"pilot bad request"}', status = 400L, error = TRUE)
        next
      }
      # #337: retained shared resolver policy, flat array_payload and mixed NULL options.
      if (isTRUE(item$resolver_bulk)) {
        variants <- list(minimal = list(ids = 'DTXSID7020182'), numeric = list(ids = c(1L, 2L)),
          false = list(ids = FALSE), zero = list(ids = 0), factor = list(ids = factor(c('b', 'a'))),
          list = list(ids = list('one', 'two')), filtered = list(ids = c('one', 'one', NA_character_, '', 'two')),
          encoding = list(ids = 'caf\u00e9 +/&'),
          null_options = list(ids = 'one', idsType = NULL, fuzzy = NULL, mol = NULL, filters = NULL, format = NULL),
          false_options = list(ids = 'one', idsType = FALSE, fuzzy = FALSE, mol = FALSE, filters = FALSE, format = FALSE),
          zero_options = list(ids = 'one', idsType = 0, fuzzy = 0, mol = 0, filters = 0, format = 0),
          empty_options = list(ids = 'one', filters = list(), format = ''),
          nested_options = list(ids = 'one', filters = list(flag = FALSE, count = 0), format = 'JSON'),
          unknown_enums = list(ids = 'one', idsType = 'unreviewed', fuzzy = 'unreviewed', format = 'unreviewed'),
          raw = list(ids = 'one', tidy = FALSE))
        wire_for_resolver <- function(inputs) {
          query <- unique(as.character(inputs$ids))
          query <- query[!is.na(query) & query != '']
          options <- list(idsType = 'AnyId', fuzzy = 'Not', mol = FALSE, filters = NULL, format = NULL)
          keys <- intersect(names(options), names(inputs))
          options[keys] <- inputs[keys]
          options <- c(options[c('idsType', 'fuzzy', 'mol')], Filter(Negate(is.null), options[c('filters', 'format')]))
          body <- c(list(ids = I(query)), options)
          list(expected('POST', '/chemi/resolver/lookup',
            body = as.character(jsonlite::toJSON(body, auto_unbox = TRUE, digits = 22, null = 'null'))))
        }
        for (variant in names(variants)) {
          probe(paste0(name, '-', variant), do.call(fun, variants[[variant]]), wire_for_resolver(variants[[variant]]))
        }
        for (setting in c(NA_character_, '0', '2', '1000')) {
          withr::with_envvar(c(batch_limit = setting), {
            inputs <- list(ids = c('one', 'two', 'three'))
            probe(paste0(name, '-batch-limit-', if (is.na(setting)) 'default' else setting),
              do.call(fun, inputs), wire_for_resolver(inputs))
          })
        }
        invalid <- list(missing = list(), null = list(ids = NULL), empty = list(ids = character()),
          empty_list = list(ids = list()), blank = list(ids = ''), na = list(ids = NA_character_))
        for (variant in names(invalid)) {
          probe(paste0(name, '-', variant), do.call(fun, invalid[[variant]]), list(), error = TRUE)
        }
        probe(paste0(name, '-http-400'), do.call(fun, variants$minimal), wire_for_resolver(variants$minimal),
          '{"error":"pilot bad request"}', status = 400L, error = TRUE)
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
