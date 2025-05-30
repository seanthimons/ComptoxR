hc_table2 <- function(query) {
  if ((ncol(query) != 50) == TRUE) {
    stop('\nIncorrect dim!\n')
  } else {
    message('TRUE')
  }

  data <- list()

  data$headers <- query %>%
    select(sid, casrn, name, hazardId.y, hazardName.y) %>%
    distinct()

  data$final <- query %>%
    select(sid, hazardId.y, finalScore.y, finalAuthority.y) %>%
    arrange(
      factor(
        hazardId.y,
        levels = c(
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
        )
      ),
      factor(
        finalScore.y,
        levels = c(
          'VH',
          'H',
          'M',
          'L',
          'I',
          'ND',
          NA
        )
      ),
      factor(
        finalAuthority.y,
        levels = c(
          'Authoritative',
          'Screening',
          'QSAR Model',
          NA
        )
      )
    ) %>%
    distinct(
      .,
      sid,
      hazardId.y,
      finalAuthority.y,
      #,finalScore.y
      .keep_all = T
    ) %>%
    pivot_wider(
      .,
      id_cols = sid,
      names_from = hazardId.y,
      values_from = finalScore.y
    )

  #data$meta <- query %>%

  data$records <- query %>%
    select(
      sid,
      hazardId.y,
      records_source,
      records_listType,
      records_score,
      records_valueMass,
      records_valueMassUnits,
      records_category,
      records_hazardCode
    ) %>%
    arrange(
      factor(
        hazardId.y,
        levels = c(
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
        )
      ),
      factor(
        records_listType,
        levels = c(
          'Authoritative',
          'Screening',
          'QSAR Model',
          NA
        )
      ),
      factor(
        records_score,
        levels = c(
          'VH',
          'H',
          'M',
          'L',
          'I',
          'ND',
          NA
        )
      ),
      records_valueMass
    ) %>%
    distinct(
      .,
      sid,
      hazardId.y,
      #,records_listType
      .keep_all = T
    )

  data$num <- data$records %>%
    filter(!is.na(records_valueMass))

  data$cat <- data$records %>%
    select(-c(records_valueMass, records_valueMassUnits)) %>%
    filter(is.na(records_valueMass)) #%>%
  #filter(!)
  # filter(!str_detect(records_category,'Classification not possible')) %>%

  return(data)
}
