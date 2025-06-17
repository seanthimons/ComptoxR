# In file: R/api.R (or another appropriate file)

#' Classifies chemical compounds
#'
#' Classifies chemical compounds as Organic, Inorganic, Isotope, or Markush
#' based on molecular formula and SMILES strings.
#'
#' This function takes a dataframe of chemical compounds and adds three new
#' columns: 'class' for detailed classification, 'super_class' for
#' broader categorization, and 'composition' to identify mixtures.
#'
#' @param df A dataframe containing chemical compound information.
#'   Must include the following columns: `molFormula`, `preferredName`,
#'   `dtxsid`, `smiles`, `isMarkush`, `isotope`, `multicomponent`, `inchiString`.
#'
#' @return A dataframe with the original columns plus 'class', 'super_class',
#'   and 'composition'.
#'
#' @export
#' @importFrom dplyr mutate case_when select %>%
#' @importFrom stringr str_detect str_split
#'
#' @examples
#' # Example usage with dummy data:
#' # df_example <- tibble::tribble(
#' #   ~molFormula, ~preferredName, ~dtxsid, ~smiles, ~isMarkush, ~isotope, ~multicomponent,
#' #   "CHNaO2", "Sodium formate", "DTXSID2027090", "[Na+].[O-]C=O", FALSE, 0L, 1L,
#' #   "C6H12O6", "Glucose", "DTXSID12345", "OC[C@H](O)...", FALSE, 0L, 0L,
#' #   "Fe2O3", "Iron(III) oxide", "DTXSID67890", "[O-2].[O-2]...", FALSE, 0L, 1L,
#' #   "[89Sr]", "Strontium-89", "DTXSID54321", "[89Sr]", FALSE, 1L, 0L,
#' #   "C2H4", "Polyethylene", "DTXSID98765", "*CC*", TRUE, 0L, 0L,
#' #   "Cl2Sn", "Stannous chloride", "DTXSID8021351", "[Cl-].[Cl-].[Sn++]", FALSE, 0L, 1L,
#' #   NA, "Some Markush", "DTXSID9028831", NA, TRUE, 0L, 0L
#' # )
#' # classified_df <- ct_classify(df_example)
#' # print(classified_df)
ct_classify <- function(df) {
  # Call the pre-built, optimized internal classifier function.
  .classifier(df)
}

