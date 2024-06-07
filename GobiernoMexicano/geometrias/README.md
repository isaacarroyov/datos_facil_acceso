# Procesamiento y transformación de datos: Geometrías de México
Isaac Arroyo
7 de junio de 2024

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
path2modgeoms = path2geoms + "/mod_geoms"

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

A partir de este se crearán los siguientes archivos GeoJSON:

- Geometría del perímetro de México
- Geometrías de los Estados de México
- Geometrías de los Municipios de México

Tenerlos como GeoJSON da mayor facilidad de carga como archivo *raw*
para usarse con Altair (una de mis principales herramientas para la
creación de gráficos interactivos), así como facilidad para compartir
con otras personas.

Para todos los casos se cortarán las siguientes islas:

- Islas Revillagigedo, Colima
- Islas Marias, Nayarit
- Arrecife Alacranes, Yucatán
- Isla Guadalupe, Baja California

> \[!NOTE\]
>
> La decisión de eliminar esas islas se debe a la lejanía a que se tiene
> con la parte territorial del estado o municipio, su baja población y
> por la naturalidad de los proyectos a los que me dedico.

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
  Oaxaca → Tezoatlan de Segura y Luna

- Heroica Ciudad de Ejutla de Crespo → Ejutla de Crespo

- Heroica Ciudad de Huajuapan de León → Huajuapan de León

- Heroica Villa de San Blas Atempa → San Blas Atempa

- Heroica Ciudad de Tlaxiac → Tlaxiac

``` python
def func_renamte_mun(nombre):
    if nombre == "Heroica Ciudad de Tlaxiac":
        return "Tlaxiac"
    elif nombre == "Heroica Villa de San Blas Atempa":
        return "San Blas Atempa"
    elif nombre == "Heroica Ciudad de Huajuapan de León":
        return "Huajuapan de León"
    elif nombre == "Heroica Ciudad de Ejutla de Crespo":
        return "Ejutla de Crespo"
    elif nombre == ' '.join(["Heroica Villa Tezoatlán de Segura y",
                             "Luna, Cuna de la Independencia de Oaxaca"]):
        return "Tezoatlan de Segura y Luna"
    elif nombre == "Dolores Hidalgo Cuna de la Independencia Nacional":
        return "Dolores Hidalgo"
    else: 
        return nombre
```

Se renombran los municipios y se elimina la columna de longitud del
nombre

``` python
df_cve_mun['nombre_municipio'] = (df_cve_mun['nombre_municipio']
                                  .apply(func_renamte_mun))

df_cve_mun = (df_cve_mun
              .drop(columns = ['len_nombre'])
              .rename(columns = {'cvegeo': 'cve_geo'}))

df_cve_mun['cve_mun'] = df_cve_mun['cve_geo'].apply(lambda x: x[2:])
```

Finalmente se unen los datos de `df_cve_mun` con el archivo
**`cve_nom_estados.csv`** para tener una base de datos que tenga no solo
la clave de los municipios con sus nombres, también el estado al que
pertenecen.

``` python
df_cve_ent = pd.read_csv(
    filepath_or_buffer= path2gobmex + "/cve_nom_estados.csv",
    dtype = 'object')

df_cve_mun['cve_ent'] = df_cve_mun['cve_geo'].apply(lambda x: x[:2])

db_cve_nom_mun = (pd.merge(
    left = df_cve_mun,
    right = df_cve_ent,
    how = 'left',
    on = "cve_ent")
  [['cve_geo', 'nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun']])
```

| cve_geo | nombre_estado    | cve_ent | nombre_municipio          | cve_mun |
|--------:|:-----------------|--------:|:--------------------------|--------:|
|   20476 | Oaxaca           |      20 | Santiago Miltepec         |     476 |
|   30004 | Veracruz         |      30 | Actopan                   |     004 |
|   24039 | San Luis Potosí  |      24 | Tampamolón Corona         |     039 |
|   26022 | Sonora           |      26 | Cucurpe                   |     022 |
|   15001 | Estado de México |      15 | Acambay de Ruíz Castañeda |     001 |

Esta nueva base de datos se va a guardar bajo el nombre
**`cve_nom_municipios.csv`**

``` python
(db_cve_nom_mun
  .to_csv(
      path_or_buf= path2gobmex + "/cve_nom_municipios.csv",
      index = False))
```

## Cortar islas

La decisión de cortar o *ignorar* las islas es con fines estéticos, ya
que existen islas lejanas al territorio del estado. El tipo de mapa en
el que se usarían estas geometrías son resúmenes de la demarcación
(geometría del estado o del municipio), por lo que no es necesario
entrar a detalle ya que las islas forman parte del municipio, caso
contrario a Cozumel, donde **la isla es el municipio**.

``` python
list_mun_no_ent_islas = ["02", "06", "18", "31"]
mask_list_mun_no_ent_islas = og_mun['cve_ent'].isin(list_mun_no_ent_islas)

mun_no_ent_islas = (og_mun[~(mask_list_mun_no_ent_islas)]
                    .reset_index(drop = True))
```

### Función para cortar islas

> \[!NOTE\]
>
> Función adaptada del código hecho por [Juvenal
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

``` python
mun_colima = og_mun.query('cve_ent == "06"')
bbox_colima_maxX = -103.47499
bbox_colima_minX = -104.76983
bbox_colima_maxY = 19.563769
bbox_colima_minY = 18.65329

mun_colima_no_islas = recorte_cuadro(
    shp= mun_colima,
    maxX= bbox_colima_maxX,
    minX= bbox_colima_minX,
    maxY= bbox_colima_maxY,
    minY= bbox_colima_minY)
```

### Cortando islas: Islas Marias, Nayarit

``` python
mun_nayarit = og_mun.query('cve_ent == "18"')
bbox_nayarit_minX = -105.7765
bbox_nayarit_maxX = -103.7209 
bbox_nayarit_minY = 20.60322 
bbox_nayarit_maxY = 23.0845

mun_nayarit_no_islas = recorte_cuadro(
    shp= mun_nayarit,
    maxX= bbox_nayarit_maxX,
    minX= bbox_nayarit_minX,
    maxY= bbox_nayarit_maxY,
    minY= bbox_nayarit_minY)
```

### Cortando islas: Arrecife Alacranes, Yucatán

``` python
mun_yucatan = og_mun.query('cve_ent == "31"')
bbox_yucatan_minX = -90.620039
bbox_yucatan_maxX = -87.414154
bbox_yucatan_minY = 19.584267 
bbox_yucatan_maxY = 21.731110

mun_yucatan_no_islas = recorte_cuadro(
    shp= mun_yucatan,
    maxX= bbox_yucatan_maxX,
    minX= bbox_yucatan_minX,
    maxY= bbox_yucatan_maxY,
    minY= bbox_yucatan_minY)
```

### Cortando islas: Isla Guadalupe, Baja California

``` python
mun_bc = og_mun.query('cve_ent == "02"')
bbox_bc_minX = -117.562296
bbox_bc_maxX = -112.662364
bbox_bc_minY = 28.005716
bbox_bc_maxY = 32.542616

mun_bc_no_islas = recorte_cuadro(
    shp= mun_bc,
    maxX= bbox_bc_maxX,
    minX= bbox_bc_minX,
    maxY= bbox_bc_maxY,
    minY= bbox_bc_minY)
```

### Unión de entidades con las de las islas cortadas

Después de cortar las islas de nuestro interés, se unen todas en un solo
`geopandas.GeoDataFrame` que se pondrá como nombre final `sf_mun` (ya
que tengo la costumbre de nombrar así las variables que contienen
objetos vectoriales, esta costumbre la cargo por **`R`** y la librería
`{sf}`)

``` python
sf_mun = (pd.concat([
    mun_no_ent_islas,
    mun_colima_no_islas,
    mun_nayarit_no_islas,
    mun_yucatan_no_islas,
    mun_bc_no_islas])
  .reset_index(drop = True)
  .sort_values(by = "cvegeo")
  .rename(columns = {'cvegeo': 'cve_geo'})
  .drop(columns= ['nomgeo'])
  .merge(
    right = db_cve_nom_mun,
    on = ['cve_geo', 'cve_ent', 'cve_mun'],
    how = 'left')
  [['cve_geo',
    'nombre_estado',
    'cve_ent',
    'nombre_municipio',
    'cve_mun',
    'geometry']])
```

## Perímetro de México

A continuación se crea el primer archivo vectorial: la geometría de
México (país)

``` python
geometry_nac = sf_mun['geometry'].unary_union

sf_nac = geopandas.GeoDataFrame(
    data = {'cve_ent': ["00"],
            "nombre_entidad": ["Nacional"]},
    crs = 4326,
    geometry = [geometry_nac])
```

## División de los Estados

A partir de los municipios modificados se crean las geometrías de los
estados de México. Para ello se va a crear un diccionario donde se
almacenarán los `geopandas.GeoDataFrame`s (32 en total).

``` python
def func_isolate_ent(gdf, codigo_entidad):
    # Aislar entidad de interés
    sf_ent_interes = gdf[gdf['cve_ent'].str.contains(codigo_entidad)]
    # Unir todos los municipios que lo conforman
    geom_ent_interes = sf_ent_interes['geometry'].unary_union
    # Extraer la información (Código y Nombre) del estado
    dict_ent_interes = (sf_ent_interes
                        .drop(columns = ['geometry'])
                        .drop_duplicates(subset=['cve_ent', 'nombre_estado'])
                        [['cve_ent','nombre_estado']]
                        .reset_index(drop = True)
                        .to_dict())
    # Crear geopandas.GeoDataFrame final
    sf_final = geopandas.GeoDataFrame(
        data = dict_ent_interes,
        crs = 4326,
        geometry = [geom_ent_interes])
    return sf_final
```

Ahora se itera por los diferentes códigos de los estados para crear las
geometrías individuales de cada uno.

``` python
list_cve_ent = sf_mun['cve_ent'].unique().tolist()
dict_gdfs = dict()

for codigo in list_cve_ent:
    dict_gdfs[codigo] = func_isolate_ent(
        gdf = sf_mun,
        codigo_entidad = codigo)
```

En la sección del código se irán guardan las geometrías de las entidades

## Simplificación de los Municipios

La función que se usa es
[`geopandas.GeoSeries.simplify`](https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoSeries.simplify.html),
la cual tiene como argumento **`tolerance`** que, en palabras sencillas,
indica el *poder* de simplificación. A mayor número, más simplificadas
las geometrías.

Elegir la tolerancia depende de cada persona, ya que el resultado final
se ve reflejado en el mapa y en el peso del archivo final.

``` python
simplified_geoms = (sf_mun['geometry']
                    .simplify(
                        tolerance = 0.0013,
                        preserve_topology = True))

sf_mun_simplified = sf_mun.copy()
sf_mun_simplified['geometry'] = simplified_geoms
```

## Guardar geometrías modificadas

### Perímetro de México

El nombre del archivo es **`geom_mexico.geojson`**

``` python
# TODO: Evaluar simplificar la geometría

sf_nac.to_file(
    filename = path2modgeoms + "/geom_mexico.geojson",
    driver = "GeoJSON")
```

### Estados

Se van a crear 33 archivos:

- Archivo de perímetro de la entidad (32 archivos): Bajo el nombre de
  **`geom_ent_XX.geojson`**, donde **XX** es la clave de dos digitos de
  cada estado.

- Archivo de México con todas las divisiones de los estados (1 archivo):
  Bajo el nombre **`geom_mexico_ent.geojson`**

#### Estados individuales

``` python
for key in dict_gdfs:
    dict_gdfs[key].to_file(
        filename = path2modgeoms + f"/geom_ent_{key}.geojson",
        driver = "GeoJSON")
```

#### Estados unidos

``` python
# TODO: Evaluar simplificar la geometría

(geopandas.GeoDataFrame(
    pd.concat([dict_gdfs[key] for key in dict_gdfs]))
    .reset_index(drop = True)
    .to_file(
        filename = path2modgeoms + "/geom_mexico_ent.geojson",
        driver = "GeoJSON"))
```

### Municipios

Se van a crear 34 archivos:

- Archivo de división municipal de la entidad (32 archivos): Bajo el
  nombre de **`geom_ent_mun_XX.geojson`**, donde **XX** es la clave de
  dos dígitos de cada estado

- Archivo de división municipal de todo el país: Bajo el nombre
  **`geom_mexico_mun.shp`**

- Archivo de división municipal de todo el país, simplificado: Bajo el
  nombre **`geom_mexico_mun_simplified.geojson`**

#### Municipios por estados individuales (no simplificado)

``` python
for codigo in list_cve_ent:
    (sf_mun
     .query(f'cve_ent == "{codigo}"')
     .reset_index(drop = True)
     .to_file(
         filename = path2modgeoms + f"/geom_ent_mun_{codigo}.geojson",
         driver = "GeoJSON"))
```

#### Municipios unidos (no simplificado)

> \[!NOTE\]
>
> Este archivo fue guardado como GeoJSON pero para que pueda ser cargado
> al repositorio de GitHub, fue comprimido como un archivo ZIP.

``` python
sf_mun.to_file(
    filename = path2modgeoms + f"/geom_mexico_mun.shp")
```

#### Municipios unidos (simplificado)

``` python
sf_mun_simplified.to_file(
    filename = path2modgeoms + f"/geom_mexico_mun_simplified.geojson",
    driver = "GeoJSON")
```
