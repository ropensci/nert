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

`nert` is an R package that provides functions to read these seven families of data. 
The function `read_tern()` returns a single data object as a `terra` `SpatRaster` [@terra] and downloads only the requested data, rather than downloading the entire Australia-wide dataset.
The function `collect_tern_data()` returns values from multiple products, at many locations and dates, as one `data.table` [@datatable] object.
Both functions provide convenience access to the seven dataset families through 20 short names, or aliases, such as `"SMIPS"` for soil moisture and `"CLY"` for clay content.
The `nert` package can be installed from the rOpenSci R-universe (<https://ropensci.r-universe.dev/nert>) or the Comprehensive R Archive Network (CRAN) (<CRAN.R-project.org/package=nert>). The source code is openly available at <https://www.github.com/ropensci/nert>.


# Statement of need

Agronomists, soil scientists and ecologists often need environmental information contained in TERN's data COGs at specific locations and dates (for instance, dates corresponding to their field trials, or agronomic planning).
Collecting these data layers manually, this process takes several steps for each product. The user has to find the file path to the COG, build a URL, pass a valid TERN API key, double-check that the requested date exists for that data product, and then either download the entire COG, or stream the COG directly from the TERN Data Portal, such as by using the Geospatial Data Abstraction Library (GDAL) [@GDAL2026].
A small typo in a path or a date returns no file; or worse, returns the wrong file without any warning.

`nert` greatly simplifies the data download, minimising the risk of a query mistake and enabling TERN data collection for the end-user.
For data products that change longitudinally, if the user provides a date that falls outside of the product's temporal extent, the request is rejected before anything is downloaded, and the error message helpfully gives the dates that are available for the product.

Note that accessing TERN's data products on the TERN Data Portal requires a free API key. The process for obtaining an API key is straightforward, and the getting-started vignette shows, with helpful screenshots, how to create a TERN API key and store it in the system keyring so that it can be used with `nert`.

# Alternative packages

There are a variety of R packages that provide similar, but not equivalent, access to Australian ecosystem datasets:

- The `slga` package [@slga] reads the Soil and Landscape Grid of Australia, one of the seven data products accessible in `nert`, through web coverage services.
However, this package has been retired; it has been archived on CRAN since September 2021, and its GitHub repository notes that the package has been deprecated since the TERN Data Portal started delivering its data products via COGs.
- The `geodata` package [@geodata] downloads global and other national or global data, such as WorldClim climate and SoilGrids soil data. However, `geodata` does not provide access to TERN's data products.
- The `ausplotsR` package [@ausplotsR] gives access to TERN's AusPlots localised field surveys of vegetation and soils, but not to its national-scale datasets.

TERN also runs a SpatioTemporal Asset Catalog (STAC). R users can search the TERN STAC with `rstac` [@Simoes2021], and Python users with TERN's own `tern-stac` package [@ternstac]. A catalogue search of the TERN STAC returns descriptions and file links, but the user still has to choose the right file, handle authentication, and work out which dates each product covers.

We developed our new package `nert`, rather than extending an existing one. Extending the `slga` package would have necessitated updating the data access to work with the COGs on the TERN Data Portal, as well as adding a second protocol for six more data families. Building off of the TERN STAC access provided by `rstac` would have allowed more generality for the dataset access, but also would have meant that the mechanism for accessing each data product would need to be discerned by the user. By contrast, `nert` reads seven TERN dataset families in a user-friendly way, making sure that a query returns the right dataset requested, or declines with an explicit and human-readable reason.

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

Reads go through GDAL's virtual file-system for remote files.
Only the parts of a file that a crop or a point touches are downloaded, as the [*Bandwidth-safe spatial subsetting*](https://docs.ropensci.org/nert/articles/bandwidth_safe_subsetting.html) vignette shows.
The API key is passed to GDAL as a setting and is never written into the URL.

`collect_tern_data()` extracts any or all 20 products at a set of sites for a date range or a list of dates.
Sites can be given as coordinates or as a table.
The result is one `data.table` with a row for each site and date and a column for each variable, named by alias and collection, such as `SMIPS_totalbucket` or `AET_ETa`.
One alias can therefore give several columns.
Time-series layers are opened once per date, while layers that do not change over time are opened once and their values repeated across dates, so the table joins directly to field records (\autoref{fig:flow}).
If a layer cannot be read, its columns are left as `NA` with a warning and the rest of the table is still returned.

Tests run offline and need no API key.
Four vignettes cover getting started, agricultural analytics, reading only part of a file, and batch collection.

![A diagram illustrating how `nert` downloaded and imports data. Both `read_tern()` (top) and `collect_tern_data()` (bottom) check the request, build the URL and let GDAL download only the parts of the file that are needed. `collect_tern_data()` repeats this for each layer, once per date for time series and once for static layers. The example is daily soil moisture for 15 January 2024.\label{fig:flow}](figure_dataflow.png){width=100%}

# Research impact statement

`nert` was approved through rOpenSci software peer review, with two reviewers, in October 2026 [@review785].
The package was developed through the Analytics for the Australian Grains Industry (AAGI) project, via the Research & Development projects AAGI-UA-RD-RNS and AAGI-AU-RD-RNT2 to supply TERN's data as covariates for use in agricultural analysis. The `nert` vignette [*Using nert to augment agricultural analytics with SMIPS data*](https://docs.ropensci.org/nert/articles/nert_for_agricultural_analytics.html) works through such an analysis, adding daily soil moisture to field data and fitting a mixed model, and can be reused as a template.

# AI usage disclosure

We used generative AI tools in developing `nert`, and in preparing this paper.
The first release of the `nert` package, v0.0.1 (April 2025), was developed without the use of AI assistance. Later versions of `nert` were developed with Anthropic's Claude AI models (specifically Opus 4.6-4.8, Sonnet 4.6 and Opus 5.5) together with the Claude Code harness. The AI model was used to help draft code, write function documentation, and write unit tests.
GitHub Copilot's coding agent wrote 12 GitHub commits for the `nert` package during its development, including an option to choose between the two canopy height products.
In all cases, a human maintainer reviewed the AI-assisted development work, and extensive local testing was conducted to ensure that the `nert` package performed as expected in end-user environments.

This paper was drafted and revised with Claude Opus 5.5, and an earlier draft of this paper was reviewed with xAI's Grok 4.7. The authors made the design decisions, reviewed all AI-assisted output, and take full accountability for this paper and its representation of the `nert` package.

# Acknowledgements

We acknowledge the support of the Grains Research and Development Corporation (GRDC) through the Analytics for the Australian Grains Industry (AAGI) project, GRDC project codes UOA2301-005OPX (AAGI-AU) and CUR2210-005OPX (AAGI-CU). We thank Michael Sumner and Shandiya Balasubramaniam for reviewing `nert` for rOpenSci, and Lauren O'Brien, the author of `slga`, for editing the [review](https://github.com/ropensci/software-review/issues/785). We thank TERN for making these useful data products openly available.

# References
