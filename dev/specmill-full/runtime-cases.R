# Inserted into the existing installed-client localhost verifier before snapshots.
# Expectations use frozen original helper calls, never generated wrapper output.
full_failures <- list()
for (name in names(full_cases)) {
  item <- full_cases[[name]]
  failure <- tryCatch(
    {
      fun <- getExportedValue('ComptoxR', name)
      arguments <- item$arguments
      supplied <- item$inputs
      if (item$helper == 'generic_chemi_request' && is.null(arguments$query)) {
        probe(paste0(name, '-public-defaults'), do.call(fun, supplied), error = TRUE)
        supplied[[names(formals(fun))[[1L]]]] <- 'pilot-1'
        arguments$query <- 'pilot-1'
      }
      wire_for <- function(a) {
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
      if (isTRUE(arguments$paginate)) {
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
        batched <- supplied
        batched[[query_parameter]] <- c('record 1', 'record 2', 'record 1', 'record 3')
        a$query <- batched[[query_parameter]]
        probe(paste0(name, '-batches'), do.call(fun, batched), wire_for(a), response)
      }
      NULL
    },
    error = identity
  )
  if (inherits(failure, 'error')) full_failures[[name]] <- conditionMessage(failure)
}
