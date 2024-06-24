# Atlas Nacional de Vulnerabilidad al Cambio Climático


> \[!NOTE\]
>
> Se puede observar que se cambia el directorio de trabajo a la carpeta
> **`/scripts/processing`** para después agregar `/../..` en la variable
> **`path2main`**, sin embargo, este cambio se hace para que al
> renderizar, el código se pueda ejecutar correctamente, ya que el
> archivo toma como directorio de trabajo la carpeta en la que se
> encuentra el script en el que se esta haciendo el código.

``` r
setwd("./GobiernoMexicano/anvcc")
```

## Introducción

En este documento se encuentran documentados los pasos y el código usado
para el procesamiento de los datos del [Atlas Nacional de Vulnerabilidad
al Cambio Climático](https://atlasvulnerabilidad.inecc.gob.mx/).

Los conjuntos de datos provenientes del Atlas Nacional de Vulnerabilidad
al Cambio Climático son:

- Infraestructura de presas de generación de energía o almacenamiento de
  agua
- Vulnerablilidad a Ciclones Tropicales en Cuencas de municipios
  costeros
- Nivel de Vulnerabilidad de municipios de México

``` r
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
```

Los datos a tratar son **datos vectoriales**, es decir, tienen una
columna de geometría (POINT, POLYGON o MULTIPOLYGON), esta columna es la
que se ignora en las muestras de datos

En varias ocasiones, por la comodidad de las funciones de limpieza y
procesamiento de datos con {tidyverse}, algunos objetos `simple_feature`
serán transformados a `tibble`

## Infraestructura de presas de generación de energía o almacenamiento de agua

En este apartado se tienen 3 conjuntos de datos:

- Presas vulnerables al estrés hídrico
- Presas vulnerables a inundaciones
- Nombre de Presas y Cuencas

En estos conjuntos de datos se seleccionaron 207 presas distribuidas en
el territorio nacional, y se definió a la cuenca de aporte como unidad
territorial para la evaluación de la vulnerabilidad.

Los datos y la ficha técnica fueron [descargados en el siguiente
URL](https://mapas.inecc.gob.mx/apps/SPCondicionesNA/Presa_Estres_Hidrico.html).

### Nombre de Subcuencas y Presas

El único cambio relevante al que pasará este conjunto de datos será el
cambio de nombre de las columnas.

| Nombre original | Nombre nuevo    |
|-----------------|-----------------|
| `nomb_cuenca`   | `nombre_cuenca` |
| `nomb_rha`      | `nombre_rha`    |

``` r
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
```

| id_cuenca | nombre_cuenca | nombre_rha              |
|----------:|:--------------|:------------------------|
|      1208 | Río Querétaro | Lerma Santiago Pacífico |
|      1608 | Barreras      | Lerma Santiago Pacífico |
|      1207 | Río La Laja 1 | Lerma Santiago Pacífico |
|      1015 | Río Fuerte 2  | Pacífico Norte          |
|      2708 | Río Tecolutla | Golfo Centro            |

### Presas vulnerables a estrés hídrico

``` r
df_og_presas_eh <- st_read(
    dsn = paste0(path2anvccpresasfolder,
                 "/presas eh",
                 "/Presas_Vul_Rec_EH_NCUENCA.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names()
```

``` r
set.seed(11)
df_og_presas_eh %>%
  select(-geometry) %>%
  slice_sample(n = 5)
```

|  no | nom_cuenca        | nomb_presa         | recomenda1                                                                                                                    | recomenda2                                                                                                                       | recomenda3                                                                                                                                                                                               | recomenda4                                                                       | recomenda5                                                                                                                           | recomenda6                                                                                                                                                  | recomenda7                                                                                 | recomenda8                                                                                                    | recomenda9                                            | recomend10                                                                                                                 | recomend11                                                                                    | recomend12                                                                                                                                                                       | recomend13                                                                                                                                                                                                                                   | recomend14                                                                                                          | recomend15                                                                                                     | vulactual | vulfutura |
|----:|:------------------|:-------------------|:------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------|:------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------|:----------|:----------|
| 134 | Ciudad de México  | Madín              | No aplica                                                                                                                     | No aplica                                                                                                                        | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | No aplica                                                                                                                                                   | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | No aplica                                             | No aplica                                                                                                                  | No aplica                                                                                     | No aplica                                                                                                                                                                        | No aplica                                                                                                                                                                                                                                    | No aplica                                                                                                           | No aplica                                                                                                      | Media     | Alta      |
|  98 | Río Conchos 1     | La Boquilla        | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | No aplica                                                                                                                                                                                                | No aplica                                                                        | No aplica                                                                                                                            | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Baja      | Baja      |
| 184 | Presa La Flor     | Santiago           | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Baja      | Baja      |
| 166 | Río San Rafael 1  | República Española | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | No aplica                                                                                                                                                                                                | No aplica                                                                        | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | No aplica                                                                                                     | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Alta      | Alta      |
| 109 | Río Santa María 1 | La Muñeca          | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Alta      | Alta      |

La serie de cambios que se realizarán son los siguientes:

- Renombrar columnas
- Asignar puntaje de 1 a las recomedaciones escritras y 0 a las columnas
  *No aplica* para obtener el número total de recomendaciones total por
  presa
- Convertir geometria (POINTS) a columnas de Longitud y Latitude

#### Renombrar columnas

La relación de cambio de nombre de columnas se presenta en la siguiente
tabla

| Nombre original | Nombre nuevo            |
|-----------------|-------------------------|
| `no`            | `id_presa`              |
| `nom_cuenca`    | `nombre_cuenca`         |
| `nomb_presa`    | `nombre_presa`          |
| `vulactual`     | `vulnerabilidad_actual` |
| `vulfutura`     | `vulnerabilidad_futura` |

``` r
df_presas_eh_renamed <- df_og_presas_eh %>%
  rename(
    id_presa = no,
    nombre_cuenca = nom_cuenca,
    nombre_presa = nomb_presa,
    vulnerabilidad_actual = vulactual,
    vulnerabilidad_futura = vulfutura)
```

| id_presa | nombre_cuenca     | nombre_presa       | recomenda1                                                                                                                    | recomenda2                                                                                                                       | recomenda3                                                                                                                                                                                               | recomenda4                                                                       | recomenda5                                                                                                                           | recomenda6                                                                                                                                                  | recomenda7                                                                                 | recomenda8                                                                                                    | recomenda9                                            | recomend10                                                                                                                 | recomend11                                                                                    | recomend12                                                                                                                                                                       | recomend13                                                                                                                                                                                                                                   | recomend14                                                                                                          | recomend15                                                                                                     | vulnerabilidad_actual | vulnerabilidad_futura |
|---------:|:------------------|:-------------------|:------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------|:------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------|:----------------------|:----------------------|
|      134 | Ciudad de México  | Madín              | No aplica                                                                                                                     | No aplica                                                                                                                        | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | No aplica                                                                                                                                                   | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | No aplica                                             | No aplica                                                                                                                  | No aplica                                                                                     | No aplica                                                                                                                                                                        | No aplica                                                                                                                                                                                                                                    | No aplica                                                                                                           | No aplica                                                                                                      | Media                 | Alta                  |
|       98 | Río Conchos 1     | La Boquilla        | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | No aplica                                                                                                                                                                                                | No aplica                                                                        | No aplica                                                                                                                            | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Baja                  | Baja                  |
|      184 | Presa La Flor     | Santiago           | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Baja                  | Baja                  |
|      166 | Río San Rafael 1  | República Española | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | No aplica                                                                                                                                                                                                | No aplica                                                                        | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | No aplica                                                                                                     | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Alta                  | Alta                  |
|      109 | Río Santa María 1 | La Muñeca          | Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas | Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse. | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua | Realizar mantenimiento operativo y estructural de las presas de manera periódica | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse | Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida | Promover el manejo de recursos hidráulicos integrados | Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego | Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social | Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles | Alta                  | Alta                  |

#### Puntuación a recomendaciones

En el la base de datos, cada columna es una recomendación (columnas cuyo
nombre inicia con `recomend`), las cuales son:

| Recomendación                                                                                                                                                                                                                                |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Incrementar el número de estaciones climáticas e hidrométricas para incentivar el monitoreo de variables climáticas                                                                                                                          |
| Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles                                                                                                                               |
| Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua                                     |
| Realizar mantenimiento operativo y estructural de las presas de manera periódica                                                                                                                                                             |
| Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa                                                                                  |
| Promover la conservación natural identificando zonas de conservación que puedan ser Áreas Naturales Protegida                                                                                                                                |
| Incluir en el Atlas de Riesgo Municipal donde se localiza el embalse, el análisis de riesgo asociado a sequía para las presas                                                                                                                |
| Promover sistemas de alerta temprana ante la posible presencia de sequías que pongan en riesgo el agua almacenada en el embalse.                                                                                                             |
| Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse                                                                                                                                                   |
| Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales                                                                                                         |
| Promover el manejo de recursos hidráulicos integrados                                                                                                                                                                                        |
| Identificar o conformar grupos de trabajo como los Comités o Consejos de Cuenca para la gestión ante los eventos de sequía                                                                                                                   |
| Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca                                                                                                                                                |
| Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego                                                             |
| Desarrollar programas de acción ante una disminución drástica del agua almacenada en la presa por eventos climáticos severos, de tal forma que se establezcan sistemas de comunicación, planes de recuperación económica, ambiental y social |

Existen presas donde una de estas recomendaciones no aplica.

Para hacer el conteo de recomendaciones que cada presa tiene, se le
asignará un valor de 1 a cada recomendación que tenga la presa y 0 en el
caso de que tenga la categoría de *No aplica*.

La manera será haciendo un `pivot_longer` para tener todas las
recomendaciones en una sola columna, e iterar entre ellas para asignar
los valores

``` r
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
```

| id_presa | nombre_cuenca                        | nombre_presa      | recomendacion                                                                                                                                                                                            | points_recomendacion | vulnerabilidad_actual | vulnerabilidad_futura |
|---------:|:-------------------------------------|:------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------:|:----------------------|:----------------------|
|      137 | Presa Santa Rosa                     | Manuel M. Dieguez | No aplica                                                                                                                                                                                                |                    0 | Media                 | Alta                  |
|       65 | Arroyo Zarco                         | Huapango          | No aplica                                                                                                                                                                                                |                    0 | Media                 | Media                 |
|       48 | Presa San José - Los Pilares y otras | El Potosino       | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua |                    1 | Media                 | Media                 |
|       86 | Río Santa María 3                    | Jalpan            | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales                                                                     |                    1 | Alta                  | Alta                  |
|      120 | Río Lerma 3                          | Laguna del Fresno | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego                         |                    1 | Muy Alta              | Muy Alta              |

#### Transformar geometría a puntos a columnas de Longitud y Latitud

La conversión de puntos a geometrías, tanto en R como Python no es
complicado, además de que al usar Altair para graficar, es más fácil
codificar y estilizar puntos de Latitud y Longitud que geometrias
espaciales.

Esta es la última transformación.

``` r
db_presas_eh <- df_presas_eh_renamed_points_recomend %>%
  mutate(
    long = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2]) %>%
  select(-geometry)
```

| id_presa | nombre_cuenca         | nombre_presa      | recomendacion                                                                                                                                                                                            | points_recomendacion | vulnerabilidad_actual | vulnerabilidad_futura |      long |      lat |
|---------:|:----------------------|:------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------:|:----------------------|:----------------------|----------:|---------:|
|      143 | Río Angulo            | Melchor Ocampo    | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego                         |                    1 | Alta                  | Muy Alta              | -101.7241 | 20.12711 |
|      135 | Lago de Cuitzeo       | Malpaís           | Realizar mantenimiento operativo y estructural de las presas de manera periódica                                                                                                                         |                    1 | Baja                  | Baja                  | -100.8787 | 19.83547 |
|      183 | Río Santiago Bayacora | Santiago Bayacora | No aplica                                                                                                                                                                                                |                    0 | Alta                  | Alta                  | -104.6761 | 23.87461 |
|      188 | Tacotán               | Tacotán           | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles                                                                                           |                    1 | Alta                  | Alta                  | -104.3209 | 20.03631 |
|       51 | Río del Valle         | El Salto          | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua |                    1 | Alta                  | Alta                  | -102.7066 | 21.04186 |

### Presas vulnerables a inundación

La documentación y explicación del procesamiento de este conjunto de
datos es menor ya que tiene muchas similitudes al conjunto de Presas
Vulnerables al Estrés Hídrico.

``` r
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
```

| id_presa | nombre_cuenca     | nombre_presa                   | recomendacion                                                                                                                                                | points_recomendacion | vulnerabilidad_actual | vulnerabilidad_futura |       long |      lat |
|---------:|:------------------|:-------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------:|:----------------------|:----------------------|-----------:|---------:|
|       58 | Río Lerma 2       | Francisco José Trinidad Fabela | Promover el programa de Pago por Servicios Ambientales difundiendo los beneficios ambientales y sociales que se establecen en los lineamientos del programa. |                    1 | Alta                  | Alta                  |  -99.79028 | 19.82778 |
|       91 | Río Lerma 2       | José Antonio Alzate            | Incrementar la superficie de áreas de vegetación en la cuenca de aporte registradas en el programa de Pago por Servicios Ambientales                         |                    1 | Media                 | Media                 |  -99.70478 | 19.46611 |
|      194 | Río Lerma 3       | Tercer Mundo                   | Fomentar la colaboración intermunicipal para la conservación de las partes altas de la cuenca.                                                               |                    1 | Muy Alta              | Muy Alta              | -100.29914 | 19.76644 |
|       40 | Presa El Chique   | El Chique                      | No aplica                                                                                                                                                    |                    0 | Alta                  | Muy Alta              | -102.89556 | 21.99667 |
|       86 | Río Santa María 3 | Jalpan                         | No aplica                                                                                                                                                    |                    0 | Alta                  | Alta                  |  -99.47218 | 21.20675 |

## Cuencas vulnerables a Ciclotes Tropicales

De acuerdo con la página del ANVCC, este conjunto de datos contiene
información de:

> *(…) la frecuencia e intensidad del impacto de ciclones tropicales en
> las cuencas hidrológicas (CONAGUA, 2021) de los municipios costeros;
> esta evaluación se realizó a partir de la metodología de CENAPRED
> (2021) para cada una de las cuencas hidrológicas de los municipios
> costeros.*

Los datos fueron [descargados en el siguiente
URL](https://mapas.inecc.gob.mx/apps/SPCondicionesNA/Ciclones_Tropicales.html).

Los únicos cambios que se le harán (además de los básico) sera el
renombramiento de algunas columnas

| Nombre original | Nombre nuevo    |
|-----------------|-----------------|
| `nombre_cuen`   | `nombre_cuenca` |
| `nivel_amen`    | `nivel_amenaza` |

``` r
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
```

> \[!NOTE\]
>
> Las columnas `fid`, `id` y `cuenca` no se eliminan pero tampoco se
> modifican ya que la docuemntación no es muy clara.

|   fid |  id | cuenca | nombre_rha           | nombre_cuenca                   | nivel_amenaza |
|------:|----:|-------:|:---------------------|:--------------------------------|:--------------|
|  7136 | 269 |    464 | GOLFO NORTE          | Río Barberena 1                 | Medio         |
|   505 | 100 |    125 | PACIFICO NORTE       | Río Fuerte 1                    | Bajo          |
|  5305 | 187 |    473 | GOLFO NORTE          | Arroyo Los Anegados o Conchos 2 | Muy bajo      |
| 10705 | 589 |    373 | PACIFICO SUR         | Río Cazadero                    | Muy bajo      |
|  4316 | 747 |    694 | PENINSULA DE YUCATAN | Arroyo Siho                     | Bajo          |

## Municipios vulnerables al cambio climático

De acuerdo con el Portal de Datos Abiertos de México, en la sección de
Vulnerabilidades Definidas por el Atlas Nacional de Vulnerabilidad Al
Cambio Climático del Instituto Nacional de Ecología y Cambio Climático
(INECC)

> \_El análisis de los municipios más vulnerables es producto de los
> resultados del Atlas Nacional de Vulnerabilidad al Cambio Climático.
> En el ANVCC se analizan vulnerabilidades específicas relacionadas con
> el clima en un contexto nacional, de esta manera, se hace evidente la
> vulnerabilidad diferencial en el territorio. Cuenta con información de
> seis vulnerabilidades específicas:
>
> - Vulnerabilidad de asentamientos humanos a deslaves
> - Vulnerabilidad de asentamientos humanos a inundaciones
> - Vulnerabilidad de asentamientos humanos al incremento potencial de
>   enfermedades transmitidas por vector (dengue)
> - Vulnerabilidad de la producción ganadera a estrés hídrico
> - Vulnerabilidad de la producción ganadera a inundaciones
> - Vulnerabilidad de la producción forrajera a estrés hídrico
>
> Todo lo anterior, considerando su vulnerabilidad actual y futura, a
> partir de las proyecciones de cuatro modelos climáticos

``` r
df_og_anvcc_mun <- st_read(
    dsn = paste0(path2anvccmunfolder,
                 "/Mun_ANVCC_Vulnerables",
                 "/Mun_ANVCC_Vulnerables.shp")) %>%
  st_transform(4326) %>%
  as_tibble() %>%
  janitor::clean_names()
```

| fid_1 | fid_12 | cve_ent | nom_ent   | municipio            | cve_mun1 | np_1448 | nivel_de_p | clas_vfeh | a_vfeh  | clas_vgeh          | a_vgeh  | clas_vpden         | a_vpden | clas_vahdes | a_vahdes | clas_vginu | a_vginu | clas_vahinu | a_vahinu | rec | n_prioriza                    |
|------:|-------:|:--------|:----------|:---------------------|---------:|--------:|-----------:|:----------|:--------|:-------------------|:--------|:-------------------|:--------|:------------|:---------|:-----------|:--------|:------------|:---------|:----|:------------------------------|
|  1786 |   1786 | 30      | Veracruz  | Texcatepec           |    30170 |    1448 |          2 | Alto      | aumento | Bajo               | aumento | Medio              | aumento | Alto        | 0        | Medio      | aumento | Alto        | aumento  | NA  | Segundo Nivel de Priorización |
|    34 |     34 | 12      | Guerrero  | Tixtla de Guerrero   |    12061 |    1448 |          3 | Alto      | 0       | Alto               | aumento | Sin Vulnerabilidad | aumento | Medio       | aumento  | Alto       | aumento | Alto        | aumento  | NA  | Tercer Nivel de Priorización  |
|   696 |    696 | 08      | Chihuahua | Saucillo             |     8062 |    1448 |          1 | Alto      | aumento | Medio              | aumento | Medio              | aumento | Medio       | 0        | Medio      | aumento | Bajo        | aumento  | NA  | Primer Nivel de Priorización  |
|   921 |    921 | 20      | Oaxaca    | Santa María Huatulco |    20413 |    1448 |          1 | Medio     | aumento | Sin Vulnerabilidad | 0       | Alto               | 0       | Medio       | 0        | Bajo       | 0       | Bajo        | 0        | NA  | Primer Nivel de Priorización  |
|   144 |    144 | 15      | México    | Temascalapa          |    15084 |    1448 |          1 | Alto      | aumento | Bajo               | aumento | -9999              | aumento | Bajo        | aumento  | Alto       | aumento | Medio       | aumento  | NA  | Primer Nivel de Priorización  |

Entre los cambios a realizar se encuentran los siguientes:

- Renombrar las columnas.
- Transformar valores que indiquen valores nulos o información no
  disponible.
- Cambiar el nombre de las entidades y municipios para que coincidan con
  los que se tienen en la base de datos del Marco Geoestadístico del
  2023.

#### Renombrar de columnas

El mismo conjunto de datos tiene un archivo XLSX llamado **Diccionario
de datos_3 clasi**, que es de donde se crea la siguiente tabla para el
renombramiento de las columnas

| Nombre en base de datos original | Nombre nuevo                         | Descripción                                                                                                                                                                                                                                       |
|----------------------------------|--------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Cve_mun1`                       | `cve_geo`                            | Clave del Municipio según INEGI                                                                                                                                                                                                                   |
| `N_Prioriza`                     | `nivel_priorizacion`                 | …                                                                                                                                                                                                                                                 |
| `ClasVFEH`                       | `vul_prod_forrajera`                 | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de Producción Forrajera ante Estrés Hídrico (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica)              |
| `A_VFEH`                         | `aumento_vul_prod_forrajera`         | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la Producción Forrajera ante Estrés Hídrico                                                                                                         |
| `ClasVGEH`                       | `vul_prod_ganadera_eh`               | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de Producción ganadera extensiva ante Estrés Hídrico (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica)     |
| `A_VGEH`                         | `aumento_vul_prod_ganadera_eh`       | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la Producción ganadera extensiva ante Estrés Hídrico                                                                                                |
| `ClasVPDEN`                      | `vul_poblacion_dengue`               | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de la población al incremento en distribución del dengue (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica) |
| `A_VPDen`                        | `aumento_vul_poblacion_dengue`       | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la población al incremento en distribución del dengue ante Estrés Hídrico                                                                           |
| `ClasVAHDES`                     | `vul_asentamientos_deslaves`         | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la vulnerabilidad de asentamientos humanos a deslaves (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica)                      |
| `A_VAHDES`                       | `aumento_vul_asentamientos_deslaves` | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de asentamientos humanos a deslaves                                                                                                                    |
| `ClasVGINU`                      | `vul_prod_ganadera_inu`              | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional de la Vulnerabilidad de la producción ganadera extensiva a inundaciones (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica)       |
| `A_VGINU`                        | `aumento_vul_prod_ganadera_inu`      | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de la producción ganadera extensiva a inundaciones                                                                                                     |
| `ClasVAHINU`                     | `vul_asentamientos_inu`              | Clasificación de la Vulnerabilidad de acuerdo a la estandarización nacional la vulnerabilidad de asentamientos humanos a inundaciones. (Muy Alta(1-0.75), Alta(0.75-0.5), Media(0.5-0.25), Baja(0.25-0), -9999 o NA no aplica)”                   |
| `A_VAHINU`                       | `aumento_vul_asentamientos_inu`      | Aumento de la Vulnerabilidad con alguno de los 4 modelos utilizados para la Vulnerabildiad de asentamientos humanos a inundaciones                                                                                                                |

``` r
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
```

| cve_geo | vul_prod_forrajera | aumento_vul_prod_forrajera | vul_prod_ganadera_eh | aumento_vul_prod_ganadera_eh | vul_poblacion_dengue | aumento_vul_poblacion_dengue | vul_asentamientos_deslaves | aumento_vul_asentamientos_deslaves | vul_prod_ganadera_inu | aumento_vul_prod_ganadera_inu | vul_asentamientos_inu | aumento_vul_asentamientos_inu | nivel_priorizacion            |
|:--------|:-------------------|:---------------------------|:---------------------|:-----------------------------|:---------------------|:-----------------------------|:---------------------------|:-----------------------------------|:----------------------|:------------------------------|:----------------------|:------------------------------|:------------------------------|
| 30170   | Alto               | aumento                    | Bajo                 | aumento                      | Medio                | aumento                      | Alto                       | 0                                  | Medio                 | aumento                       | Alto                  | aumento                       | Segundo Nivel de Priorización |
| 12061   | Alto               | 0                          | Alto                 | aumento                      | Sin Vulnerabilidad   | aumento                      | Medio                      | aumento                            | Alto                  | aumento                       | Alto                  | aumento                       | Tercer Nivel de Priorización  |
| 08062   | Alto               | aumento                    | Medio                | aumento                      | Medio                | aumento                      | Medio                      | 0                                  | Medio                 | aumento                       | Bajo                  | aumento                       | Primer Nivel de Priorización  |
| 20413   | Medio              | aumento                    | Sin Vulnerabilidad   | 0                            | Alto                 | 0                            | Medio                      | 0                                  | Bajo                  | 0                             | Bajo                  | 0                             | Primer Nivel de Priorización  |
| 15084   | Alto               | aumento                    | Bajo                 | aumento                      | -9999                | aumento                      | Bajo                       | aumento                            | Alto                  | aumento                       | Medio                 | aumento                       | Primer Nivel de Priorización  |

Después del renombramiento, la información de las columnas son un poco
más facil de entender

#### Transformar valores que indiquen valores nulos o información no disponible

| cve_geo | vul_prod_forrajera | vul_prod_ganadera_eh | vul_poblacion_dengue | vul_asentamientos_deslaves |
|:--------|:-------------------|:---------------------|:---------------------|:---------------------------|
| 23003   | -9999.00000000000  | Sin Vulnerabilidad   | Alto                 | -9999.00                   |
| 21115   | Alto               | Alto                 | -9999                | Medio                      |
| 16018   | Alto               | Medio                | -9999                | Medio                      |
| 21190   | Muy Alto           | Medio                | -9999                | Alto                       |
| 31099   | Alto               | Medio                | Alto                 | -9999.00                   |

Este tipo de valores son normalmente escritos comom `-999.99` o `0`,
especialmente cuando se encuentran en columnas de caracteres o
categóricas, por lo que serán transformadas a valores `NA` para mayor
uniformidad en los conteos y visualizaciones

``` r
df_anvcc_mun_renamed_transformed_na <- df_anvcc_mun_renamed %>%
  mutate(
    across(
      .cols = vul_prod_forrajera:aumento_vul_asentamientos_inu,
      .fns = ~ if_else(
        condition = .x %in% c("-9999", "-9999.00", "-9999.00000000000", "0"),
        true = NA,
        false = str_to_title(string = .x))))
```

#### Asignar nombres de estados-municipios

> \[!NOTE\]
>
> Hay municipios que no aparecen en la base de datos porque puede que
> hayan sido de reciente creación y no se tomaron en cuenta al momento
> de la creación de la base de datos de vulnerabilidades.

``` r
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
```

| nombre_estado    | cve_ent | nombre_municipio     | cve_geo | nivel_priorizacion            | vul_prod_forrajera | aumento_vul_prod_forrajera | vul_prod_ganadera_eh | aumento_vul_prod_ganadera_eh | vul_poblacion_dengue | aumento_vul_poblacion_dengue | vul_asentamientos_deslaves | aumento_vul_asentamientos_deslaves | vul_prod_ganadera_inu | aumento_vul_prod_ganadera_inu | vul_asentamientos_inu | aumento_vul_asentamientos_inu |
|:-----------------|:--------|:---------------------|:--------|:------------------------------|:-------------------|:---------------------------|:---------------------|:-----------------------------|:---------------------|:-----------------------------|:---------------------------|:-----------------------------------|:----------------------|:------------------------------|:----------------------|:------------------------------|
| Veracruz         | 30      | Texcatepec           | 30170   | Segundo Nivel de Priorización | Alto               | Aumento                    | Bajo                 | Aumento                      | Medio                | Aumento                      | Alto                       | NA                                 | Medio                 | Aumento                       | Alto                  | Aumento                       |
| Guerrero         | 12      | Tixtla de Guerrero   | 12061   | Tercer Nivel de Priorización  | Alto               | NA                         | Alto                 | Aumento                      | Sin Vulnerabilidad   | Aumento                      | Medio                      | Aumento                            | Alto                  | Aumento                       | Alto                  | Aumento                       |
| Chihuahua        | 08      | Saucillo             | 08062   | Primer Nivel de Priorización  | Alto               | Aumento                    | Medio                | Aumento                      | Medio                | Aumento                      | Medio                      | NA                                 | Medio                 | Aumento                       | Bajo                  | Aumento                       |
| Oaxaca           | 20      | Santa María Huatulco | 20413   | Primer Nivel de Priorización  | Medio              | Aumento                    | Sin Vulnerabilidad   | NA                           | Alto                 | NA                           | Medio                      | NA                                 | Bajo                  | NA                            | Bajo                  | NA                            |
| Estado de México | 15      | Temascalapa          | 15084   | Primer Nivel de Priorización  | Alto               | Aumento                    | Bajo                 | Aumento                      | NA                   | Aumento                      | Bajo                       | Aumento                            | Alto                  | Aumento                       | Medio                 | Aumento                       |

#### Transformación *wide2long*

Esta transformación se hace para poder tener en una columna las
diferentes vulnerabilidades, el nivel de vulnerabilidad y si tiene
aumento o no. Resulta más amable a la hora de visualizar.

``` r
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
```

| nombre_estado | cve_ent | nombre_municipio    | cve_geo | nivel_priorizacion            | tipo_vul                                   | vulnerabilidad_actual | aumento_vulnerabilidad |
|:--------------|:--------|:--------------------|:--------|:------------------------------|:-------------------------------------------|:----------------------|:-----------------------|
| Sonora        | 26      | Guaymas             | 26029   | Primer Nivel de Priorización  | Población expuesta al dengue               | Medio                 | Aumento                |
| Zacatecas     | 32      | Momax               | 32030   | Segundo Nivel de Priorización | Producción forrajera en estrés hídrico     | Alto                  | Aumento                |
| Michoacán     | 16      | Churumuco           | 16029   | Tercer Nivel de Priorización  | Población expuesta al dengue               | Alto                  | Aumento                |
| Puebla        | 21      | Xayacatlán de Bravo | 21196   | NA                            | Asentamientos humanos expuestos a deslaves | NA                    | NA                     |

## Guardar conjuntos de datos

Finalmente los conjuntos de datos seran guardados para su uso en EDAs

### Subcuencas y Presas

Este es el único conjunto de datos que será guardado como un archivo
GeoJSON.

``` r
sf_subcuencas_presas %>%
  st_write(
    dsn = paste0(path2anvccfolder, "/nombre_id_cuencas_anvcc.geojson"),
    driver = "GeoJSON")
```

| Columna         | Descripción                                           |
|-----------------|-------------------------------------------------------|
| `id_cuenca`     | Número identificador de la cuenca                     |
| `nombre_cuenca` | Nombre de la cuenca                                   |
| `nombre_rha`    | Nombre de la Región Hidro-Administrativa              |
| `geometry`      | Puntos de los vértices del `POLYGON` o `MULTIPOLYGON` |

| id_cuenca | nombre_cuenca    | nombre_rha              |
|----------:|:-----------------|:------------------------|
|       905 | Río Mátape 1     | Noroeste                |
|      2433 | Río San Juan 1   | Río Bravo               |
|      1213 | Río Lerma 5      | Lerma Santiago Pacífico |
|      1602 | Corcovado        | Lerma Santiago Pacífico |
|      1808 | Río Medio Balsas | Balsas                  |

### Presas vulenrables a estrés hídrico

``` r
db_presas_eh %>%
  write_csv(
    file = paste0(path2anvccfolder, "/db_presas_eh_anvcc.csv"),
    na = "")
```

| Columna                 | Descripción                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------|
| `id_presa`              | Identificador de la presa                                                                                 |
| `nombre_cuenca`         | Nombre de la cuenca a la que pertenece la presa                                                           |
| `nombre_presa`          | Nombre de la presa                                                                                        |
| `recomendacion`         | Lista de recomendaciones. Si el valor es “No aplica” se puede ignorar                                     |
| `points_recomendacion`  | Puntos asignados a cada recomendación. Tiene el valor de 1 ante alguna recomendación y 0 cuando No aplica |
| `vulnerabilidad_actual` | Vulnerabilidad actual ante el **Estrés Hídrico**                                                          |
| `vulnerabilidad_futura` | Vulnerabilidad futura ante el **Estrés Hídrico**                                                          |
| `long`                  | Longitud (grados) de la ubicación de la presa                                                             |
| `lat`                   | Latitud (grados) de la ubicación de la presa                                                              |

| id_presa | nombre_cuenca         | nombre_presa      | recomendacion                                                                                                                                                                                            | points_recomendacion | vulnerabilidad_actual | vulnerabilidad_futura |      long |      lat |
|---------:|:----------------------|:------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------:|:----------------------|:----------------------|----------:|---------:|
|      143 | Río Angulo            | Melchor Ocampo    | Implementar medidas de captación y conservación del agua para disminuir la vulnerabilidad del sector agrícola, tanto para las áreas de temporal como para los distritos de riego                         |                    1 | Alta                  | Muy Alta              | -101.7241 | 20.12711 |
|      135 | Lago de Cuitzeo       | Malpaís           | Realizar mantenimiento operativo y estructural de las presas de manera periódica                                                                                                                         |                    1 | Baja                  | Baja                  | -100.8787 | 19.83547 |
|      183 | Río Santiago Bayacora | Santiago Bayacora | No aplica                                                                                                                                                                                                |                    0 | Alta                  | Alta                  | -104.6761 | 23.87461 |
|      188 | Tacotán               | Tacotán           | Dar mantenimiento a las estaciones climáticas e hidrométricas para mejorar la calidad de los datos disponibles                                                                                           |                    1 | Alta                  | Alta                  | -104.3209 | 20.03631 |
|       51 | Río del Valle         | El Salto          | Crear incentivos para que los gobiernos estatales y locales y el sector privado inviertan en mantenimiento y mejoren la eficiencia y el rendimiento de la infraestructura de distribución y uso del agua |                    1 | Alta                  | Alta                  | -102.7066 | 21.04186 |

### Presas vulnerables a inundación

``` r
db_presas_inu %>%
  write_csv(
    file = paste0(path2anvccfolder, "/db_presas_inu_anvcc.csv"),
    na = "")
```

| Columna                 | Descripción                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------|
| `id_presa`              | Identificador de la presa                                                                                 |
| `nombre_cuenca`         | Nombre de la cuenca a la que pertenece la presa                                                           |
| `nombre_presa`          | Nombre de la presa                                                                                        |
| `recomendacion`         | Lista de recomendaciones. Si el valor es “No aplica” se puede ignorar                                     |
| `points_recomendacion`  | Puntos asignados a cada recomendación. Tiene el valor de 1 ante alguna recomendación y 0 cuando No aplica |
| `vulnerabilidad_actual` | Vulnerabilidad actual ante **inundaciones**                                                               |
| `vulnerabilidad_futura` | Vulnerabilidad futura ante **inundaciones**                                                               |
| `long`                  | Longitud (grados) de la ubicación de la presa                                                             |
| `lat`                   | Latitud (grados) de la ubicación de la presa                                                              |

| id_presa | nombre_cuenca  | nombre_presa  | recomendacion                                                                               | points_recomendacion | vulnerabilidad_actual | vulnerabilidad_futura |       long |      lat |
|---------:|:---------------|:--------------|:--------------------------------------------------------------------------------------------|---------------------:|:----------------------|:----------------------|-----------:|---------:|
|      190 | Presa Requena  | Taxhimay      | No aplica                                                                                   |                    0 | Media                 | Alta                  |  -99.38511 | 19.83593 |
|      110 | Río Lerma 5    | La Purísima   | Desarrollar y calibrar modelos de la demanda y disponibilidad del recurso hídrico.          |                    1 | Alta                  | Alta                  | -101.28597 | 20.86648 |
|       55 | Presa Endhó    | Endhó         | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse. |                    1 | Media                 | Alta                  |  -99.36047 | 20.15731 |
|       42 | Río Verde 1    | El Estribón   | Promover la conservación de la vegetación natural cuenca arriba y cuenca abajo del embalse. |                    1 | Alta                  | Muy Alta              | -102.90183 | 21.18371 |
|      100 | Río Huazuntlán | La Cangrejera | No aplica                                                                                   |                    0 | Baja                  | Baja                  |  -94.33083 | 18.10944 |

### Cuencas vulnerables a Ciclones Tropicales

``` r
sf_cuencas_ct %>%
  st_write(
    dsn = paste0(path2anvccfolder,
                "/cuencas_ciclones_tropicales_anvcc.geojson"),
    driver = "GeoJSON")
```

| Columna         | Descripción                                                         |
|-----------------|---------------------------------------------------------------------|
| `nombre_rha`    | Nombre de la región Hidro-Administrativa al que pertenece la cuenca |
| `nombre_cuenca` | Nombre de la cuenca                                                 |
| `nivel_amenaza` | Nivel de amenaza ante los Ciclones Tropicales                       |
| `geometry`      | Vértices del POLYGON o MULTIPOLYGON                                 |

> \[!NOTE\]
>
> Las columnas `fid`, `id` y `cuenca` no se escriben en la tabla ya que
> la documentación no es muy clara.

``` r
set.seed(1)
sf_cuencas_ct %>%
  as_tibble() %>%
  select(-geometry) %>%
  slice_sample(n = 5)
```

|   fid |  id | cuenca | nombre_rha                   | nombre_cuenca                 | nivel_amenaza |
|------:|----:|-------:|:-----------------------------|:------------------------------|:--------------|
|  9258 | 452 |    682 | FRONTERA SUR                 | Usumacinta                    | Bajo          |
|  4873 |  22 |     51 | PENINSULA DE BAJA CALIFORNIA | Bahía San Felipe              | Muy bajo      |
|  3539 | 659 |    403 | FRONTERA SUR                 | Suchiate                      | Muy bajo      |
| 10854 | 604 |    382 | FRONTERA SUR                 | Las Arenas                    | Muy bajo      |
| 11599 | 729 |    137 | PACIFICO NORTE               | Grupo de corrientes Agiabampo | Medio         |

### Municipios Vulnerables al Cambio Climático

El conjunto de datos se guardará como un archivo CSV, sin la geometría,
ya que como GeoJSON el archivo se vuelve muy pesado. Cuando se requiera
crear mapas con esta información, simplemente se tiene que unir con el
GeoJSON del repositorio `datos_facil_acceso`

``` r
db_anvcc_mun %>%
  write_csv(
    file = paste0(path2anvccfolder, "/mun_vulnerables_anvcc.csv"),
    na = "")
```

| Columna                  | Descripción                                                                                                         |
|--------------------------|---------------------------------------------------------------------------------------------------------------------|
| `nombre_estado`          | Nombre del estado                                                                                                   |
| `cve_ent`                | Clave del Estado segun INEGI                                                                                        |
| `nombre_municipio`       | Nombrel del municipio                                                                                               |
| `cve_geo`                | Clave del Municipio según INEGI                                                                                     |
| `nivel_priorizacion`     | Priorizacion del municipios de acuerdo al número y tipo de vulnerabilidades actuales y futuras                      |
| `tipo_vul`               | Tipo de vulnerabilidad                                                                                              |
| `vulnerabilidad_actual`  | Vulnerabilidad actual, toma los valores **Sin Vulnerabilidad**, **Bajo**, **Medio**, **Alto**, **Muy Alto**, y `NA` |
| `aumento_vulnerabilidad` | Si existe o no aumento en la vulnerabilidad, toma los valores **Aumento** y `NA`                                    |

Los **tipos de vulnerabilidad (`tipo_vul`)** son:

1.  Vulnerabilidad de Producción Forrajera ante Estrés Hídrico
2.  Vulnerabilidad de Producción Ganadera Extensiva ante Estrés Hídrico
3.  Vulnerabilidad de Producción Ganadera Extensiva ante inundaciones
4.  Vulnerabilidad de la población al incremento en distribución del
    dengue
5.  Vulnerabilidad de asentamientos humanos a deslaves
6.  Vulnerabildiad de asentamientos humanos a inundaciones

| nombre_estado | cve_ent | nombre_municipio                        | cve_geo | nivel_priorizacion            | tipo_vul                                       | vulnerabilidad_actual | aumento_vulnerabilidad |
|:--------------|:--------|:----------------------------------------|:--------|:------------------------------|:-----------------------------------------------|:----------------------|:-----------------------|
| Tlaxcala      | 29      | Ziltlaltépec de Trinidad Sánchez Santos | 29037   | Primer Nivel de Priorización  | Asentamientos humanos expuestos a inundaciones | Alto                  | NA                     |
| Puebla        | 21      | Zinacatepec                             | 21214   | Segundo Nivel de Priorización | Asentamientos humanos expuestos a inundaciones | NA                    | NA                     |
| Oaxaca        | 20      | Santo Domingo Ingenio                   | 20505   | Tercer Nivel de Priorización  | Población expuesta al dengue                   | Muy Alto              | Aumento                |
| Tamaulipas    | 28      | Jiménez                                 | 28018   | NA                            | Asentamientos humanos expuestos a inundaciones | NA                    | NA                     |
