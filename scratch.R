groq <- function(query) {
  GROQ_API_KEY <- "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"

  headers <- c(
    `Authorization` = paste("Bearer ", GROQ_API_KEY, sep = ""),
    `Content-Type` = "application/json"
  )

  data <- jsonlite::toJSON(
    list(
      messages = list(
        list(
          role = "user",
          content = query
        )
      ),
      model = "mixtral-8x7b-32768"
    ),
    auto_unbox = T
  )

  res <- httr::POST(
    url = "https://api.groq.com/openai/v1/chat/completions",
    httr::add_headers(.headers = headers),
    body = data,
    httr::progress()
  )

  res <- httr::content(
    res
    # , as = 'text'
  )
  res <- purrr::pluck(res, "choices", 1, "message", "content") %>% cat("\n", .)

  return(res)
}

# testing ----

df <- chemi_predict(query = "DTXSID1034187")

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "exact"
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "substructure",
  min_similarity = 0.8
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "similar",
  min_similarity = 0.8
)

df <- chemi_search(
  searchType = "features",
  element_inc = "Cr",
  element_exc = "ALL"
)

df <- ct_details(query = df$sid, projection = "structure")

###########################

# ToxPrints calculate

query <- as.list(dtx_list$dtxsid[1:5])

burl <- paste0(Sys.getenv("chemi_burl"), "api/toxprints/calculate")

options <- list(
  "OR" = 3L,
  "PV1" = 0.05,
  "TP" = 3
)

chemicals <- vector(mode = "list", length = length(query))

chemicals <- map(query, ~ {
  list(
    sid = .x
  )
})

{
  chemicals <- list(
    list(
      # "id"= "34187",
      # "cid"= "DTXCID9014187",
      "sid" = "DTXSID1034187",
      # "casrn"= "10540-29-1",
      # "name"= "Tamoxifen",
      "smiles" = "C(/C1C=CC=CC=1)(\\C1=CC=C(C=C1)OCCN(C)C)=C(/CC)\\C1=CC=CC=C1"
      # "canonicalSmiles"= "CC/C(=C(\\C1C=CC=CC=1)/C1C=CC(=CC=1)OCCN(C)C)/C1C=CC=CC=1",
      # "inchi"= "InChI=1S/C26H29NO/c1-4-25(21-11-7-5-8-12-21)26(22-13-9-6-10-14-22)23-15-17-24(18-16-23)28-20-19-27(2)3/h5-18H,4,19-20H2,1-3H3/b26-25-",
      # "inchiKey"= "NKANXQFJJICGDU-QPLCGJKRSA-N",
      # "checked"= 'true'
    )
  )

  payload <- list(
    "chemicals" = chemicals,
    "options" = options
  ) %>%
    jsonlite::toJSON(., auto_unbox = T)

  df <- POST(
    url = burl,
    body = payload,
    content_type("application/json"),
    encode = "json",
    progress()
  ) %>%
    content(., "text", encoding = "UTF-8") %>%
    fromJSON(simplifyVector = TRUE)
}


# Curation ----------------------------------------------------------------
{
  isotopes <- ComptoxR::pt$isotopes %>%
    select(-isotope_mass_symbol) %>%
    mutate(isotope_symbol = str_remove_all(isotope_symbol, "-"))

  search_list <- rio::import("cas_list.csv", na.strings = "") %>%
    select(analyte, cas_number) %>%
    mutate(raw_analyte = analyte) %>%
    left_join(., isotopes, join_by(analyte == isotope_symbol)) %>%
    mutate(analyte = case_when(
      !is.na(isotopes) ~ isotopes,
      .default = analyte
    )) %>%
    select(-isotopes)

  rm(isotopes)
}

{
  comp <- ct_search(type = "string", search_param = "equal", query = search_list$analyte) %>%
    rename_with(., ~ paste0("compound_", .x, recycle0 = T), !raw_search)

  # comp_sw <- comp %>%
  #   filter(is.na(compound_dtxsid)) %>%
  #   select(raw_search) %>%
  #   ct_search(type = 'string', search_param = 'start-with', query = .$raw_search, suggestions = T) %>%
  #   rename_with(., ~paste0('compound_sw_', .x, recycle0 = T), !raw_search)

  cas <- ct_search(type = "string", search_param = "equal", query = search_list$cas_number, suggestions = T) %>%
    rename_with(., ~ paste0("cas_", .x, recycle0 = T), !raw_search)
}

search_cur <- left_join(search_list, comp, join_by(analyte == raw_search)) %>%
  left_join(., cas, join_by(cas_number == raw_search)) %>%
  select(contains(c("analyte", "cas_number")), ends_with(c("_dtxsid", "_rank", "_preferredName"))) %>%
  mutate(
    across(ends_with("_dtxsid"), ~ if_else(is.na(.x), "NA", .x)),
    auth = case_when(
      cas_dtxsid == "NA" & compound_dtxsid == "NA" ~ "MISS",
      cas_dtxsid == compound_dtxsid ~ "TRUE",
      cas_dtxsid != compound_dtxsid ~ "FALSE",
      compound_dtxsid != cas_dtxsid ~ "FALSE"
    ),
    final_dtx = case_when(
      # auth == FALSE ~ NA,
      auth == TRUE ~ compound_dtxsid,
      as.numeric(cas_rank) < as.numeric(compound_rank) ~ cas_dtxsid,
      is.na(compound_rank) & !is.na(cas_rank) ~ cas_dtxsid,
      as.numeric(cas_rank) > as.numeric(compound_rank) ~ compound_dtxsid,
      !is.na(compound_rank) & is.na(cas_rank) ~ compound_dtxsid,
      .default = NA
    ),
    auth = forcats::fct_relevel(auth, c("TRUE", "FALSE", "MISS"))
  ) %>%
  arrange(auth) %>%
  select(-analyte) %>%
  rename(analyte = raw_analyte)



# toxpi -------------------------------------------------------------------

temp <- chemi_hazard(testing_chemicals$dtxsid)

library(toxpiR)

data(txp_example_input, package = "toxpiR")

temp2 <- txp_example_input %>%
  as_tibble() %>%
  select(name, metric1:metric3) %>%
  mutate(across(matches("metric2"), function(x) {
    x^2
  }))

g_list <- temp %>%
  colnames(.) %>%
  str_subset(., pattern = "name", negate = T) %>%
  enframe(name = "group", value = "endpoint") %>%
  mutate(group = case_when(
    str_detect(endpoint, pattern = "2|3") ~ "Slice2",
    .default = "Slice1"
  )) %>%
  split(.$group) %>%
  map(., ~ select(., endpoint)) %>%
  map(., pluck(1))

slice_list <- TxpSliceList()

slice_list <- map2(g_list, names(g_list), function(x, y) {
  y <- TxpSlice(x)
})

trans_list <- list(f1 = NULL, f2 = function(x) log10(x))
weightslist <- c(2, 1)

model <- TxpModel(
  txpSlices = slice_list,
  txpWeights = weightslist,
  txpTransFuncs = trans_list
)

result <- txpCalculateScores(
  model = model,
  input = temp,
  id.var = "name"
)


# tp2 ---------------------------------------------------------------------

temp <- chemi_hazard(testing_chemicals$dtxsid)
temp <- temp$records

ec <- tp_endpoint_coverage(table = temp, id = "dtxsid", filter = 0.5) %>%
  mutate(endpoint = forcats::fct(endpoint))

g_list <- temp %>%
  select(ec$endpoint) %>%
  colnames(.) %>%
  enframe(name = "group", value = "endpoint") %>%
  # mutate(group = paste0('Slice', group)) %>%
  # split(.$group) %>%
  split(.$endpoint) %>%
  .[order(match(names(.), ec$endpoint))] %>%
  map(., ~ select(., endpoint)) %>%
  map(., pluck(1))

slice_list <- TxpSliceList()

slice_list <- map2(g_list, names(g_list), function(x, y) {
  y <- TxpSlice(x)
})

model <- TxpModel(
  txpSlices = slice_list
  # ,txpWeights = weightslist
  # ,txpTransFuncs = trans_list
)

result <- txpCalculateScores(
  model = model,
  input = temp,
  id.var = "dtxsid"
)

top <- tibble(dtxsid = result@txpIDs, score = result@txpScores) %>%
  arrange(desc(score)) %>%
  # left_join(., temp$headers) %>%
  filter(score > 0.15) %>%
  slice_sample(n = 10)

bind_cols(dtxsid = result@txpIDs, result@txpSliceScores) %>%
  # left_join(df$headers, .) %>%
  filter(dtxsid %in% top$dtxsid)

p1 <- plot(
  # result['DTXSID9032537'],
  result[result@txpIDs %in% top$dtxsid],
  # result,
  package = "gg",
  fills = ComptoxR::cust_pal,
  bgColor = NULL,
  borderColor = "black",
  sliceBorderColor = NULL,
  sliceLineColor = "black",
  sliceValueColor = "black",
  showCenter = FALSE,
  ncol = 5,
  showMissing = TRUE
)

# EP spill ----------------------------------------------------------------


ep_spill <- c(
  "POLYPROPYLENE",
  "POLYETHYLENE",
  "VINYL CHLORIDE",
  "DIPROPYLENE GLYCOL",
  "PROPYLENE GLYCOL",
  "DIETHYLENE GLYCOL",
  "ETHYLENE GLYCOL MONOBUTYL ETHER",
  "ETHYLHEXYL ACRYLATE",
  "POLYVINYL",
  "PETROLEUM LUBE OIL",
  "POLYPROPYL GLYCOL",
  "ISOBUTYLENE",
  "BUTYL ACRYLATES, STABILIZED",
  "BENZENE",
  "PARAFFIN WAX"
)

ep_dat <- ct_search(
  type = "string",
  search_param = "equal",
  query = ep_spill,
  suggestions = F
)

ep_search <- ep_dat %>%
  filter(!is.na(dtxsid))

ep_dat <- chemi_hazard(ep_search$dtxsid, coerce = "bin")

temp <- ep_dat$records %>%
  left_join(ep_dat$headers, ., join_by(dtxsid)) %>%
  select(-dtxsid)

{
  endpoints_list <- list(
    "Full" = list(
      "acuteMammalianOral",
      "acuteMammalianDermal",
      "acuteMammalianInhalation",
      "developmental",
      "reproductive",
      "endocrine",
      "genotoxicity",
      "carcinogenicity",
      "neurotoxicitySingle",
      "neurotoxicityRepeat",
      "systemicToxicitySingle",
      "systemicToxicityRepeat",
      "eyeIrritation",
      "skinIrritation",
      "skinSensitization",
      "acuteAquatic",
      "chronicAquatic",
      "persistence",
      "bioaccumulation",
      "exposure"
    ),
    "Emergency Response" = list(
      "acuteMammalianOral",
      "acuteMammalianDermal",
      "acuteMammalianInhalation",
      "genotoxicity",
      "neurotoxicitySingle",
      "systemicToxicitySingle",
      "eyeIrritation",
      "skinIrritation",
      "skinSensitization",
      "acuteAquatic"
    ),
    "Site-Specific" = list(
      "developmental",
      "reproductive",
      "endocrine",
      "genotoxicity",
      "carcinogenicity",
      "neurotoxicityRepeat",
      "systemicToxicityRepeat",
      "chronicAquatic",
      "persistence",
      "bioaccumulation"
    )
  )
}

profile <- "Emergency Response"

ec <- tp_endpoint_coverage(table = temp, id = "name", filter = 0) %>%
  mutate(endpoint = forcats::fct(endpoint)) %>%
  filter(endpoint %in% endpoints_list$`Emergency Response`)
# filter(endpoint %in% endpoints_list$`Site-Specific`)
# filter(endpoint %in% endpoints_list$Full)

info <- tp_variable_coverage(table = temp, id = "name")

{
  g_list <- temp %>%
    select(ec$endpoint) %>%
    colnames(.) %>%
    enframe(name = "group", value = "endpoint") %>%
    # mutate(group = paste0('Slice', group)) %>%
    # split(.$group) %>%
    split(.$endpoint) %>%
    .[order(match(names(.), ec$endpoint))] %>%
    map(., ~ select(., endpoint)) %>%
    map(., pluck(1))


  slice_list <- TxpSliceList()

  slice_list <- map2(g_list, names(g_list), function(x, y) {
    y <- TxpSlice(x)
  })

  model <- TxpModel(
    txpSlices = slice_list
    # ,txpWeights = weightslist
    # ,txpTransFuncs = trans_list
  )

  result <- txpCalculateScores(
    model = model,
    input = temp,
    id.var = "name"
  )

  top <- tibble(name = result@txpIDs, score = result@txpScores) %>%
    arrange(desc(score)) %>%
    left_join(., ep_dat$headers)

  plot(
    result[result@txpIDs %in% top$name] %>%
      .[order(txpRanks(result)[1:length(result)])],
    package = "gg",
    fills = ComptoxR::cust_pal,
    bgColor = NULL,
    borderColor = "black",
    sliceBorderColor = "black",
    # liceLineColor = "black",
    sliceValueColor = "black",
    showCenter = FALSE,
    ncol = 3,
    showMissing = FALSE
  ) +
    ggtitle(paste("Hazard Comparison Profile:", profile))
}

ggsave_all("hcd_ep_spill")

# testing_tp --------------------------------------------------------------


ep_dat <- chemi_hazard(testing_chemicals$dtxsid, coerce = "bin")

temp <- ep_dat$records %>%
  left_join(ep_dat$headers, ., join_by(dtxsid)) %>%
  select(-dtxsid)

{
  endpoints_list <- list(
    "Full" = list(
      "acuteMammalianOral",
      "acuteMammalianDermal",
      "acuteMammalianInhalation",
      "developmental",
      "reproductive",
      "endocrine",
      "genotoxicity",
      "carcinogenicity",
      "neurotoxicitySingle",
      "neurotoxicityRepeat",
      "systemicToxicitySingle",
      "systemicToxicityRepeat",
      "eyeIrritation",
      "skinIrritation",
      "skinSensitization",
      "acuteAquatic",
      "chronicAquatic",
      "persistence",
      "bioaccumulation",
      "exposure"
    ),
    "Emergency Response" = list(
      "acuteMammalianOral",
      "acuteMammalianDermal",
      "acuteMammalianInhalation",
      "genotoxicity",
      "neurotoxicitySingle",
      "systemicToxicitySingle",
      "eyeIrritation",
      "skinIrritation",
      "skinSensitization",
      "acuteAquatic"
    ),
    "Site-Specific" = list(
      "developmental",
      "reproductive",
      "endocrine",
      "genotoxicity",
      "carcinogenicity",
      "neurotoxicityRepeat",
      "systemicToxicityRepeat",
      "chronicAquatic",
      "persistence",
      "bioaccumulation"
    )
  )
}

profile <- "Emergency Response"

ec <- tp_endpoint_coverage(table = temp, id = "name", filter = 0) %>%
  mutate(endpoint = forcats::fct(endpoint)) %>%
  filter(endpoint %in% endpoints_list$`Emergency Response`)
# filter(endpoint %in% endpoints_list$`Site-Specific`)
# filter(endpoint %in% endpoints_list$Full)

info <- tp_variable_coverage(table = temp, id = "name")

tp_headers <- tibble(id = result@txpIDs, txpScores = result@txpScores, rank = result@txpRanks)

info_tbl <- left_join(info, tp_headers, join_by(name == id)) %>%
  arrange(rank) %>%
  mutate(name = forcats::fct_reorder(name, desc(rank)))

ggplot(info_tbl) +
  aes(x = txpScores, y = name, color = data_coverage) +
  geom_point(shape = "circle", size = 3.45, alpha = 0.5) +
  scale_color_viridis_c(option = "viridis", direction = 1) +
  labs(
    x = "Risk Score",
    y = "Compound",
    title = "Relative Risk Ranking",
    caption = "Color indicates data coverage on [0-1] scale",
    color = "Data Coverage Score"
  ) +
  theme_classic() +
  theme(
    axis.title.y = element_text(size = 14L),
    axis.title.x = element_text(size = 14L)
  )



{
  g_list <- temp %>%
    select(ec$endpoint) %>%
    colnames(.) %>%
    enframe(name = "group", value = "endpoint") %>%
    # mutate(group = paste0('Slice', group)) %>%
    # split(.$group) %>%
    split(.$endpoint) %>%
    .[order(match(names(.), ec$endpoint))] %>%
    map(., ~ select(., endpoint)) %>%
    map(., pluck(1))


  slice_list <- TxpSliceList()

  slice_list <- map2(g_list, names(g_list), function(x, y) {
    y <- TxpSlice(x)
  })

  model <- TxpModel(
    txpSlices = slice_list
    # ,txpWeights = weightslist
    # ,txpTransFuncs = trans_list
  )

  result <- txpCalculateScores(
    model = model,
    input = temp,
    id.var = "name"
  )

  top <- tibble(name = result@txpIDs, score = result@txpScores) %>%
    arrange(desc(score)) %>%
    left_join(., ep_dat$headers) %>%
    slice_head(n = 10)

  plot(
    result[result@txpIDs %in% top$name] %>%
      .[order(txpRanks(.)[1:length(.)])],
    package = "gg",
    fills = ComptoxR::cust_pal,
    bgColor = NULL,
    borderColor = "black",
    sliceBorderColor = "black",
    # liceLineColor = "black",
    sliceValueColor = "black",
    showCenter = FALSE,
    ncol = ceiling(sqrt(nrow(top))),
    showMissing = FALSE
  ) +
    ggtitle(paste("Hazard Comparison Profile:", profile, "\n"))
}

ggsave_all("hcm_er")






# toxprint ----------------------------------------------------------------
burl <- paste0(Sys.getenv("chemi_burl"), "api/toxprints/calculate")

query <- testing_chemicals$dtxsid[1:3] %>%
  ct_details(query = ., projection = "structure")

query <- ct_list("ANTIMICROBIALS")
query <- query[["ANTIMICROBIALS"]][["dtxsids"]] %>%
  ct_details(query = ., projection = "structure") %>%
  filter(!is.na(smiles))

options <- list(
  "OR" = 3L,
  "PV1" = 0.05,
  "TP" = 3
)

chemicals <- vector(mode = "list", length = length(query))

chemicals <- map2(query$dtxsid, query$smiles, ~ {
  list(
    "sid" = .x,
    "smiles" = .y
  )
})

chemicals <- list(
  list(
    # "id"= "21317",
    # "cid"= "DTXCID801317",
    "sid" = "DTXSID2021317",
    # "casrn"= "630-20-6",
    # "name"= "1,1,1,2-Tetrachloroethane",
    "smiles" = "ClC(Cl)(Cl)CCl"
    # "canonicalSmiles"= "ClCC(Cl)(Cl)Cl",
    # "inchi"= "InChI=1S/C2H2Cl4/c3-1-2(4,5)6/h1H2",
    # "inchiKey"= "QVLAWKAXOMEXPM-UHFFFAOYSA-N",
    # "checked"= 'true'
  ),
  list(
    # "id"= "21381",
    # "cid"= "DTXCID501381",
    "sid" = "DTXSID0021381",
    # "casrn"= "71-55-6",
    # "name"= "1,1,1-Trichloroethane",
    "smiles" = "CC(Cl)(Cl)Cl"
    # "canonicalSmiles"= "CC(Cl)(Cl)Cl",
    # "inchi"= "InChI=1S/C2H3Cl3/c1-2(3,4)5/h1H3",
    # "inchiKey"= "UOCLXMDMGBRAIB-UHFFFAOYSA-N",
    # "checked"= 'true'
  ),
  list(
    # "id"= "21318",
    # "cid"= "DTXCID201318",
    "sid" = "DTXSID7021318",
    # "casrn"= "79-34-5",
    # "name"= "1,1,2,2-Tetrachloroethane",
    "smiles" = "ClC(Cl)C(Cl)Cl"
    # "canonicalSmiles"= "ClC(Cl)C(Cl)Cl",
    # "inchi"= "InChI=1S/C2H2Cl4/c3-1(4)2(5)6/h1-2H",
    # "inchiKey"= "QPFMBZIOSGYJDE-UHFFFAOYSA-N",
    # "checked"= 'true'
  )
)

payload <- list(
  "chemicals" = chemicals,
  "options" = options
)

response <- POST(
  url = burl,
  # url = 'https://hcd.rtpnc.epa.gov/api/toxprints/calculate',
  body = jsonlite::toJSON(payload, auto_unbox = T),
  content_type("application/json"),
  accept("*/*"),
  progress()
) %>%
  content(., "text", encoding = "UTF-8") %>%
  fromJSON(simplifyVector = FALSE)


metrics <- response$metrics %>%
  map(., as_tibble) %>%
  list_rbind()

bits <- response$chemicals %>%
  map(., ~ {
    .x <- keep(.x, names(.) %in% c("sid", "bits"))
  })

bits <- set_names(bits, ~ {
  map_depth(bits, 1, ~ pluck(., "sid")) %>%
    list_c()
  }, .progress = T) %>%
  map(., ~ discard_at(.x, "sid"), .progress = T) %>%
  map(., ~ pluck(., "bits"), .progress = T) %>%
  compact() %>%
  map(., ~ set_names(.x, toxprint_ID_key$`ToxPrint name`)) %>%
  map(., as_tibble, .progress = T) %>%
  list_rbind(names_to = "dtxsid")


