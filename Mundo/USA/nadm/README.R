#' ---
#' title: 'Procesamiento de datos: North American Drought Monitor'
#' author: Isaac Arroyo
#' date-format: long
#' date: last-modified
#' lang: es
#' format:
#'   gfm:
#'     html-math-method: katex
#'     fig-width: 5
#'     fig-asp: 0.75
#'     fig-dpi: 300
#'     code-annotations: below
#'     df-print: kable
#'     wrap: none
#' execute:
#'   echo: true
#'   eval: true
#'   warning: false
#' ---
 
#| label: setwd-to-path2README_R
#| eval: false
#| echo: false

setwd("./Mundo/USA/nadm/")

#' ## Introducción y objetivos
#'
#' Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed luctus 
#' sollicitudin nisi, in ultricies est vestibulum eu. Vestibulum eleifend, 
#' nunc ac sagittis porta, dolor mi cursus dolor, ut porta tellus augue at 
#' ex. Morbi eget ante aliquet, tristique erat convallis, fermentum 
#' mauris. Nullam eu egestas ipsum. Vestibulum ex tortor, ultricies 
#' accumsan gravida eget, dictum sed diam. Aliquam fringilla dapibus 
#' ligula, sed commodo neque sagittis suscipit. Fusce mattis vitae enim 
#' nec faucibus. Donec odio massa, tincidunt a ultrices vulputate, volutpat 
#' sit amet libero.
#' 
#' Quisque convallis egestas lobortis. Proin a finibus nulla, eu imperdiet 
#' ex. Vestibulum ac nibh sit amet sapien aliquam porttitor. Nam dictum 
#' venenatis imperdiet. Quisque imperdiet ac neque in pulvinar. Nulla 
#' facilisi. Pellentesque eu consectetur metus. Praesent non nunc eu mi 
#' eleifend finibus a ac metus.

#| label: load-libraries-paths

library(tidyverse)
library(gt)
library(sf)

path2main <- paste0(getwd(), "/../../..")
path2mundo <- paste0(path2main, "/Mundo")
path2usa <- paste0(path2mundo, "/USA")
path2nadmfolder <- paste0(path2usa, "/nadm")
path2ogdata_nadm <- paste0(path2nadmfolder, "/og_data")


#' ## Poligonos de tipos de sequía
#' 
#' Vestibulum felis augue, pharetra sed leo eu, pretium rutrum leo. Sed 
#' viverra, leo et pulvinar fermentum, massa urna bibendum neque, sit amet 
#' consequat nunc mi et metus. Etiam et aliquam libero, quis scelerisque 
#' tellus. Pellentesque sodales metus at aliquet aliquam. Phasellus aliquam 
#' hendrerit nulla. Cras ut commodo metus. Nulla a lectus mollis, fringilla 
#' nisi id, iaculis est. Nunc pharetra nulla arcu, vitae aliquet erat 
#' posuere vel. Aliquam non varius quam. Phasellus sed purus nulla. Praesent 
#' tempus aliquam iaculis. Curabitur et sapien vel neque lacinia pretium.

#| label: load_data-sequias
#| output: false

recent_date <- "202405"

sf_d0 <- st_read(dsn = paste0(path2ogdata_nadm,
                              "/nadm-", recent_date,
                              "/nadm_d0.shp"))

#' Nulla vehicula nunc vitae ex commodo convallis. Nullam iaculis urna ac 
#' condimentum suscipit. Nulla ultricies euismod ligula vitae 
#' varius. Praesent quam orci, volutpat id ante vitae, suscipit ultricies 
#' dolor. Nam varius blandit urna quis blandit. Nam eget porttitor 
#' neque. Maecenas maximus risus ac mauris porta, in tempus dolor 
#' convallis. Maecenas sagittis malesuada blandit. Duis molestie euismod 
#' eleifend. Curabitur volutpat leo vitae vestibulum ornare. Duis molestie 
#' facilisis dui.
#' 
#' Nunc vitae ligula magna. Mauris eu urna non lacus suscipit 
#' maximus. Nullam sodales porttitor magna quis rhoncus. Vestibulum 
#' elementum nibh quis quam cursus interdum. Vestibulum sit amet justo ut 
#' ex molestie rhoncus. Praesent tempus posuere urna, vel rutrum quam 
#' maximus blandit. Vivamus sed dui eu leo euismod congue. Curabitur in 
#' ante ut ligula finibus porttitor. Fusce iaculis odio et erat finibus, 
#' egestas vulputate nunc sollicitudin. Cras sollicitudin risus eleifend 
#' pharetra tincidunt. Quisque eleifend fringilla maximus. Vivamus vitae 
#' cursus enim.