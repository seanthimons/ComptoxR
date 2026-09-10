# Client credential names and recording guidance; validation is development-only.
ctx_api_key_status <- function(value = Sys.getenv('ctx_api_key')) {
  specmill::credential_status(value, 'ctx_api_key')
}
ctx_api_key_preflight <- function(value = Sys.getenv('ctx_api_key'), abort = TRUE) {
  specmill::credential_preflight(
    value,
    'ctx_api_key',
    abort,
    guidance = c(
      'i' = 'Set a real token in the ctx_api_key environment variable before live recording.',
      'i' = 'Do not paste or print the token in logs. In GitHub Actions, map secrets.CTX_API_KEY to ctx_api_key.'
    )
  )
}
