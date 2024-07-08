#' ToxPrint Chemotyper
#'
#' @param query A list of DTXSIDs
#' @param odds_ratio numeric
#' @param p_val numeric
#' @param true_pos numeric
#'
#' @return A dataframe
#' @export

chemi_toxprint <- function(query,
                           odds_ratio,
                           p_val,
                           true_pos
                           ){

  if(missing(query) == TRUE){
    cli::cli_abort('Missing query!')
  }else{
    query <- as.list(query)
  }

  options <- list(
    'OR' = ifelse(missing(odds_ratio), 3L , as.numeric(odds_ratio)),
    'PV1' = ifelse(missing(p_val), 0.05 , as.numeric(p_val)),
    'TP' = ifelse(missing(true_pos), 3 , as.numeric(true_pos))
    )

  cli::cli_rule(left = 'Payload options')
  cli::cli_dl(options)
  cli::cli_end()

  chemicals <- vector(mode = 'list', length = length(query))

  chemicals <- map(query, ~{
    sid <- .x
  })

  payload = list(
    chemicals,
    options
  )

  burl <- paste0(Sys.getenv("chemi_burl"), "api/toxprints/calculate")

  response <- POST(
    url = burl,
    body = jsonlite::toJSON(payload),
    content_type("application/json"),
    accept("*/*"),
    progress()
  )

  if (response$status_code == 200) {
    df <- content(response, "text", encoding = "UTF-8") %>%
      fromJSON(simplifyVector = FALSE)

  } else {
    cli::cli_alert_danger("\nBad request!")
  }

}
