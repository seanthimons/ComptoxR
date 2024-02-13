
data(txp_example_input, package = "toxpiR")

test <- txp_example_input %>%
  select(., name, metric1:metric3) %>%
  rowwise() %>%
  mutate(metric2 = metric2^2) %>%
  mutate(metric2 = sum(
    c(metric2,metric3),
    na.rm = F)
         ) %>%
  ungroup() %>%
  select(-metric3)

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
