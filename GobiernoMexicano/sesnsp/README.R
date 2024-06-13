#' ---
#' title: 'Procesamiento de datos: Incidencia Delictiva del Fuero Común'
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

# TODO: Encontrar la manera de hacer la descarga directa con el URL del 
#       archivo de Google Drive (INCIDENCIA EN MUNICIPIOS)

# - - Número de delitos - - #
path2dataincidenciamun <- list.files(
  path = path2ogdatasesnsp,
  pattern = ".csv",
  full.names = TRUE)

db_incidencia_mun <- read_csv(
    file = path2dataincidenciamun,
    locale = locale(encoding = "latin1"),
    col_types = cols(.default = "c")) %>%
  janitor::clean_names()

# - - Número de víctimas de delitos - - #
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

#' **Muestra de `db_incidencia_mun`**

#| label: sample-db_incidencia_mun
#| echo: false

set.seed(11)
db_incidencia_mun %>%
  slice_sample(n = 5)

#' **Muestra de `db_victimas_delitos_ent`**

#| label: sample-db_victimas_delitos_ent
#| echo: false

set.seed(11)
db_victimas_delitos_ent %>%
  slice_sample(n = 5)

#' ## Objetivos
#' 
#' El objetivo con ambos conjuntos es crear nuevos conjuntos, con 
#' información extra que es de interés general. Los 
#' conjuntos de datos contemplados son los siguientes:
#' 
#' * **Incidencia Delictiva del Fuero Común anual a nivel municipal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad y municipio)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes
#' * **Incidencia Delicitva del fuero Común anual a nivel estatal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes
#' * **Víctimas de Delitos del Fuero Común anual a nivel estatal (general)**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de delitos por género
#'   * Número de delitos por cada 100 mil habitantes del total de la 
#' población total por género
#' * **Víctimas de Delitos del Fuero Común anual a nivel estatal 
#' (rango de edad)**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Género
#'   * Rango de edad
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes de la población total
#'   * Número de delitos por cada 100 mil habitantes de la población del 
#' rango de edad
#' 
#' > [!NOTE]
#' > 
#' > Los conjuntos de datos propuestos y el procesamiento de datos están 
#' sujetos cambios dependiendo del desarrollo de los proyectos que se harán 
#' con ellos o conforme se avance en la documentación.
#' 
#' ## Lista de cambios 
#' 
#' Curabitur orci lacus, cursus a fermentum nec, pretium a nulla. Curabitur 
#' nec condimentum eros. Aliquam nibh enim, ullamcorper in malesuada in, 
#' egestas at magna. Sed commodo id dui sed varius: 
#' 
#' * Nulla ultrices maximus risus. 
#' * Nam sodales vehicula nulla, ut placerat nunc dignissim non.
#' * Quisque tincidunt justo a ultrices dignissim. Curabitur aliquet ut elit 
#' id aliquam.
#' * Vivamus dictum imperdiet odio, ac consequat augue dapibus pulvinar. 
#' * Interdum et malesuada fames ac ante ipsum primis in faucibus. 
#' * Donec sit amet libero a justo aliquam sagittis ut a eros.
#' 
#' ## Pendiente 2
#' 
#' Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum 
#' iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis. 
#' Maecenas semper nunc nec nunc tempus, non egestas purus porttitor. 
#' Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod 
#' lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros 
#' at eleifend. In quis ante commodo, tempus nisl a, elementum neque. 
#' Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel 
#' scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu 
#' tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
#' Vestibulum non tristique ante. Curabitur a risus non justo varius dictum 
#' sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus 
#' mi feugiat tellus, eu vestibulum lacus massa quis arcu.
#' 
#' ## Pendiente 3
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ## Pendiente 4
#' 
#' Duis ac ex venenatis turpis vulputate porttitor ut euismod libero. 
#' Fusce sem neque, volutpat mattis sapien id, ultrices porta elit. Sed 
#' consequat risus eu diam vehicula aliquet. Sed in mi posuere risus 
#' sollicitudin rutrum ut id odio. In hac habitasse platea dictumst. Duis 
#' tincidunt interdum pellentesque. In blandit vulputate dui, nec iaculis 
#' diam ullamcorper quis.
#' 
#' ## Pendiente 5
#' 
#' Curabitur orci lacus, cursus a fermentum nec, pretium a nulla. Curabitur 
#' nec condimentum eros. Aliquam nibh enim, ullamcorper in malesuada in, 
#' egestas at magna. Sed commodo id dui sed varius. Nulla ultrices maximus 
#' risus. Nam sodales vehicula nulla, ut placerat nunc dignissim non. 
#' Quisque tincidunt justo a ultrices dignissim. Curabitur aliquet ut elit 
#' id aliquam. Vivamus dictum imperdiet odio, ac consequat augue dapibus 
#' pulvinar. Interdum et malesuada fames ac ante ipsum primis in faucibus. 
#' Donec sit amet libero a justo aliquam sagittis ut a eros.
#' 
#' ## Pendiente 6
#' 
#' Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum 
#' iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis. 
#' Maecenas semper nunc nec nunc tempus, non egestas purus porttitor. 
#' Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod 
#' lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros 
#' at eleifend. In quis ante commodo, tempus nisl a, elementum neque. 
#' Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel 
#' scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu 
#' tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
#' Vestibulum non tristique ante. Curabitur a risus non justo varius dictum 
#' sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus 
#' mi feugiat tellus, eu vestibulum lacus massa quis arcu.
#' 
#' ## Pendiente 7
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ## Pendiente 8
#' 
#' Duis ac ex venenatis turpis vulputate porttitor ut euismod libero. 
#' Fusce sem neque, volutpat mattis sapien id, ultrices porta elit. Sed 
#' consequat risus eu diam vehicula aliquet. Sed in mi posuere risus 
#' sollicitudin rutrum ut id odio. In hac habitasse platea dictumst. Duis 
#' tincidunt interdum pellentesque. In blandit vulputate dui, nec iaculis 
#' diam ullamcorper quis.