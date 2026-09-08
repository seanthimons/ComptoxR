#' Retrieves metadata from the database about a single product declaration.  This is not necessarily just the metadata
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the product declaration.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_product_declaration_editor_info(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_product_declaration_editor_info <- function(internal_id) {
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_product_declaration_editor_info/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
