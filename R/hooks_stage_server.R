enforce_stage_server <- function(data) {
  cfg <- get_hook_config()[[data$fn_name]]
  supported <- unlist(cfg$supported_schema_stages, use.names = FALSE)
  if (length(supported) == 0L) {
    return(data)
  }

  stage_urls <- c(
    public = chemi_server(1, url_only = TRUE),
    staging = chemi_server(2, url_only = TRUE),
    development = chemi_server(3, url_only = TRUE)
  )
  normalize_url <- function(url) sub("/+$", "", url)
  selected <- data$params$server
  if (is.null(selected) && is.list(data$request)) {
    selected <- data$request$server
  }
  if (is.null(selected) || length(selected) != 1L || !nzchar(selected)) {
    return(data)
  }

  resolved <- Sys.getenv(selected, unset = selected)
  selected_stage <- names(stage_urls)[
    normalize_url(stage_urls) == normalize_url(resolved)
  ]
  if (length(selected_stage) == 0L) {
    return(data)
  }
  selected_stage <- selected_stage[[1]]
  if (selected_stage %in% supported) {
    return(data)
  }

  fallback <- cfg$preferred_fallback_stage
  if (is.null(fallback) || !fallback %in% supported) {
    fallback <- intersect(c("public", "staging", "development"), supported)[[1]]
  }
  target <- unname(stage_urls[[fallback]])
  data$params$server <- target
  if (is.list(data$request) && !is.null(data$request$server)) {
    data$request$server <- target
  }

  cli::cli_warn(c(
    "{.fn {data$fn_name}} is not available on the selected {selected_stage} server; using {fallback}.",
    "i" = "Server: {.url {target}}"
  ))
  data
}
