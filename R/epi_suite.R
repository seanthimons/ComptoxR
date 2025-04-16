
epi_suite_search <- function(query){

  req <- GET(url = paste0(Sys.getenv('epi_burl'), "/search?query=", query))

  resp 

}

epi_suite_analysis <- function(query){

  req <- GET(url = paste0(Sys.getenv('epi_burl'), "/submit?cas=", query))

  resp

}
