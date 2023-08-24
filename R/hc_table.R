#' Create the Hazard Comparison matrix.
#'
#' This involves calling several functions
#' other `ComptoxR` functions and processes the results. Large queries may take
#' some time to request. Returns a table with the available endpoints in a
#' binned format ('VH', 'H', 'M', 'L', 'NA') as well as a numerical response. Some of
#' the endpoints have been transformed to better allow for a relative risk
#' characterization. Where responses are not available, a 'NA' response will be
#' present.
#'
#'
#' @param query Takes a list of compounds using DTXSIDs
#' @param archive Boolean value to use archived data from a previous run to recreate table. Defaults to `FALSE`. File will be prefixed with `search_data_` and a date-time suffix.
#' @param save Boolean value to save searched data. Highly recommended to be enabled. File will be prefixed with `search_data_` and a date-time suffix.
#'
#' @return A tibble of results
#' @export

hc_table <- function(query, archive = FALSE, save = TRUE){


if (archive == TRUE) {
  cat('\nAttempting to load from saved data...\n')
  foo <- file.info(list.files(path = ".", pattern = "^search_data_"))
  if(nrow(foo) == 0){
    cat('\nNo files found! Are you in the right working directory?\n')

  }else{

    cache <- rownames(foo)[which.max(foo$mtime)]
    search_data <- readRDS(cache)
    cat("\nFile loaded:\n", cache, "\n")
    search_data$query -> query
    search_data$q -> q
    search_data$se -> se
    search_data$c -> c
    search_data$g -> g
    search_data$f -> f
    search_data$p -> p
    search_data$d -> d
    search_data$t -> t
    search_data$ghs -> ghs

    rm(foo, cache, search_data)}

}else{

  if(missing(query) == T){stop('No query list found!')}


  cat('\nStarting search...\n')
  q <- ct_hazard(query)
  se <-ct_skin_eye(query)
  c <- ct_cancer(query)
  g <- ct_genotox(query)
  f <- ct_env_fate(query)
  p <- ct_prop(query)
  d <- ct_details(query)
  t <- ct_test(query)
  ghs <- ct_ghs(query)
}



  ##Preload----
  #takes a list data frame with hazard data from API and creates comparison tables
  {

    h_list <- list()
    h_list$compound <- unlist(query) %>% as_tibble()
    colnames(h_list$compound) <- 'compound'

    e_list <- list()

  }
  ###Human health----
  ####Oral----
  {
    e_list$haz <- q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'oral') %>% #Remove dashed parameter to remove TEST
      dplyr::filter(toxvalType == 'LD50') %>%
      dplyr::filter(toxvalUnits == 'mg/kg' | toxvalUnits == 'mg/kg') %>%
      group_by(compound) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Oral = case_when(
        amount <= 50 ~ 'VH',
        (amount > 50 & amount <= 300)  ~ 'H',
        (amount > 300 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>%
      rename(oral_amount = amount)

    #finds GHS data points, adds median values for amounts
    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Oral = case_when(
        Result = str_detect(Result, 'H300') ~ 'VH',
        Result = str_detect(Result, 'H301') ~ 'H',
        Result = str_detect(Result, 'H302') ~ 'M',
        Result = str_detect(Result, 'H303') ~ 'L'
      )) %>%
      dplyr::filter(!is.na(Oral)) %>%
      arrange(compound, factor(Oral, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Oral) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(oral_amount = case_when(
        Oral == 'VH' ~ 50,
        Oral == 'H' ~ 175,
        Oral == 'M' ~ 1150,
        Oral == 'L' ~ 2000,
      ))

    e_list$test <- t %>%
      dplyr::filter(endpoint == 'LD50') %>%
      group_by(compound) %>%
      summarize(amount = as.numeric(predValMass)) %>%
      mutate(Oral = case_when(
        amount <= 50 ~ 'VH',
        (amount > 50 & amount <= 300)  ~ 'H',
        (amount > 300 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>%
      rename(oral_amount = amount)

    e_list$h_test <- q %>%
      dplyr::filter(source == 'TEST' & exposureRoute == 'oral') %>%
      dplyr::filter(toxvalType == 'LD50') %>%
      group_by(compound) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Oral = case_when(
        amount <= 50 ~ 'VH',
        (amount > 50 & amount <= 300)  ~ 'H',
        (amount > 300 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>%
      rename(oral_amount = amount)

    h_list$oral <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','ghs','h_test','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(oral_amount = -log10(oral_amount)+10)

    e_list <- list()

    cat('\nOral search complete!\n')
  }
  ####Dermal----
  {
    e_list$haz <-  q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'dermal') %>%
      dplyr::filter(toxvalType == 'LD50') %>%
      dplyr::filter(toxvalUnits == 'mg/kg') %>%
      group_by(compound) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Dermal = case_when(
        amount <= 200 ~ 'VH',
        (amount > 200 & amount <= 1000)  ~ 'H',
        (amount > 1000 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>% rename(dermal_amount = amount)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Dermal = case_when(
        Result = str_detect(Result, 'H310') ~ 'VH',
        Result = str_detect(Result, 'H311') ~ 'H',
        Result = str_detect(Result, 'H312') ~ 'M',
        Result = str_detect(Result, 'H313') ~ 'L'
      )) %>%
      dplyr::filter(!is.na(Dermal)) %>%
      arrange(compound, factor(Dermal, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Dermal) %>%
      distinct(compound, .keep_all = T)%>%
      mutate(dermal_amount = case_when(
        Dermal == 'VH' ~ 200,
        Dermal == 'H' ~ 600,
        Dermal == 'M' ~ 1500,
        Dermal == 'L' ~ 2000,
      ))

    h_list$derm <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(dermal_amount = -log10(dermal_amount)+10)

    e_list <- list()

    cat('\nDermal search complete!\n')
  }
  ####Inhalation----
  {
    e_list$haz <-  q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'inhalation') %>%
      #dplyr::filter(riskAssessmentClass == 'acute') %>%
      dplyr::filter(toxvalType == 'LC50') %>%
      dplyr::filter(toxvalUnits == 'mg/m3') %>% # removed (toxvalUnits == 'mg/L'|)
      group_by(compound) %>%
      summarize(amount = (min(toxvalNumeric)*0.001)) %>%
      mutate(Inhalation = case_when(
        amount <= 2 ~ 'VH',
        (amount > 2 & amount <= 10)  ~ 'H',
        (amount > 10 & amount <= 20)  ~ 'M',
        amount > 20 ~ 'L'
      )) %>% rename(inhalation_amount = amount)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Inhalation = case_when(
        Result = str_detect(Result, 'H330') ~ 'VH',
        Result = str_detect(Result, 'H331') ~ 'H',
        Result = str_detect(Result, 'H332') ~ 'M',
        Result = str_detect(Result, 'H333') ~ 'L'
      )) %>%
      dplyr::filter(!is.na(Inhalation)) %>%
      arrange(compound, factor(Inhalation, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Inhalation) %>%
      distinct(compound, .keep_all = T)%>%
      mutate(inhalation_amount = case_when(
        Inhalation == 'VH' ~ 2,
        Inhalation == 'H' ~ 6,
        Inhalation == 'M' ~ 15,
        Inhalation == 'L' ~ 20,
      ))

    #binds two df together

    h_list$inhal <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(inhalation_amount = -log10(inhalation_amount)+10)

    e_list <- list()

    cat('\nInhalation search complete!\n')
  }
  ####Cancer----
  {
    e_list$haz <- c %>%
      dplyr::filter(dtxsid %in% query) %>%
      group_by(dtxsid) %>%
      mutate(Carcinogenicity = case_when(
        Result = str_detect(cancerCall,'Known Human Carcinogen|potential occupational carcinogen|Likely Human Carcinogen|Likely to be Carcinogenic to Humans|Likely to be carcinogenic to humans|Carcinogenic to humans|Known|Group 1|Group 2A|Group A|Group B|B1|B2') ~ 'VH',
        Result = str_detect(cancerCall,'(Possible human carcinogen)|2B|Group C|Reasonably Anticipated') ~ 'H',
        Result = str_detect(cancerCall, 'Suggestive Evidence|Suggestive evidence') ~ 'M',
        Result = str_detect(cancerCall, 'Group 4|Group E') ~ 'L'
      )) %>%
      dplyr::filter(!is.na(Carcinogenicity)) %>%
      select(dtxsid, Carcinogenicity) %>%
      rename(compound = dtxsid) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 10000,
        Carcinogenicity == 'H' ~ 1000,
        Carcinogenicity == 'M' ~ 10,
        Carcinogenicity == 'L' ~ 1,
      )) %>% relocate(cancer_amount, .after = compound)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Carcinogenicity = case_when(
        Result = str_detect(Result, 'H350') ~ 'VH',
        Result = str_detect(Result, 'H351') ~ 'H'
      )) %>%
      dplyr::filter(!is.na(Carcinogenicity)) %>%
      arrange(compound, factor(Carcinogenicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Carcinogenicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 10000,
        Carcinogenicity == 'H' ~ 1000,
        Carcinogenicity == 'M' ~ 10,
        Carcinogenicity == 'L' ~ 1,
      ))

    e_list$reach <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, 'Carcinogenic')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Carcinogenicity = case_when(
        str_detect(reason, 'Carcinogenic') ~ 'VH'
      )) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 10000
      )) %>%
      rename(compound = dtxsid)

    h_list$cancer <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','reach','ghs'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()

    cat('\nCancer search complete!\n')
  }

  ####Genotoxic----
  {

    e_list$haz <- g %>%
      dplyr::filter(assayResult == 'positive' & assayCategory == 'in vitro' | assayCategory == 'in vivo') %>%
      group_by(dtxsid) %>%
      select(dtxsid, assayCategory) %>%
      mutate(active = 1) %>%
      pivot_wider(id_cols = dtxsid, names_from = assayCategory, values_from = active, values_fn = mean) %>%
      mutate(Mutagenicity = case_when(
        `in vivo` == 1 & `in vitro` == 1 ~ 'H',
        is.na(`in vivo`) == T | is.na(`in vitro`) == 1 ~ 'M'

      )) %>%
      select(dtxsid, Mutagenicity) %>%
      mutate(geno_amount = case_when(
        Mutagenicity  == 'H' ~ 500,
        Mutagenicity  == 'M' ~ 100
      )) %>%
      rename(compound = dtxsid)

    e_list$test <- t %>%
      dplyr::filter(endpoint == 'Mutagenicity') %>%
      group_by(compound) %>%
      summarize(amount = predActive) %>%
      mutate(Mutagenicity = case_when(
        amount == TRUE ~ 'H',
        amount == FALSE ~ 'L'
      )) %>%
      rename(geno_amount = amount) %>%
      mutate(geno_amount = case_when(
        geno_amount  == TRUE ~ 500,
        geno_amount  == FALSE ~ 25
      ))

    e_list$reach <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, 'Mutagenic')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Mutagenicity = case_when(
        str_detect(reason, 'Mutagenic') ~ 'VH'
      )) %>%
      mutate(geno_amount = case_when(
        Mutagenicity == 'VH' ~ 1000
      )) %>%
      rename(compound = dtxsid)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Mutagenicity = case_when(
        Result = str_detect(Result, 'H340') ~ 'VH',
        Result = str_detect(Result, 'H341') ~ 'H'
      )) %>%
      dplyr::filter(!is.na(Mutagenicity)) %>%
      arrange(compound, factor(Mutagenicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Mutagenicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(geno_amount = case_when(
        Mutagenicity == 'VH' ~ 1000,
        Mutagenicity == 'H' ~ 500
      ))

    h_list$geno <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','reach','ghs','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()

    cat('\nMutagenic search complete!\n')

  }
  ####Endocrine-----
  {
    e_list$reach <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, 'Endocrine disrupting properties')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Endocrine_Disruption = case_when(
        str_detect(reason, 'Endocrine disrupting properties') ~ 'H'
      )) %>%
      mutate(endo_amount = case_when(
        Endocrine_Disruption == 'H' ~ 500
      )) %>%
      rename(compound = dtxsid)


    e_list$test <- t %>%
      dplyr::filter(compound %in% query) %>%
      dplyr::filter(endpoint == 'ER_Binary') %>%
      group_by(compound) %>%
      summarize(amount = predActive) %>%
      mutate(Endocrine_Disruption = case_when(
        amount == TRUE ~ 'H',
        amount == FALSE ~ 'L'
      )) %>%
      rename(endo_amount = amount) %>%
      mutate(endo_amount = case_when(
        endo_amount  == TRUE ~ 500,
        endo_amount  == FALSE ~ 25
      ))

    h_list$endo <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('reach','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()

    cat('\nEndocrine disruptor search complete!\n')


  }
  ####Reproductive----
  {
    e_list$haz <- q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'oral' & toxvalUnits == 'mg/kg-day' | exposureRoute == 'dermal' & toxvalUnits == 'mg/kg-day' | exposureRoute == 'inhalation' & toxvalUnits == 'mg/L' | exposureRoute == 'inhalation' & toxvalUnits == 'mg/m3' | exposureRoute == 'inhalation' & toxvalUnits == 'ppm') %>%
      dplyr::filter(toxvalType == 'NOAEL' | toxvalType == 'LOAEL' | toxvalType == 'LOAEC' | toxvalType == 'NOAEC') %>%
      dplyr::filter(str_detect(studyType, 'reproduct|multigeneration'))  %>%
      group_by(compound, exposureRoute, toxvalUnits) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(amount = case_when(
        exposureRoute == 'inhalation' & toxvalUnits == 'mg/m3' ~ amount/1000,
        TRUE ~ amount
      )) %>%
      mutate(Reproductive = case_when(
        exposureRoute == 'oral' & amount < 50 | exposureRoute == 'dermal' & amount < 100 | exposureRoute == 'inhalation' & amount < 1 ~ 'H',
        exposureRoute == 'oral' & amount >= 50 & amount <= 250 | exposureRoute == 'oral' & amount >= 100 & amount <= 500 | exposureRoute == 'inhalation' & amount >= 1 & amount <= 2.5 ~ 'M',
        exposureRoute == 'oral' & amount > 250 | exposureRoute == 'dermal' & amount > 500 | exposureRoute == 'inhalation' & amount > 2.5 ~ 'L',

      )) %>%
      as_tibble() %>%
      select(-toxvalUnits, -exposureRoute) %>%
      arrange(compound, factor(Reproductive, levels = c('VH', 'H','M','L'))) %>%
      distinct(compound, .keep_all = T) %>%
      rename(reproductive_amount = amount)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Reproductive = case_when(
        Result = str_detect(Result, 'H360|H360F|H360Fd|H360FD') ~ 'H',
        Result = str_detect(Result, 'H360Df|H361|H361D|H361f') ~ 'M'
      )) %>%
      dplyr::filter(!is.na(Reproductive)) %>%
      arrange(compound, factor(Reproductive, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Reproductive) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 1000,
        Reproductive == 'M' ~ 10,
        Reproductive == 'L' ~ 1,
      ))

    e_list$reach <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, 'Toxic for reproduction')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Reproductive = case_when(
        str_detect(reason, 'Toxic for reproduction') ~ 'H'
      )) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 1000
      )) %>%
      rename(compound = dtxsid)

    h_list$reprod <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','reach','ghs'))) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 1000,
        Reproductive == 'M' ~ 10,
        Reproductive == 'L' ~ 1,
      )) %>%
      select(-source)

    e_list <- list()

    cat('\nReproductive search complete!\n')
  }

  ####Developmental----
  {
    e_list$haz <- q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'oral' & toxvalUnits == 'mg/kg-day' | exposureRoute == 'dermal' & toxvalUnits == 'mg/kg-day' | exposureRoute == 'inhalation' & toxvalUnits == 'mg/L' | exposureRoute == 'inhalation' & toxvalUnits == 'mg/m3' | exposureRoute == 'inhalation' & toxvalUnits == 'ppm') %>%
      dplyr::filter(toxvalType == 'NOAEL' | toxvalType == 'LOAEL' | toxvalType == 'LOAEC' | toxvalType == 'NOAEC') %>%
      dplyr::filter(str_detect(studyType, 'develop'))  %>%
      dplyr::filter(!str_detect(studyType, 'reproduct|multigeneration'))  %>%
      group_by(compound, exposureRoute, toxvalUnits) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(amount = case_when(
        exposureRoute == 'inhalation' & toxvalUnits == 'mg/m3' ~ amount/1000,
        TRUE ~ amount
      )) %>%
      mutate(Developmental = case_when(
        exposureRoute == 'oral' & amount < 50 | exposureRoute == 'dermal' & amount < 100 | exposureRoute == 'inhalation' & amount < 1 ~ 'H',
        exposureRoute == 'oral' & amount >= 50 & amount <= 250 | exposureRoute == 'oral' & amount >= 100 & amount <= 500 | exposureRoute == 'inhalation' & amount >= 1 & amount <= 2.5 ~ 'M',
        exposureRoute == 'oral' & amount > 250 | exposureRoute == 'dermal' & amount > 500 | exposureRoute == 'inhalation' & amount > 2.5 ~ 'L',

      )) %>% as_tibble() %>%
      select(-toxvalUnits, -exposureRoute) %>%
      arrange(compound, factor(Developmental, levels = c('VH', 'H','M','L'))) %>%
      distinct(compound, .keep_all = T) %>%
      rename(developmental_amount = amount) %>%
      mutate(developmental_amount = case_when(
        Developmental == 'H' ~ 1000,
        Developmental == 'M' ~ 10,
        Developmental == 'L' ~ 1,
      ))


    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      group_by(compound) %>%
      mutate(Developmental = case_when(
        Result = str_detect(Result, 'H360|H360Df|H360D|H360FD|H360Df|H362') ~ 'H',
        Result = str_detect(Result, 'H36Fd|H361|H361d|H361fd') ~ 'M'
      )) %>%
      dplyr::filter(!is.na(Developmental)) %>%
      arrange(compound, factor(Developmental, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Developmental) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(developmental_amount = case_when(
        Developmental == 'H' ~ 1000,
        Developmental == 'M' ~ 100,
        Developmental == 'L' ~ 10
      ))


    e_list$test <-t %>%
      dplyr::filter(endpoint == 'DevTox') %>%
      group_by(compound) %>%
      summarize(amount = predActive) %>%
      mutate(Developmental = case_when(
        amount == TRUE ~ 'H',
        amount == FALSE ~ 'L'
      )) %>%
      mutate(developmental_amount = case_when(
        amount  == TRUE ~ 1000,
        amount  == FALSE ~ 10
      )) %>%
      select(-amount)

    h_list$develop <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','ghs', 'test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()

    cat('\nDevelopmental search complete!\n')
  }

  ##Ecotox----
  ####Acute Aquatic Toxicity----
  {
    e_list$haz <- q %>%
      dplyr::filter(humanEcoNt == 'eco') %>%
      dplyr::filter(speciesCommon %in% std_spec$common) %>%
      dplyr::filter(studyDurationUnits == 'days') %>%
      dplyr::filter(studyDurationValue <= 6) %>%
      dplyr::filter(toxvalUnits == 'mg/L' | toxvalUnits == 'ppm') %>%
      dplyr::filter(riskAssessmentClass  == 'acute') %>%
      dplyr::filter(toxvalType == 'LC50' | toxvalType == 'EC50') %>%
      group_by(compound, toxvalType) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      summarize(compound = compound, amount = min(amount)) %>%
      mutate('Acute_Aquatic_Toxicity' = case_when(

        (amount < 1) ~ 'VH',
        (amount >= 1 & amount <= 10)  ~ 'H',
        (amount > 10 & amount <= 100)  ~ 'M',
        (amount > 100) ~ 'L'
      )) %>%
      arrange(compound, factor(Acute_Aquatic_Toxicity, levels = c('VH', 'H','M','L'))) %>%
      distinct(compound, .keep_all = T) %>%
      rename(acute_aq_amount = amount)

    e_list$test <- t %>%
      dplyr::filter(endpoint == 'LC50') %>%
      group_by(compound) %>%
      summarize(amount = as.numeric(predValMass)) %>%
      mutate(Acute_Aquatic_Toxicity = case_when(

        (amount < 1) ~ 'VH',
        (amount >= 1 & amount <= 10)  ~ 'H',
        (amount > 10 & amount <= 100)  ~ 'M',
        (amount > 100) ~ 'L'
      )) %>%
      rename(acute_aq_amount = amount)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Acute_Aquatic_Toxicity = case_when(
        Result = str_detect(Result, 'H400') ~ 'VH',
        Result = str_detect(Result, 'H401') ~ 'H',
        Result = str_detect(Result, 'H402') ~ 'M',

      )) %>%
      dplyr::filter(!is.na(Acute_Aquatic_Toxicity)) %>%
      arrange(compound, factor(Acute_Aquatic_Toxicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Acute_Aquatic_Toxicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(acute_aq_amount = case_when(
        Acute_Aquatic_Toxicity == 'VH' ~ 1,
        Acute_Aquatic_Toxicity == 'H' ~ 5,
        Acute_Aquatic_Toxicity == 'M' ~ 50,
        Acute_Aquatic_Toxicity == 'L' ~ 100,
      ))

    h_list$ac_aqua <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','ghs', 'test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(acute_aq_amount = -log10(acute_aq_amount)+10)

    e_list <- list()

    cat('\nAcute aquatic search complete!\n')
  }
  ####Chronic Aquatic Toxicity----
  {
    e_list$chron_aqua <- q %>%
      dplyr::filter(humanEcoNt == 'eco') %>%
      dplyr::filter(speciesCommon %in% std_spec$common) %>%
      dplyr::filter(studyDurationUnits == 'days') %>%
      dplyr::filter(studyDurationValue > 6) %>%
      dplyr::filter(toxvalUnits == 'mg/L') %>%
      dplyr::filter(toxvalType == 'NOEC' | toxvalType == 'LOEC') %>%
      group_by(compound, toxvalType) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      summarize(compound = compound, amount = min(amount)) %>%
      mutate('Chronic_Aquatic_Toxicity' = case_when(

        (amount < 0.1) ~ 'VH',
        (amount >= 0.1 & amount <= 1)  ~ 'H',
        (amount > 1 & amount <= 10)  ~ 'M',
        (amount > 10) ~ 'L',

      )) %>%
      distinct() %>%
      rename(chronic_aq_amount = amount)

    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Chronic_Aquatic_Toxicity = case_when(
        Result = str_detect(Result, 'H410') ~ 'VH',
        Result = str_detect(Result, 'H4411') ~ 'H',
        Result = str_detect(Result, 'H412') ~ 'M',
        Result = str_detect(Result, 'H413') ~ 'L'
      )) %>%
      dplyr::filter(!is.na(Chronic_Aquatic_Toxicity)) %>%
      arrange(compound, factor(Chronic_Aquatic_Toxicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Chronic_Aquatic_Toxicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(chronic_aq_amount = case_when(
        Chronic_Aquatic_Toxicity == 'VH' ~ 0.1,
        Chronic_Aquatic_Toxicity == 'H' ~ 0.55,
        Chronic_Aquatic_Toxicity == 'M' ~ 5.5,
        Chronic_Aquatic_Toxicity == 'L' ~ 10,
      ))

    h_list$chron_aqua <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('haz','ghs'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(chronic_aq_amount = -log10(chronic_aq_amount)+10)

    e_list <- list()

    cat('\nChronic aquatic search complete!\n')
  }


  #Other----
  ###Ignition----
  {
    e_list$ghs <- ghs %>%
      group_by(compound) %>%
      mutate(Ignitability = case_when(
        Result = str_detect(Result, 'H230|H231|H232|H250|H251|H252|H271') ~ 'VH',
        Result = str_detect(Result, 'H220|H224|H270') ~ 'H',
        Result = str_detect(Result, 'H225|H226|H272') ~ 'M',
        Result = str_detect(Result, 'H221|H227|H228') ~ 'L'

      )) %>%
      dplyr::filter(!is.na(Ignitability)) %>%
      arrange(compound, factor(Ignitability, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Ignitability) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(ignite_amount = case_when(
        Ignitability == 'VH' ~ 10000,
        Ignitability == 'H' ~ 1000,
        Ignitability == 'M' ~ 100,
        Ignitability == 'L' ~ 1,
      ))

    e_list$prop <- p %>%
      rename('compound' = 'dtxsid') %>%
      group_by(compound) %>%
      mutate(Ignitability = case_when(
        name == 'Boiling Point' & value < 38 & name == 'Flash Point' & value < 38 ~ 'H',
        name == 'Boiling Point' & value > 38 & name == 'Flash Point' & value < 38 ~ 'M',
        name == 'Flash Point' & value >= 38 & name == 'Flash Point' & value <= 60 ~ 'L'

      )) %>%
      dplyr::filter(!is.na(Ignitability)) %>%
      arrange(compound, factor(propType, levels = c('experimental', 'predicted')), factor(Ignitability, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Ignitability) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(ignite_amount = case_when(
        Ignitability == 'VH' ~ 10000,
        Ignitability == 'H' ~ 1000,
        Ignitability == 'M' ~ 100,
        Ignitability == 'L' ~ 1,
      ))

    h_list$ignite <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('ghs','prop'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()
  }
  ###RXN Water----
  {
    h_list$waterrxn <- ghs %>%
      group_by(compound) %>%
      mutate(RxnWater = case_when(
        Result = str_detect(Result, 'H260') ~ 'VH',
        Result = str_detect(Result, 'H261') ~ 'H'
      )) %>%
      dplyr::filter(!is.na(RxnWater)) %>%
      arrange(compound, factor(RxnWater, levels = c('VH', 'H','M','L'))) %>%
      select(compound, RxnWater) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(rxnwater_amount = case_when(
        RxnWater == 'VH' ~ 10000,
        RxnWater == 'H' ~ 1000
      ))

    e_list <- list()
  }
  ###SelfRXN----
  {
    h_list$selfrxn <- ghs %>%
      group_by(compound) %>%
      mutate(SelfRxn = case_when(
        Result = str_detect(Result, 'H240|H241') ~ 'VH',
        Result = str_detect(Result, 'H251') ~ 'H',
        Result = str_detect(Result, 'H242|H252') ~ 'M',
      )) %>%
      dplyr::filter(!is.na(SelfRxn)) %>%
      arrange(compound, factor(SelfRxn, levels = c('VH', 'H','M','L'))) %>%
      select(compound, SelfRxn) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(selfrxn_amount = case_when(
        SelfRxn == 'VH' ~ 10000,
        SelfRxn == 'H' ~ 1000,
        SelfRxn == 'M' ~ 10,
      ))

    e_list <- list()
  }

  #Fate and transport----

  ####Persistence----
  {
    e_list$f <- f %>%
      dplyr::filter(endpointName == 'Biodeg. Half-Life') %>%
      arrange(dtxsid,
              factor(valueType, levels = c('experimental',
                                           'predicted'))) %>%
      distinct(dtxsid, .keep_all = T) %>%
      select(dtxsid, resultValue) %>%
      mutate('Persistence' = case_when(
        (resultValue) > 180 ~ 'VH',
        (resultValue >= 60 & resultValue <= 180)  ~ 'H',
        (resultValue >= 16 & resultValue < 60)  ~ 'M',
        (resultValue) < 16 ~ 'L',
      )) %>%
      rename(compound = dtxsid, persistance_amount = resultValue)

    e_list$r <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, '\\#PBT|\\#vPvB')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Persistence = case_when(
        str_detect(reason, '57e') ~ 'VH', #vPvB
        str_detect(reason, '57d') ~ 'H' #PBT
      )) %>%
      mutate(persistance_amount = case_when(
        Persistence == 'VH' ~ 180,
        Persistence == 'H' ~ 120 #median value from dict table
      )) %>%
      rename(compound = dtxsid)

    h_list$pers <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('f','r'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source)

    e_list <- list()

  }
  ####Bioaccumulation----
  {
    e_list$f <- f %>%
      dplyr::filter(endpointName == 'Bioconcentration Factor' | endpointName == 'Bioaccumulation Factor') %>%
      dplyr::filter(!is.na(resultValue)) %>%
      dplyr::select(dtxsid, endpointName, resultValue, unit, modelSource, valueType) %>% #TODO Account for ECOTOX that has max/min values
      arrange(dtxsid,
              desc(resultValue),
              factor(endpointName, levels = c('experimental',
                                              'predicted')),
              factor(endpointName, levels = c('Bioaccumulation Factor',
                                              'Bioconcentration Factor'))
      ) %>%
      distinct(dtxsid, .keep_all = T) %>%
      group_by(dtxsid) %>%
      summarize(bac_amount = log10(resultValue)) %>%
      mutate('Bioaccumulation' = case_when(
        bac_amount > 3.7 ~ 'VH',
        bac_amount <= 3.7 & bac_amount > 3  ~ 'H',
        bac_amount >= 3 & bac_amount < 2 ~ 'M',
        bac_amount <= 2 ~ 'L')) %>%
      rename(compound = dtxsid)

    e_list$r <- e_list$r <- reach %>%
      dplyr::filter(`CAS No.` %in% d$casrn) %>%
      dplyr::filter(str_detect(`Reason for inclusion`, '\\#PBT|\\#vPvB')) %>%
      rename(reason = `Reason for inclusion`) %>%
      left_join(., select(d, casrn, dtxsid), by = c(`CAS No.` = 'casrn')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Bioaccumulation = case_when(
        str_detect(reason, '57e') ~ 'VH', #vPvB
        str_detect(reason, '57d') ~ 'H' #PBT
      )) %>%
      mutate(bac_amount = case_when(
        Bioaccumulation == 'VH' ~ log10(5000), #median value from dict table
        Bioaccumulation == 'H' ~ log10(3000)
      )) %>%
      rename(compound = dtxsid)

    e_list$test <- t %>%
      dplyr::filter(endpoint == 'BCF') %>%
      group_by(compound) %>%
      select(method, compound, predValMass, expValMass) %>%
      pivot_longer(cols = predValMass:expValMass, names_to = 'model', values_to = 'bac_amount', values_drop_na = TRUE) %>%
      arrange(factor(model, levels = c('expValMass', 'predValMass')),
              factor(method, levels = c('consensus','hc','sm','gc','nn'))) %>%
      distinct(compound, .keep_all = T) %>%
      summarize(bac_amount = as.numeric(bac_amount)) %>%
      mutate('Bioaccumulation' = case_when(
        (bac_amount) > 3.7 ~ 'VH',
        (bac_amount >= 3 & bac_amount <= 3.7)  ~ 'H',
        (bac_amount >= 2 & bac_amount < 3)  ~ 'M',
        (bac_amount) < 2 ~ 'L'))

    h_list$bio <- map_dfr(e_list, as_tibble, .id = 'source') %>%
      arrange(factor(source, levels = c('f','r','test'))) %>%
      distinct(compound, .keep_all = T) %>%
      select(-source) %>%
      mutate(bac_amount = 10^bac_amount)

    cat('\nBioconcentration factor search complete!\n')

    e_list <- list()
  }

  ###Mobile----
  {
    e_list$m <- p %>%
      dplyr::filter(propertyId == 'logkow-octanol-water') %>%
      select(value, propType, unit, propertyId, dtxsid) %>%
      summarise(mobile_amount = mean(value), .by = c(dtxsid, propertyId, propType)) %>%
      arrange(dtxsid, propertyId, factor(propType, levels = c('experimental', 'predicted'))) %>%
      distinct(dtxsid, propertyId, .keep_all = T) %>%
      mutate(Mobility = case_when(
        #taken from vPvM definitions from REACH Art 57 (f)
        mobile_amount <= 3 ~ 'VH',
        mobile_amount < 4 ~ 'M',
        mobile_amount >= 4 ~ 'L'

      )) %>%
      select(-c(propertyId,propType)) %>%
      rename(compound = dtxsid)

    h_list$mobile <- map_dfr(e_list, as_tibble) %>%
      mutate(mobile_amount = 1/(mobile_amount^2))


    e_list <- list()
    cat('\nLogKow search complete!\n')
  }

  #Saving----
  if(save == TRUE){
    search_data <- list()
    search_data$query <- query
    search_data$q <- q
    search_data$se <- se
    search_data$c <- c
    search_data$g <- g
    search_data$f <- f
    search_data$p <- p
    search_data$d <- d
    search_data$t <- t
    search_data$ghs <-ghs

    saveRDS(search_data, file = paste0('search_data_',format(Sys.time(), "%Y-%m-%d_%H.%M.%S"),'.Rds'))

    cat('\nSearch data archived: ',paste0('search_data_',format(Sys.time(), "%Y-%m-%d_%H.%M.%S"),'.Rds'),'\n')


  }

  ##Joining----
  cat('\n')
  hc_summary <- reduce(h_list, left_join)
  cat('\nTable made!\n')

  return(hc_summary)

}

#' Function to load archived data in the working directory
#'
#' Helper function to debug the saved archive files. Also useful if a user would like to drill into the data.
#'
#' @return The files
#' @export

ct_archive_load <- function(){
  cat('\nAttempting to load from saved data...\n')
  foo <- file.info(list.files(path = ".", pattern = "^search_data_"))
  if(nrow(foo) == 0){
    cat('\nNo files found! Are you in the right working directory?\n')

  }else{

    cache <- rownames(foo)[which.max(foo$mtime)]
    search_data <- readRDS(cache)
    cat("\nFile loaded:\n", cache, "\n")


    search_data$q -> .GlobalEnv$q
    search_data$se -> .GlobalEnv$se
    search_data$c -> .GlobalEnv$c
    search_data$g -> .GlobalEnv$g
    search_data$f -> .GlobalEnv$f
    search_data$p -> .GlobalEnv$p
    search_data$d -> .GlobalEnv$d
    search_data$t -> .GlobalEnv$t
    search_data$ghs -> .GlobalEnv$ghs
    search_data ->.GlobalEnv$search_data

    rm(foo, cache, search_data)
    }
}
