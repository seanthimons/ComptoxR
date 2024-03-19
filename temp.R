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


