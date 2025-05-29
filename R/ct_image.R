#' @title Download Chemical Image by DTXSID
#' @description Downloads a chemical image from the EPA's CompTox Chemicals Dashboard API based on the provided DTXSID and saves it to a specified directory.
#' @param query A character vector of DTXSIDs to search for.
#' @param download_dir Optional directory to save the downloaded images. If not specified, a temporary directory will be used.
#' @return A list of file paths to the downloaded images, or an empty list if no images are found.
#' @importFrom httr2 request
#' @importFrom httr2 req_headers
#' @importFrom httr2 req_perform
#' @importFrom httr2 resp_body_json
#' @importFrom httr2 resp_body_raw
#' @importFrom httr2 resp_header
#' @importFrom purrr map
#' @importFrom purrr safely
#' @importFrom cli cli_rule
#' @importFrom cli cli_dl
#' @importFrom cli cli_end
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_alert_warning
#' @importFrom fs path_join
#' @importFrom fs file_exists
#' @importFrom fs dir_create
#' @examples
#' \dontrun{
#' # Download the image for a single DTXSID to a temporary directory
#' image_files <- get_ct_image(query = "DTXSID7020182")
#' # Download images for multiple DTXSIDs to a specified directory
#' image_files <- get_ct_image(query = c("DTXSID7020182", "DTXSID5020452"), download_dir = "~/Downloads/ct_images")
#' }
#' @export
get_ct_image <- function(query, download_dir = tempdir()) {
  # Input validation
  if (!is.character(query)) {
    stop("query must be a character vector of DTXSIDs.")
  }

  if (!is.character(download_dir) || length(download_dir) != 1) {
    stop(
      "download_dir must be a single character string specifying the directory to save images."
    )
  }

  # Create the download directory if it doesn't exist
  if (!fs::dir_exists(download_dir)) {
    fs::dir_create(download_dir, recurse = TRUE)
    cli::cli_alert_info("Created download directory: {download_dir}")
  }

  # Prepare the base URL
  base_url <- "https://api-ccte.epa.gov/chemical/file/image/search/by-dtxsid/"

  # Create debugging messages for the user
  cli::cli_rule(left = "API payload options")
  cli::cli_dl(c(
    "Number of compounds" = "{length(query)}",
    "Download directory" = "{download_dir}"
  ))
  cli::cli_rule()
  cli::cli_end()

  # Function to safely fetch and download image
  safe_download <- purrr::safely(function(dtxsid) {
    req <-
      httr2::request(paste0(base_url, dtxsid)) |>
      httr2::req_headers(accept = "application/hal+json")
    resp <- httr2::req_perform(req)

    if (httr2::resp_status(resp) == 200) {
      content_type <- httr2::resp_header(resp, "content-type")
      if (grepl("application/hal\\+json", content_type)) {
        body <- httr2::resp_body_json(resp)
        if (length(body$`_links`$image$href) > 0) {
          image_url <- body$`_links`$image$href
          # Determine the file extension (e.g., .png, .jpg)
          file_ext <- tools::file_ext(image_url)
          if (file_ext == "") {
            file_ext <- "png" # Default to png if no extension is found
          }
          # Create a filename based on the DTXSID and file extension
          destfile <- fs::path_join(c(
            download_dir,
            paste0(dtxsid, ".", file_ext)
          ))
          # Download the image
          image_req <- httr2::request(image_url)
          image_resp <- httr2::req_perform(image_req)
          image_raw <- httr2::resp_body_raw(image_resp)
          writeBin(image_raw, destfile)
          cli::cli_alert_success(
            "Successfully downloaded image for {dtxsid} to {destfile}"
          )
          return(destfile)
        } else {
          cli::cli_alert_warning("No image URL found for {dtxsid}")
          return(NULL)
        }
      } else if (grepl("image/", content_type)) {
        # The response is directly the image
        file_ext <- tools::file_ext(httr2::resp_url(resp))
        if (file_ext == "") {
          file_ext <- switch(
            content_type,
            "image/png" = "png",
            "image/jpeg" = "jpg",
            "image/gif" = "gif",
            "png"
          ) # Default to png
        }
        destfile <- fs::path_join(c(
          download_dir,
          paste0(dtxsid, ".", file_ext)
        ))
        image_raw <- httr2::resp_body_raw(resp)
        writeBin(image_raw, destfile)
        cli::cli_alert_success(
          "Successfully downloaded image for {dtxsid} to {destfile}"
        )
        return(destfile)
      } else {
        cli::cli_alert_warning(
          "Unexpected content type {content_type} for {dtxsid}"
        )
        return(NULL)
      }
    } else {
      cli::cli_alert_warning(
        "Request failed for {dtxsid} with status {httr2::resp_status(resp)}"
      )
      return(NULL)
    }
  })

  # Download images for all DTXSIDs
  results <- purrr::map(query, safe_download)

  # Extract the results and errors
  image_files <- purrr::map(results, "result")
  errors <- purrr::map(results, "error")

  # Handle errors
  has_errors <- any(!sapply(errors, is.null))
  if (has_errors) {
    cli::cli_alert_warning("Some requests failed. See errors list for details.")
    print(errors) # or handle them in a more user-friendly way
  }

  # Clean up the results (remove NULLs)
  image_files <- image_files[!sapply(image_files, is.null)]

  return(image_files)
}
