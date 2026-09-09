# Explicit maintenance callbacks; never sourced by the installed client.
batch_limit_100 <- function(operation) {
  quote(as.numeric(Sys.getenv('batch_limit', '100')))
}

batch_limit_1000 <- function(operation) {
  quote(as.numeric(Sys.getenv('batch_limit', '1000')))
}

# These two prediction APIs accept exactly one of smiles or chemicals. Keep
# their existing cli condition and model-id requirement in the emitted body.
prediction_body <- function(operation) {
  fields <- intersect(
    c('cache_only', 'model_id', 'smiles', 'chemicals'),
    vapply(operation$parameters, `[[`, character(1), 'name')
  )
  values <- stats::setNames(
    lapply(fields, function(name) {
      substitute(params[[NAME]], list(NAME = name))
    }),
    fields
  )
  substitute(
    local({
      if (sum(c(!is.null(params$smiles), !is.null(params$chemicals))) != 1L || MISSING_MODEL) {
        cli::cli_abort('Supply exactly one supported request-body shape.')
      }
      Filter(Negate(is.null), BODY)
    }),
    list(
      MISSING_MODEL = if ('model_id' %in% fields) quote(is.null(params$model_id)) else FALSE,
      BODY = as.call(c(list(as.name('list')), values))
    )
  )
}

lowercase_sort <- function(operation) {
  quote(if (!is.null(params$sort)) tolower(as.character(params$sort)) else NULL)
}
