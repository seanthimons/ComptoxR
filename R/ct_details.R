#' Retrieve compound details by DTXSID
#'
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param projection A subset of date to be returned. By default returns a minimal set of common identifiers.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return a data frame
#' @export

ct_details <- function(query, projection = c("all", "standard", "id", "structure", "nta"), ccte_api_key = NULL) {

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv("burl")

  if (missing(projection)) {
    proj <- "chemicalidentifier"
  } else {
    if (projection == "all") {
      proj <- "chemicaldetailall"
    } else {
      if (projection == "standard") {
        proj <- "chemicaldetailstandard"
      } else {
        if (projection == "id") {
          proj <- "chemicalidentifier"
        } else {
          if (projection == "structure") {
            proj <- "chemicalstructure"
          } else {
            if (projection == "nta") {
              proj <- "ntatoolkit"
            }
          }
        }
      }
    }
  }

  cli_rule(left = 'Payload options')
  cli_dl(
    c('Projection' = '{proj}',
      'Number of compounds'= '{length(query)}'
    )
  )
  #cli_rule()

  surl <- "chemical/detail/search/by-dtxsid/"

  urls <- paste0(burl, surl, "?projection=", proj)

  headers <- c(
    `x-api-key` = token
  )

  if(length(query) > 200){

    sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
    sublists <- map(sublists, as.list)
  }else{
    sublists <- vector(mode = 'list', length = 1L)
    sublists[[1]] <- query %>% as.list()
  }

  df <- map(sublists, ~{

    response <- POST(
      url = urls,
      body = .x,
      add_headers("x-api-key" = token),
      encode = 'json',
      progress()
    )
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }, .progress = T) %>% list_rbind()

  cli::cli_text()
  return(df)
}
