?remotes::install_github()

library(ComptoxR)



bias_table <- tp_endpoint_coverage(test, id = 'name', filter = '0.1')
bias_table$weight[1] <- 2

tp <- tp_combined_score(test, id = 'name', bias = bias_table, back_fill = NULL)

test %>%
  mutate(
    metric2 = log10(metric2),
    metric1 = scales::rescale(metric1),
    metric2 = scales::rescale(metric2)
    ,across(where(is.numeric), ~replace_na(., 0))) %>%
  rowwise() %>%
  mutate(score = mean(c(metric1, metric2)))


####

slice2.trans <- TxpTransFuncList(func1 = function(x) x^2, func2 = NULL)
#slice2.trans <- TxpTransFuncList(func1 = function(x) x^2, func2 = function(x) log10(x))


f.slices <- TxpSliceList(Slice1 = TxpSlice("metric1"),
                         Slice2 = TxpSlice(c("metric2", "metric3"),
                                           txpTransFuncs = slice2.trans ))

final.trans <- TxpTransFuncList(f1 = NULL, f2 = function(x) log10(x))

f.model <- TxpModel(txpSlices = f.slices,
                    txpWeights = c(2,1)
                    ,txpTransFuncs = final.trans
                    )

f.results <- txpCalculateScores(model = f.model,
                                input = txp_example_input,
                                id.var = 'name' )
#txpSliceScores(f.results)


  sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
  sublists <- map(sublists, as.list)

  df <- map(sublists, ~{

    token <- ct_api_key()

    burl <- Sys.getenv("burl")

    surl <- "chemical/detail/search/by-dtxsid/"

    urls <- paste0(burl, surl, "?projection=chemicalidentifier")

    headers <- c(
      `x-api-key` = token
    )


    .x <- POST(
      url = urls,
      body = rjson::toJSON(.x),
      add_headers(.headers = headers),
      content_type("application/json"),
      accept("application/json, text/plain, */*"),
      encode = "json",
      progress() # progress bar
    )

    .x <- content(.x, "text", encoding = "UTF-8") %>%
      jsonlite::fromJSON(simplifyVector = TRUE)

}) %>% list_rbind()


######################################

tp_combined_score <- function(table, id = NULL, bias = NULL, back_fill){

    if(missing(table)) cli_abort('No table present!')

    cat_line()
    cli_rule(left = 'ID variable')

    if(is.null(id) == TRUE){
      id <- colnames(table[1,1])

      cli_alert_warning((col_yellow('Defaulting to first column for id: {id}')))

    }else{
      cli_alert_success('ID column: {id}')
    }

    cat_line()

    tp_list <- list(tp_scores = NULL, bias = NULL, variable_coverage = NULL)

    #Bias table----
    cli_rule(left = 'Bias table')
    cat_line()

    if(is.null(bias) == TRUE){
      cli_alert_warning(
        col_yellow('WARNING:
                   No bias table detected, defaulting to filter = 0.5!
                   Did you know about `tp_endpoint_coverage()`?
                   '
        ))

      bias <- tp_endpoint_coverage(table, id, suffix = NA, filter = 0.5)
      bias %>% print(n = Inf)
      tp_list$bias <- bias
    }else{
      bias %>% print(n = Inf)
      tp_list$bias <- bias
    }

    cat_line()

    #TODO-----
    tp <- table %>%
      select(c(id,bias$endpoint))

    bias <- bias %>%
      select(endpoint, weight) %>%
      pivot_wider(names_from = endpoint,
                  values_from = weight)

    #Variable coverage----

    cli_rule(left = 'Variable data coverage')

    tp_list$variable_coverage <- tp_variable_coverage(table = table, id = id)
    print(head(tp_list$variable_coverage, n = nrow(tp_list$variable_coverage)))

    cat_line()
    cli_rule()


    #Backfilling----

    if(missing(back_fill) == TRUE){cli_alert_warning('No back filling option specified!')
      back_fill <- NULL
    }else{
      cli_alert_warning('Back filling option selected: {back_fill}')
    }
    cat_line()

    #TP scores----
    tp_scores <- q1$records %>%
      #removes INF
      mutate(
        across(
          .cols = everything(), ~ ifelse(is.infinite(.x), 0, .x))
      ) %>%
      #tie breaking logic needed here....
      mutate(
        across(
          .cols = !contains(id),
          ~{if(length(na.omit(.)) == 1){
            ifelse(is.na(.x) == TRUE, 0, 1)
          }else{
            if(sd(na.omit(.)) == 0){
              ifelse(is.na(.), NA, 1)
            }else{tp_single_score(., back_fill = NULL) %>%
                round(digits = 4)}

          }}
        )
      ) %>%
      mutate(
        across(
          where(is.numeric), ~replace_na(.,0))
      )

    tp_names <- tp_scores[,id] %>%
      as.data.frame()

    tp_scores <- data.frame(mapply('*',tp_scores[,2:ncol(tp_scores)], bias)) %>%
      as_tibble()

    tp_scores <- cbind(tp_names, tp_scores)

    tp_scores <- tp_scores %>%
      rowwise() %>%
      mutate(score =
               rowSums(across(where(is.numeric))
               )
      ) %>%
      relocate(score, .after = id) %>%
      arrange(desc(score)) %>%
      ungroup()

    tp_list$tp_scores <- tp_scores

    return(tp_list)
  }

######


  tp_names <- q2$tp_scores[,id] %>%
    as.data.frame()
    dplyr::rename(id = dtxsid)





