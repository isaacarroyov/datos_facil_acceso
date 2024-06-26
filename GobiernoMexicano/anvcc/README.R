#' ---
#' title: 'Atlas Nacional de Vulnerabilidad al Cambio Climático'
#' lang: es
#' format:
#'   gfm:
#'     toc: false
#'     number-sections: true
#'     papersize: letter
#'     fig-width: 5
#'     fig-asp: 0.75
#'     fig-dpi: 300
#'     code-annotations: below
#'     df-print: kable
#'     wrap: none
#' 
#' execute:
#'   echo: true
#'   eval: true
#'   warning: false
#' ---
#' 
#' > [!NOTE]
#' > 
#' > Se puede observar que se cambia el directorio de trabajo a la carpeta 
#' **`/scripts/processing`** para después agregar `/../..` en la variable 
#' **`path2main`**, sin embargo, este cambio se hace para que al renderizar, 
#' el código se pueda ejecutar correctamente, ya que el archivo toma como 
#' directorio de trabajo la carpeta en la que se encuentra el script en el 
#' que se esta haciendo el código.

#| label: setworkingdir
#| eval: false

setwd("./GobiernoMexicano/anvcc")

#' ## Introducción
#' 
#' En este documento se encuentran documentados los pasos y el código usado 
#' para el procesamiento de los datos del [Atlas Nacional de 
#' Vulnerabilidad al Cambio Climático](https://atlasvulnerabilidad.inecc.gob.mx/).
#' 
#' Los conjuntos de datos provenientes del Atlas Nacional de Vulnerabilidad 
#' al Cambio Climático son:
#' 
#' * Infraestructura de presas de generación de energía o almacenamiento de agua
#' * Vulnerablilidad a Ciclones Tropicales en Cuencas de municipios costeros
#' * Nivel de Vulnerabilidad de municipios de México

#| label: load-necesarios
#| output: false

Sys.setlocale(locale = "es_ES")
library(tidyverse)
library(sf)

path2main <- paste0(getwd(), "/../..")
path2gobmex <- paste0(path2main, "/GobiernoMexicano")
path2anvccfolder <- paste0(path2gobmex, "/anvcc")

# Temas dentro del ANVCC
path2anvccmunfolder <- paste0(path2anvccfolder, "/municipios_vulnerables")
path2anvccpresasfolder <- paste0(path2anvccfolder,
                                 "/Presas_Inmundaciones_Estres_Hidrico")
path2anvccctfolder <- paste0(path2anvccfolder, "/amenazaCT")

#' Los datos a tratar son **datos vectoriales**, es decir, tienen una 
#' columna de geometría (POINT, POLYGON o MULTIPOLYGON), esta columna es 
#' la que se ignora en las muestras de datos
#' 
#' En varias ocasiones, por la comodidad de las funciones de limpieza y 
#' procesamiento de datos con {tidyverse}, algunos objetos `simple_feature` 
#' serán transformados a `tibble`
#'  
#' ## Infraestructura de presas de generación de energía o almacenamiento de agua
#' 
#' En este apartado se tienen 3 conjuntos de datos:
#' 
#' * Presas vulnerables al estrés hídrico
#' * Presas vulnerables a inundaciones
#' * Nombre de Presas y Cuencas
#' 
#' En estos conjuntos de datos se seleccionaron 207 presas distribuidas en 
#' el territorio nacional, y se definió a la cuenca de aporte como unidad 
#' territorial para la evaluación de la vulnerabilidad.
#' 
#' 
#' Los datos y la ficha técnica fueron [descargados en el siguiente 
#' URL](https://mapas.inecc.gob.mx/apps/SPCondicionesNA/Presa_Estres_Hidrico.html).
#' 
#' ### Nombre de Subcuencas y Presas
#' 
#' El único cambio relevante al que pasará este conjunto de datos será 
#' el cambio de nombre de las columnas.
#' 
#' |Nombre original|Nombre nuevo|
#' |---|---|
#' |`nomb_cuenca`|`nombre_cuenca`|
#' |`nomb_rha`|`nombre_rha`|

#| label: load-df_og_subcuencas_presas
#| output: false

sf_subcuencas_presas <- st_read(
    dsn = paste0(path2anvccpresasfolder,
                 "/subcuencas con nombre",
                 "/SubcuencasPresas_NomCuenca.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  rename(
    nombre_cuenca = nomb_cuenca,
    nombre_rha = nomb_rha) %>%
  st_as_sf()

#' 

#| label: show_sample-sf_subcuencas_presas
#| echo: false

set.seed(11)
sf_subcuencas_presas %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' ### Presas vulnerables a estrés hídrico

#| label: load-df_og_presas_eh
#| output: false

df_og_presas_eh <- st_read(
    dsn = paste0(path2anvccpresasfolder,
                 "/presas eh",
                 "/Presas_Vul_Rec_EH_NCUENCA.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names()

#' 

#| label: show_sample-df_og_presas_eh

set.seed(11)
df_og_presas_eh %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' La serie de cambios que se realizarán son los siguientes:
#' 
#' * Renombrar columnas
#' * Asignar puntaje de 1 a las recomedaciones escritras y 0 a las columnas 
#' _No aplica_ para obtener el número total de recomendaciones total por 
#' presa
#' * Convertir geometria (POINTS) a columnas de Longitud y Latitude
#' 
#' #### Renombrar columnas 
#' 
#' La relación de cambio de nombre de columnas se presenta en la siguiente 
#' tabla
#' 
#' |Nombre original|Nombre nuevo|
#' |---|---|
#' |`no`|`id_presa`|
#' |`nom_cuenca`|`nombre_cuenca`|
#' |`nomb_presa`|`nombre_presa`|
#' |`vulactual`|`vulnerabilidad_actual`|
#' |`vulfutura`|`vulnerabilidad_futura`|

#| label: rename_cols-presas_eh

df_presas_eh_renamed <- df_og_presas_eh %>%
  rename(
    id_presa = no,
    nombre_cuenca = nom_cuenca,
    nombre_presa = nomb_presa,
    vulnerabilidad_actual = vulactual,
    vulnerabilidad_futura = vulfutura)

#'

#| label: show_sample-df_presas_eh_renamed
#| echo: false

set.seed(11)
df_presas_eh_renamed %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' #### Puntuación a recomendaciones
#' 
#' En el la base de datos, cada columna es una recomendación (columnas 
#' cuyo nombre inicia con `recomend`), las cuales son:

#| label: tbl-recomendaciones-presas-eh
#| echo: false

df_presas_eh_renamed %>%
  pivot_longer(
    cols = dplyr::starts_with("recomend")) %>%
  filter(value != "No aplica") %>%
  distinct(value) %>%
  rename(`Recomendación` = value)

#' Existen presas donde una de estas recomendaciones no aplica.
#' 
#' Para hacer el conteo de recomendaciones que cada presa tiene, se le 
#' asignará un valor de 1 a cada recomendación que tenga la presa y 0 
#' en el caso de que tenga la categoría de _No aplica_.
#' 
#' La manera será haciendo un `pivot_longer` para tener todas las 
#' recomendaciones en una sola columna, e iterar entre ellas para asignar 
#' los valores

#| label: trans_cols-puntaje_a_recomendaciones

df_presas_eh_renamed_points_recomend <- df_presas_eh_renamed %>%
  pivot_longer(
    cols = dplyr::starts_with("recomend"),
    names_to = "variable",
    values_to = "recomendacion") %>%
  mutate(
    points_recomendacion = if_else(
      condition = recomendacion == "No aplica",
      true = 0,
      false = 1)) %>%
  select(!c(variable)) %>%
  relocate(recomendacion, .after = nombre_presa) %>%
  relocate(points_recomendacion, .after = recomendacion)

#'

#| label: show_sample-df_presas_eh_renamed_points_recomend
#| echo: false

set.seed(13)
df_presas_eh_renamed_points_recomend %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' #### Transformar geometría a puntos a columnas de Longitud y Latitud
#' 
#' La conversión de puntos a geometrías, tanto en R como Python no es 
#' complicado, además de que al usar Altair para graficar, es más fácil 
#' codificar y estilizar puntos de Latitud y Longitud que geometrias 
#' espaciales. 
#' 
#' Esta es la última transformación.

#| label: create-db_presas_eh

db_presas_eh <- df_presas_eh_renamed_points_recomend %>%
  mutate(
    long = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2]) %>%
  select(-geometry)

#'

#| label: show_sample-db_presas_eh
#| echo: false

set.seed(1)
db_presas_eh %>%
  slice_sample(n = 5)

#' ### Presas vulnerables a inundación
#' 
#' La documentación y explicación del procesamiento de este conjunto de 
#' datos es menor ya que tiene muchas similitudes al conjunto de 
#' Presas Vulnerables al Estrés Hídrico.

#| label: create-db_presas_inu
#| output: false

db_presas_inu <- st_read(
    dsn = paste0(path2anvccpresasfolder,
                 "/presas inu",
                 "/Presas_Vul_Rec_INU_NCUENCA.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  # Renombrar columnas
  rename(
    id_presa = no,
    nombre_cuenca = nom_cuenca,
    nombre_presa = nomb_presa,
    vulnerabilidad_actual = vulactual,
    vulnerabilidad_futura = vulfutura) %>%
  # Dar puntaje de 1 a recomendaciones que no sean 'No aplica'
  pivot_longer(
    cols = dplyr::starts_with("recomend"),
    names_to = "variable",
    values_to = "recomendacion") %>%
  mutate(
    points_recomendacion = if_else(
      condition = recomendacion == "No aplica",
      true = 0,
      false = 1)) %>%
  select(!c(variable)) %>%
  relocate(recomendacion, .after = nombre_presa) %>%
  # Eliminar geometry (POINT) y en su lugar crear columnas de 
  # longitud y latitud
  relocate(points_recomendacion, .after = recomendacion) %>%
  mutate(
    long = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2]) %>%
  select(-geometry)

#' 

#| label: show_sample_db_presas_inu
#| echo: false

set.seed(13)
db_presas_inu %>%
  slice_sample(n = 5)
 
#' ## Cuencas vulnerables a Ciclotes Tropicales
#' 
#' De acuerdo con la página del ANVCC, este conjunto de datos contiene 
#' información de:
#' 
#' > _(...) la frecuencia e intensidad del impacto de ciclones tropicales 
#' en las cuencas hidrológicas (CONAGUA, 2021) de los municipios costeros; 
#' esta evaluación se realizó a partir de la metodología de CENAPRED (2021) 
#' para cada una de las cuencas hidrológicas de los municipios costeros._
#' 
#' Los datos fueron [descargados en el siguiente 
#' URL](https://mapas.inecc.gob.mx/apps/SPCondicionesNA/Ciclones_Tropicales.html).
#' 
#' Los únicos cambios que se le harán (además de los básico) sera el 
#' renombramiento de algunas columnas
#' 
#' |Nombre original|Nombre nuevo|
#' |---|---|
#' |`nombre_cuen`|`nombre_cuenca`|
#' |`nivel_amen`|`nivel_amenaza`|

#| label: pendiente-sf_cuencas_ct
#| output: false

sf_cuencas_ct <- st_read(
    dsn = paste0(path2anvccctfolder,
                 "/insumo",
                 "/amenCuencasCosterasCT.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  rename(
    nombre_cuenca = nombre_cuen,
    nivel_amenaza = nivel_amen) %>%
  st_as_sf()

#' > [!NOTE]
#' > 
#' > Las columnas `fid`, `id` y `cuenca` no se eliminan pero tampoco se 
#' modifican ya que la docuemntación no es muy clara.

#| label: show_sample-sf_cuencas_ct
#| echo: false

set.seed(11)
sf_cuencas_ct %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' ## Municipios vulnerables al cambio climático
#' 
#' De acuerdo con el Portal de Datos Abiertos de México, en la sección de 
#' Vulnerabilidades Definidas por el Atlas Nacional de Vulnerabilidad Al 
#' Cambio Climático del Instituto Nacional de Ecología y Cambio Climático 
#' (INECC)
#' 
#' > _El análisis de los municipios más vulnerables es producto de los 
#' resultados del Atlas Nacional de Vulnerabilidad al Cambio Climático. 
#' En el ANVCC se analizan vulnerabilidades específicas relacionadas con el 
#' clima en un contexto nacional, de esta manera, se hace evidente la 
#' vulnerabilidad diferencial en el territorio. Cuenta con información de 
#' seis vulnerabilidades específicas:
#' > 
#' > * Vulnerabilidad de asentamientos humanos a deslaves 
#' > * Vulnerabilidad de asentamientos humanos a inundaciones 
#' > * Vulnerabilidad de asentamientos humanos al incremento potencial de 
#' enfermedades transmitidas por vector (dengue)
#' > * Vulnerabilidad de la producción ganadera a estrés hídrico 
#' > * Vulnerabilidad de la producción ganadera a inundaciones 
#' > * Vulnerabilidad de la producción forrajera a estrés hídrico
#' >
#' > Todo lo anterior, considerando su vulnerabilidad actual y futura, 
#' a partir de las proyecciones de cuatro modelos climáticos

#| label: load-df_og_anvcc_mun
#| output: false

df_og_anvcc_mun <- st_read(
    dsn = paste0(path2anvccmunfolder,
                 "/Mun_ANVCC_Vulnerables",
                 "/Mun_ANVCC_Vulnerables.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names()

#'

#| label: show_sample-df_og_anvcc_mun
#| echo: false

set.seed(11)
df_og_anvcc_mun %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' Entre los cambios a realizar se encuentran los siguientes:
#' 
#' * Renombrar las columnas.
#' * Transformar valores que indiquen valores nulos o información 
#' no disponible.
#' * Cambiar el nombre de las entidades y municipios para que coincidan con 
#' los que se tienen en la base de datos del Marco Geoestadístico del 2023.
#' 
#' #### Renombrar de columnas
#' 
#' El mismo conjunto de datos tiene un archivo XLSX llamado **Diccionario 
#' de datos_3 clasi**, que es de donde se crea la siguiente tabla para 
#' el renombramiento de las columnas
#' 
#' |Nombre en base de datos original|Nombre nuevo|Descripción|
#' |---|---|---|
#' |`Cve_mun1`|`cve_geo`|Clave del Municipio según INEGI|
#' |`N_Prioriza`|`nivel_priorizacion`|...|
#' |`ClasVFEH`|`vul_prod_forrajera`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de Producción Forrajera ante Estrés Hídrico (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)|
#' |`A_VFEH`|`aumento_vul_prod_forrajera`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la Producción Forrajera ante Estrés Hídrico|
#' |`ClasVGEH`|`vul_prod_ganadera_eh`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de Producción ganadera extensiva ante Estrés Hídrico (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)|
#' |`A_VGEH`|`aumento_vul_prod_ganadera_eh`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la Producción ganadera extensiva ante Estrés Hídrico|
#' |`ClasVPDEN`|`vul_poblacion_dengue`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de la población al incremento en distribución del dengue (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)|
#' |`A_VPDen`|`aumento_vul_poblacion_dengue`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la población al incremento en distribución del dengue ante Estrés Hídrico|
#' |`ClasVAHDES`|`vul_asentamientos_deslaves`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de asentamientos humanos a deslaves (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)|
#' |`A_VAHDES`|`aumento_vul_asentamientos_deslaves`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de asentamientos humanos a deslaves|
#' |`ClasVGINU`|`vul_prod_ganadera_inu`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la Vulnerabilidad de la producción ganadera extensiva a inundaciones (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)|
#' |`A_VGINU`|`aumento_vul_prod_ganadera_inu`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la producción ganadera extensiva a inundaciones|
#' |`ClasVAHINU`|`vul_asentamientos_inu`|Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional la vulnerabilidad de asentamientos humanos a inundaciones. (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999  o NA no aplica)"|
#' |`A_VAHINU`|`aumento_vul_asentamientos_inu`|Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de asentamientos humanos a inundaciones|

#| label: rename_cols-df_anvcc_mun

df_anvcc_mun_renamed <- df_og_anvcc_mun %>%
  rename(
    cve_geo = cve_mun1,
    nivel_priorizacion = n_prioriza,
    vul_prod_forrajera = clas_vfeh,
    aumento_vul_prod_forrajera = a_vfeh,
    vul_prod_ganadera_eh = clas_vgeh,
    aumento_vul_prod_ganadera_eh = a_vgeh,
    vul_poblacion_dengue = clas_vpden,
    aumento_vul_poblacion_dengue = a_vpden,
    vul_asentamientos_deslaves = clas_vahdes,
    aumento_vul_asentamientos_deslaves = a_vahdes,
    vul_prod_ganadera_inu = clas_vginu,
    aumento_vul_prod_ganadera_inu = a_vginu,
    vul_asentamientos_inu = clas_vahinu,
    aumento_vul_asentamientos_inu = a_vahinu) %>%
  # Cambiar a caracter los códigos de los municipios
  mutate(
    cve_geo = if_else(
      condition = cve_geo >= 10000,
      true = as.character(cve_geo),
      false = paste0("0", cve_geo))) %>%
  # Ignorar columnas que tienen información redundante o no relevante
  select(!c(cve_ent, municipio, nom_ent, rec, nivel_de_p, np_1448,
            fid_1, fid_12))

#'

#| label: show_sample-df_anvcc_mun_renamed
#| echo: false

set.seed(11)
df_anvcc_mun_renamed %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' Después del renombramiento, la información de las columnas son un 
#' poco más facil de entender
#' 
#' #### Transformar valores que indiquen valores nulos o información no disponible

#| label: show_sample-df_anvcc_mun_renamed-na_vals
#| echo: false

set.seed(5)
df_anvcc_mun_renamed %>%
  filter(
    vul_prod_forrajera %in% c("-9999", "-9999.00", "-9999.00000000000", "0") |
    vul_prod_ganadera_eh %in% c("-9999", "-9999.00", "-9999.00000000000", "0") |
    vul_poblacion_dengue %in% c("-9999", "-9999.00", "-9999.00000000000", "0") |
    vul_asentamientos_deslaves %in% c("-9999", "-9999.00", "-9999.00000000000", "0")) %>%
  select(
    cve_geo,
    vul_prod_forrajera,
    vul_prod_ganadera_eh,
    vul_poblacion_dengue,
    vul_asentamientos_deslaves) %>%
  slice_sample(n = 5)

#' Este tipo de valores son normalmente escritos comom `-999.99` 
#' o `0`, especialmente cuando se encuentran en columnas de caracteres o 
#' categóricas, por lo que serán transformadas a valores `NA` para mayor 
#' uniformidad en los conteos y visualizaciones

#| label: transform_cols-dealing_w_na

df_anvcc_mun_renamed_transformed_na <- df_anvcc_mun_renamed %>%
  mutate(
    across(
      .cols = vul_prod_forrajera:aumento_vul_asentamientos_inu,
      .fns = ~ if_else(
        condition = .x %in% c("-9999", "-9999.00", "-9999.00000000000", "0"),
        true = NA,
        false = str_to_title(string = .x))))

#' #### Asignar nombres de estados-municipios
#' 
#' > [!NOTE]
#' > 
#' > Hay municipios que no aparecen en la base de datos porque puede que 
#' hayan sido de reciente creación y no se tomaron en cuenta al momento de 
#' la creación de la base de datos de vulnerabilidades.

#| label: transform_cols-agregar_cve_mun_ent

# Cargar base de datos de relacion de nombres-codigos de 
# entidades y municipios

cve_nom_ent_mun <- read_csv(
  file = paste0(path2gobmex, "/cve_nom_municipios.csv"))

df_anvcc_mun_renamed_transformed_na_named_ubi <- df_anvcc_mun_renamed_transformed_na %>%
  left_join(
    y = cve_nom_ent_mun,
    by = join_by(cve_geo)) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  relocate(nivel_priorizacion, .after = cve_geo) %>%
  select(!c(cve_mun, geometry))

#' 

#| label: show_sample-df_anvcc_mun_renamed_transformed_na_named_ubi
#| echo: false

set.seed(11)
df_anvcc_mun_renamed_transformed_na_named_ubi %>%
  slice_sample(n = 5)
 
#' #### Transformación _wide2long_
#' 
#' Esta transformación se hace para poder tener en una columna las 
#' diferentes vulnerabilidades, el nivel de vulnerabilidad y si tiene 
#' aumento o no. Resulta más amable a la hora de visualizar.

#| label: create-db_anvcc_mun

db_anvcc_mun <- df_anvcc_mun_renamed_transformed_na_named_ubi %>%
  pivot_longer(
    cols = vul_prod_forrajera:aumento_vul_asentamientos_inu,
    names_to = "name",
    values_to = "value") %>%
  mutate(
    tipo_info = if_else(
      condition = str_starts(
        string = name,
        pattern = "vul_"),
      true = "vulnerabilidad_actual",
      false = "aumento_vulnerabilidad"),
    tipo_vul = case_when(
      str_ends(string = name, "prod_forrajera") ~ "Producción forrajera en estrés hídrico",
      str_ends(string = name, "prod_ganadera_eh") ~ "Producción ganadera en estrés hídrico",
      str_ends(string = name, "prod_ganadera_inu") ~ "Producción ganadera en inundaciones",
      str_ends(string = name, "poblacion_dengue") ~ "Población expuesta al dengue",
      str_ends(string = name, "asentamientos_deslaves") ~ "Asentamientos humanos expuestos a deslaves",
      str_ends(string = name, "asentamientos_inu") ~ "Asentamientos humanos expuestos a inundaciones",
      .default = NA_character_)) %>%
  select(-name) %>%
  pivot_wider(
    names_from = tipo_info,
    values_from = value)

#'

#| label: show_sample-db_anvcc_mun
#| echo: false

set.seed(1)
db_anvcc_mun %>%
  group_by(nivel_priorizacion) %>%
  slice_sample(n = 1) %>%
  ungroup()

#' ## Guardar conjuntos de datos
#' 
#' Finalmente los conjuntos de datos seran guardados para su uso en EDAs
#' 
#' ### Subcuencas y Presas
#' 
#' Este es el único conjunto de datos que será guardado como un archivo 
#' GeoJSON.

#| label: save-sf_subcuencas_presas
#| output: false

sf_subcuencas_presas %>%
  st_write(
    dsn = paste0(path2anvccfolder, "/nombre_id_cuencas_anvcc.geojson"),
    driver = "GeoJSON")

#' |Columna|Descripción|
#' |---|---|
#' |`id_cuenca`|Número identificador de la cuenca|
#' |`nombre_cuenca`|Nombre de la cuenca|
#' |`nombre_rha`|Nombre de la Región Hidro-Administrativa|
#' |`geometry`|Puntos de los vértices del `POLYGON` o `MULTIPOLYGON`|

#| label: show_sample-sf_subcuencas_presas_final
#| echo: false

set.seed(1)
sf_subcuencas_presas %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)

#' ### Presas vulenrables a estrés hídrico

#| label: save-db_presas_eh

db_presas_eh %>%
  write_csv(
    file = paste0(path2anvccfolder, "/db_presas_eh_anvcc.csv"),
    na = "")

#' |Columna|Descripción|
#' |---|---|
#' |`id_presa`|Identificador de la presa|
#' |`nombre_cuenca`|Nombre de la cuenca a la que pertenece la presa|
#' |`nombre_presa`|Nombre de la presa|
#' |`recomendacion`|Lista de recomendaciones. Si el valor es "No aplica" se puede ignorar|
#' |`points_recomendacion`|Puntos asignados a cada recomendación. Tiene el valor de 1 ante alguna recomendación y 0 cuando No aplica|
#' |`vulnerabilidad_actual`|Vulnerabilidad actual ante el **Estrés Hídrico**|
#' |`vulnerabilidad_futura`|Vulnerabilidad futura ante el **Estrés Hídrico**|
#' |`long`|Longitud (grados) de la ubicación de la presa|
#' |`lat`|Latitud (grados) de la ubicación de la presa|

#| label: show_sample-db_presas_eh_final
#| echo: false

set.seed(1)
db_presas_eh %>%
  slice_sample(n = 5)

#' 
#' ### Presas vulnerables a inundación

#| label: save-db_presas_inu

db_presas_inu %>%
  write_csv(
    file = paste0(path2anvccfolder, "/db_presas_inu_anvcc.csv"),
    na = "")

#' |Columna|Descripción|
#' |---|---|
#' |`id_presa`|Identificador de la presa|
#' |`nombre_cuenca`|Nombre de la cuenca a la que pertenece la presa|
#' |`nombre_presa`|Nombre de la presa|
#' |`recomendacion`|Lista de recomendaciones. Si el valor es "No aplica" se puede ignorar|
#' |`points_recomendacion`|Puntos asignados a cada recomendación. Tiene el valor de 1 ante alguna recomendación y 0 cuando No aplica|
#' |`vulnerabilidad_actual`|Vulnerabilidad actual ante **inundaciones**|
#' |`vulnerabilidad_futura`|Vulnerabilidad futura ante **inundaciones**|
#' |`long`|Longitud (grados) de la ubicación de la presa|
#' |`lat`|Latitud (grados) de la ubicación de la presa|


#| label: show_sample-db_presas_inu_final
#| echo: false

set.seed(1)
db_presas_inu %>%
  slice_sample(n = 5)

#' ### Cuencas vulnerables a Ciclones Tropicales

#| label: save-sf_cuencas_ct
#| output: false

sf_cuencas_ct %>%
  st_write(
    dsn = paste0(path2anvccfolder,
                "/cuencas_ciclones_tropicales_anvcc.geojson"),
    driver = "GeoJSON")


#' |Columna|Descripción|
#' |---|---|
#' |`nombre_rha`|Nombre de la región Hidro-Administrativa al que pertenece la cuenca|
#' |`nombre_cuenca`|Nombre de la cuenca|
#' |`nivel_amenaza`|Nivel de amenaza ante los Ciclones Tropicales|
#' |`geometry`|Vértices del POLYGON o MULTIPOLYGON|
#' 
#' > [!NOTE]
#' > 
#' > Las columnas `fid`, `id` y `cuenca` no se escriben en la tabla ya que 
#' la documentación no es muy clara.


#| label: show_sample_sf_cuencas_ct_final

set.seed(1)
sf_cuencas_ct %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)
 
#' ### Municipios Vulnerables al Cambio Climático
#' 
#' El conjunto de datos se guardará como un archivo CSV, sin la geometría, 
#' ya que como GeoJSON el archivo se vuelve muy pesado. Cuando se requiera 
#' crear mapas con esta información, simplemente se tiene que unir con el 
#' GeoJSON del repositorio `datos_facil_acceso`

#| label: save-db_anvcc_mun

db_anvcc_mun %>%
  write_csv(
    file = paste0(path2anvccfolder, "/mun_vulnerables_anvcc.csv"),
    na = "")

#' 
#' |Columna|Descripción|
#' |---|---|
#' |`nombre_estado`|Nombre del estado|
#' |`cve_ent`|Clave del Estado segun INEGI|
#' |`nombre_municipio`|Nombrel del municipio|
#' |`cve_geo`|Clave del Municipio según INEGI|
#' |`nivel_priorizacion`|Priorizacion del municipios de acuerdo al número y tipo de vulnerabilidades actuales y futuras|
#' |`tipo_vul`|Tipo de vulnerabilidad|
#' |`vulnerabilidad_actual`|Vulnerabilidad actual, toma los valores **Sin Vulnerabilidad**, **Bajo**, **Medio**, **Alto**, **Muy Alto**, y `NA`|
#' |`aumento_vulnerabilidad`|Si existe o no aumento en la vulnerabilidad, toma los valores **Aumento** y `NA`|
#' 
#' Los **tipos de vulnerabilidad (`tipo_vul`)** son:
#' 
#' 1. Vulnerabilidad de Producción Forrajera ante Estrés Hídrico
#' 2. Vulnerabilidad de Producción Ganadera Extensiva ante Estrés Hídrico
#' 3. Vulnerabilidad de Producción Ganadera Extensiva ante inundaciones 
#' 4. Vulnerabilidad de la población al incremento en distribución del dengue
#' 5. Vulnerabilidad de asentamientos humanos a deslaves 
#' 6. Vulnerabildiad de asentamientos humanos a inundaciones

#| label: show_sample-db_anvcc_mun_final
#| echo: false

set.seed(13)
db_anvcc_mun %>%
  group_by(nivel_priorizacion) %>%
  slice_sample(n = 1) %>%
  ungroup()
