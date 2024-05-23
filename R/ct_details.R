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
   # cli::cli_alert_warning("{length(sublists)} request needed...")

    df <- map(sublists, ~{

    .x <- POST(
      url = urls,
      body = .x,
      add_headers(.headers = headers),
      content_type("application/json"),
      accept("application/json, text/plain, */*"),
      encode = "json",
      progress() # progress bar
      )

    .x <- content(.x, "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(simplifyVector = TRUE)

    }) %>%
      list_rbind() %>%
      split(.$propertyId)

  }else{

  payload <- as.list(query)

  response <- POST(
    url = urls,
    body = payload,
    add_headers(.headers = headers),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = "json",
    progress() # progress bar
  )

  df <- content(response, "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyVector = TRUE)

  #df <- map(df, \(x) as.data.frame(x)) %>% list_rbind()
  } #%>%
    #list_rbind() %>%
    #split(.$propertyId)

  cli::cli_text()
  return(df)
}
