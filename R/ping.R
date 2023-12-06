#' Ping test for servers
#'
#' @export
#'
ping_ccte <- function(){

ping_list <- list(
  'api-ccte.epa.gov',
  'hcd.rtpnc.epa.gov'
  )

cat('\n Pinging APIs...\n')
map(
  ping_list, ~{
  cat('\n',.,'\n')
  pingr::ping(., count = 4L) %>% cat('\n',.,'\n','------','\n')
  })

}
