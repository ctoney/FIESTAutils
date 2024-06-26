## getrastlst - verifies a list of raster or raster files.
## areacalc.pixel - calculates area of raster pixels and appends to polygon attribute table.
## aspect_transform - transforms aspect, in degrees, to easting and northing units.
## checkrast.longlat - checks of raster has long/lat crs


#' @rdname raster_desc
#' @export
getrastlst <- function(rastnmlst, rastfolder=NULL, stopifLonLat=FALSE,
	stopifnull=FALSE, gui=FALSE, quiet=FALSE){

  #########################################################################
  ## DESCRIPTION:
  ## To verify rasters. Checks if rasters exist. If rastfolder is not NULL,
  ## checks for rasters in the rastfolder.
  ##
  ## ARGUMENTS:
  ## rastnmlst   RasterLayer, RasterStack, RasterBrick, or String vector.
  ##		List of raster names. Extensions included.
  ## rastfolder  String. The name of the folder where rasters are. Optional.
  ##
  ## VALUE:
  ## rastfnlst  String vector. List of raster file names.
  ##########################################################################

  ## Adds to file filters to Cran R Filters table.
  if (.Platform$OS.type == "windows") {
    Filters <- rbind(Filters,img=c("Erdas Image (*.img)", "*.img"))
    Filters <- rbind(Filters,tif=c("GeoTIFF (*.tif)", "*.tif"))
    Filters <- rbind(Filters,bil=c("Binary (*.bil)", "*.bil"))
  }
 
  rastfnlst <- {}
  if (is.null(rastnmlst)) {
    if (gui) {
      if (is.null(rastfolder)) {
        rastfolder <- getwd()
      } else {
        if (!file.exists(rastfolder)){
          warning("the raster folder does not exist - check path")
          rastfolder <- getwd()
        }
      }

      rasts <- TRUE
      while (rasts) {
        rasttype <- select.list(c("Erdas Image (*.img)", "GeoTIFF (*.tif)", "binary (*.bil)"),
		"Arc/Info GRID", title="Raster Type")
        rastext <- row.names(Filters)[Filters[,1] == rasttype]

        if (rasttype != "Arc/Info GRID" && .Platform$OS.type=="windows") {
          rastnm <- choose.files(default="", caption="Select raster image(s)",
                filters=Filters[rastext,], multi=TRUE)
          if (length(rastnm) == 0) {
            stop("")
          } else {
            rastfnlst <- c(rastfnlst, rastnm)
          }
        } else if (rasttype == "Arc/Info GRID" && .Platform$OS.type=="windows") {
          rastnm <- choose.dir(default=rastfolder, caption="Select raster grid")
          if (is.na(rastnm)) {
            stop("")
          } else {
            rastfnlst <- c(rastfnlst, rastnm)
          }
        } else {
          stop("")
        }
        rasts <- select.list(c("Yes", "No"), title="Another raster")
        rasts <- ifelse(rasts == "Yes", TRUE, FALSE)
      }
    } else {
      if (stopifnull) {
        stop("rastnmlst is NULL")
      } else {
        return(NULL)
      }
    }
  } else {

    if (!is.list(rastnmlst)) {
      if (class(rastnmlst) %in% c("RasterLayer", "RasterStack", "RasterBrick")) {
        rastnmlst <- list(rastnmlst)
      } else {
        rastnmlst <- as.list(rastnmlst)
      }
    }

    if (any(lapply(rastnmlst, class) %in% "SpatRaster")) {
      for (rastnm in rastnmlst) {
        if (!class(rastnm) %in% "SpatRaster") {
          if (file.exists(rastnm[[1]])) {
            rastfnlst <- c(rastfnlst, rastnm)
          } else {
            message(rastnm[[1]], "is invalid")
          }
        } else {
          rastfn <- terra::sources(rastnm)
          if (file.exists(rastfn)) {
            rastfnlst <- unique(c(rastfnlst, rastfn))
            rm(rastnm)
            # gc()
          } else {
            stop(rastfn, "is invalid")
          }
        }
      } 
    } else if (any(lapply(rastnmlst, class) %in% c("RasterLayer", "RasterStack", "RasterBrick"))) {
      for (rastnm in rastnmlst) {
        if (!class(rastnm) %in% c("RasterLayer", "RasterStack", "RasterBrick")) {
          if (file.exists(rastnm[[1]])) {
            rastfnlst <- c(rastfnlst, rastnm)
          } else {
            message(rastnm[[1]], "is invalid")
          }
        } else {
          rastfn <- rastnm[[1]]@file@name
          if (file.exists(rastfn)) {
            rastfnlst <- unique(c(rastfnlst, rastfn))
            rm(rastnm)
            # gc()
          } else {
            stop(rastfn, "is invalid")
          }
        }
      } 
    } else {  ## !is.null(rastnmlst)
      if (!is.null(rastfolder)) {
        if (file.exists(rastfolder) && rastfolder != "") {
          rastfnlst <- paste(rastfolder, rastnmlst, sep="/")
        } else {
          stop("rastfolder is not valid")
        }
      } else {
        rastfnlst <- rastnmlst
      }
      if (sum(sapply(rastfnlst, file.exists) == FALSE) > 0) {
         notexist <- rastfnlst[sapply(rastfnlst, file.exists) == FALSE]
         message("invalid rastnm in rastmlst:")
         message(paste(unlist(notexist), collapse=", "))
      }
    }
  }

  ## Check each raster for projection information
  for (rastfn in rastfnlst) {
    if (!quiet) {
      message(rastfn)
    }
    rast.info <- rasterInfo(rastfn)
    if (is.null(rast.info)) {
      stop("invalid raster: ", rastfn)
    }
    rast.prj <- rast.info$crs

    if (any(is.na(rast.prj)) || any(rast.prj == "")) {
      message(paste("raster has undefined projection:", rastfn))
    } else if (sf::st_is_longlat(rast.prj)) {
      message(paste("rast is longlat:", rastfn))
      if (stopifLonLat) stop("")
    }
  }
  return(unlist(rastfnlst))
}

#' @rdname raster_desc
#' @export
areacalc.pixel <- function(rastfn, unit="ACRES", rast.NODATA=NULL, na.rm=TRUE) {

  ## DESCRIPTION:
  ## Calculates and returns area of a raster pixel. If rast is longlat
  ## projection, reproject to default, Albers NAD83.

  unitlst <- c("ACRES", "HECTARES", "SQMETERS")
  if (!unit %in% unitlst) stop("must be 'ACRES', 'HECTARES', or 'SQMETERS'")


  ## Check if raster is not projected
  rastfn <- checkrast.longlat(rastfn)

  ## Check if rastfn is long/lat
  rast_info <- rasterInfo(rastfn)
  rast.prj <- rast_info$crs
  rast.res <- rast_info$cellsize


  ## Get raster units
  rast.units <- getprjatt(rast.prj, "units")
  if (is.null(rast.units)) {
    message("no units defined in proj4string... assuming meters")
    rast.units <- "m"
  }
  if (rast.units %in% c("m", "meters")) {
    cfactor.ac <- 0.00024711
    cfactor.ha <- 0.0001
  } else if (rast.units %in% c("ft", "us-ft")) {
    cfactor.ac <- 0.00002296
    cfactor.ha <- 0.0000092903
  } else {
    stop("no conversion factor defined")
  }
  cfactor <- ifelse(unit == "ACRES", cfactor.ac, ifelse(unit == "HECTARES", cfactor.ha, 1))


  ## Calculate pixel counts by raster value
  pixelarea <- pixelCount(rastfn)

  ## Calculate area based on number of pixels
  pixelarea$area <- pixelarea$count * rast.res[1] * rast.res[2] * cfactor


  ## Remove values that equal NA
  if (na.rm)
    pixelarea <- pixelarea[!is.na(pixelarea$value), ]

  ## Remove values that equal rast.NODATA
  if (!is.null(rast.NODATA))
    pixelarea <- pixelarea[pixelarea$value != rast.NODATA, ]

  return(pixelarea)
}

#' @rdname raster_desc
#' @export
aspect_transform <- function(df, asp) {
## DESCRIPTION: Transform aspect, in degrees to northing and easting units
  	#northness - set flat to east for neutral value:
	df$asp_n <- df[[asp]]
	df$asp_n[df$asp_n==-1] <- 90
	df$cosAsp <- cos(df$asp_n*pi/180)
	df$asp_n <- NULL
	#eastness - set flat to north for neutral value:
	df$asp_e <- df[[asp]]
	df$asp_e[df$asp_e==-1] <- 0
	df$sinAsp <- sin(df$asp_e*pi/180)
	df$asp_e <- NULL
     return(df)
}


#' @rdname raster_desc
#' @export
checkrast.longlat <- function(rastfn, dstfile=NULL, nolonglat=TRUE, crs.default=NULL) {
  ##################################################################################
  ## DESCRIPTION: Check for longlat Geodetic coordinate system.
  ##
  ## Default projection: NAD83 - Conus Albers (EPSG:5070)
  ## +proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96,
  ##		+x_0=0 +y_0=0", "+ellps=GRS80 +towgs84=0,0,0,-0,-0,-0,0 +units=m +no_defs")
  ##################################################################################
  crs.albersUS <- "EPSG:5070"

  ## Define default coordinate System
  if (is.null(crs.default))
    crs.default <- crs.albersUS
  crs.default <- sf::st_crs(crs.default)

  rastfn <- getrastlst(rastfn)
  rast.prj <- rasterInfo(rastfn)$crs
  rast.name <- basename.NoExt(rastfn)
  #rast.dirname <- dirname(nlcdfn)


  ## Reproject coordinate system
  if (sf::st_is_longlat(rast.prj) && nolonglat) {
    if (is.null(dstfile)) {
      dstfile <- paste0(getwd(), "/rastprj.img")
      message("saving projected raster to: ", dstfile)
    }
    rastprjfn <- reprojectRaster(rastfn, dstfile=dstfile, t_srs=crs.default, of="HFA")
    return(rastprjfn)
  } else {
    return(rastfn)
  }
}
