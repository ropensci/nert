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

Australia's Terrestrial Ecosystem Research Network (TERN) publishes several national-scale geospatial datasets (hereafter referred to as products), including soil properties [for example, clay content; @Malone2022clay], soil classes [@Searle2021], soil bacterial and fungal diversity [@RomanDobarco2022], daily soil moisture [@Stenson2021], actual evapotranspiration [@McVicar2021], canopy height [@Pucino2025], and land surface phenology [@Xie2024].
These products comprise large files stored in the cloud-optimised GeoTIFF (COG) format on TERN's data server, together with associated metadata.
Each product has its own directory structure, file-naming convention, temporal resolution, date range, and map projection.

`nert` is an R package that provides a consistent interface for reading these seven data products.
The `read_tern()` function returns a requested dataset as a `terra` `SpatRaster` [@terra], transferring only the requested data rather than downloading an entire Australia-wide dataset.
For queries spanning multiple products, locations, or dates, `collect_tern_data()` returns the requested values as a single `data.table` [@datatable].
Both functions provide convenient access to the seven dataset families through 20 short names, or aliases, such as `"SMIPS"` for soil moisture and `"CLY"` for clay content.

The `nert` package can be installed from the rOpenSci R-universe (<https://ropensci.r-universe.dev/nert>) or the Comprehensive R Archive Network (CRAN) (<https://CRAN.R-project.org/package=nert>).
The source code is openly available at <https://www.github.com/ropensci/nert>.

# Statement of need

Agronomists, soil scientists, and ecologists often need environmental information from TERN's COGs for specific locations and dates, for example to characterise field trials or support agronomic planning.
Obtaining these data manually requires several steps for each product.
The user must identify the appropriate COG, construct its URL, provide a valid TERN API key, confirm that the requested date is available for that product, and then either download the entire COG or access it remotely from the TERN Data Portal using software such as the Geospatial Data Abstraction Library (GDAL) [@GDAL2026].
A small error in a file path or date can result in no file being returned or, more problematically, the wrong file being retrieved without warning.

`nert` simplifies this process, reducing the opportunity for query errors while making TERN data easier to use in reproducible analyses.
For products that vary through time, `nert` checks a requested date against the temporal extent of the product before attempting data access.
If the date falls outside that extent, the request is rejected and the error message reports the dates available for that product.

Access to these products through the TERN Data Portal requires a free API key.
The getting-started vignette provides step-by-step instructions, with screenshots, for obtaining a TERN API key and storing it securely in the system keyring for use with `nert`.

# Alternative packages

Several R packages provide related, but not equivalent, access to Australian ecosystem and environmental data:

- The `slga` package [@slga] provides access to the Soil and Landscape Grid of Australia, one of the seven data-product families accessible through `nert`, using web coverage services.
  However, `slga` has been retired: it has been archived on CRAN since September 2021, and its GitHub repository notes that the package was deprecated after the TERN Data Portal began delivering these products as COGs.
- The `geodata` package [@geodata] provides access to global and national geospatial datasets, including WorldClim climate and SoilGrids soil data.
  However, it does not provide access to the TERN products supported by `nert`.
- The `ausplotsR` package [@ausplotsR] provides access to TERN's AusPlots field surveys of vegetation and soils, but not to the national-scale geospatial products supported by `nert`.

TERN also operates a SpatioTemporal Asset Catalog (STAC).
R users can search the TERN STAC using `rstac` [@Simoes2021], while Python users can use TERN's `tern-stac` package [@ternstac].
A STAC search returns dataset descriptions and links to files, but users must still identify the appropriate file, handle authentication, and determine the temporal coverage of individual products.

We developed `nert` as a new package rather than extending an existing one.
Extending `slga` would have required replacing its existing data-access mechanism to support COGs from the TERN Data Portal, as well as adding support for six additional data-product families.
Building on the TERN STAC interface provided by `rstac` would offer a more general approach to dataset discovery, but users would still need to determine how to access and interpret each individual product.
By contrast, `nert` provides a consistent interface to seven TERN dataset families, validates requests before retrieving data, and returns explicit, human-readable errors when a request cannot be fulfilled.

# Software design

`nert` was designed to simplify access to the TERN API while following best practices for security and R package development.
It abstracts away much of the underlying API interaction, making it straightforward to configure an API key and find and access TERN data from an R session.

API GET requests are handled through GDAL's virtual file system for remote files.
Only the portions of a file needed for a requested point or spatial crop are transferred, as described in the [*Bandwidth-safe spatial subsetting*](https://docs.ropensci.org/nert/articles/bandwidth_safe_subsetting.html) vignette.
The API key is passed to GDAL as a configuration setting and is never included in the URL.

Functions in `nert` fall into two broad groups: reader functions and helper functions.
The `read_*()` family provides the core functionality, retrieving TERN data and importing it into the R session.
Three helper functions support dataset discovery, API-key management, and aggregation.
`show_datasets()` lists the TERN datasets available through the API and accessible with `nert`.
`get_key()` manages the API key securely using the `keyring` package [@keyring] and prompts the user to set a key if none is found.
`collect_tern_data()` builds on the `read_*()` functions to extract any selection of the 20 supported products for a set of sites over a date range or specified dates.

Each TERN data-product family has a dedicated reader, such as `read_smips()` or `read_aet()`, for convenient interactive use.
Alternatively, `read_tern()` accepts a product alias, for example `read_tern("SMIPS", date = "2024-01-15")`.
Aliases are supplied as case-insensitive character strings.
This makes `read_tern()` particularly useful in scripts and scheduled pipelines: aliases can be obtained from `show_datasets()` or read from a configuration file, allowing code to iterate over products without requiring a separate function call for each one.

Sites can be supplied either as individual coordinates (`lon`, `lat`) or as a `data.frame`, `data.table` [@datatable], or `matrix` containing coordinate columns named `lon`/`lat` or `x`/`y`.
When a table or matrix of sites is supplied, it takes precedence over individual coordinate values.
`collect_tern_data()` returns a `data.table` [@datatable], which is also compatible with a base R `data.frame`, with one row for each site-date combination and columns for the requested datasets.
This structure follows the principles of tidy data [@hadley].
Columns are named by product alias and collection, such as `SMIPS_totalbucket` or `AET_ETa`, so a single alias can produce multiple columns.

Time-varying layers are opened once per date, whereas static layers are opened once and their values reused across dates.
The resulting table can therefore be joined directly to field observations (\autoref{fig:flow}).
If a layer cannot be read, its columns are filled with `NA`, a warning is issued, and the remainder of the table is still returned.

Because file locations are encoded in the package, a new release is required if TERN moves a source file.
Snapshot tests guard the URL templates against accidental changes during package development.

![A diagram showing how `nert` downloads and imports data. Both `read_tern()` (top) and `collect_tern_data()` (bottom) validate the request, construct the URL, and use GDAL to transfer only the required portions of the file. `collect_tern_data()` repeats this process for each requested layer, once per date for time-varying layers and once for static layers. The example shows daily soil moisture for 15 January 2024.\label{fig:flow}](figure_dataflow.png){width=100%}

# Research impact statement

`nert` provides product-specific handling that is not provided by a general STAC catalogue.
For example, two of the six soil-moisture collections begin in 2005, while the remaining four begin in 2015.
The phenology product covers 2003 to 2018 and contains two growing seasons per year.
Canopy height is provided in the Australian Albers projection (EPSG:3577), rather than longitude and latitude.

`nert` handles these product-specific differences for the user.
For example, `read_tern("CANOPY")` returns the canopy-height map in its native projection, so a bounding box used to crop the data must be supplied in Australian Albers coordinates.
By contrast, `collect_tern_data()` accepts longitude and latitude for every supported product, including canopy height.

`nert` was reviewed through the rOpenSci software peer review process by two reviewers and was accepted in October 2026 [@review785].
The package was developed through the Analytics for the Australian Grains Industry (AAGI) project, through the Research & Development projects AAGI-UA-RD-RNS and AAGI-AU-RD-RNT2, to make TERN data readily available as covariates for agricultural analyses.
The `nert` vignette [*Using nert to augment agricultural analytics with SMIPS data*](https://docs.ropensci.org/nert/articles/nert_for_agricultural_analytics.html) demonstrates this use case by adding daily soil-moisture data to field observations and fitting a mixed model, providing a workflow that can be adapted to other agricultural analyses.

# AI usage disclosure

We used generative AI tools during the development of `nert` and the preparation of this paper.
The first release of `nert`, v0.0.1 (April 2025), was developed without AI assistance.
Later versions were developed with Anthropic's Claude models, specifically Opus 4.6--4.8, Sonnet 4.6, and Opus 5.5, together with the Claude Code harness.
These tools were used to assist with drafting code, writing function documentation, and developing unit tests.
GitHub Copilot's coding agent produced 12 commits during the development of `nert`, including an option to choose between the two canopy-height products.
In all cases, a human maintainer reviewed the AI-assisted development work, and extensive local testing was used to ensure that `nert` performed as expected in end-user environments.

This paper was drafted and revised with Claude Opus 5.5, and an earlier draft was reviewed with xAI's Grok 4.7.
The authors made the design decisions, reviewed all AI-assisted output, and take full responsibility for the paper and its representation of `nert`.

# Acknowledgements

We acknowledge the support of the Grains Research and Development Corporation (GRDC) through the Analytics for the Australian Grains Industry (AAGI) project, GRDC project codes UOA2301-005OPX (AAGI-AU) and CUR2210-005OPX (AAGI-CU).
We thank Michael Sumner and Shandiya Balasubramaniam for reviewing `nert` through rOpenSci software peer review, and Lauren O'Brien, the author of `slga`, for editing the [review](https://github.com/ropensci/software-review/issues/785).
We thank TERN for making these data products openly available.

# References
