var <- df$toxpi$variable_coverage
tp <- df$toxpi$tp_scores

tp %>%
  arrange(score) %>%
  left_join(., var, by = 'dtxsid') %>%
  select(dtxsid, score, data_coverage) %>%
  mutate(dtxsid = forcats::fct_reorder(dtxsid, score)) %>%
  ggplot(mapping = aes(
    x = dtxsid,
    y = score,
    color = data_coverage
    )) +
  geom_point(
     size = 1.5,
     ) +
  scale_color_continuous(type = "viridis") +
  coord_flip() +
  theme_light()
