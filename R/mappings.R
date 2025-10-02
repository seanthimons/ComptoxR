
.search_mappings <- list(
  searchType = c(
    "exact" = "EXACT",
    "substructure" = "SUBSTRUCTURE",
    "similar" = "SIMILAR",
    "toxprints" = "TOXPRINTS",
    "hazard" = "HAZARD",
    "mass" = "MASS",
    "features" = "FEATURES"
  ),
  similarity_type = c(
    "tanimoto" = "tanimoto",
    "euclid" = "euclid-sub",
    "tversky" = "tversky"
  ),
  min_auth = c(
    "auth" = "Authoritative",
    "screen" = "Screening",
    "qsar" = "QSAR"
  ),
  mass_type = c(
    "mono" = "monoisotopic-mass",
    "mw" = "molecular-weight",
    "abu" = "most-abundant-mass"
  ),
  hazard_name = c(
    "acute_oral" = "Acute Mammalian Toxicity Oral",
    "acute_inhal" = "Acute Mammalian Toxicity Inhalation",
    "acute_dermal" = "Acute Mammalian Toxicity Dermal",
    "cancer" = "Carcinogenicity",
    "geno" = "Genotoxicity Mutagenicity",
    "endo" = "Endocrine Disruption",
    "reprod" = "Reproductive",
    "develop" = "Developmental",
    "neuro_single" = "Neurotoxicity	",
    "neuro_repeat" = "Neurotoxicity Repeat Exposure",
    "sys_single" = "Systemic Toxicity Single Exposure",
    "sys_repeat" = "Systemic Toxicity Repeat Exposure",
    "skin_sens" = "Skin Sensitization",
    "skin_irr" = "Skin Irritation",
    "eye" = "Eye Irritation",
    "aq_acute" = "Acute Aquatic Toxicity",
    "aq_chron" = "Chronic Aquatic Toxicity",
    "persis" = "Persistence",
    "bioacc" = "Bioaccumulation",
    "expo" = "Exposure"
  )
)
