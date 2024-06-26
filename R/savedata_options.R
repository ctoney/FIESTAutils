#' Data saving options.
#' 
#' Returns a list of user-supplied parameters and parameter values for saving data.
#' 
#' If no parameters, an empty list is returned.
#' 
#' @param outfolder String. The outfolder to write files to. If NULL, files are
#' written to working directory, or if gui=TRUE, a window to browse.
#' @param out_fmt String. Format for output tables ('csv', 'sqlite', 'gpkg', 'gdb').
#' @param outsp_fmt String. Format for output spatial ('shp', sqlite', 'gpkg', 'gdb').
#' @param outobj_fmt String. Format for output spatial ('rda', 'rds', 'llo').
#' @param out_dsn String. Data source name for output. If extension is
#' not included, out_fmt is used. Use full path if outfolder=NULL.
#' @param out_layer outlayer.
#' @param outfn.pre String. If savedata=TRUE, prefix for output files. If
#' rawdata=TRUE, prefix for rawdata files (if raw_fmt = 'csv') or raw_dsn (if
#' raw_fmt != 'csv').
#' @param outfn.date Logical. If TRUE, add current date to out_dsn.
#' @param addtitle Logical. If TRUE and savedata=TRUE, adds title to outfile.
#' @param raw_fmt String. Format for output rawdata tables ('sqlite',
#' 'gpkg', 'csv', 'gdb').
#' @param raw_dsn String. Data source name for rawdata output. If extension is
#' not included, out_fmt is used. Use full path if outfolder=NULL.
#' @param overwrite_dsn Logical. If TRUE, overwrites raw_dsn, if exists.
#' @param overwrite_layer Logical. If TRUE, overwrites the output. If
#' rawdata=TRUE, overwrites out_layer in rawdata folder (if raw_fmt = 'csv') or
#' out_layers in raw_dsn (if raw_fmt != 'csv').
#' @param append_layer Logical. If TRUE, and appends data to existing *.csv
#' files (if *_fmt = 'csv') or *_dsn layers (if *_fmt != 'csv".
#' @param add_layer Logical. If TRUE, adds layer to an existing out_dsn 
#' (if out_fmt != c('csv','shp')).
#' @param layer.pre Layer prefix. 
#' @param outconn Open database connection to save to.
#' @param ... For extendibility.
#' @return A list of user-supplied parameters and parameter values for saving data.
#' @author Grayson W. White
#' @keywords options
#' @examples
#' 
#' savedata_options(outfolder = "path", overwrite_dsn = FALSE)
#' 
#' @export savedata_options
savedata_options <- function(outfolder = NULL, 
                             out_fmt = "csv", 
                             outsp_fmt = "shp", 
                             outobj_fmt = "rds",
                             out_dsn = NULL, 
                             out_layer = "outdat", 
                             outfn.pre = NULL, 
                             outfn.date = FALSE, 
                             addtitle = TRUE, 
                             raw_fmt = "csv", 
                             raw_dsn = NULL, 
                             overwrite_dsn = FALSE, 
                             overwrite_layer = TRUE, 
                             append_layer = FALSE, 
                             add_layer = TRUE, 
                             layer.pre = NULL,
                             outconn = NULL,
                             ...) {
  # Check input parameters
  input.params <- names(as.list(match.call()))[-1]
  formallst <- c(names(formals(savedata_options)))
  if (!all(input.params %in% formallst)) {
    miss <- input.params[!input.params %in% formallst]
    stop("invalid parameter: ", toString(miss))
  }
  
  # removes input parameters to create l correctly
  rm(input.params, formallst)
  
  # create list from input parameters
  l <- c(as.list(environment()), list(...))
  
  # return list
  return(l)
}

