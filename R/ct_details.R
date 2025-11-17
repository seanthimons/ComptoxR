#' Retrieve compound details by DTXSID
#'
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param projection A subset of date to be returned. By default returns a minimal set of common identifiers.
#' @param ctx_api_keyChecks for API key in Sys env
#'
#' @return a data frame
#' @export

ct_details <- function(
  query,
  projection = c(
    "all",
    "standard",
    "id",
    "structure",
    "nta",
    'compact'
  ),
  ctx_api_key= NULL
) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  ctx_burl <- Sys.getenv("ctx_burl")

  if (missing(projection)) {
    projection <- 'compact'
  }

  proj <- case_when(
    projection == "all" ~ "chemicaldetailall",
    projection == "standard" ~ "chemicaldetailstandard",
    projection == "id" ~ "chemicalidentifier",
    projection == "structure" ~ "chemicalstructure",
    projection == "nta" ~ "ntatoolkit",

    projection == 'compact' ~ 'compact',
    TRUE ~ NA_character_
  )

  cli_rule(left = 'Payload options')
  cli_dl(
    c('Projection' = '{proj}', 'Number of compounds' = '{length(query)}')
  )
  cli_rule()

  surl <- "chemical/detail/search/by-dtxsid/"

  urls <- paste0(ctx_burl, surl, "?projection=", proj)

  headers <- c(
    `x-api-key` = token
  )

  if (length(query) > 200) {
    sublists <- split(
      query,
      rep(
        1:ceiling(length(query) / 200),
        each = 200,
        length.out = length(query)
      )
    )
    sublists <- map(sublists, as.list)
  } else {
    sublists <- vector(mode = 'list', length = 1L)
    sublists[[1]] <- query %>% as.list()
  }

  df <- map(
    sublists,
    ~ {
      response <- POST(
        url = urls,
        body = .x,
        add_headers("x-api-key" = token),
        encode = 'json',
        progress()
      )
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    },
    .progress = T
  ) %>%
    #TODO Probably needs to be validated for missing or NULL values
    list_rbind()

  cli::cli_text()
  return(df)
}
