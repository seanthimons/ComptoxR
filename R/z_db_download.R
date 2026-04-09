# GitHub Release Download Helper for Local Databases
# --------------------------------------------------

#' Download a DuckDB database from a GitHub Release asset
#'
#' Internal helper used by `tox_install()`, `eco_install()`, and `dss_install()`
#' to download pre-built `.duckdb` files attached to GitHub Releases.
#'
#' @param db_name One of `"dsstox"`, `"ecotox"`, or `"toxval"`.
#' @param dest_path Where to write the downloaded file.
#' @param tag GitHub release tag (e.g. `"v2.1.0"`), or `"latest"` (default).
#' @param repo GitHub repository in `"owner/repo"` format.
#' @return The downloaded file path (invisibly), or aborts on failure.
#' @keywords internal
.db_download_release <- function(db_name,
                                 dest_path,
                                 tag = "latest",
                                 repo = "seanthimons/ComptoxR") {
  asset_name <- paste0(db_name, ".duckdb")

  # Build GitHub API URL
  if (identical(tag, "latest")) {
    api_url <- sprintf("https://api.github.com/repos/%s/releases/latest", repo)
  } else {
    api_url <- sprintf("https://api.github.com/repos/%s/releases/tags/%s", repo, tag)
  }

  cli::cli_alert_info("Fetching release info from {.url {api_url}}")

  # Get release metadata
  release_req <- httr2::request(api_url) |>
    httr2::req_headers(Accept = "application/vnd.github+json") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(30)

  release_resp <- tryCatch(
    httr2::req_perform(release_req),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to fetch release info from GitHub.",
        "i" = "URL: {.url {api_url}}",
        "x" = conditionMessage(e)
      ))
    }
  )

  release_data <- httr2::resp_body_json(release_resp)
  assets <- release_data$assets

  if (length(assets) == 0) {
    cli::cli_abort(c(
      "No assets found in release {.val {release_data$tag_name}}.",
      "i" = "Database assets may not have been uploaded yet.",
      "i" = "Use {.code build = TRUE} to build from source instead."
    ))
  }

  # Find the matching asset
  asset_names <- vapply(assets, function(a) a$name, character(1))
  match_idx <- match(asset_name, asset_names)

  if (is.na(match_idx)) {
    cli::cli_abort(c(
      "Asset {.file {asset_name}} not found in release {.val {release_data$tag_name}}.",
      "i" = "Available assets: {.file {asset_names}}",
      "i" = "Use {.code build = TRUE} to build from source instead."
    ))
  }

  download_url <- assets[[match_idx]]$browser_download_url
  asset_size <- assets[[match_idx]]$size

  cli::cli_alert_info(
    "Downloading {.file {asset_name}} ({.strong {format(structure(asset_size, class = 'object_size'), units = 'auto')}})"
  )

  # Download the asset

  dl_req <- httr2::request(download_url) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(300)

  tryCatch(
    httr2::req_perform(dl_req, path = dest_path),
    error = function(e) {
      # Clean up partial download
      if (file.exists(dest_path)) unlink(dest_path)
      cli::cli_abort(c(
        "Failed to download {.file {asset_name}}.",
        "x" = conditionMessage(e)
      ))
    }
  )

  cli::cli_alert_success("Downloaded {.file {asset_name}} to {.path {dest_path}}")
  invisible(dest_path)
}
