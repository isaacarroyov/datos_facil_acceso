#' ---
#' title: 'Procesamiento de datos: Incidencia delictiva del Fuero Común'
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
#' execute:
#'   echo: true
#'   eval: true
#'   warning: false
#' ---
 
#| label: setwd-to-path2README_R
#| eval: false
#| echo: false

setwd("./GobiernoMexicano/sesnsp/")

#' ## Introducción y objetivos
#'
#' De acuerdo con la página del Secretariado Ejecutivo del Sistema Nacional 
#' de Seguridad Pública (SESNSP):
#' 
#' > La incidencia delictiva se refiere a la presunta ocurrencia de delitos 
#' registrados en averiguaciones previas iniciadas o carpetas de 
#' investigación, reportadas por las Procuradurías de Justicia y Fiscalías 
#' Generales de las entidades federativas 

#| label: load-libraries-paths

library(tidyverse)
library(gt)

path2main <- paste0(getwd(), "/../..")
path2gobmex <- paste0(path2main, "/GobiernoMexicano")
path2sesnsp <- paste0(path2gobmex, "/sesnsp")
path2ogdatasesnsp <- paste0(path2sesnsp,
                            "/og_incidencia_delitos_fuero_comun")

#' En este documento se usan los datos de la Incidencia Delicitiva del 
#' Fuero Común (nivel municipal), así como el número de víctimas (nivel 
#' estatal), ambos encontrados en el portal [Datos Abiertos de 
#' Incidencia Delictiva](https://www.gob.mx/sesnsp/acciones-y-programas/datos-abiertos-de-incidencia-delictiva?state=published) 
#' del SESNSP.

#| label: load-csv_incidencia-victimas_delictiva_nivel_ent-mun
#| output: false

url_victimas_delitos_ent <- "https://drive.google.com/file/d/1MeLHOZnPQ7kyxRg2JSQvnDh_2U5gjR2i/view"
id_file_victimas_delitos_ent <- str_extract(
    string = url_victimas_delitos_ent,
    pattern = "(?<=d/)(.*?)(?=/view)")

db_victimas_delitos_ent <- read_csv(
    file = paste0("https://drive.google.com/uc?export=download&id=",
                  id_file_victimas_delitos_ent),
    col_types = cols(.default = "c"),
    locale = locale(encoding = "latin1")) %>%
  janitor::clean_names()

# TODO: Encontrar la manera de hacer la descarga directa con el URL del 
#       archivo de Google Drive (INCIDENCIA EN MUNICIPIOS)

path2dataincidenciamun <- list.files(
  path = path2ogdatasesnsp,
  pattern = ".csv",
  full.names = TRUE)

db_incidencia_mun <- read_csv(
    file = path2dataincidenciamun,
    locale = locale(encoding = "latin1"),
    col_types = cols(.default = "c")) %>%
  janitor::clean_names()

#' > Muestra de `db_victimas_delitos_ent`

#| label: sample-db_victimas_delitos_ent
#| echo: false

set.seed(11)
db_victimas_delitos_ent %>%
  slice_sample(n = 5) %>%
  gt()

#' > Muestra de `db_victimas_delitos_ent`

#| label: sample-db_incidencia_mun
#| echo: false

set.seed(11)
db_incidencia_mun %>%
  slice_sample(n = 5) %>%
  gt()

#' Morbi a aliquam odio. Sed feugiat nibh et pulvinar commodo. Nullam 
#' dapibus pharetra justo sed blandit. Nullam at velit volutpat, tincidunt 
#' lacus non, bibendum ex. Cras id luctus nulla, eget tempor libero. 
#' Proin tincidunt consequat massa in viverra. Phasellus sit amet mi vitae 
#' velit vehicula eleifend.
#' 
#' Morbi orci urna, malesuada et viverra ac, tincidunt in libero. Interdum 
#' et malesuada fames ac ante ipsum primis in faucibus. Pellentesque quis 
#' laoreet augue, in interdum turpis. In iaculis erat magna, commodo 
#' hendrerit leo elementum sit amet. Proin gravida dolor nisi, vel aliquam 
#' nibh sagittis eget. Vivamus suscipit, felis at lobortis dictum, dolor 
#' tellus imperdiet ipsum, id maximus lacus diam quis nisl. Nam pretium 
#' arcu id nisl lobortis vehicula.