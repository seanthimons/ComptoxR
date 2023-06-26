#Create HCD table-----

hcd_table <- function(dtx_list){

  #takes a hazard data and fate/transpo outputs to create table

  #q <- ct_hazard(dtx_list)
  #f <- ct_env_fate(dtx_list)
  #t <- ct_bulk_test(dtx_list)
  #ghs <- ct_ghs(dtx_list)

  ##Preload----
  #takes a list data frame with hazard data from API and creates comparison tables

  df_length = length(dtx_list)
  hcd_summary <- data.frame(matrix(ncol = 1,nrow = df_length))

  colnames(hcd_summary) <- 'Compound'

  hcd_summary$Compound <- dtx_list
  hcd_summary$Compound <- as.character(hcd_summary$Compound)

  rm(df_length)

  ###Human health----
  ####Oral----
  {
    hcd_oral <- q %>%
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

    #finds GHS datapoints, adds median values for amounts
    oral_ghs <- ghs %>%
      filter(compound %ni% hcd_oral$compound) %>%
      group_by(compound) %>%
      mutate(Oral = case_when(
        Result = str_detect(Result, 'H300') ~ 'VH',
        Result = str_detect(Result, 'H301') ~ 'H',
        Result = str_detect(Result, 'H302') ~ 'M',
        Result = str_detect(Result, 'H303') ~ 'L'
      )) %>%
      filter(!is.na(Oral)) %>%
      arrange(compound, factor(Oral, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Oral) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(oral_amount = case_when(
        Oral == 'VH' ~ 50,
        Oral == 'H' ~ 175,
        Oral == 'M' ~ 1150,
        Oral == 'L' ~ 2000,
      ))

    #####ORAL TEST----
    test <- t %>%
      filter(compound %ni% hcd_oral$compound) %>%
      filter(endpoint == 'LD50') %>%
      group_by(compound) %>%
      summarize(amount = as.numeric(predValMass)) %>%
      mutate(Oral = case_when(
        amount <= 50 ~ 'VH',
        (amount > 50 & amount <= 300)  ~ 'H',
        (amount > 300 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>%
      rename(oral_amount = amount)

    #CT TEST
    test <- q %>%
      filter(source == 'TEST' & exposureRoute == 'oral') %>%
      dplyr::filter(toxvalType == 'LD50') %>%
      group_by(compound) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Oral = case_when(
        amount <= 50 ~ 'VH',
        (amount > 50 & amount <= 300)  ~ 'H',
        (amount > 300 & amount <= 2000)  ~ 'M',
        amount > 2000 ~ 'L'
      )) %>%
      rename(oral_amount = amount) %>% View()


    #binds two df together
    hcd_oral <- bind_rows(hcd_oral, test, oral_ghs) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(oral_amount = -log10(oral_amount)+10)


    cat(green('\nOral search complete!'))
  }
  ####Dermal----
  {
    hcd_dermal <-  q %>%
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

    derm_ghs <- ghs %>%
      filter(compound %ni% hcd_dermal$compound) %>%
      group_by(compound) %>%
      mutate(Dermal = case_when(
        Result = str_detect(Result, 'H310') ~ 'VH',
        Result = str_detect(Result, 'H311') ~ 'H',
        Result = str_detect(Result, 'H312') ~ 'M',
        Result = str_detect(Result, 'H313') ~ 'L'
      )) %>%
      filter(!is.na(Dermal)) %>%
      arrange(compound, factor(Dermal, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Dermal) %>%
      distinct(compound, .keep_all = T)%>%
      mutate(dermal_amount = case_when(
        Dermal == 'VH' ~ 200,
        Dermal == 'H' ~ 600,
        Dermal == 'M' ~ 1500,
        Dermal == 'L' ~ 2000,
      ))


    #binds two df together
    hcd_dermal <- bind_rows(hcd_dermal, derm_ghs) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(dermal_amount = -log10(dermal_amount)+10)

    cat(green('\nDermal search complete!'))
  }


  ####Inhalation----
  {
    hcd_inhalation <-  q %>%
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

    inhal_ghs <- ghs %>%
      filter(compound %ni% hcd_inhalation$compound) %>%
      group_by(compound) %>%
      mutate(Inhalation = case_when(
        Result = str_detect(Result, 'H330') ~ 'VH',
        Result = str_detect(Result, 'H331') ~ 'H',
        Result = str_detect(Result, 'H332') ~ 'M',
        Result = str_detect(Result, 'H333') ~ 'L'
      )) %>%
      filter(!is.na(Inhalation)) %>%
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
    hcd_inhalation <- bind_rows(hcd_inhalation, inhal_ghs)%>%
      distinct(compound, .keep_all = T) %>%
      mutate(inhalation_amount = -log10(inhalation_amount)+10)


    cat(green('\nInhalation search complete!'))
  }
  ####Cancer----

  #Prefer the lists over the toxval table
  #Requires cancer db to be loaded!
  {
    hcd_cancer <- cancer %>%
      select(list, dtxsid) %>%
      dplyr::filter(dtxsid %in% dtx_list) %>%
      group_by(dtxsid) %>%
      mutate(Carcinogenicity = case_when(
        list == 'IARC1' | list == 'IARC2A' ~ 'VH',
        list == 'IARC2B' ~ 'H',
        list == 'IARC3' ~ 'NA',
        list == 'IARC4' ~ 'L'
      )) %>%
      rename(cancer_amount = list, compound = dtxsid) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 1000,
        Carcinogenicity == 'H' ~ 100,
        Carcinogenicity == 'M' ~ 10,
        Carcinogenicity == 'L' ~ 1,
      )) %>% relocate(cancer_amount, .after = compound)

    # Disable until able to determine how to deal with category vs values
    # hcd_cancer_toxval <-  q %>%
    #   dplyr::filter(endpoint == 'human') %>%
    #   dplyr::filter(toxvalType == 'cancer slope factor' | toxvalType == 'cancer unit risk') %>%
    #   group_by(compound) %>%
    #   summarize(amount = mean(toxvalNumeric)) %>%
    #   mutate(Cancer = case_when(
    #     amount > 0 ~ 'VH')) %>%
    #   rename(cancer_amount = amount)

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, 'Carcinogenic')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Carcinogenicity = case_when(
        str_detect(reason, 'Carcinogenic') ~ 'VH'
      )) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 1000
      )) %>%
      rename(compound = dtxsid)

    p <- p65 %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(tox_type, 'cancer')) %>%
      select(dtxsid) %>%
      group_by(dtxsid) %>%
      transmute(Carcinogenicity = case_when(
        is.character(dtxsid) ~ 'VH'
      )) %>%
      mutate(cancer_amount = case_when(
        Carcinogenicity == 'VH' ~ 1000
      )) %>%
      rename(compound = dtxsid)


    hcd_cancer <- bind_rows(hcd_cancer, r, p) %>%
      arrange(compound,desc(cancer_amount)) %>%
      distinct(compound, .keep_all = T)

    cat(green('\nCancer search complete!'))
  }

  ####Genotoxic----
  {
    #Waiting for ACToR to be added in
    #2023-03-24

    #hcd_geno <-

    ##### GENO TEST----

    test <- t %>%
      #reverted %ni% to inclusive search, will use tiered approach
      filter(compound %in% dtx_list) %>%
      filter(endpoint == 'Mutagenicity') %>%
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

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, 'Mutagenic')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Mutagenicity = case_when(
        str_detect(reason, 'Mutagenic') ~ 'VH'
      )) %>%
      mutate(geno_amount = case_when(
        Mutagenicity == 'VH' ~ 1000
      )) %>%
      rename(compound = dtxsid)

    geno_ghs <- ghs %>%
      filter(compound %in% dtx_list) %>%
      group_by(compound) %>%
      mutate(Mutagenicity = case_when(
        Result = str_detect(Result, 'H340') ~ 'VH',
        Result = str_detect(Result, 'H341') ~ 'H'
      )) %>%
      filter(!is.na(Mutagenicity)) %>%
      arrange(compound, factor(Mutagenicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Mutagenicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(geno_amount = case_when(
        Mutagenicity == 'VH' ~ 1000,
        Mutagenicity == 'H' ~ 550
      ))

    hcd_geno <- bind_rows(test, r, geno_ghs) %>%
      arrange(compound,desc(geno_amount)) %>%
      distinct(compound, .keep_all = T)
  }
  ####Endocrine-----
  {
    #present on TEDx list
    #Wait until curation is done

    # hcd_endo <- endo_list %>%
    #   filter(dtxsid %in% dtx_list) %>%
    #   select(dtxsid) %>%
    #   mutate(Endocrine_Disruption = case_when(
    #     is.character(dtxsid) == TRUE ~ 'H'
    #   )) %>%
    #   mutate(endo_amount = case_when(
    #     Endocrine_Disruption == 'H' ~ 500
    #   )) %>%
    #   rename(compound = dtxsid)

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, 'Endocrine disrupting properties')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Endocrine_Disruption = case_when(
        str_detect(reason, 'Endocrine disrupting properties') ~ 'H'
      )) %>%
      mutate(endo_amount = case_when(
        Endocrine_Disruption == 'H' ~ 500
      )) %>%
      rename(compound = dtxsid)

    #####ENDO TEST----

    test <- t %>%
      #reverted %ni% to inclusive search, will use tiered approach
      filter(compound %in% dtx_list) %>%
      filter(endpoint == 'ER_Binary') %>%
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

    hcd_endo <- bind_rows(
      #hcd_endo,
      r,
      test) %>%
      distinct(compound, .keep_all = T)

  }
  ####Reproductive----
  {
    hcd_repro <-  q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'oral' | exposureRoute == 'dermal') %>%
      dplyr::filter(toxvalType == 'NOAEL' | toxvalType == 'LOAEL') %>%
      dplyr::filter(str_detect(riskAssessmentClass, 'reprod'))  %>%
      dplyr::filter(toxvalUnits == 'mg/kg-day' ) %>%
      group_by(compound) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Reproductive = case_when(
        amount < 100 ~ 'H',
        (amount > 100 & amount <= 500)  ~ 'M',
        amount > 500 ~ 'L'
      )) %>%
      rename(reproductive_amount = amount)

    repro_ghs <- ghs %>%
      filter(compound %ni% hcd_repro$compound) %>%
      group_by(compound) %>%
      mutate(Reproductive = case_when(
        Result = str_detect(Result, 'H360 | H360F | H360Fd | H360FD') ~ 'H',
        Result = str_detect(Result, 'H360Df | H361 | H361D | H361f') ~ 'M'
      )) %>%
      filter(!is.na(Reproductive)) %>%
      arrange(compound, factor(Reproductive, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Reproductive) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 100,
        Reproductive == 'M' ~ 300,
        Reproductive == 'L' ~ 500,
      ))

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, '57c')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Reproductive = case_when(
        str_detect(reason, '57c') ~ 'H'
      )) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 100
      )) %>%
      rename(compound = dtxsid)

    p <- p65 %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(tox_type, 'female|male')) %>%
      select(dtxsid) %>%
      group_by(dtxsid) %>%
      transmute(Reproductive = case_when(
        is.character(dtxsid) ~ 'H'
      )) %>%
      mutate(reproductive_amount = case_when(
        Reproductive == 'H' ~ 100
      )) %>%
      rename(compound = dtxsid)

    #binds two df together
    hcd_repro <- bind_rows(hcd_repro, repro_ghs, r, p) %>%
      arrange(compound,desc(reproductive_amount)) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(reproductive_amount = -log10(reproductive_amount)+10)

    cat(green('\nReproductive search complete!'))
  }

  ####Developmental----
  {
    hcd_develop <- q %>%
      dplyr::filter(humanEcoNt == 'human health') %>%
      dplyr::filter(speciesCommon == 'rat' | speciesCommon == 'mouse' | speciesCommon == 'rabbit' | speciesCommon == 'guinea pig' | speciesCommon == 'mouse, rat') %>%
      dplyr::filter(exposureRoute == 'oral' | exposureRoute == 'dermal') %>%
      dplyr::filter(toxvalType == 'NOAEL' | toxvalType == 'LOAEL') %>%
      dplyr::filter(toxvalUnits == 'mg/kg-day') %>%
      dplyr::filter(str_detect(studyType, 'develop'))  %>%
      dplyr::filter(!str_detect(riskAssessmentClass, 'reprod'))  %>%
      group_by(compound, exposureRoute) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      mutate(Developmental = case_when(

        amount < 50 & exposureRoute == 'oral' ~ 'H',
        (amount >= 50 & amount <= 250) & exposureRoute == 'oral'  ~ 'M',
        amount > 250 & exposureRoute == 'oral'~ 'L',

        amount < 100 & exposureRoute == 'dermal' ~ 'H',
        (amount >= 100 & amount <= 500) & exposureRoute == 'dermal'  ~ 'M',
        amount > 500 & exposureRoute == 'dermal'~ 'L',

        amount < 1 & exposureRoute == 'inhalation' ~ 'H',
        (amount >= 1 & amount <= 2.5) & exposureRoute == 'inhalation'  ~ 'M',
        amount > 2.5 & exposureRoute == 'inhalation'~ 'L'
      )) %>%
      rename(develop_amount = amount) %>%
      pivot_wider(
        names_from = exposureRoute,
        values_from = c(develop_amount, Developmental))

    ##### DEV TEST----

    test <- t %>%
      #reverted %ni% to inclusive search, will use tiered approach
      filter(compound %ni% hcd_develop$compound) %>%
      filter(endpoint == 'DevTox') %>%
      group_by(compound) %>%
      summarize(amount = predActive) %>%
      mutate(Developmental_oral = case_when(
        amount == TRUE ~ 'H',
        amount == FALSE ~ 'L'
      )) %>%
      rename(develop_amount_oral = amount) %>%
      mutate(develop_amount_oral = case_when(
        develop_amount_oral  == TRUE ~ 50,
        develop_amount_oral  == FALSE ~ 625
      ))

    dev_ghs <- ghs %>%
      filter(compound %ni% hcd_develop$compound) %>%
      group_by(compound) %>%
      mutate(Developmental = case_when(
        Result = str_detect(Result, 'H360 | H360Df | H360D | H360FD | H360Df | H362') ~ 'H',
        Result = str_detect(Result, 'H36Fd | H361 | H361d | H361fd') ~ 'M'
      )) %>%
      filter(!is.na(Developmental)) %>%
      arrange(compound, factor(Developmental, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Developmental) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(develop_amount_oral = case_when(
        Developmental == 'H' ~ 50,
        Developmental == 'M' ~ 150,
        Developmental == 'L' ~ 625
      )) %>%
      rename(Developmental_oral = Developmental)

    p <- p65 %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(tox_type, 'developmental')) %>%
      select(dtxsid) %>%
      group_by(dtxsid) %>%
      transmute(Developmental_oral = case_when(
        is.character(dtxsid) ~ 'H'
      )) %>%
      mutate(develop_amount_oral = case_when(
        Developmental_oral == 'H' ~ 50
      )) %>%
      rename(compound = dtxsid)

    hcd_develop <- bind_rows(hcd_develop, test, dev_ghs, p) %>%
      arrange(compound,develop_amount_oral) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(develop_amount_oral = -log10(develop_amount_oral)+10)

    cat(green('\nDevelopmental search complete!'))
  }

  ##Ecotox----
  ####Acute Aquatic Toxicity----
  {
    hcd_acute_aqua <- q %>%
      dplyr::filter(humanEcoNt == 'eco') %>%
      dplyr::filter(speciesCommon %in% std_spec$common) %>%
      dplyr::filter(studyDurationUnits == 'days') %>%
      dplyr::filter(studyDurationValue < 6) %>%
      dplyr::filter(toxvalUnits == 'mg/L') %>%
      dplyr::filter(riskAssessmentClass  == 'acute') %>%
      dplyr::filter(toxvalType == 'LC50' | toxvalType == 'EC50') %>%
      group_by(compound, toxvalType) %>%
      summarize(amount = min(toxvalNumeric)) %>%
      summarize(compound = compound, amount = min(amount)) %>%
      mutate('Acute_Aquatic_Toxicity' = case_when(

        (amount < 1) ~ 'VH',
        (amount >= 1 & amount <= 10)  ~ 'H',
        (amount > 10 & amount <= 100)  ~ 'M',
        (amount > 100) ~ 'L',

      )) %>%
      distinct() %>%
      rename(acute_aq_amount = amount)

    #####AC AQUA TEST----
    test <- t %>%
      filter(compound %ni% hcd_acute_aqua$compound) %>%
      filter(endpoint == 'LC50') %>%
      group_by(compound) %>%
      summarize(amount = as.numeric(predValMass)) %>%
      mutate(Acute_Aquatic_Toxicity = case_when(

        (amount < 1) ~ 'VH',
        (amount >= 1 & amount <= 10)  ~ 'H',
        (amount > 10 & amount <= 100)  ~ 'M',
        (amount > 100) ~ 'L',
      )) %>%
      rename(acute_aq_amount = amount)

    acute_ghs <- ghs %>%
      filter(compound %ni% hcd_acute_aqua$compound) %>%
      group_by(compound) %>%
      mutate(Acute_Aquatic_Toxicity = case_when(
        Result = str_detect(Result, 'H400') ~ 'VH',
        Result = str_detect(Result, 'H401') ~ 'H',
        Result = str_detect(Result, 'H402') ~ 'M',

      )) %>%
      filter(!is.na(Acute_Aquatic_Toxicity)) %>%
      arrange(compound, factor(Acute_Aquatic_Toxicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Acute_Aquatic_Toxicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(acute_aq_amount = case_when(
        Acute_Aquatic_Toxicity == 'VH' ~ 1,
        Acute_Aquatic_Toxicity == 'H' ~ 5,
        Acute_Aquatic_Toxicity == 'M' ~ 55,
        Acute_Aquatic_Toxicity == 'L' ~ 100,
      ))

    hcd_acute_aqua <- bind_rows(hcd_acute_aqua,test, acute_ghs) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(acute_aq_amount = -log10(acute_aq_amount)+10)


    cat(green('\nAcute aquatic search complete!'))
  }
  ####Chronic Aquatic Toxicity----
  {
    hcd_chron_aqua <-  q %>%
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

    chron_ghs <- ghs %>%
      filter(compound %ni% hcd_chron_aqua$compound) %>%
      group_by(compound) %>%
      mutate(Chronic_Aquatic_Toxicity = case_when(
        Result = str_detect(Result, 'H410') ~ 'VH',
        Result = str_detect(Result, 'H4411') ~ 'H',
        Result = str_detect(Result, 'H412') ~ 'M',
        Result = str_detect(Result, 'H413') ~ 'L'

      )) %>%
      filter(!is.na(Chronic_Aquatic_Toxicity)) %>%
      arrange(compound, factor(Chronic_Aquatic_Toxicity, levels = c('VH', 'H','M','L'))) %>%
      select(compound, Chronic_Aquatic_Toxicity) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(chronic_aq_amount = case_when(
        Chronic_Aquatic_Toxicity == 'VH' ~ 0.1,
        Chronic_Aquatic_Toxicity == 'H' ~ 0.55,
        Chronic_Aquatic_Toxicity == 'M' ~ 5.5,
        Chronic_Aquatic_Toxicity == 'L' ~ 10,
      ))

    hcd_chron_aqua <- bind_rows(hcd_chron_aqua, chron_ghs) %>%
      distinct(compound, .keep_all = T) %>%
      mutate(chronic_aq_amount = -log10(chronic_aq_amount)+10)

    cat(green('\nChronic aquatic search complete!'))
  }




  #Fate and transport----

  ####Persistence----
  {
    hcd_persist <- f %>%
      dplyr::filter(endpointName == 'Biodeg. Half-Life') %>%
      dplyr::select(dtxsid, endpointName, resultValue, unit, modelSource, valueType) %>%
      arrange(dtxsid,
              desc(resultValue),
              factor(endpointName, levels = c('experimental',
                                              'predicted'))
      ) %>%
      distinct(dtxsid, .keep_all = T) %>%
      select(dtxsid, resultValue) %>%
      mutate('Persistence' = case_when(
        (resultValue) > 180 ~ 'VH',
        (resultValue >= 60 & resultValue <= 180)  ~ 'H',
        (resultValue >= 16 & resultValue < 60)  ~ 'M',
        (resultValue) < 16 ~ 'L',
      )) %>%
      rename(compound = dtxsid, persistance_amount = resultValue)

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, '\\#PBT|\\#vPvB')) %>%
      select(dtxsid, reason) %>%
      group_by(dtxsid) %>%
      transmute(Persistence = case_when(
        str_detect(reason, '57e') ~ 'VH', #vPvB
        str_detect(reason, '57d') ~ 'H' #PBT
      )) %>%
      mutate(persistance_amount = case_when(
        Persistence == 'VH' ~ 180, #median value from dict table
        Persistence == 'H' ~ 120
      )) %>%
      rename(compound = dtxsid)

    hcd_persist <- bind_rows(hcd_persist, r) %>%
      arrange(compound,desc(persistance_amount)) %>%
      distinct(compound, .keep_all = T)
  }
  ####Bioaccumulation----
  {
    hcd_bac <- f %>%
      dplyr::filter(endpointName == 'Bioconcentration Factor' | endpointName == 'Bioaccumulation Factor') %>%
      dplyr::select(dtxsid, endpointName, resultValue, unit, modelSource, valueType) %>%
      filter(!is.na(resultValue)) %>%
      arrange(dtxsid,
              desc(resultValue),
              factor(endpointName, levels = c('Bioaccumulation Factor',
                                              'Bioconcentration Factor')),
              factor(endpointName, levels = c('experimental',
                                              'predicted'))
      ) %>%
      distinct(dtxsid, .keep_all = T) %>%
      group_by(dtxsid) %>%
      summarize(bac_amount = log10(resultValue)) %>%
      mutate('Bioaccumulation' = case_when(

        (bac_amount) > 3.7 ~ 'VH',
        (bac_amount >= 3 & bac_amount <= 3.7)  ~ 'H',
        (bac_amount >= 2 & bac_amount < 3)  ~ 'M',
        (bac_amount) < 2 ~ 'L',

      ))%>%
      rename(compound = dtxsid)

    r <- reach %>%
      filter(dtxsid %in% dtx_list) %>%
      filter(str_detect(reason, '\\#PBT|\\#vPvB')) %>%
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

    #####BAC TEST----

    test <- t %>%
      filter(compound %ni% hcd_bac$compound) %>%
      filter(endpoint == 'BCF') %>%
      group_by(compound) %>%
      summarize(bac_amount = as.numeric(predValMolarLog)) %>%
      mutate('Bioaccumulation' = case_when(

        (bac_amount) > 3.7 ~ 'VH',
        (bac_amount >= 3 & bac_amount <= 3.7)  ~ 'H',
        (bac_amount >= 2 & bac_amount < 3)  ~ 'M',
        (bac_amount) < 2 ~ 'L',

      ))

    hcd_bac <- bind_rows(hcd_bac, test, r) %>%
      distinct(compound, .keep_all = T)

    cat(green('\nBioconcentration factor search complete!'))
  }

  ####Exposure----
  #   hcd_expo <- hcd_data$expo_pred %>%
  #     dplyr::filter(demographic == 'Total' & predictor == 'SEEM3 Consensus') %>%
  #     group_by(dtxsid)
  #
  #   hcd_expo$median <- as.numeric(hcd_expo$median)
  #
  #   hcd_expo <- hcd_expo %>%
  #     summarize(perc = min(median)) %>%
  #     mutate('Exposure'  = case_when(
  #
  #       (perc <= 1e-4) ~ 'L',
  #       (perc > 1e-4 & perc < 1e-3) ~ 'M',
  #       (perc > 1e-3 & perc < 1) ~ 'H',
  #       (perc >= 1) ~ 'VH',
  #
  #     )) %>%
  #     rename(median_expo_amount = perc, compound = dtxsid)
  #
  ##Joining----

  hcd_summary <- left_join(hcd_summary, hcd_oral, by = c('Compound' = 'compound'))
  cat('\nOral joined')

  hcd_summary <- left_join(hcd_summary, hcd_dermal, by = c('Compound' = 'compound'))
  cat('\nDermal joined')

  hcd_summary <- left_join(hcd_summary, hcd_inhalation, by = c('Compound' = 'compound'))
  cat('\nInhalation joined')

  hcd_summary <- left_join(hcd_summary, hcd_cancer, by = c('Compound' = 'compound'))
  cat('\nCancer joined')

  hcd_summary <- left_join(hcd_summary, hcd_geno, by = c('Compound' = 'compound'))
  cat('\nGeno joined')

  hcd_summary <- left_join(hcd_summary, hcd_endo, by = c('Compound' = 'compound'))
  cat('\nEndo joined')

  hcd_summary <- left_join(hcd_summary, hcd_repro, by = c('Compound' = 'compound'))
  cat('\nRepro joined')

  hcd_summary <- left_join(hcd_summary, hcd_develop, by = c('Compound' = 'compound'))
  cat('\nDevelop joined')

  hcd_summary <- left_join(hcd_summary, hcd_acute_aqua, by = c('Compound' = 'compound'))
  cat('\nAcute Aq joined')

  hcd_summary <- left_join(hcd_summary, hcd_chron_aqua, by = c('Compound' = 'compound'))
  cat('\nChron aq joined')

  hcd_summary <- left_join(hcd_summary, hcd_persist, by = c('Compound' = 'compound'))
  cat('\nPersist joined')

  hcd_summary <- left_join(hcd_summary, hcd_bac, by = c('Compound' = 'compound'))
  cat('\nBAC joined')

  # hcd_summary <- left_join(hcd_summary, hcd_expo, by = c('Compound' = 'compound'))

  # DEBUG
  hcd_summary_bin <- hcd_summary

  hcd_summary_bin <- left_join(hcd_summary_bin, dsstox, by = c('Compound'='dtxsid'))
  cat('\nNames joined')

  hcd_summary_bin <- relocate(hcd_summary_bin, casrn, preferredName, .after = Compound)

  cat(red('\nTable made!'))

  return(hcd_summary_bin)

}
