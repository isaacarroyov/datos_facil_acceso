# Procesamiento y transformación de datos: Geometrías de México
Isaac Arroyo
22 de mayo de 2024

## Introducción y objetivos

En este documento se encuentra documentado el código usado para la
transformación, estandarización y la creación de nuevos conjuntos de
datos a partir del Marco Geoestadístico 2023, que contiene las
geometrías de México:

- División Estatal
- División Municipal
- Geometrías de Localicades Urbanas y Rurales
- Localidades Puntuales Rurales
- Localidades Urbanas y Rurales Amanzandas

Para este espacio y en este documento se usará únicamente la División
Municipal

``` python
import pandas as pd
from janitor import clean_names
import geopandas
import os

# Cambiar al folder principal del repositorio
os.chdir("../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2geoms = path2gobmex + "/geometrias"
path2mg = path2geoms + '/og_geoms'

# Datos de división municipal
og_mun = (geopandas.read_file(filename = path2mg + "/00mun.shp")
          .to_crs(4326)
          .clean_names())
```

| cvegeo | cve_ent | cve_mun | nomgeo                    |
|-------:|--------:|--------:|:--------------------------|
|  20476 |      20 |     476 | Santiago Miltepec         |
|  30004 |      30 |     004 | Actopan                   |
|  24039 |      24 |     039 | Tampamolón Corona         |
|  26022 |      26 |     022 | Cucurpe                   |
|  15001 |      15 |     001 | Acambay de Ruíz Castañeda |

> La tabla omite la columna **`geometry`** por cuestiones de espacio

A partir de este se crearán los siguientes archivos:

- Geometría del perímetro de México
- Geometrías de los Estados de México
- Geometrías de los Municipios de México

Para todos los casos se cortarán las siguientes islas:

- Islas Revillagigedo, Colima
- Islas Marias, Nayarit
- Arrecife Alacranes, Yucatán
- Isla Guadalupe, Baja California

> \[!NOTE\] La decisión de eliminar esas islas se debe a la lejanía a
> que se tiene con la parte territorial del estado o municipio, su baja
> población y por la naturalidad de los proyectos a los que me dedico.

## Cambio de nombres de nombres de municipios y asignación del estado

Existen municipios cuyos nombres son **demasiado largos**, por lo que se
les acortarán los nombres, tanto para mostrarlo en algún gráfico
(estático o interactivo), así como para facilidad de lectura.

``` python
df_cve_mun = (og_mun[['cvegeo', 'nomgeo']]
              .rename(columns = {'nomgeo': 'nombre_municipio'}))

df_cve_mun['len_nombre'] = (df_cve_mun['nombre_municipio']
                            .apply(lambda x: len(x.split(" "))))
```

| Número de palabras en el nombre | Número de municipios |
|--------------------------------:|---------------------:|
|                              13 |                    1 |
|                               7 |                    2 |
|                               6 |                    8 |
|                               5 |                   40 |
|                               4 |                  156 |
|                               2 |                  362 |
|                               3 |                  673 |
|                               1 |                 1233 |

Existen 11 municipios con 6 palabras o más en el nombre, por lo que se
revisarán para identificar si cuentan con un nombre *más corto*

| cvegeo | nombre_municipio                                                             | len_nombre |
|-------:|:-----------------------------------------------------------------------------|-----------:|
|  11014 | Dolores Hidalgo Cuna de la Independencia Nacional                            |          7 |
|  12068 | La Unión de Isidoro Montes de Oca                                            |          7 |
|  20549 | Heroica Villa Tezoatlán de Segura y Luna, Cuna de la Independencia de Oaxaca |         13 |
|  20124 | Heroica Villa de San Blas Atempa                                             |          6 |
|  20180 | San Juan Bautista Lo de Soto                                                 |          6 |
|  20339 | San Pedro y San Pablo Teposcolula                                            |          6 |
|  20340 | San Pedro y San Pablo Tequixtepec                                            |          6 |
|  20337 | San Pedro y San Pablo Ayutla                                                 |          6 |
|  20028 | Heroica Ciudad de Ejutla de Crespo                                           |          6 |
|  20039 | Heroica Ciudad de Huajuapan de León                                          |          6 |
|  30206 | Nanchital de Lázaro Cárdenas del Río                                         |          6 |

Los nombres que tendrán un cambio con los siguientes:

- Dolores Hidalgo Cuna de la Independencia Nacional → Dolores Hidalgo

- Heroica Villa Tezoatlán de Segura y Luna, Cuna de la Independencia de
  Oaxaca →

- Heroica Villa Tezoatlán de Segura y Luna, Cuna de la Independencia de
  Oaxaca → Tezoatlan de Segura y Luna

- Heroica Ciudad de Ejutla de Crespo → Ejutla de Crespo

- Heroica Ciudad de Huajuapan de León → Huajuapan de León

- Heroica Villa de San Blas Atempa → San Blas Atempa

## Cortar islas

### Función para cortar islas

> \[!NOTE\] Función adaptada del código hecho por [Juvenal
> Campos](https://x.com/JuvenalCamposF) de su blog [Cortando
> Islas](https://juvenalcampos.com/2020/07/26/cortando-islas/),
> publicado el 26 de Julio del 2020.
>
> La función que comparte esta hecha en R y fue adaptada a Python.

``` python
from shapely.geometry import Polygon
def recorte_cuadro(shp, minX, maxX, minY, maxY):
    bbox = Polygon([(minX, minY), (maxX, minY), (maxX, maxY), (minX, maxY)])
    
    bbox_gdf = geopandas.GeoDataFrame(geometry = [bbox], crs = 4326)
    
    edo_sin_islas = geopandas.overlay(shp, bbox_gdf, how='intersection')
    
    return edo_sin_islas
```

### Cortando islas: Islas Revillagigedo, Colima

### Cortando islas: Islas Marias, Nayarit

### Cortando islas: Arrecife Alacranes, Yucatán

### Cortando islas: Isla Guadalupe, Baja California

### Unión de entidades con las de las islas cortadas

## Perímetro de México

## División de los Estados

## Simplificación de los Municipios

## Guardar geometrías modificadas
