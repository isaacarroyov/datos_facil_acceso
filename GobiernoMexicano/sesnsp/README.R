#' ---
#' title: 'Procesamiento y transformación de datos: Sequía en México'
#' author: Isaac Arroyo
#' date-format: long
#' date: last-modified
#' lang: es
#' jupyter: python3
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
#' 
#' ## Introducción y objetivos
#'
#' Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas 
#' scelerisque felis elit, sed dictum nisi volutpat nec. Vestibulum ante 
#' ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; 
#' Vestibulum mauris risus, congue id sem et, imperdiet molestie nisl. 
#' Vivamus eget libero in nisl sollicitudin commodo. Ut odio velit, 
#' placerat ac volutpat quis, consectetur at justo. Nam faucibus, neque at 
#' dictum fringilla, arcu est sollicitudin neque, non mattis orci tortor 
#' sed dolor. Integer nisl nibh, lobortis at cursus in, commodo nec erat. 
#' Duis nec dapibus felis. Cras sodales nulla at posuere finibus. Morbi 
#' molestie commodo tortor ut tincidunt.

#| label: setwd-to-path2README_R
#| eval: false
#| echo: false

setwd("./GobiernoMexicano/sesnsp/")

#'

#| label: load-libraries-paths

library(tidyverse)

#' 
#' Fusce porttitor ligula et est tempor, ut viverra lectus suscipit. 
#' Pellentesque pellentesque eleifend felis, non eleifend lacus faucibus 
#' vitae. Vestibulum congue tempus justo, at maximus augue imperdiet et. 
#' Nullam pharetra volutpat tortor eu ultricies. Nam sed lectus sem. 
#' Integer quam felis, cursus eget arcu at, faucibus tincidunt mi. Etiam 
#' sed vestibulum lorem, sed finibus arcu. Aliquam quis faucibus urna, ut 
#' tincidunt nulla. Phasellus rhoncus risus a lacus venenatis, id luctus 
#' est molestie. Morbi quis turpis eu ex ullamcorper interdum. Class aptent 
#' taciti sociosqu ad litora torquent per conubia nostra, per inceptos 
#' himenaeos. Pellentesque non odio ut arcu elementum maximus pretium ac 
#' quam. Proin dapibus ipsum odio.

#| label: load-csv_incidencia-victimas_delictiva_nivel_ent-mun
#| output: false
url_victimas_delitos_ent <- "https://drive.google.com/file/d/1MeLHOZnPQ7kyxRg2JSQvnDh_2U5gjR2i/view"
id_file_victimas_delitos_ent <- str_extract(
    string = url_victimas_delitos_ent,
    pattern = "(?<=d/)(.*?)(?=/view)")

# TODO: Encontrar la manera de hacer la descarga directa con el URL del 
#       archivo de Google Drive (INCIDENCIA EN MUNICIPIOS)
# url_incidencia_delitos_mun <- ""
# id_file_victimas_delitos_ent <- str_extract(
#     string = url_incidencia_delitos_mun,
#     pattern = "(?<=d/)(.*?)(?=/view)")

db_victimas_delitos_ent <- read_csv(
    file = paste0("https://drive.google.com/uc?export=download&id=",
                  id_file_victimas_delitos_ent),
    col_types = cols(.default = "c"),
    locale = locale(encoding = "latin1")) %>%
  janitor::clean_names()

# db_incidencia_mun


#' Vestibulum aliquet pharetra lorem, quis cursus est dapibus a. Nunc 
#' fringilla aliquam urna non volutpat. Aenean faucibus ullamcorper erat 
#' quis auctor. Quisque sodales ornare ligula ac molestie. Duis tincidunt 
#' rhoncus rutrum. Aenean sagittis a tellus ac accumsan. Mauris quis 
#' pretium nisl, pulvinar convallis ante. Mauris placerat nibh eu lectus 
#' ullamcorper, sed dapibus urna interdum. Duis sem justo, rutrum sed 
#' tortor ac, lacinia tincidunt nisi. Suspendisse efficitur ante a velit 
#' consectetur, auctor lobortis orci maximus. In maximus dolor eget est 
#' commodo blandit.
#' 
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