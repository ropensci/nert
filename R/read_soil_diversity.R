#' Read Soil Beta Diversity from TERN
#'
#' Wrapper around [read_tern()] for retrieving the v1.0 datasets for
#' soil bacteria and soil fungi Beta Diversity from the TERN Data Portal.
#' The Beta Diversity datasets were constructed using Digital Soil Mapping
#' techniques together with Biome of Australia Soil Environments (BASE)
#' DNA sequences, and provide Non-metric MultiDimensional Scaling (NMDS)
#' axes for soil bacteria and fungi at 90m X 90m spatial resolution across
#' Australia.
#'
#' @param collection One of \code{"Bacteria"} (default) or \code{"Fungi"}.
#' @param axis \acronym{NMDS} axis number: `1` (default), `2`, or
#'   `3`.
#' @inheritParams read_tern
#'
#' @returns
#' A [terra::SpatRaster] object of the requested Beta Diversity NMDS axis.
#'
#' @seealso
#' [read_tern()]
#'
#' @examplesIf interactive()
#' # Read bacterial diversity NMDS axis 1
#' r <- read_soil_diversity()
#' plot(r)
#'
#' # Read fungal diversity NMDS axis 2
#' r_f2 <- read_soil_diversity(collection = "Fungi", axis = 2)
#' plot(r_f2)
#'
#' @references
#'   Dobarco, M., Wadoux, A. & Xue, P. (2024). Soil and Landscape Grid National
#'   Soil Attribute Maps - Soil Bacteria and Fungi Beta Diversity (3"
#'   resolution) - Release 1. Version 1.0. Terrestrial Ecosystem Research
#'   Network. (Dataset). \doi{10.25919/4x7n-y874}.
#'
#'   TERN Soil Beta Diversity Point-of-truth metadata URL:
#'   <https://geonetwork.tern.org.au/geonetwork/srv/eng/catalog.search#/metadata/4a428d52-dda6-4097-8dd9-d3ec63973029>
#'
#'
#' @export
read_soil_diversity <- function(
  collection = "Bacteria",
  axis = 1L,
  api_key = get_key(),
  max_tries = NULL,
  initial_delay = NULL
) {
  return(read_tern(
    "SOILDIV",
    collection = collection,
    axis = axis,
    api_key = api_key,
    max_tries = max_tries,
    initial_delay = initial_delay
  ))
}


#' Internal handler for retrieving Soil Beta Diversity datasets
#'
#' @inheritParams .read_tern_smips
#' @inheritParams read_tern
#' @returns A [terra::SpatRaster] object for the requested soil diversity layer.
#'
#' @dev
.read_tern_soil_diversity <- function(
  did,
  dots,
  api_key,
  max_tries,
  initial_delay
) {
  collection <- if (!is.null(dots[["collection"]])) {
    dots[["collection"]]
  } else {
    "Bacteria"
  }
  axis <- if (!is.null(dots[["axis"]])) {
    as.integer(dots[["axis"]])
  } else {
    1L
  }

  approved_collections <- c("Bacteria", "Fungi")
  collection <- rlang::arg_match(collection, approved_collections)

  if (length(axis) != 1L) {
    cli::cli_abort(
      "Soil Beta Diversity {.arg axis} must be a single value; got length \\
       {.val {length(axis)}}."
    )
  }
  if (!axis %in% 1L:3L) {
    cli::cli_abort("Soil Beta Diversity {.arg axis} must be 1, 2, or 3.")
  }

  fname <- sprintf("NMDS_%s_%d_%s_pred.tif", collection, axis, collection)
  full_url <- sprintf(
    "/vsicurl/https://data.tern.org.au/model-derived/slga/NationalMaps/Other/SoilBetaDiversity/%s",
    fname
  )
  .set_tern_auth(api_key)
  return(.read_cog(full_url, max_tries, initial_delay))
}
