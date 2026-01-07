#' Get Chemical Structure Image
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Retrieves chemical structure images (PNG) from the EPA CompTox Chemicals Dashboard API.
#'
#' @param dtxsid A character vector of DTXSIDs to retrieve images for.
#' @return For a single DTXSID: a magick image object (if magick package is installed),
#'   otherwise raw bytes. For multiple DTXSIDs: a named list of images.
#'
#' @examples
#' \dontrun{
#' # Get image for a single compound
#' img <- ct_image("DTXSID7020182")
#'
#' # Get images for multiple compounds
#' imgs <- ct_image(c("DTXSID7020182", "DTXSID5020452"))
#' }
#' @export
ct_image <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "chemical/file/image/search/by-dtxsid",
    method = "GET",
    batch_limit = 1,
    content_type = "image/png"
  )
}

#' Download Chemical Structure Images to Disk
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Downloads chemical structure images (PNG) from the EPA CompTox API and saves them to disk.
#'
#' @param dtxsid A character vector of DTXSIDs to download images for.
#' @param download_dir Directory to save images. Defaults to a temporary directory.
#' @param overwrite Logical; whether to overwrite existing files. Defaults to FALSE.
#' @return A named character vector of file paths to the downloaded images.
#'   Names correspond to the input DTXSIDs.
#'
#' @examples
#' \dontrun{
#' # Download image for a single compound
#' path <- ct_image_download("DTXSID7020182", download_dir = "~/images")
#'
#' # Download multiple images
#' paths <- ct_image_download(
#'   c("DTXSID7020182", "DTXSID5020452"),
#'   download_dir = "~/images"
#' )
#' }
#' @export
ct_image_download <- function(dtxsid, download_dir = tempdir(), overwrite = FALSE) {
  # Create directory if it doesn't exist
  if (!dir.exists(download_dir)) {
    dir.create(download_dir, recursive = TRUE)
  }

  # Process each DTXSID
  paths <- purrr::map_chr(dtxsid, function(id) {
    destfile <- file.path(download_dir, paste0(id, ".png"))

    # Skip if file exists and not overwriting
    if (file.exists(destfile) && !overwrite) {
      cli::cli_alert_info("Skipping {id}: file already exists at {destfile}")
      return(destfile)
    }

    # Get the image
    img <- tryCatch(
      ct_image(id),
      error = function(e) {
        cli::cli_alert_warning("Failed to retrieve image for {id}: {e$message}")
        return(NULL)
      }
    )

    if (is.null(img)) {
      return(NA_character_)
    }

    # Save to disk
    tryCatch({
      if (inherits(img, "magick-image")) {
        magick::image_write(img, destfile, format = "png")
      } else {
        # Raw bytes
        writeBin(img, destfile)
      }
      cli::cli_alert_success("Downloaded {id} to {destfile}")
      destfile
    }, error = function(e) {
      cli::cli_alert_warning("Failed to save image for {id}: {e$message}")
      NA_character_
    })
  })

  names(paths) <- dtxsid
  paths[!is.na(paths)]
}

#' @rdname ct_image_download
#' @export
get_ct_image <- function(dtxsid, download_dir = tempdir(), overwrite = FALSE) {
  lifecycle::deprecate_warn("1.0.0", "get_ct_image()", "ct_image_download()")
  ct_image_download(dtxsid = dtxsid, download_dir = download_dir, overwrite = overwrite)
}
