# Pure preflight on complete normalized parameters, before hooks and fan-out.
# The service answers an unknown search_type with an empty list, so reject it here.
.chet_validate_inputs <- function(params) {
  types <- c('lib_id', 'reaction_process', 'reaction_type', 'reaction_scheme', 'reaction_phase')
  if (!rlang::is_string(params$search_type) || !params$search_type %in% types)
    cli::cli_abort('{.arg search_type} must be one of {.val {types}}.')
  invisible(NULL)
}
