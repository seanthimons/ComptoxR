# Internal lookup tables for chemi_search parameter mapping
# These are not exported - used internally by chemi_search functions

# Search type mapping: user-friendly -> API value
.search_type_map <- c(
  exact = "EXACT",
  substructure = "SUBSTRUCTURE",
  similar = "SIMILAR",
  mass = "MASS",
  hazard = "HAZARD",
  features = "FEATURES"
)

# Similarity type mapping
.similarity_type_map <- c(
  tanimoto = "tanimoto",
  euclid = "euclid-sub",
  tversky = "tversky"
)

# Mass type mapping (fixed typo: "moleculuar" -> "molecular")
.mass_type_map <- c(
  mono = "monoisotopic-mass",
  mw = "molecular-weight",
  abu = "most-abundant-mass"
)

# Authority level mapping
.authority_map <- c(
  auth = "Authoritative",
  screen = "Screening",
  qsar = "QSAR"
)

# Hazard name mapping: short name -> full API name
.hazard_name_map <- c(
  acute_oral = "Acute Mammalian Toxicity Oral",
  acute_inhal = "Acute Mammalian Toxicity Inhalation",
  acute_dermal = "Acute Mammalian Toxicity Dermal",
  cancer = "Carcinogenicity",
  geno = "Genotoxicity Mutagenicity",
  endo = "Endocrine Disruption",
  reprod = "Reproductive",
  develop = "Developmental",
  neuro_single = "Neurotoxicity",
  neuro_repeat = "Neurotoxicity Repeat Exposure",
  sys_single = "Systemic Toxicity Single Exposure",
  sys_repeat = "Systemic Toxicity Repeat Exposure",
  skin_sens = "Skin Sensitization",
  skin_irr = "Skin Irritation",
  eye = "Eye Irritation",
  aq_acute = "Acute Aquatic Toxicity",
  aq_chron = "Chronic Aquatic Toxicity",
  persis = "Persistence",
  bioacc = "Bioaccumulation",
  expo = "Exposure"
)

# Valid feature filter names
.feature_filter_names <- c(
  "stereo",
  "chiral",
  "isotopes",
  "charged",
  "multicomponent",
  "radicals",
  "salts",
  "polymers",
  "sgroups"
)

# Empty MOL string placeholder (used for hazard/features searches)
.empty_mol_string <- "\n  Ketcher  4112412132D 1   1.00000     0.00000     0\n\n  0  0  0     0  0            999 V2000\nM  END\n"
