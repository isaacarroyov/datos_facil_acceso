# %% [markdown]
# ---
# title: 'Procesamiento y transformación de datos: Geometrías de México'
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# jupyter: python3
# format:
#   gfm:
#     html-math-method: katex
#     fig-width: 5
#     fig-asp: 0.75
#     fig-dpi: 300
#     code-annotations: below
# execute:
#   echo: true
#   eval: true
#   warning: false
# ---

# %% [markdown]
"""
## Introducción y objetivos

En este documento se encuentra documentado el 
código usado para la transformación, estandarización y la 
creación de nuevos conjuntos de datos a partir del 
Marco Geoestadístico 2023, que contiene las geometrías de México: 

* División Estatal
* División Municipal
* Geometrías de Localicades Urbanas y Rurales
* Localidades Puntuales Rurales
* Localidades Urbanas y Rurales Amanzandas

Para este espacio y en este documento se usará únicamente la División 
Municipal
"""

# %%
#| label: load-libraries-paths-00mun
import pandas as pd
from janitor import clean_names
import geopandas
from shapely.geometry import Polygon
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

# %%
#| label: show-og_mun
#| echo: false
from IPython.display import Markdown

Markdown(
    og_mun
    .sample(n = 5, random_state = 11)
    .iloc[:, :-1]
    .to_markdown(index = False))

# %% [markdown]
"""
> La tabla omite la columna **`geometry`** por cuestiones de espacio


A partir de este se crearán los siguientes archivos:

* Geometría del perímetro de México
* Geometrías de los Estados de México
* Geometrías de los Municipios de México

Para todos los casos se cortarán las siguientes islas:

* Islas Revillagigedo, Colima
* Islas Marias, Nayarit
* Arrecife Alacranes, Yucatán
* Isla Guadalupe, Baja California

> [!NOTE]
> La decisión de eliminar esas islas se debe a la lejanía a que se tiene 
> con la parte territorial del estado o municipio, su baja población y 
> por la naturalidad de los proyectos a los que me dedico.

"""

# %% [markdown]
"""
## Cambio de nombres de nombres de municipios y asignación del estado
"""



# %% [markdown]
"""
## Cortar islas
"""

# %% [markdown]
"""
### Función para cortar islas

> [!NOTE]
> Función adaptada del código hecho por 
> [Juvenal Campos](https://x.com/JuvenalCamposF) de su blog 
> [Cortando Islas](https://juvenalcampos.com/2020/07/26/cortando-islas/), 
> publicado el 26 de Julio del 2020. 
> 
> La función que comparte esta hecha en R y fue adaptada a Python.
"""

# %%
#| eval: false
def recorte_cuadro(shp, minX, maxX, minY, maxY):
    bbox = Polygon([(minX, minY), (maxX, minY), (maxX, maxY), (minX, maxY)])
    
    bbox_gdf = geopandas.GeoDataFrame(geometry = [bbox], crs = 4326)
    
    edo_sin_islas = geopandas.overlay(shp, bbox_gdf, how='intersection')
    
    return edo_sin_islas

# %% [markdown]
"""
### Cortando islas: Islas Revillagigedo, Colima
"""

# %% [markdown]
"""
### Cortando islas: Islas Marias, Nayarit
"""

# %% [markdown]
"""
### Cortando islas: Arrecife Alacranes, Yucatán
"""

# %% [markdown]
"""
### Cortando islas: Isla Guadalupe, Baja California
"""

# %% [markdown]
"""
### Unión de entidades con las de las islas cortadas
"""

# %% [markdown]
"""
## Perímetro de México
"""

# %% [markdown]
"""
## División de los Estados
"""

# %% [markdown]
"""
## Simplificación de los Municipios
"""

# %% [markdown]
"""
## Guardar geometrías modificadas
"""