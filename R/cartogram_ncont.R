# Copyright (C) 2016 Sebastian Jeworutzki
# Copyright (C) of 'nc_cartogram' Timothee Giraud and Nicolas Lambert
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.


#' @title Calculate Non-Contiguous Cartogram Boundaries
#' @description Construct a non-contiguous area cartogram (Olson 1976).
#'
#' @name cartogram_ncont
#' @param x SpatialPolygonDataFrame or an sf object
#' @param weight Name of the weighting variable in x
#' @param k Factor expansion for the unit with the greater value
#' @param inplace If TRUE, each polygon is modified in its original place, 
#' if FALSE multi-polygons are centered on their initial centroid
#' @return An object of the same class as x with resized polygon boundaries
#' @export
#' @import sp
#' @import rgeos
#' @importFrom methods is slot as
#' @examples
#' library(maptools)
#' library(cartogram)
#' library(rgdal)
#' data(wrld_simpl)
#' 
#' # Remove uninhabited regions
#' afr <- spTransform(wrld_simpl[wrld_simpl$REGION==2 & wrld_simpl$POP2005 > 0,],
#'                    CRS("+init=epsg:3395"))
#'
#' # Create cartogram
#' afr_nc <- cartogram_ncont(afr, "POP2005")
#'
#' # Plot
#' plot(afr)
#' plot(afr_nc, add = TRUE, col = 'red')
#'
#' # Same with sf objects
#' library(sf)
#'
#' afr_sf = st_as_sf(afr)
#'
#' afr_sf_nc <- cartogram_ncont(afr_sf, "POP2005")
#'
#' plot(st_geometry(afr_sf))
#' plot(st_geometry(afr_sf_nc), add = TRUE, col = 'red')
#'
#' @references Olson, J. M. (1976). Noncontiguous Area Cartograms. In The Professional Geographer, 28(4), 371-380.
cartogram_ncont <- function(x, weight, k = 1, inplace = TRUE){
  UseMethod("cartogram_ncont")
}

#' @title Calculate Non-Contiguous Cartogram Boundaries
#' @description This function has been renamed: Please use cartogram_ncont() instead of nc_cartogram().
#'
#' @export
#' @param shp SpatialPolygonDataFrame or an sf object
#' @inheritDotParams cartogram_ncont -x
#' @keywords internal
nc_cartogram <- function(shp, ...) {
  message("\nPlease use cartogram_ncont() instead of nc_cartogram().\n")
  cartogram_ncont(x=shp, ...)
}

#' @rdname cartogram_ncont
#' @export
cartogram_ncont.SpatialPolygonsDataFrame <- function(x, weight, k = 1, inplace = TRUE){
  as(cartogram_cont.sf(st_as_sf(x), weight, k = k, inplace = inplace), 'Spatial')
}


#' @rdname cartogram_ncont
#' @export
cartogram_ncont.sf <- function(x, weight, k = 1, inplace = TRUE){
  
  var <- weight
  spdf <- x[!is.na(x[, var, drop=T]),]
  
  # size
  surf <- st_area(spdf, by_element=T)
  v <- spdf[, var, drop=T] 
  mv <- max(v)
  ms <- surf[v==mv]
  wArea <- k * v * (ms / mv)
  spdf$r <- sqrt( wArea/ surf)
  n <- nrow(spdf)
  for(i in 1:n){
    st_geometry(spdf[i,]) <- rescalePoly.sf(spdf[i, ], 
                                         inplace = inplace, 
                                         r = as.numeric(spdf[i,]$r))
  } 
  spdf$r <- NULL
  return(return(st_buffer(spdf, 0)))
}

rescalePoly.sf <- function(p, r = 1, inplace = T){
  
  co <- st_geometry(p)
  
  if(inplace) {
    cntr <- st_centroid(co)
    ps <- (co - cntr) * r + cntr
  } else {
    cop <- st_cast(co, "POLYGON")
    cntrd = st_centroid(cop) 
    ps <- st_union((cop - cntrd) * r + cntrd)
  }
  
  return(ps)
}