mapdeckPolygonDependency <- function() {
	list(
		htmltools::htmlDependency(
			"polygon",
			"1.0.0",
			system.file("htmlwidgets/lib/polygon", package = "mapdeck"),
			script = c("polygon.js")
		)
	)
}


#' Add Polygon
#'
#' The Polygon Layer renders filled and/or stroked polygons. If using \code{sf} objects
#' only POLYGONs are supported, MULTIPOLYGONs are ignored.
#'
#' @inheritParams add_arc
#'
#' @param polyline column of \code{data} containing the polylines
#' @param fill_colour column of \code{data} or hex colour for the fill colour
#' @param fill_opacity value between 1 and 255. Either a string specifying the
#' column of \code{data} containing the fill opacity of each shape, or a value
#' between 1 and 255 to be applied to all the shapes
#' @param stroke_colour variable of \code{data} or hex colour for the stroke
#' @param stroke_width width of the stroke
#' @param light_settings list of light setting parameters. See \link{light_settings}
#' @param elevation the height of the polygon
#' @param tooltip variable of \code{data} containing text or HTML to render as a tooltip
#'
#' @examples
#' \donttest{
#'
#' ## You need a valid access token from Mapbox
#' key <- 'abc'
#'
#' df <- melbourne
#' df$elevation <- sample(100:5000, size = nrow(df))
#' df$info <- paste0("<b>SA2 - </b><br>",df$SA2_NAME)
#'
#' mapdeck(
#'   token = key
#'   , style = mapdeck_style('dark')
#'   , location = c(145, -38)
#'   , zoom = 8
#'   ) %>%
#'   add_polygon(
#'     data = df
#'     , polyline = "geometry"
#'     , layer = "polygon_layer"
#'     , fill_colour = "fillColor",
#'     , stroke_colour = "fillColor",
#'     , elevation = "elevation"
#'     , stroke_width = 0
#'     , tooltip = 'info'
#'   )
#'
#' library(sf)
#' library(geojsonsf)
#'
#' sf <- geojson_sf("https://symbolixau.github.io/data/geojson/SA2_2016_VIC.json")
#'
#' mapdeck(
#'   token = key
#'   , style = 'mapbox://styles/mapbox/dark-v9'
#' ) %>%
#'   add_polygon(
#'     data = sf
#'     , layer = "polygon_layer"
#'     , fill_colour = "SA2_NAME16"
#'   )
#'
#' }
#'
#' @export
add_polygon <- function(
	map,
	data = get_map_data(map),
	polyline = NULL,
	stroke_colour = NULL,
	stroke_width = NULL,
	fill_colour = NULL,
	fill_opacity = NULL,
	elevation = NULL,
	tooltip = NULL,
	auto_highlight = FALSE,
	light_settings = list(),
	layer_id = NULL,
	digits = 6,
	palette = viridisLite::viridis
) {

	objArgs <- match.call(expand.dots = F)

	data <- normaliseSfData(data, "POLYGON", multi = FALSE)
	polyline <- findEncodedColumn(data, polyline)

	## - if sf object, and geometry column has not been supplied, it needs to be
	## added to objArgs after the match.call() function
	if( !is.null(polyline) && !polyline %in% names(objArgs) ) {
		objArgs[['polyline']] <- polyline
	}

	## parameter checks
	checkNumeric(digits)
	checkPalette(palette)
	layer_id <- layerId(layer_id, "polygon")
	## TODO(light_settings)

	## TODO(check highlight_colour)

	## end parameter checks

	allCols <- polygonColumns()
	requiredCols <- requiredPolygonColumns()

	colourColumns <- shapeAttributes(
		fill_colour = fill_colour
		, stroke_colour = stroke_colour
		, stroke_from = NULL
		, stroke_to = NULL
	)

	shape <- createMapObject(data, allCols, objArgs)

	pal <- createPalettes(shape, colourColumns)

	colour_palettes <- createColourPalettes(data, pal, colourColumns, palette)
	colours <- createColours(shape, colour_palettes)

	if(length(colours) > 0) {
		shape <- replaceVariableColours(shape, colours)
	}

	requiredDefaults <- setdiff(requiredCols, names(shape))

	if(length(requiredDefaults) > 0){
		shape <- addDefaults(shape, requiredDefaults, "polygon")
	}

	shape <- jsonlite::toJSON(shape, digits = digits)

	light_settings <- jsonlite::toJSON(light_settings, auto_unbox = T)

	map <- addDependency(map, mapdeckPolygonDependency())
	invoke_method(map, "add_polygon", shape, layer_id, light_settings, auto_highlight)
}


requiredPolygonColumns <- function() {
	c("fill_colour", "fill_opacity", "stroke_width", "stroke_colour","elevation")
}

polygonColumns <- function() {
	c("polyline", "fill_colour", "fill_opacity","stroke_width", "stroke_colour","elevation")
}

polygonDefaults <- function(n) {
	data.frame(
		"fill_colour" = rep("#440154", n),
		"fill_opacity" = rep(255, n),
		"stroke_colour" = rep("#440154", n),
		"stroke_width" = rep(1, n),
		"elevation" = rep(0, n),
		stringsAsFactors = F
	)
}
