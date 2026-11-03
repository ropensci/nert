---
title: "nert: Curated Access to TERN Environmental Raster Data in R"
tags:
  - R
  - Australia
  - TERN
  - soil
  - soil moisture
  - evapotranspiration
  - raster
  - cloud-optimised GeoTIFF
  - GDAL
  - agriculture
authors:
  - name: Max Moldovan
    orcid: 0000-0001-9680-8474
    corresponding: true
    affiliation: 1
  - name: Russell Edson
    orcid: 0000-0002-4607-5396
    affiliation: 1
  - name: Wasin Pipattungsakul
    orcid: 0009-0005-2666-6315
    affiliation: 1
  - name: Sam Rogers
    orcid: 0000-0002-8147-1239
    affiliation: 1
  - name: Adam H. Sparks
    orcid: 0000-0002-0061-8359
    affiliation: 2
affiliations:
  - name: School of Agriculture, Food and Wine, Adelaide University, Urrbrae, South Australia, Australia
    index: 1
  - name: Centre for Crop and Disease Management, School of Molecular and Life Sciences, Curtin University, Bentley, Western Australia, Australia
    index: 2
date: 3 November 2026
bibliography: paper.bib
---

# Summary

Australia's Terrestrial Ecosystem Research Network (TERN) publishes several national-scale geospatial data sets (hereafter referred to as products) of soil properties [for example, clay content, @Malone2022clay], soil classes [@Searle2021], soil bacterial and fungal diversity [@RomanDobarco2022], daily soil moisture [@Stenson2021], actual evapotranspiration [@McVicar2021], canopy height [@Pucino2025] and land surface phenology [@Xie2024].
The products contain large files stored in the cloud-optimised GeoTIFF (COG) format on TERN's data server along with other metadata.
Each product has its own folder layout, file names, time step, date range and map projection.

`nert` is an R package that reads these seven families of maps.
`read_tern()` returns a single map as a `terra` `SpatRaster` [@terra] and downloads only the part that is needed.
`collect_tern_data()` returns values from many maps, at many locations and dates, as one `data.table` [@datatable].
It can be installed from the rOpenSci R-universe (<https://ropensci.r-universe.dev/nert>), and its source is at <https://github.com/ropensci/nert>.
The package covers the seven families through 20 short names, or aliases, such as `"SMIPS"` for soil moisture and `"CLY"` for clay content.

# Statement of need

Agronomists, soil scientists and ecologists often need environmental information contained in TERN's data layers at the locations and dates of their own field trials.
Collecting manually, this takes several steps for each product.
The user has to find the file path, build a URL, pass an API key, check that the date exists for that product, and read the file with the Geospatial Data Abstraction Library (GDAL) [@GDAL2026] without downloading a whole national map.
A small typo in a path or a date returns no file, or worse, the wrong file without a warning.

`nert` greatly simplifies data download, minimising the risk of a query mistake and allowing TERN data collection for a naïve curious user.
For records changing longitudinally, a date outside the product's record is rejected before anything is downloaded, and the error message gives the dates that are available.
Reading TERN's files needs a free API key.
The getting-started vignette shows, with screenshots, how to create a key on TERN's website and store it in the system keyring.
`get_key()` reads it from there.

# Alternative packages

The `slga` package [@slga] reads the Soil and Landscape Grid of Australia, one of the seven families in `nert`, through web coverage services.
It was archived on CRAN in September 2021 and is now available from GitHub.
The `geodata` package [@geodata] downloads global and other national data, such as WorldClim climate and SoilGrids soil maps, but not TERN's products.
The `ausplotsR` package [@ausplotsR] gives access to TERN's AusPlots field surveys of vegetation and soils, not to national maps.

TERN also runs a SpatioTemporal Asset Catalog (STAC).
R users can search it with `rstac` [@Simoes2021], and Python users with TERN's own `tern-stac` package [@ternstac].
A catalogue search returns descriptions and file links.
The user still has to choose the right file, handle authentication and work out which dates each product covers.

We wrote a new package rather than extending any existing one.
Extending `slga` would have meant adding a second protocol for six more families, while a STAC client is general by design but leaves the rules of each product to the user.
`nert` reads all seven TERN families, making sure that a query returns the right dataset or declines to do so with an explicit reason.

# Software design

`show_datasets()` lists every product with its alias, TERN identifier, time step and resolution.
Some facts that the STAC catalogue does not provide are built into `nert`.
Two of the six soil moisture collections start in 2005 and the other four in 2015.
The phenology product covers 2003 to 2018, with two growing seasons a year.
Canopy height comes in the Australian Albers projection (EPSG:3577) rather than in longitude and latitude.
`read_tern("CANOPY")` returns the map in that projection, so a crop must be given in Albers coordinates, while `collect_tern_data()` takes longitude and latitude for every product, canopy height included.
Because the file locations are fixed in the package, a new release is needed whenever TERN moves a file.
Snapshot tests guard the URL templates against accidental change.

Each product family has its own reader, such as `read_smips()` or `read_aet()`, for interactive work.
`read_tern()` takes any alias instead, as in `read_tern("SMIPS", date = "2024-01-15")`.
Aliases are plain strings, not sensitive for case change.
A script or a scheduled pipeline can take them from `show_datasets()` or from a configuration file and loop over products without code for each one.

Reads go through GDAL's virtual file system for remote files.
Only the parts of a file that a crop or a point touches are downloaded, as the *Bandwidth-safe spatial subsetting* vignette shows.
The API key is passed to GDAL as a setting and is never written into the URL.

`collect_tern_data()` extracts any or all of the 20 products at a set of sites, for a date range or a list of dates.
Sites can be given as coordinates or as a table.
The result is one `data.table` with a row for each site and date and a column for each variable, named by alias and collection, such as `SMIPS_totalbucket` or `AET_ETa`.
One alias can therefore give several columns.
Time-series layers are opened once per date, while layers that do not change over time are opened once and their values repeated across dates, so the table joins directly to field records (\autoref{fig:flow}).
If a layer cannot be read, its columns are left as `NA` with a warning and the rest of the table is still returned.

Tests run offline and need no API key.
Four vignettes cover getting started, agricultural analytics, reading only part of a file, and batch collection.

![How `nert` reads data. Both `read_tern()` (top) and `collect_tern_data()` (bottom) check the request, build the URL and let GDAL download only the parts of the file that are needed. `collect_tern_data()` repeats this for each layer, once per date for time series and once for static layers. The example is daily soil moisture for 15 January 2024.\label{fig:flow}](figure_dataflow.png){width=100%}

# Research impact statement

`nert` was approved after rOpenSci software peer review, with two reviewers, in October 2026 [@review785].
The package was developed in the Analytics for the Australian Grains Industry (AAGI) program to supply TERN's maps as covariates for agricultural analysis.
Its vignette *Using nert to augment agricultural analytics with SMIPS data* works through such an analysis, adding daily soil moisture to field data and fitting a mixed model, and can be reused as a template.

# AI usage disclosure

We used generative AI tools in developing `nert` and in preparing this paper.
The first release, v0.0.1 (April 2025), was written without them.
Later versions were developed with Anthropic's Claude models (Opus 4.6 to 4.8, Sonnet 4.6 and Opus 5.5) through the Claude Code assistant, which helped draft code, documentation and tests.
GitHub Copilot's coding agent wrote 12 commits, including an option to choose between the two canopy height products.
A maintainer reviewed and merged each of these commits.

Claude introduced two errors in v1.0.0.
The phenology function offered variables that the product does not contain, and the soil function offered confidence intervals that it could not retrieve.
Co-authors found both, and v1.1.0 fixed them.
This paper was drafted and revised with Claude Opus 5.5.
An earlier draft was reviewed with xAI's Grok 4.7.
The authors made the design decisions, reviewed all assisted output and take responsibility for the code and this paper.
Dataset paths, date limits and examples were checked against TERN's data server and catalogue.

# Acknowledgements

We acknowledge the support of the Grains Research and Development Corporation (GRDC) through the Analytics for the Australian Grains Industry (AAGI) projects UOA2301-005OPX (AAGI-AU) and CUR2210-005OPX (AAGI-CU).
We thank Michael Sumner and Shandiya Balasubramaniam for reviewing `nert` for rOpenSci, and Lauren O'Brien, the author of `slga`, for editing the review.
We thank TERN for making these products openly available.

# References
