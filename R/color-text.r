#' Colorize text for display in the terminal.
#'
#' If R is not currently running in a system that supports terminal colors
#' the text will be returned unchanged.
#'
#' Allowed colors are: black, blue, brown, cyan, dark gray, green, light
#' blue, light cyan, light gray, light green, light purple, light red,
#' purple, red, white, yellow
#'
#' Taken from `testthat` package `@0e70997`

#'
#' @param text character vector
#' @param fg foreground color, defaults to white
#' @param bg background color, defaults to transparent
#' @export

colorize <- function(text, fg = "white", bg = NULL) {

  col <- .fg_colours[tolower(fg)]
  #print(col)

  if (!is.null(bg)) {
    col <- paste0(col, ";",.bg_colours[tolower(bg)])
    #print(col)
  }

  paste0("\033[",col,';m', text, "\033[0m")
}

.fg_colours <- c(
  "black" = "0;30",
  "blue" = "0;34",
  "green" = "0;32",
  "cyan" = "0;36",
  "red" = "0;31",
  "purple" = "0;35",
  "brown" = "0;33",
  "light gray" = "0;37",
  "dark gray" = "1;30",
  "light blue" = "1;34",
  "light green" = "1;32",
  "light cyan" = "1;36",
  "light red" = "1;31",
  "light purple" = "1;35",
  "yellow" = "1;33",
  "white" = "1;37"
)

.bg_colours <- c(
  "black" = "40",
  "red" = "41",
  "green" = "42",
  "brown" = "43",
  "blue" = "44",
  "purple" = "45",
  "cyan" = "46",
  "light gray" = "47"
)



