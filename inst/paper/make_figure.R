# Draws the data-flow figure for paper.md (figure_dataflow.png).
# Run from the folder that holds paper.md: Rscript make_figure.R
#
# The figure is drawn at the width of the JOSS text column (5.4 in), so it
# prints at its own size. The three shared steps run left to right through
# the middle row. read_tern() enters it from above and gets its SpatRaster
# back above the last step. collect_tern_data() enters from below, once for
# each layer and date, and its data.table leaves below the last step.
# Colours are Okabe-Ito.

library(grid)

W <- 5.4 # inches
H <- 3.50

sans <- "Helvetica Neue"
mono <- "Menlo"

ink <- "#1D2733"
muted <- "#5B6573"
rule <- "#C9D1DB"
core_edge <- "#7A8696"
blue <- "#0072B2"
blue_fill <- "#E8F1F8"
orange <- "#D55E00"
orange_fill <- "#FCEEE4"
green <- "#009E73"

size_title <- 8.2
size_body <- 6.8
size_code <- 6.3
pad <- 0.1

`%||%` <- function(a, b) if (is.null(a)) b else a
lead <- function(size) size * 1.3 / 72 # line height in inches

# Boxes as left, right, bottom, top in inches.
bx <- function(l, r, b, t) list(l = l, r = r, b = b, t = t, x = (l + r) / 2)

core_b <- 1.22
core_t <- 2.42
v1 <- bx(0.05, 1.49, core_b, core_t)
v2 <- bx(1.69, 3.71, core_b, core_t)
v3 <- bx(3.91, 5.35, core_b, core_t)
e_top <- bx(0.05, 2.12, 2.80, 3.45)
x_top <- bx(3.28, 5.35, 2.80, 3.45)
e_bot <- bx(0.05, 2.12, 0.05, 0.86)
x_bot <- bx(3.28, 5.35, 0.05, 0.86)

card <- function(b, fill, edge, lwd = 0.9) {
  grid.roundrect(
    b$x, (b$b + b$t) / 2, b$r - b$l, b$t - b$b,
    default.units = "native",
    r = unit(0.055, "inches"),
    gp = gpar(fill = fill, col = edge, lwd = lwd)
  )
}

txt <- function(label, x, y, size, family = sans, face = "plain",
                col = ink, just = c("left", "top")) {
  grid.text(
    label, x, y,
    default.units = "native",
    just = just,
    gp = gpar(fontfamily = family, fontface = face, fontsize = size, col = col)
  )
}

# Lines stacked down from a top-left anchor, each with its own style.
# Returns the y below the last line.
stack <- function(x, y, spec) {
  for (s in spec) {
    y <- y - (s$gap %||% 0)
    txt(s$label, x, y, s$size, s$family %||% sans, s$face %||% "plain",
        s$col %||% ink)
    y <- y - lead(s$size)
  }
  return(y)
}
code <- function(label, gap = 0) {
  list(label = label, size = size_code, family = mono, gap = gap)
}
note <- function(label, gap = 0, col = muted) {
  list(label = label, size = size_body, col = col, gap = gap)
}
head_mono <- function(label, col) {
  list(label = label, size = size_title, family = mono, face = "bold",
       col = col)
}

# Arrow whose tip ends exactly on the target edge: a filled head with no
# outline, and a shaft that stops at the base of the head.
arrow_seg <- function(x0, y0, x1, y1, col, lwd = 1.25) {
  len <- sqrt((x1 - x0)^2 + (y1 - y0)^2)
  ux <- (x1 - x0) / len
  uy <- (y1 - y0) / len
  head <- 0.075
  half <- head * tan(24 * pi / 180)
  bx <- x1 - head * ux
  by <- y1 - head * uy
  grid.segments(x0, y0, bx + 0.01 * ux, by + 0.01 * uy,
                default.units = "native",
                gp = gpar(col = col, lwd = lwd, lineend = "butt"))
  grid.polygon(c(x1, bx - half * uy, bx + half * uy),
               c(y1, by + half * ux, by - half * ux),
               default.units = "native", gp = gpar(fill = col, col = NA))
}

step_title <- function(b, n, label) {
  cx <- b$l + pad + 0.07
  cy <- b$t - pad - 0.07
  grid.circle(cx, cy, r = unit(0.072, "inches"), default.units = "native",
              gp = gpar(fill = ink, col = NA))
  txt(n, cx, cy, 6.2, face = "bold", col = "white",
      just = c("centre", "centre"))
  txt(label, cx + 0.13, cy, size_title, face = "bold",
      just = c("left", "centre"))
  return(cy - 0.15)
}

# A small raster in viridis colours.
raster_icon <- function(x0, y0, cell) {
  vir <- c("#440154", "#46337E", "#365C8D", "#277F8E",
           "#1FA187", "#4AC16D", "#9FDA3A", "#FDE725")
  vals <- c(2, 3, 4, 5, 5, 6, 7, 3, 4, 4, 5, 6, 7, 8, 4, 5, 5, 6, 7, 7, 8)
  k <- 0
  for (r in 0:2) {
    for (c in 0:6) {
      k <- k + 1
      grid.rect(x0 + c * cell, y0 - r * cell, cell, cell,
                default.units = "native", just = c("left", "top"),
                gp = gpar(fill = vir[vals[k]], col = "white", lwd = 0.4))
    }
  }
}

# A small table with the column names collect_tern_data() writes.
table_icon <- function(x0, y0, total, rh, col) {
  heads <- c("date", "lon", "lat", "SMIPS_totalbucket", "AET_ETa")
  share <- c(0.15, 0.13, 0.13, 0.38, 0.21)
  widths <- total * share
  lefts <- x0 + c(0, cumsum(widths)[-5])
  for (c in 1:5) {
    grid.rect(lefts[c], y0, widths[c], rh, default.units = "native",
              just = c("left", "top"),
              gp = gpar(fill = col, col = "white", lwd = 0.6))
    txt(heads[c], lefts[c] + widths[c] / 2, y0 - rh / 2, 4.9, family = mono,
        col = "white", just = c("centre", "centre"))
    for (r in 1:2) {
      grid.rect(lefts[c], y0 - r * rh, widths[c], rh,
                default.units = "native", just = c("left", "top"),
                gp = gpar(fill = "white", col = rule, lwd = 0.5))
    }
  }
}

# The tiles of a remote file. The two that a point request touches are filled.
tile_icon <- function(x0, y0, cell) {
  hit <- c("2-1", "3-1")
  for (r in 0:3) {
    for (c in 0:5) {
      on <- paste(c, r, sep = "-") %in% hit
      grid.rect(x0 + c * cell, y0 - r * cell, cell, cell,
                default.units = "native", just = c("left", "top"),
                gp = gpar(fill = if (on) green else "white",
                          col = if (on) "white" else rule, lwd = 0.6))
    }
  }
  grid.rect(x0, y0, 6 * cell, 4 * cell, default.units = "native",
            just = c("left", "top"),
            gp = gpar(fill = NA, col = core_edge, lwd = 0.6))
  grid.circle(x0 + 3 * cell, y0 - 1.5 * cell, r = unit(0.024, "inches"),
              default.units = "native",
              gp = gpar(fill = ink, col = "white", lwd = 0.6))
}

draw_figure <- function() {
  grid.newpage()
  pushViewport(viewport(xscale = c(0, W), yscale = c(0, H)))

  txt("SHARED STEPS", (e_top$r + x_top$l) / 2, core_t + 0.1, 6,
      face = "bold", col = muted, just = c("centre", "bottom"))

  # Step 1: check the request.
  card(v1, "white", core_edge)
  y <- step_title(v1, "1", "Check the request")
  y <- stack(v1$l + pad, y - 0.02, list(
    note("SMIPS totalbucket: daily", col = ink),
    note("soil moisture, available", col = ink),
    code("2005-01-01 to today")
  ))
  stack(v1$l + pad, y - 0.06, list(
    note("A date outside this window"),
    note("is rejected before anything"),
    note("is downloaded.")
  ))

  # Step 2: build the URL.
  card(v2, "white", core_edge)
  y <- step_title(v2, "2", "Build the URL")
  y <- stack(v2$l + pad, y - 0.02, list(
    code("/vsicurl/https://data.tern.org.au/"),
    code("model-derived/smips/v1_0/"),
    code("totalbucket/2024/"),
    code("smips_totalbucket_mm_20240115.tif")
  ))
  stack(v2$l + pad, y - 0.06, list(
    note("Fixed URL templates, guarded"),
    note("by tests against accidental change.")
  ))

  # Step 3: read byte ranges.
  card(v3, "white", core_edge)
  y <- step_title(v3, "3", "Read with GDAL")
  cell <- 0.088
  tile_icon(v3$l + pad, y - 0.03, cell)
  stack(v3$l + pad, y - 0.03 - 4 * cell - 0.07, list(
    note("Only the parts of the file", col = ink),
    note("that a crop or a point", col = ink),
    note("touches are downloaded.", col = ink)
  ))

  core_y <- (core_b + core_t) / 2
  arrow_seg(v1$r, core_y, v2$l, core_y, ink)
  arrow_seg(v2$r, core_y, v3$l, core_y, ink)

  # Top lane: read_tern() in, SpatRaster out.
  card(e_top, blue_fill, blue)
  stack(e_top$l + pad, e_top$t - pad + 0.01, list(
    head_mono("read_tern()", blue),
    note("one layer, one date"),
    code("read_tern(\"SMIPS\",", gap = 0.04),
    code("          date = \"2024-01-15\")")
  ))
  card(x_top, blue_fill, blue)
  stack(x_top$l + pad, x_top$t - pad + 0.01, list(
    head_mono("SpatRaster", blue),
    note("returned by read_tern(),"),
    note("ready for terra")
  ))
  raster_icon(x_top$r - pad - 7 * 0.07, x_top$b + pad + 3 * 0.07, 0.07)

  arrow_seg(v1$x, e_top$b, v1$x, v1$t, blue)
  arrow_seg(v3$x, v3$t, v3$x, x_top$b, blue)

  # Bottom lane: collect_tern_data() in, data.table out.
  card(e_bot, orange_fill, orange)
  stack(e_bot$l + pad, e_bot$t - pad + 0.01, list(
    head_mono("collect_tern_data()", orange),
    note("many layers, sites and dates"),
    code("collect_tern_data(xy = sites,", gap = 0.04),
    code("  dates = d,"),
    code("  datasets = c(\"SMIPS\", \"AET\"))")
  ))
  card(x_bot, orange_fill, orange)
  y <- stack(x_bot$l + pad, x_bot$t - pad + 0.01, list(
    head_mono("data.table", orange),
    note("one row per point and date,"),
    note("one column per variable")
  ))
  table_icon(x_bot$l + pad, y - 0.035, x_bot$r - x_bot$l - 2 * pad,
             0.074, orange)

  arrow_seg(v1$x, e_bot$t, v1$x, v1$b, orange)
  arrow_seg(v3$x, v3$b, v3$x, x_bot$t, orange)

  # Labels beside the vertical arrows.
  mid_top <- (e_top$b + core_t) / 2
  mid_bot <- (e_bot$t + core_b) / 2
  txt("once", v1$x + 0.08, mid_top, size_body, col = blue,
      just = c("left", "centre"))
  txt("for each layer: once per date, or once if static", v1$x + 0.08,
      mid_bot, size_body,
      col = orange, just = c("left", "centre"))
  txt("values extracted at all points", v3$x - 0.08, mid_bot, size_body,
      col = orange, just = c("right", "centre"))

  popViewport()
}

ragg::agg_png("figure_dataflow.png", width = W, height = H, units = "in",
              res = 450, background = "white")
draw_figure()
invisible(dev.off())
