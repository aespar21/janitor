#' @title Add underlying Ns to a tabyl displaying percentages.
#'
#' @description
#' This function adds back the underlying Ns to a \code{tabyl} whose percentages were calculated using \code{adorn_percentages()}, to display the Ns and percentages together.  You can also call it on a non-tabyl data.frame with tabyl-like format to which you wish to append Ns.
#'
#' @param dat a data.frame of class \code{tabyl} that has had \code{adorn_percentages} and/or \code{adorn_pct_formatting} called on it.
#' @param position should the N go in the front, or in the rear, of the percentage? 
#' @param ns the Ns to append.  The default is the "core" attribute of the input tabyl \code{dat}, where the original Ns of a two-way \code{tabyl} are stored.  However, if you need to modify the numbers, e.g., to format \code{4000} as \code{4,000} or \code{4k}, you can do that separately and supply the formatted result here.
#' 
#' @return a data.frame with Ns appended
#' @export
#' @examples
#' 
#' mtcars %>%
#'   tabyl(am, cyl) %>%
#'   adorn_percentages("col") %>%
#'   adorn_pct_formatting() %>%
#'   adorn_ns(position = "front")

adorn_ns <- function(dat, position = "rear", ns = attr(dat, "core")){
  #TODO: validate inputs
  if(! position %in% c("rear", "front")){stop("\"position\" must be one of \"front\" or \"rear\"")}
  if(is.null(ns)){stop("argument \"ns\" cannot be null; if not calling adorn_ns() on a data.frame of class \"tabyl\", pass your own value for ns")}
  if("one_way" %in% attr(dat, "tabyl_type")){warning("adorn_ns() is meant to be called on a two_way tabyl; consider combining columns of a one_way tabyl with tidyr::unite()")}
  attrs <- attributes(dat) # save these to re-append later
  
  # If ns argument is not the default "core" attribute, validate that it's a data.frame and has correct right dimensions
  if(!is.data.frame(ns)){ stop("if supplying a value to the ns argument, it must be of class data.frame") }
  if((!identical(ns, attr(dat, "core"))) & !identical(dim(ns), dim(dat))){ # user-supplied Ns must include values for totals row/col if present 
    stop("if supplying your own data.frame of Ns to append, its dimensions must match those of the data.frame in the \"dat\" argument")
  }
  
  # If appending the default Ns from the core, and there are totals rows/cols, append those values to the Ns table
  # Custom inputs to ns argument will need to calculate & format their own totals row/cols 
  if(identical(ns, attr(dat, "core"))){
    if(!is.null(attr(dat, "totals"))){ # add totals row/col to core for pasting, if applicable
      ns <- adorn_totals(ns, attr(dat, "totals"))
    }
  }

  if(position == "rear"){
    result <- paste_matrices(dat, ns%>%
                               dplyr::mutate_all(as.character) %>%
                               dplyr::mutate_all(wrap_parens) %>%
                               dplyr::mutate_all(standardize_col_width))
    
  } else if(position == "front"){
    result <- paste_matrices(ns, dat %>%
                               dplyr::mutate_all(as.character) %>%
                               dplyr::mutate_all(wrap_parens) %>%
                               dplyr::mutate_all(standardize_col_width))
  }
  attributes(result) <- attrs
  result
}

### Helper functions called by adorn_ns

# takes two matrices, pastes them together, keeps spacing of the two columns aligned
paste_matrices <- function(front, rear){
  front_matrix <- as.matrix(front)
  rear_matrix <- as.matrix(rear)
  
  # paste the results together
  pasted <- paste(front_matrix, " ", rear_matrix, sep = "") %>% # paste the matrices
    matrix(., nrow = nrow(front_matrix), dimnames = dimnames(rear_matrix)) %>% # cast as matrix, then data.frame
    dplyr::as_data_frame()
  pasted[[1]] <- front[[1]] # undo the pasting in this 1st column
  pasted
}


# Padding function to standardize a column's width by pre-pending whitespace 
standardize_col_width <- function(x){
  width = max(nchar(x))
  sprintf(paste0("%", width, "s"), x)
}

# Wrap a string in parentheses
wrap_parens <- function(x){
  paste0("(", x, ")")
}