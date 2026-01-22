
raw_spec <- jsonlite::fromJSON(here::here('schema', 'chemi-hazard-prod.JSON'), simplifyVector = TRUE, flatten = TRUE)

r1 <- raw_spec %>%
  keep(names(.) %in% c('paths', 'components')) %>%
	modify_at('components', flatten) %>% 
	# Keeps only the useful endpoints
  modify_at('paths', ~discard(.x, grepl('render|replace|add|freeze|metadata|version|reports|download|export|protocols', names(.x))))

# Body schemas
r2 <- r1$paths %>%
  map(~if("post" %in% names(.x)) {
    .x$post$requestBody$content$`application/json`$schema$`$ref`
  } else {
    NULL
  }) %>%
  compact() %>%   # Remove NULL entries
	unname()
	
r3 <- r1$paths %>%
  map(~if("post" %in% names(.x)) {
    .x$post$parameters$`schema.$ref`
  } else {
    NULL
  }) %>% 
  compact() %>%   # Remove NULL entries
	flatten() %>% 
	discard(is.na)

# Simple vector for searching
r4 <- list(r2, r3) %>% 
	flatten() %>% 
	unlist() %>% 
	str_remove_all(., "\\#\\/components\\/schemas\\/") %>%
	str_squish()

# Keeps only needed schemas
r5 <- r1 %>% 
	modify_at('components', ~keep(.x, grepl(paste(r4, collapse = "|"), names(.x)))) %>% 
	modify_at('components', ~map(.x, as_tibble))

r6 <- r5$components %>% 
	list_rbind() %>% 
	modify_at(., 'properties', flatten) %>% 
	unnest_wider(., properties, names_sep = "_")

