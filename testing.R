library(toxpiR)

chems <- ct_list('CWA311HS') %>%
  map(., ~ pluck(., 'dtxsids')) %>%
  list_c() %>%
  unique()

dat <- chemi_hazard(query = chems)

#slice_list <-
dat$records %>%
  select(-dtxsid) %>%
  imap(
    seq_along(.),
    ~ {
      print(.x, .y)
    }
  )


library(toxpiR)
library(purrr)

chems <- ct_list('CWA311HS') %>%
  map(., ~ pluck(., 'dtxsids')) %>%
  list_c() %>%
  unique()

dat <- chemi_hazard(query = chems)

df <-
  left_join(
    dat$headers,
    dat$records
  )

slice_list <-
  df %>%
  select(-dtxsid, -name) %>%
  names() %>%
  map(., ~ TxpSlice(.x)) %>%

  #slice_list <- slice_list %>%
  set_names(
    .,
    df %>%
      select(-dtxsid, -name) %>%
      names()
  ) %>%
  as.TxpSliceList(.)

model <- TxpModel(
  txpSlices = slice_list
)

results <- txpCalculateScores(
  model = model,
  input = df,
  id.var = 'dtxsid'
)

ranked <-
  tibble(
    dtx = results@txpIDs,
    r = results@txpRanks,
    s = results@txpScores,
    m = results@txpSliceScores %>%
      as_tibble() %>%
      mutate(zero_count = rowSums(. == 0), .keep = 'none') %>%
      pull(.)
  ) %>%
  left_join(dat$headers, ., join_by(dtxsid == dtx))

rk_class <- chemi_classyfire(query = ranked$dtxsid)

top_results <-
  results[
    results@txpIDs %in%
      (ranked %>%
        slice_min(., order_by = r, n = 12) %>%
        pull(dtx))
  ] %>%
  .[order(.@txpRanks)]

plot(
  top_results,
  package = 'gg',
  bgColor = NULL,
  showMissing = FALSE,
  borderColor = 'black',
  sliceLineColor = 'black',
  sliceBorderColor = 'black',
  fills = cust_pal[1:20]
)

ranked %>%
  mutate(dtx = fct_reorder(dtx, s)) %>%
  filter(s != 0) %>%
  ggplot(
    aes(x = s, y = dtx, color = m)
  ) +
  geom_point() +
  theme_minimal() +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )
