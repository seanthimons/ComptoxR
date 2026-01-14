# Optimization Matrix for Hazard Scoring
# This tibble maps hazard endpoints and letter bins into numerical values
# used for the 'numerical' coercion branch in chemi_hazard.
get_hazard_scoring_matrix <- function() {
  # Endpoint categories
  acute_mammalian <- c("acuteMammalianOral", "acuteMammalianDermal", "acuteMammalianInhalation")
  human_health <- c("carcinogenicity", "genotoxicity", "reproductive", "developmental", "endocrine")
  neuro_systemic <- c("neurotoxicitySingle", "neurotoxicityRepeat", "systemicToxicitySingle", "systemicToxicityRepeat", "skinSensitization")
  physical_eco <- c("skinIrritation", "eyeIrritation", "acuteAquatic", "chronicAquatic", "persistence", "bioaccumulation")
  
  # Standardized scoring map
  tibble::tribble(
    ~endpoint, ~finalScore, ~amount, ~invert_flag,
    # Acute Mammalian
    "acuteMammalianOral", "VH", 50, TRUE,
    "acuteMammalianOral", "H", 175, TRUE,
    "acuteMammalianOral", "M", 1150, TRUE,
    "acuteMammalianOral", "L", 2000, TRUE,
    "acuteMammalianDermal", "VH", 200, TRUE,
    "acuteMammalianDermal", "H", 600, TRUE,
    "acuteMammalianDermal", "M", 1500, TRUE,
    "acuteMammalianDermal", "L", 2000, TRUE,
    "acuteMammalianInhalation", "VH", 2, TRUE,
    "acuteMammalianInhalation", "H", 6, TRUE,
    "acuteMammalianInhalation", "M", 15, TRUE,
    "acuteMammalianInhalation", "L", 20, TRUE,
    # Human Health
    "carcinogenicity", "VH", 10000, FALSE,
    "carcinogenicity", "H", 1000, FALSE,
    "carcinogenicity", "M", 10, FALSE,
    "carcinogenicity", "L", 1, FALSE,
    "genotoxicity", "VH", 1000, FALSE,
    "genotoxicity", "H", 500, FALSE,
    "genotoxicity", "L", 1, FALSE,
    "reproductive", "H", 1000, FALSE,
    "reproductive", "M", 10, FALSE,
    "reproductive", "L", 1, FALSE,
    "developmental", "H", 1000, FALSE,
    "developmental", "M", 10, FALSE,
    "developmental", "L", 1, FALSE,
    "endocrine", "H", 1000, FALSE,
    "endocrine", "L", 1, FALSE,
    # Neuro/Systemic
    "neurotoxicitySingle", "H", 500, FALSE,
    "neurotoxicitySingle", "M", 100, FALSE,
    "neurotoxicityRepeat", "H", 500, FALSE,
    "neurotoxicityRepeat", "M", 100, FALSE,
    "systemicToxicitySingle", "H", 500, FALSE,
    "systemicToxicitySingle", "M", 100, FALSE,
    "systemicToxicityRepeat", "H", 500, FALSE,
    "systemicToxicityRepeat", "M", 100, FALSE,
    "skinSensitization", "H", 100, FALSE,
    "skinSensitization", "L", 1, FALSE,
    # Eco/Irritation
    "skinIrritation", "VH", 1000, FALSE,
    "skinIrritation", "H", 100, FALSE,
    "skinIrritation", "M", 10, FALSE,
    "skinIrritation", "L", 1, FALSE,
    "eyeIrritation", "VH", 1000, FALSE,
    "eyeIrritation", "H", 100, FALSE,
    "eyeIrritation", "M", 10, FALSE,
    "acuteAquatic", "VH", 1, TRUE,
    "acuteAquatic", "H", 5, TRUE,
    "acuteAquatic", "M", 50, TRUE,
    "acuteAquatic", "L", 100, TRUE,
    "chronicAquatic", "VH", 0.1, TRUE,
    "chronicAquatic", "H", 0.55, TRUE,
    "chronicAquatic", "M", 5.5, TRUE,
    "chronicAquatic", "L", 10, TRUE,
    "persistence", "VH", 1000, FALSE,
    "persistence", "H", 100, FALSE,
    "persistence", "M", 10, FALSE,
    "persistence", "L", 1, FALSE,
    "bioaccumulation", "H", 1000, FALSE,
    "bioaccumulation", "L", 1, FALSE
  )
}
