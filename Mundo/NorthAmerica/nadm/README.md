# Procesamiento de datos: *North American Drought Monitor*
Isaac Arroyo
29 de junio de 2024

## Introducción y objetivos

De acuerdo con el sitio oficial del *North American Drought Monitor*:

> *The North American Drought Monitor (NADM) is a cooperative effort between drought experts in Canada, Mexico and the United States to monitor drought across the continent on an ongoing basis*

Traducido a:

> El Monitor de Sequía de América del Norte (NADM) es un esfuerzo continuo y cooperativo entre expertos de Canadá, México y Estados Unidos de América.

En México, el [Monitor de Sequía de México (MSM)]() es encargado de compartir la información de la sequía en México. Los datos del MSM han sido procesado y se encuentran en la carpeta [GobiernoMexicano/msm](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/msm)

A pesar de que se le puede pedir al Servicio Meteorológico Nacional los polígonos de las zonas de sequía, el NADM publica mensualmente los archivos vectoriales de los mapas. A partir de estas publicaciones es en que se crea este archivo.

El resultado de este procesamiento y transformación de los datos es una serie de conjuntos vectoriales y tabulares que ayuden al monitoreo y al registro histórico de la sequía de Canadá, México y Estados Unidos:

- Tabulares (CSV)
  - a.1
  - b.1
  - c.1
- Vectoriales (GeoJSON, *shapefiles*)
  - a.2
  - b.2
  - c.2

``` r
library(tidyverse)
library(gt)
library(sf)

path2main <- paste0(getwd(), "/../../..")
path2mundo <- paste0(path2main, "/Mundo")
path2usa <- paste0(path2mundo, "/USA")
path2nadmfolder <- paste0(path2usa, "/nadm")
path2ogdata_nadm <- paste0(path2nadmfolder, "/og_data")
```

## Estructura de la carpeta de datos

Vestibulum felis augue, pharetra sed leo eu, pretium rutrum leo. Sed viverra, leo et pulvinar fermentum, massa urna bibendum neque, sit amet consequat nunc mi et metus. Etiam et aliquam libero, quis scelerisque tellus. Pellentesque sodales metus at aliquet aliquam. Phasellus aliquam hendrerit nulla. Cras ut commodo metus. Nulla a lectus mollis, fringilla nisi id, iaculis est. Nunc pharetra nulla arcu, vitae aliquet erat posuere vel. Aliquam non varius quam. Phasellus sed purus nulla. Praesent tempus aliquam iaculis. Curabitur et sapien vel neque lacinia pretium.

## Cambios en los conjuntos de datos

Nulla vehicula nunc vitae ex commodo convallis. Nullam iaculis urna ac condimentum suscipit. Nulla ultricies euismod ligula vitae varius. Praesent quam orci, volutpat id ante vitae, suscipit ultricies dolor. Nam varius blandit urna quis blandit. Nam eget porttitor neque. Maecenas maximus risus ac mauris porta, in tempus dolor convallis. Maecenas sagittis malesuada blandit. Duis molestie euismod eleifend. Curabitur volutpat leo vitae vestibulum ornare. Duis molestie facilisis dui.

## Poligonos de tipos de sequía

Vestibulum felis augue, pharetra sed leo eu, pretium rutrum leo. Sed viverra, leo et pulvinar fermentum, massa urna bibendum neque, sit amet consequat nunc mi et metus. Etiam et aliquam libero, quis scelerisque tellus. Pellentesque sodales metus at aliquet aliquam. Phasellus aliquam hendrerit nulla. Cras ut commodo metus. Nulla a lectus mollis, fringilla nisi id, iaculis est. Nunc pharetra nulla arcu, vitae aliquet erat posuere vel. Aliquam non varius quam. Phasellus sed purus nulla. Praesent tempus aliquam iaculis. Curabitur et sapien vel neque lacinia pretium.

``` r
recent_date <- "202405"

sf_d0 <- st_read(dsn = paste0(path2ogdata_nadm,
                              "/nadm-", recent_date,
                              "/nadm_d0.shp"))
```

Nunc vitae ligula magna. Mauris eu urna non lacus suscipit maximus. Nullam sodales porttitor magna quis rhoncus. Vestibulum elementum nibh quis quam cursus interdum. Vestibulum sit amet justo ut ex molestie rhoncus. Praesent tempus posuere urna, vel rutrum quam maximus blandit. Vivamus sed dui eu leo euismod congue. Curabitur in ante ut ligula finibus porttitor. Fusce iaculis odio et erat finibus, egestas vulputate nunc sollicitudin. Cras sollicitudin risus eleifend pharetra tincidunt. Quisque eleifend fringilla maximus. Vivamus vitae cursus enim.
