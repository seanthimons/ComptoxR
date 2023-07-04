hcd_toxpi_table <- function(hcd_tbl, filter_score = NA){

  #data coverage score
  {
    coverage_score <- hcd_tbl %>%
      select(c(!contains('_amount'))) %>%
      mutate(data_coverage = (rowSums(is.na(.))))

    j = length(coverage_score)-4

    coverage_score <- coverage_score %>%
      mutate(data_coverage = 1-data_coverage/j) %>%
      select(Compound, data_coverage)
    #print(coverage_score)
  }

  #Per endpoint score
  {
    j = nrow(hcd_tbl)

    endpoint_score <- hcd_tbl %>%
      select(!c(Compound:preferredName)) %>%
      select(c(contains('_amount'))) %>%
      map( ~sum(is.na(.))) %>%
      as.data.frame() %>%
      mutate(across(everything(), ~ 1-(.x/j))) %>%
      pivot_longer(everything(), names_to = 'endpoint', values_to = 'score') %>%
      arrange(desc(score))
    cat('\nSorted endpoint scores\n')
    print(endpoint_score)

    if(is.na(filter_score) == T){
      #filter_score <- 0
      cat('\nNo filter for score applied!\n')
      filter_score <- readline(prompt = 'Apply filter score [0-1]:\n')
    }


    filt_score = filter_score

    endpoint_filt_weight <- endpoint_score %>%
      filter(score >= filt_score) %>% #%>% mutate(weight = 1)
      as_tibble() %>%
      arrange(desc(score))
    cat('\nFiltered endpoint scores\n')
    print(endpoint_filt_weight)
    endpoint_filt_weight <- endpoint_filt_weight %>% add_row(endpoint = 'Compound')
  }


  tp <- hcd_tbl %>%
    select(c('Compound', contains('_amount')))

  tp <- tp[, which((names(tp) %in% endpoint_filt_weight$endpoint) == TRUE)]

  tp_scores <- tp %>%
    mutate(across(where(is.numeric),
                  ~ if(sd(na.omit(.)) == 0)
                  {ifelse(is.na(.), NA, 1)}
                  else {tp_single_score(.) %>%
                      round(digits = 3)
                  }))

  tp_scores2 <- tp_scores %>%
    mutate(across(where(is.numeric), ~ {
      min_val <- min(.[-which(. == 0)], na.rm = T)
      replace(., . == 0, 0.5 * min_val)
    }))

  tp_scores2[is.na(tp_scores2)] <- 0

  tp_scores3 <- tp_scores2 %>%
    rowwise() %>%
    mutate(toxpi_score = sum(c_across(cols = !contains('compound'))))

  tp_table <- left_join(hcd_tbl, select(tp_scores3, Compound, toxpi_score)) %>%
    arrange(desc(toxpi_score)) %>%
    select(Compound:preferredName, toxpi_score)

  tp_table <- left_join(tp_table, coverage_score)

  return(tp_table)
}
