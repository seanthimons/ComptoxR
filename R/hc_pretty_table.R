#' Create conditionally formatted table from comparison table
#'
#' @param table Table to color
#' @param ID ID column
#' @param suffix Suffix to subset by
#'
#' @return A tibble
#' @export

hc_pretty_table <- function(table, ID = NA, suffix = NA){

df <- select(table, ID, !contains(suffix))

df <- df %>% datatable(
      options = list(
        columnDefs = list(list(className = 'dt-center', targets = '_all')))) %>%
    formatStyle(names(tbl %>% select('compound', !contains('_amount'))),
                backgroundColor = styleEqual(c('VH', 'H','M','L'), c('red', 'orange', 'yellow', 'green')))

return(df)
}
