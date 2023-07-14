#' Per compound data availability scoring
#'
#' Will return in the console the endpoint coverage before weighing.
#'
#' @param table
#' @param suffix
#'
#' @return A tibble of results
#' @export

hc_compound_coverage <- function(table, suffix = NA){
  if(is.na(suffix)){
    cat('\nMissing search parameter!\n')
    coverage_score <- table %>%
      mutate(data_coverage = (rowSums(is.na(.))))


    coverage_score <- coverage_score %>%
      mutate(data_coverage = 1-(data_coverage/(ncol(coverage_score)-2))) %>%
      select(compound, data_coverage)

    return(coverage_score)
    }
  else{
    coverage_score <- table %>%
      select(c(!contains(suffix))) %>%
      mutate(data_coverage = (rowSums(is.na(.))))


    coverage_score <- coverage_score %>%
      mutate(data_coverage = 1-(data_coverage/(ncol(coverage_score)-2))) %>%
      select(compound, data_coverage)

  return(coverage_score)}
}

#' Per endpoint - compound availability scoring
#'
#' @param table Takes a the result of a `hc_table()` function and returns a table of scores (0-1) on the amount of compounds by percent each endpoint has.
#' @param filter A number(0-1) to cut off endpoint by for weighing. By default, sets to 0.5.
#' @param ID
#' @param suffix
#'
#' @return A tibble of results
#' @export

hc_endpoint_coverage <- function(table, ID = NA, suffix = NA, filter = NA){

  if(is.na(filter) == T){
    filt_score = 0.5
    cat('\nDefaulting to 0.5% score for cutoff!\n')

    }else(filt_score <- filter)
  if(is.na(suffix) == T){
    endpoint_score <- table %>%
    select(!c(ID)) %>%
    map( ~sum(is.na(.))) %>%
    as.data.frame() %>%
    mutate(across(everything(), ~ 1-(.x/nrow(table)))) %>%
    pivot_longer(everything(), names_to = 'endpoint', values_to = 'score')
  }else{
    endpoint_score <- table %>%
    select(!c(ID)) %>%
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
