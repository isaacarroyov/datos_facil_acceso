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
#' * **Incidencia Delictiva del Fuero Común mensual a nivel municipal**:
#'   * Es la misma información que la base original pero en _long format_
#' * **Incidencia Delicitva del fuero Común mensual a nivel estatal**:
#'   * Es la misma información que la base original de municipios pero 
#' agrupada por estado y en _long format_
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
#' * **Víctimas de Delitos del Fuero Común mensual a nivel estatal (general)**:
#'   * Es la misma información que la base original pero en _long format_.
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
#' ### Cambios generales
#' 
#' Existen tipos de cambios que se usarán en las dos bases de 
#' datos originales, estos son:
#' 
#' * Renombramiento de municipios y estados
#' * Renombrar la columna de Año (por la función `clean_names` se renombró 
#' a `ano`)
#' * Cambio de _long format_ a _wide format_: Esto para crear una variable 
#' de fecha, de esta manera la base de datos original como una serie 
#' de tiempo.
#' 
#' ### Cambios específicos 
#' 
#' Los siguientes cambios se hacen de manera específica a cada una de las 
#' bases de datos originales.
#' 
#' **Para `db_incidencia_mun`**
#' 
#' 1. Agrupar por año, municipio y (sub)tipo el número de delitos
#' 2. Adjuntar el valor de la población del municipio (los que tengan dicha 
#' información) para el tasado de delitos por 100 mil habitantes.
#' 3. Agrupar por año, estado y (sub)tipo el número de delitos.
#' 4. Adjuntar el valor de la población del estado para el tasado de 
#' delitos por 100 mil habitantes.
#' 
#' **Para `db_victimas_delitos_ent`**
#' 
#' * Aenean molestie faucibus libero at efficitur.
#' * Sed suscipit a eros at eleifend. 
#' * In quis ante commodo, tempus nisl a, elementum neque. 
#' * Nullam convallis fermentum tortor. 
#' * Nunc scelerisque, nunc vel scelerisque tempor, metus justo dictum 
#' augue, et luctus ante sapien eu tellus. 
#' * Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
#' 
#' ## Cambios generales
#' 
#' ### Renombramiento de valores (nombre de municipios y estados) y de columnas
#' 
#' Muchas veces (si no es que en todas las ocasiones) el nombre de los 
#' estados y municipios son los que dicta el INEGI. La _desventaja_ de esto 
#' es que muchas veces los nombres son demasiado largos o no son como 
#' estan _popularmente_ conocidos. Por ejemplo, el municipio que comúnmente 
#' se le conoce como **Dolores Hidalgo**, cuenta como nombre oficial 
#' **Dolores Hidalgo, Cuna de la Independencia Nacional**, haciendo que la 
#' búsqueda y el nombre en una visualización (mapa, gráfica o tabla) sea un 
#' poco más _complicada_.
#' 
#' Afortunadamente, en el repositorio se cuenta con un conjunto de datos que 
#' facilita el renombramiento.

#| label: load-cve_nom_ent_mun

cve_nom_ent_mun <- read_csv(paste0(path2gobmex, "/cve_nom_municipios.csv"))

#'

#| label: show_sample_cve_nom_ent_mun
#| echo: false

set.seed(1)
cve_nom_ent_mun %>%
  slice_sample(n = 5)

#' Con este conjunto en el ambiente, se hace el renombramiento. Los pasos 
#' para cada conjunto de datos son similares, obviamente adaptados al las 
#' columnas disponibles en cada uno

#| label: join-cve_nom_ent_mun-db_incidencia_mun

# - - Incidencia delictiva (municipios) - - #
db_incidencia_mun_renamed <- db_incidencia_mun %>%
  # Quitar las columnas de clave de entidad y nombres (entidad y municipios)
  select(!c(entidad, clave_ent, municipio))  %>%
  # Renombrar la clave del municipio a `cve_geo`
  rename(cve_geo = cve_municipio) %>%
  # Completar con el 0' al inicio de `cve_geo`
  mutate(
    cve_geo = if_else(
      condition = as.integer(cve_geo) >= 10000,
      true = cve_geo,
      false = paste0("0", cve_geo))) %>%
  # Unir con los nombres de los municipios
  left_join(
    y = select(.data = cve_nom_ent_mun, -cve_mun),
    by = join_by(cve_geo)) %>%
  # Reordenar las columnas
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .before = nombre_estado) %>%
  relocate(nombre_municipio, .after = cve_geo) %>%
  # Renombrar `ano`
  rename(n_year = ano)

#'

#| label: show_sample-db_incidencia_mun_renamed
#| echo: false

set.seed(1)
db_incidencia_mun_renamed %>%
  slice_sample(n = 5)

#'

#| label: join-cve_nom_ent_mun-db_victimas_delitos_ent

# - - Número de víctimas (estados) - - #
db_victimas_delitos_ent_renamed <- db_victimas_delitos_ent %>%
  select(!c(entidad))  %>%
  rename(cve_ent = clave_ent) %>%
  mutate(
    cve_ent = if_else(
      condition = as.integer(cve_ent) >= 10,
      true = cve_ent,
      false = paste0("0", cve_ent))) %>%
  left_join(
    y = distinct(.data = cve_nom_ent_mun, cve_ent, nombre_estado),
    by = join_by(cve_ent)) %>%
  relocate(nombre_estado, .after = cve_ent) %>%
  rename(n_year = ano)

#' 

#| label: show_sample-db_victimas_delitos_ent_renamed
#| echo: false

set.seed(1)
db_victimas_delitos_ent_renamed %>%
  slice_sample(n = 5)

#' ### Transformación de _wide format_ a _long format_
#' 
#' Esta tarea se hace para que se pueda tener la base de datos como 
#' normalmente se encuentran los datos de series de tiempo.
#' 
#' Este cambio tambien implica sustituir los nombres de los meses por 
#' el número de mes para crear la columna de tiempo.

#| label: wide2long-db_incidencia_mun_renamed

db_incidencia_mun_long <- db_incidencia_mun_renamed %>%
  pivot_longer(
    cols = enero:diciembre,
    names_to = "n_month",
    values_to = "n_delitos") %>%
  mutate(
    # Cambiar a valores numéricos el número de delitos
    n_delitos = as.numeric(n_delitos),
    # Cambiar nombres a número de mes
    n_month = case_when(
      n_month == "enero" ~ "01",
      n_month == "febrero" ~ "02",
      n_month == "marzo" ~ "03",
      n_month == "abril" ~ "04",
      n_month == "mayo" ~ "05",
      n_month == "junio" ~ "06",
      n_month == "julio" ~ "07",
      n_month == "agosto" ~ "08",
      n_month == "septiembre" ~ "09",
      n_month == "octubre" ~ "10",
      n_month == "noviembre" ~ "11",
      n_month == "diciembre" ~ "12",
      .default = NA_character_),
  date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
  relocate(date_year_month, .before = n_year) %>%
  relocate(n_month, .after = n_year) %>%
  # Asegurar que solo se cuenten con los datos del último mes 
  # de actualizacion
  filter(!is.na(n_delitos))

#'

#| label: show_sample-db_incidencia_mun_long
#| echo: false

set.seed(1)
db_incidencia_mun_long %>%
  slice_sample(n = 5)

#'

#| label: wide2long-db_victimas_delitos_ent_renamed

db_victimas_delitos_ent_long <- db_victimas_delitos_ent_renamed %>%
  pivot_longer(
    cols = enero:diciembre,
    names_to = "n_month",
    values_to = "n_victimas") %>%
  mutate(
    n_victimas = as.numeric(n_victimas),
    n_month = case_when(
      n_month == "enero" ~ "01",
      n_month == "febrero" ~ "02",
      n_month == "marzo" ~ "03",
      n_month == "abril" ~ "04",
      n_month == "mayo" ~ "05",
      n_month == "junio" ~ "06",
      n_month == "julio" ~ "07",
      n_month == "agosto" ~ "08",
      n_month == "septiembre" ~ "09",
      n_month == "octubre" ~ "10",
      n_month == "noviembre" ~ "11",
      n_month == "diciembre" ~ "12",
      .default = NA_character_),
  date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
  relocate(date_year_month, .before = n_year) %>%
  relocate(n_month, .after = n_year) %>%
  filter(!is.na(n_victimas))

#'

#| label: show_sample-db_victimas_delitos_ent_long
#| echo: false

set.seed(1)
db_victimas_delitos_ent_long %>%
  slice_sample(n = 5)

#' ## Cambios a `db_incidencia_mun_long`
#' 
#' ### Agrupar por año, municipio y (sub)tipo el número de delitos
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ### Adjuntar el valor de la población del municipio para el tasado de delitos por 100 mil habitantes.
#' 
#' > [!IMPORTANT]
#' > 
#' > El tasado para el delito de **Feminicidio** es con respecto al número 
#' de mujeres por cada 100 mil habitantes. Es por ello que se crea la 
#' columna específica. En la columna `n_delitos_100khab` se hace con respecto 
#' a la población de ambos géneros, esto para cuando se hagan agregaciones 
#' por modalidad (por ejemplo: agrupar por delitos hechos con arma de fuego) 
#' se haga la sumatoria y todo quede con respecto a la población del 
#' municipio o estado. Sin embargo, para el estudio específico del delito 
#' de **Feminicidio**, se usa la información de la columna 
#' `n_delitos_100kmujeres`
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ### Agrupar por año, estado y (sub)tipo el número de delitos.
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ### Adjuntar el valor de la población del estado para el tasado de delitos por 100 mil habitantes.
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