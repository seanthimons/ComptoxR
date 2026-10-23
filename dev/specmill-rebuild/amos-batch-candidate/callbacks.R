amos_batch_body <- function(operation) {
  general <- identical(operation$name, 'chemi_amos_batch')
  substitute(base::local({
    body <- base::Filter(base::Negate(base::is.null), params)
    body$identifiers <- base::as.list(body$ids)
    body$ids <- NULL
    if (GENERAL) body$exclude_analytical_qc <- FALSE
    body <- .api_validation$body_value(body, SCHEMA)
    body$identifiers <- base::I(body$identifiers)
    body
  }), list(GENERAL = general, SCHEMA = operation$schema_body))
}
