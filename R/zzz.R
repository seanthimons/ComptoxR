.onAttach <- function(libname, ComptoxR) {



packageStartupMessage(
  cli_alert_success(
    c("This is version ", {as.character(utils::packageVersion('ComptoxR'))}," of ComptoxR"))
  )

#packageStartupMessage('\n')

packageStartupMessage(
  cli_alert_info(
    c("\nAPI endpoint selected:\n",
      {comptox_server()})
    )
)

# packageStartupMessage(
#   cli_alert_warning(
#   '\nAttempting ping test....\n')
#   )
#   ping_ccte()

}
