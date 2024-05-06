.onAttach <- function(libname, ComptoxR) {

  if(Sys.getenv('burl') == "" | Sys.getenv("chemi_burl") == ""){
    comptox_server()
    chemi_server()
  }

  packageStartupMessage(
    .header()
  )
}

.header <- function(){

  cli::cli({
    cli::cli_rule()

    cli::cli_alert_success(
      c("This is version ", {as.character(utils::packageVersion('ComptoxR'))}," of ComptoxR"))

    cli::cli_alert_info('Available API endpoints:')
    cli::cli_dl(c(
      'CompTox' = '{Sys.getenv("burl")}',
      'Cheminformatics' =  '{Sys.getenv("chemi_burl")}'
    ))
  })

  run_setup()

}
