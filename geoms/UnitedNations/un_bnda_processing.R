#' ---
#' title: 'Data processing: United Nations Geospatial Data: `BNDA_simplified`'
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
setwd("./geoms/UnitedNations")

#'

#| label: load-libraries-paths
library(tidyverse)
library(sf)

path2repo <- paste0(getwd(), "/../..")
path2main <- paste0(path2repo, "/geoms")
path2source <- paste0(path2main, "/UnitedNations")
path2source_data <- paste0(path2source, "/UN_BNDA_simplified")

#' La documentación de este conjunto de datos se realiza para entender de 
#' donde se obtienen los nombres y códigos de otros conjuntos 
#' georeferenciados, tales como los datos de TerraClimate o CHIRPS, ya que 
#' **BNDA simplified** se encuentra también en el catálogo de Google 
#' Earth Engine y es la `ee.FeatureCollection` que uso para reducir los 
#' datos raster a vectoriales o formato de tabla.
#'
#' ## Sobre los datos
#' 
#' Información tomada del sitio de _United Nations_ donde se encuentra el 
#' conjunto de datos `BNDA_simplified` [[1]](https://geoportal.un.org/arcgis/home/item.html?id=e4ee80edac9d4e08b8303522dd4a5fc1):
#' 
#' > _The United Nations Geospatial Data, or Geodata, is a worldwide 
#' geospatial dataset of the United Nations._
#' > 
#' > _The United Nations Geodata is provided to facilitate the preparation 
#' of cartographic materials in the United Nations includes geometry, 
#' attributes and labels to facilitate the adequate depiction and naming of 
#' geographic features for the preparation of maps in accordance with 
#' United Nations policies and practices._
#' >
#' > _The geospatial datasets here included are referred to as UN Geodata 
#' simplified and are generalized based on UNGeodata 25 million scale._
#' >
#' > *The feature layers include polygons/areas of countries 
#' (BNDA_simplified), lines for international boundaries and limits 
#' (BNDL_simplified), and major water body (WBYA_simplified). In addition, 
#' aggregated regional areas are available following M49 methodology 
#' (GEOA_simplified, SUBA_simplified, INTA_simplified) and SDG regional 
#' grouping (SDGA_simplified).*
#' >
#' > _The UN Geodata simplified is prepared in the context of the 
#' Administrative Instruction on the 
#' “Guidelines for the Publication of Maps” and should serve global mapping 
#' purposes as opposed to local mapping. The scale is unspecific for the 
#' United Nations Geodata simplified and is suitable for generalized world 
#' maps and web-maps._
#' 
#' [Para saber más de las propiedades del conjunto de datos, visitar "Table Schema" en Google Earth Engine](https://developers.google.com/earth-engine/datasets/catalog/UN_Geodata_BNDA_simplified_current#table-schema)

#| label: load-data_geoms
un_bnda_simplfied <- st_read(paste0(path2source_data, "/BNDA_simplified.shp"))

#' ## Seleccionar variables de interés y renombrarlas
#' 
#' A pesar de que el conjunto de datos contiene cerca de 20 variables/propiedades, 
#' por motivos personales solamente aquellas propiedades que sean 
#' relevantes, tales como nombre del país/región/territorio, códigos ISO, 
#' continente, subregiones, etc.

#| label: create-un_bnda_simplfied_oi
un_bnda_simplfied_oi <- un_bnda_simplfied %>%
  select(
    # Etiqueta/Nombre cartográfico
    lbl_en,
    # Nombre del territorio en inglés
    nam_en,
    # Código ISO3
    iso3cd,
    # Código ISO2
    iso2cd,
    # Nombre y código del continente, respectivamente
    georeg,
    geo_cd,
    # Nombre y código de la subregión, respectivamente
    subreg,
    sub_cd,
    # Nombre y código de la región intermediaria, respectivamente
    intreg,
    int_cd,
    # Código del estatus de soveranía
    stscod) %>%
  as_tibble() %>%
  rename(
    # Nombre del territorio en inglés
    country_name = nam_en,
    # Etiqueta/Nombre cartográfico
    carto_label = lbl_en,
    # Código ISO3 e ISO 2
    iso3 = iso3cd,
    iso2 = iso2cd,
    # Nombre y código del continente, respectivamente
    continent_name = georeg,
    continent_code = geo_cd,
    # Nombre y código de la subregión, respectivamente
    subregion_name = subreg,
    subregion_code = sub_cd,
    # Nombre y código de la región intermediaria, respectivamente
    intermediary_region_name = intreg,
    intermediary_region_code = int_cd,
    # Código del estatus de soveranía
    sovereignty_status_code = stscod)

#' ## Decodificar códigos de estatus de soveranía (`sovereignty_status_code`) y nombre del continente (`continent_name`)
#' 
#' Para tener una base de datos más clara, se agregará la columna del 
#' nombre del estatus de soveranía (`sovereignty_status_name`).
#' 
#' De igual manera, se extenderá el nombre de los valores en 
#' `continent_name` ya que esta propiedad tiene los valores abreviados en 
#' tres letras (AME = América)
#' 
#' Estado de soveranía (`sovereignty_status_code`):
#' 
#' |Code|Description|
#' |---|---|
#' |0|Antarctica|
#' |1|State|
#' |2|Occupied Palestinian Territory|
#' |3|Non-Self Governing Territory|
#' |4|Territory|
#' |5|Special Region or Province|
#' |99|Undetermined| 

un_bnda_simplfied_oi_decoded <- un_bnda_simplfied_oi %>%
  mutate(
    sovereignty_status_name = case_when(
      sovereignty_status_code == 0 ~ "Antarctica",
      sovereignty_status_code == 1 ~ "State",
      sovereignty_status_code == 2 ~ "Occupied Palestinian Territory",
      sovereignty_status_code == 3 ~ "Non-Self Governing Territory",
      sovereignty_status_code == 4 ~ "Territory",
      sovereignty_status_code == 5 ~ "Special Region or Province",
      .default = "Undetermined"),
    continent_name = case_when(
      continent_name == "AME" ~ "America",
      continent_name == "ASI" ~ "Asia",
      continent_name == "AFR" ~ "Africa",
      continent_name == "EUR" ~ "Europe",
      continent_name == "OCE" ~ "Oceania",
      continent_name == "ANT" ~ "Antarctica",
      .default = NA)) %>%
  relocate(sovereignty_status_name, .after = sovereignty_status_code)

#' ## Crear columna identificador de regiones de interés
#' 
#' A pesar de que la ONU ha etiquetado los territorios en subregiones y 
#' regiones intermediarias, me gustaría etiquetar de acuerdo a otras 
#' perspectivas, por ejemplo, Puerto Rico está etiquetado en 
#' `intermediary_region_name` como el Caribe, lo cual no es cierto, 
#' pero para otras personas, Puerto Rico es Latinoamérica, al igual que Cuba.
#' 
#' Este apartado aún esta en desarrollo para poder hablar con más personas 
#' para tener más claridad en el tema.

# TODO: Seleccionar regiones. Preguntar a terceros sobre opinion
# Regiones de interés: Latinoamérica, Centro América, Sudamérica, Caribe, 
#                      Medio Oriente, MENA (Middle East and North Africa), 
#                      Estados Árabes, Union Europea, etc. 

#' ## Guardar datos
#' 
#' ### como GeoJSON
#' 
#' Guardar el conjunto de datos como GeoJSON facilita su lectura en 
#' diferentes programas GIS, así como su extracción a través de una 
#' URL pública (este repositorio)

#| label: save_data-sf_un_bnda_mena
sf_un_bnda_oi <- un_bnda_simplfied_oi_decoded %>%
  st_as_sf()

st_write(
    sf_un_bnda_oi,
    dsn = paste0(path2source, "/sf_un_bnda_oi.geojson"),
    driver = "GeoJSON")

#' ### as CSV
#' 
#' Se guarda también una versión sin la columna de geometría para poder 
#' usar como referencia de nombres y códigos para futuros proyectos.

df_world_regions <- un_bnda_simplfied_oi_decoded %>%
  select(!geometry)

write_csv(
  x = df_world_regions,
  file = paste0(path2source, "/world_regions.csv"),
  na = "")
