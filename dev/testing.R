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


# list ----------------------------------------------------------------



q1 <- ct_search(query = c(
  'Acetone Peroxide',
  'HMTD',
  'Mercury(II) Fulminate',
  'Nitroglycerin',
  'PLX',
  'Trinitrotoluene',
  'RDX',
  'HMX',
  'Ammonium Nitrate',
  'Picric Acid'
),
request_method = 'POST'
)

q1 <- ct_search(query = c(
'Hydrogen-3',        
'Cobalt-60',
'Strontium-90',
'Caesium-137',
'Radium-226',
'Radium-228',
'Uranium-233',
'Thorium-232',
'Uranium-234',
'Uranium-235'
),
request_method = 'POST'
)


chemi_resolver_lookup(query = c(testing_chemicals$casrn, testing_chemicals$casrn))



ct_similar(query = 'DTXSID3021774')
	

ct_hazard(query = 'DTXSID3021774')

temp <- testing_chemicals %>% slice_sample(n = 10) %>% select(dtxsid, preferredName)

q1 <- ct_env_fate(query = temp$dtxsid)

q1 <- ct_env_fate(query = 'DTXSID3021774')

#gets names
query_names <- q1 %>% 
	map(., 
		~pluck(., 'dtxsid')
) %>% 
	list_c()

#gets properties
q3 <- q1 %>% 
	map(., 
		~pluck(., 'properties')
) %>% 
	set_names(query_names) %>% 
	# Process sublists for each chemical, going 3 levels deep
	map_depth(., 3, ~{
		# If the element is a list, replace any NULL elements within it with NA
		if (is.list(.x)) {
			map(.x, ~if (is.null(.)) NA else .) %>% pluck(., 1)
			# If the element itself is NULL or an empty list, replace it with NA
		} else if (is.null(.x) || length(.x) == 0) {
			NA
			# Otherwise, keep the element as is
		} else {
			.x
		}
	})
