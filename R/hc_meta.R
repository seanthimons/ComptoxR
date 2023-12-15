#' Per variable data availability scoring
#'
#' Will return in the console the endpoint coverage before weighing.
#'
#' @param table Takes a table from the
#' @param suffix Suffix to subset out by
#' @param id id column to ignore. Must be present to continue calculation.
#'
#' @return A tibble of results
#' @export

tp_variable_coverage <- function(table, id = NA, suffix = NA){

  if(missing(id) == T){cli_abort('Missing id variable!')
    }else{
      if(is.na(suffix) == TRUE){
    # cli_alert_warning('Missing search parameter!')
    coverage_score <- table %>%
      mutate(data_coverage = (rowSums(is.na(.))))


    coverage_score <- coverage_score %>%
      mutate(data_coverage = 1-(data_coverage/(ncol(coverage_score)-2))) %>%
      select(id, data_coverage)

    return(coverage_score)
  }
    else{
      coverage_score <- table %>%
        select(c(!contains(suffix))) %>%
        mutate(data_coverage = (rowSums(is.na(.))))


      coverage_score <- coverage_score %>%
        mutate(data_coverage = 1-(data_coverage/(ncol(coverage_score)-2))) %>%
        select(id, data_coverage)

      return(coverage_score)}}


}

#' Per endpoint - compound availability scoring
#'
#' @param table Takes a the result of a `hc_table()` function and returns a table of scores (0-1) on the amount of compounds by percent each endpoint has.
#' @param filter A number (0-1) to cut off endpoint by for weighing. By default, sets to 0.5.
#' @param id id column to ignore. Must be present to continue calculation.
#' @param suffix A string to filter columns by. Useful if you are using the [hc_table()] function which outuputs a binned variable and a numerical value.
#'
#' @return A tibble of results
#' @export

tp_endpoint_coverage <- function(table, id = NA, suffix = NA, filter = NA){

  if(missing(id) == T){cli_abort('Missing id variable!')
  }

  if(is.na(filter) == T){
    filt_score = 0.5
    cli_alert_warning('Defaulting to 0.5% score for cutoff!')

    }else(filt_score <- as.numeric(filter))

  if(is.na(suffix) == T){
    endpoint_score <- table %>%
    select(!c(id)) %>%
    map( ~sum(is.na(.))) %>%
    as.data.frame() %>%
    mutate(across(everything(), ~ 1-(.x/nrow(table)))) %>%
    pivot_longer(everything(), names_to = 'endpoint', values_to = 'score')
  }else{
    endpoint_score <- table %>%
    select(!c(id)) %>%
    select(c(contains(suffix))) %>%
    map( ~sum(is.na(.))) %>%
    as.data.frame() %>%
    mutate(across(everything(), ~ 1-(.x/nrow(table)))) %>%
    pivot_longer(everything(), names_to = 'endpoint', values_to = 'score')
  }

    #debug
    #print(endpoint_score)

    endpoint_filt_weight <- endpoint_score %>%
    filter(score >= filt_score) %>%
    mutate(weight = 1)

  return(endpoint_filt_weight)
}
