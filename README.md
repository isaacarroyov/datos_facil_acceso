# Base de Datos para Fácil Acceso

> [!NOTE]
> Nuevos aspectos y conjuntos de datos se irán agregando al paso del tiempo, todo depende de los proyectos en los que me encuentre involucrados.

## Objetivo del repositorio

La búsqueda, descarga, limpieza y transformación de los datos es un trabajo de siempre para cualquier persona en esta área.

Este repositorio es resultado del un proyecto personal cuyo objetivo es **tener datos como me gusta tenerlos**, es decir:

- **Estandarizados**: La estandarización puede ser un concepto subjetivo, ya que cada usuario puede tener su preferencia. En el caso de este repositorio, se busca que cumplan con la [estructura _tidy_](https://tidyr.tidyverse.org/articles/tidy-data.html#tidy-data).
- **Formato amigable**: **CSV**, **CSV.BZ2** o **GeoJSON**.
- **Procesamiento y transformación documentados**: Descrito el paso a paso en un archivo Markdown.
- **Públicos**: Para poder accesar a ellos a través de un URL.

## Organización del repositorio

El repositorio se encuentra dividido en diferentes temas o fuentes, las cuales se encuentran en diferentes carpetas, por ejemplo, si la fuente/tema es **Google Earth Engine**, en esa carpeta estarán todo lo relacionado a los datos descargados de ahí.

Las carpetas de las fuentes contienen la documentación del procesamiento y transformación de los datos. 

* [**EarthEngine**](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/EarthEngine)
  * TerraClimate
  * CHIRPS Daily
* [**GobiernoMexicano**](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano)
  * INEGI
  * Proyeccion de población de la nacion, estados y municipios
  * Geometrías de los estados, municipios, etc.
  * Monitor de Sequía de México
  * Relación de claves-nombres de los estados y municipios
* [**Mundo**](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/Mundo)
  * Geomtrías de los países del mundo
  * Geometría de los estados de Estados Unidos de América

---

## Cambios comunes

Existen ciertos tipos de cambios que son los primeros en realizarse y son los más comunes en todos los _scripts_ de procesamiento. 

1. **Limpieza de nombres de columnas**: La limpieza consta de estandarizar los nombres al formato [**`snake_case`**](https://developer.mozilla.org/en-US/docs/Glossary/Snake_case) con la ayuda de la función **`clean_names`** de la librería [`{janitor}` (R)](https://sfirke.github.io/janitor/index.html) o [`pyjanitor` (Python)](https://pyjanitor-devs.github.io/pyjanitor/). **Este cambio se hace para datos estructurados (tablas y CSVs) así como [datos vectoriales](https://docs.qgis.org/3.34/es/docs/gentle_gis_introduction/vector_data.html)**

2. **Reproyección**: Consta de transformar la reproyección a [`crs = 4326`](https://epsg.io/4326). **Este cambio se hace únicamente a datos vectoriales**.
