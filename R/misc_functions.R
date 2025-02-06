#' Purrr map_df with progress bar
#'
#' @param .x List to map over
#' @param .f Function to apply
#' @param ... Passes along other function arguments
#' @param .id ID column to be created
#'
#' @return A list

map_df_progress <- function(.x, .f, ..., .id = NULL) {
  .f <- purrr::as_mapper(.f, ...)
  pb <- progress::progress_bar$new(total = length(.x), force = TRUE)

  f <- function(...) {
    pb$tick()
    .f(...)
  }
  purrr::map_df(.x, f, ..., .id = .id)
}


#' Creates a new minimum function that ignores NAs and suppresses warning
#'
#' @param x Vector
#'
#' @return A vector
#' @export

min2 <- function(x){
  y <- suppressWarnings(min(x, na.rm = T)) #suppress the warnings; ignore NAs
  if (y==Inf){
    y <- NA #replace Inf with NA
  }
  return(y)
}

#' Geometric mean function
#'
#' @param x Vector
#' @param na.rm Flag
#'
#' @return A vector
#' @export

geometric.mean <- function(x,na.rm=TRUE)  {
    exp(mean(log(x[x > 0]),na.rm=na.rm)) }

#' ggsave_all
#'
#' @param filename Filename to save under
#' @param plot GGplot variable or the last plot generated
#' @param specs Dimension
#' @param path Path to file
#' @param ... Other args
#'
#' @return A set of end-use plots at the proper resolution
#' @export

ggsave_all <- function(filename, plot = ggplot2::last_plot(), specs = NULL, path = "output", ...) {
  specs <- if (!is.null(specs)) specs else {
    # Create default outputs data.frame rowwise using only base R
    specs <- rbind(
      c("_quart_portrait", "png", 1, (8.5-2)/2, (11-2)/2, "in", 300), # doc > layout > margins
      c("_half_portrait", "png", 1, 8.5-2, (11-2)/2, "in", 300),
      c("_full_portrait", "png", 1, 8.5-2, (11-2), "in", 300),
      c("_full_landscape", "png", 1, 11-2, 8.5-2, "in", 300),
      c("_ppt_title_content", "png", 1, 11.5, 4.76, "in", 300), # ppt > format pane > size
      c("_ppt_full_screen", "png", 1, 13.33, 7.5, "in", 300),   # ppt > design > slide size
      c("_ppt_two_content", "png", 1, 5.76, 4.76, "in", 300)    # ppt > format pane > size
    )

    colnames(specs) <- c("suffix", "device", "scale", "width", "height", "units", "dpi")
    specs <- as.data.frame(specs)
  }

  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  invisible(
    apply(specs, MARGIN = 1, function(...) {
      args <- list(...)[[1]]
      filename <- file.path(paste0(filename, args['suffix'], ".", args['device']))
      message("Saving: ", file.path(path, filename))

      ggplot2::ggsave(
        filename = filename,
        plot = ggplot2::last_plot(),
        path = path,
        device = args['device'],
        width = as.numeric(args['width']), height = as.numeric(args['height']), units = args['units'],
        dpi = if (is.na(as.numeric(args['dpi']))) args['dpi'] else as.numeric(args['dpi']),
        bg = 'white'
      )
    })
  )
}

#' Pretty list
#'
#' @param x list
#'
#' @return list
#' @export

pretty_list <- function(x) {
  #x <- colnames(x)
  cat(paste0("'", x, "',", "\n"))
}

#' Pretty print list
#'
#' @param x list
#'
#' @return list
#' @export

pretty_print <- function(x){
  cat(paste0(x, "\n"))
}

#' Pretty re-name
#'
#' @param x list
#'
#' @return list
#' @export

pretty_rename <- function(x) {
  #x <- colnames(x)
  cat(paste0("'' = '", x, "',", "\n"))
}

#' Not-in
#'
#' @return Opposite of %in%
#' @export
`%ni%` <- Negate(`%in%`)
