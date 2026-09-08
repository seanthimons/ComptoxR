#' Optimized GHS Table Creation with Session Caching
#'
#' @return Data frame
ghs_create_tbl <- function() {
  # Check if table is already in session cache
  if (!is.null(.ComptoxREnv$ghs_table)) {
    return(.ComptoxREnv$ghs_table)
  }

  url <- "https://pubchem.ncbi.nlm.nih.gov/ghs/ghscode_10.txt"
  lines <- tryCatch(readLines(url, warn = FALSE), error = function(e) return(NULL))

  if (is.null(lines)) {
    return(tibble::tibble())
  }

  split_lines <- purrr::map(strsplit(lines, "\t"), ~ .x[-8])
  # Header is actually H-Code, Statement, Class, Category, UN, Pictogram, Signal
  # We only need H-Code and the bin logic.
  df <- as.data.frame(do.call(rbind, split_lines[-1]), stringsAsFactors = FALSE)
  colnames(df) <- split_lines[[1]]

  # Unified binning logic
  res <- df %>%
    dplyr::filter(stringr::str_detect(`H-Code`, pattern = "H")) %>%
    dplyr::mutate(
      bin = dplyr::case_when(
        `H-Code` %in%
          c(
            "H222",
            "H229",
            "H304",
            "H282",
            "H314",
            "H318",
            "H315+H320",
            "H220",
            "H221",
            "H230",
            "H231",
            "H232",
            "H224",
            "H225",
            "H228",
            "H270",
            "H271",
            "H272",
            "H250",
            "H251"
          ) ~ "VH",
        `H-Code` %in%
          c(
            "H240",
            "H241",
            "H242",
            "H260",
            "H261",
            "H200",
            "H201",
            "H202",
            "H203",
            "H205",
            "H209",
            "H210",
            "H211",
            "H206",
            "H207"
          ) ~ "VH",
        `H-Code` %in%
          c(
            "H223",
            "H305",
            "H283",
            "H284",
            "H290",
            "H204",
            "H208",
            "H226",
            "H227",
            "H280",
            "H281",
            "H420",
            "H252"
          ) ~ "H",
        `H-Code` %in% c("H315", "H319") ~ "M",
        `H-Code` %in% c("H316", "H320") ~ "L",
        `H-Code` == "-" ~ "I",
        .default = "MISSING"
      )
    ) %>%
    dplyr::filter(bin != "MISSING") %>%
    dplyr::select(h_code = `H-Code`, hazard_class = `Hazard Class`, bin) %>%
    dplyr::distinct(h_code, bin, .keep_all = TRUE)

  # Cache the result for the remainder of the session
  .ComptoxREnv$ghs_table <- res

  return(res)
}
