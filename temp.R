temp <- ct_list(list_name = 'NERVEAGENTS') %>%
  pluck(., 1, 'dtxsids')

temp <- ct_list(list_name = 'DIOXINS') %>%
  pluck(., 1, 'dtxsids')

q1 <- chemi_cluster(chemicals = temp, sort = FALSE, dry_run = FALSE)

mol_names <- q1 %>%
  pluck(., 'order') %>%
  map(., ~ pluck(.x, 'chemical')) %>%
  map(., ~ keep(.x, names(.x) %in% c('sid', 'name'))) %>%
  map(., as_tibble) %>%
  list_rbind()

#library(ggdendro)

q2 <- q1 %>%
  pluck(., 'similarity') %>%
  map(
    .,
    ~ map(., ~ discard_at(.x, 'cl')) %>%
      list_flatten() %>%
      unname() %>%
      list_c() %>%
      replace(., . == 0, 1)
  )

hc <- matrix(unlist(q2), nrow = length(q2), byrow = TRUE) %>%
  `colnames<-`(mol_names$name) %>%
  `row.names<-`(mol_names$name) %>%
  {
    1 - .
  } %>%
  as.dist(.) %>%
  hclust(.)

hcdata <- dendro_data(hc)

# hc <- USArrests  %>%
#   dist(.) %>%
#   hclust()

# hcdata <- dendro_data(hc, type = "rectangle")

ggplot() +
  geom_segment(
    data = segment(hcdata),
    aes(x = x, y = y, xend = xend, yend = yend)
  ) +
  geom_text(
    data = label(hcdata),
    aes(x = x, y = y, label = label, hjust = 0),
    size = 3
  ) +
  coord_flip() +
  theme_dendro() +
  scale_y_reverse(expand = c(0.2, 0))
