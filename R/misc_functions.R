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

min2 <- function(x) {
  y <- suppressWarnings(min(x, na.rm = T)) #suppress the warnings; ignore NAs
  if (y == Inf) {
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

geometric.mean <- function(x, na.rm = TRUE) {
  exp(mean(log(x[x > 0]), na.rm = na.rm))
}

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
ggsave_all <- function(
  filename,
  plot = ggplot2::last_plot(),
  specs = NULL,
  path = "output",
  ...
) {
  default_specs <- tibble::tribble(
    ~suffix,
    ~device,
    ~scale,
    ~width,
    ~height,
    ~units,
    ~dpi,
    "_quart_portrait",
    "png",
    1,
    (8.5 - 2) / 2,
    (11 - 2) / 2,
    "in",
    300,
    "_half_portrait",
    "png",
    1,
    8.5 - 2,
    (11 - 2) / 2,
    "in",
    300,
    "_full_portrait",
    "png",
    1,
    8.5 - 2,
    (11 - 2),
    "in",
    300,
    "_full_landscape",
    "png",
    1,
    11 - 2,
    8.5 - 2,
    "in",
    300,
    "_ppt_title_content",
    "png",
    1,
    11.5,
    4.76,
    "in",
    300,
    "_ppt_full_screen",
    "png",
    1,
    13.33,
    7.5,
    "in",
    300,
    "_ppt_two_content",
    "png",
    1,
    5.76,
    4.76,
    "in",
    300
  )

  specs <- if (is.null(specs)) {
    default_specs
  } else {
    specs
  }

  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  specs %>%
    dplyr::mutate(
      filename = file.path(
        path,
        paste0(filename, suffix, ".", device)
      )
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      dpi = if (is.na(as.numeric(dpi))) {
        dpi
      } else {
        as.numeric(dpi)
      }
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(filename, device, width, height, units, dpi) %>%
    purrr::pwalk(
      ggplot2::ggsave,
      plot = plot,
      bg = "white",
      ...
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
  message(paste0("'", x, "',", "\n"))
}

#' Pretty print list
#'
#' @param x list
#'
#' @return list
#' @export

pretty_print <- function(x) {
  message(paste(x, "\n"))
}

#' Pretty re-name
#'
#' @param x list
#'
#' @return list
#' @export

pretty_rename <- function(x) {
  #x <- colnames(x)
  message(paste0("'' = '", x, "',", "\n"))
}

#' Pretty Case When
#'
#' @param var Variable
#' @param x Case
#'
#' @return list
#' @export

pretty_casewhen <- function(var, x) {
  message(paste0(var, " == ", x, " ~ '',\n"))
}

#' Not-in
#'
#' @return Opposite of %in%
#' @export
`%ni%` <- Negate(`%in%`)
