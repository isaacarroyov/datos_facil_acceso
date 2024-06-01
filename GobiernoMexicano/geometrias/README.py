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

Existen municipios cuyos nombres son **demasiado largos**, por lo que se 
les acortarán los nombres, tanto para mostrarlo en algún 
gráfico (estático o interactivo), así como para facilidad de lectura.
"""

# %% 
#| label: create-df_cve_mun
df_cve_mun = (og_mun[['cvegeo', 'nomgeo']]
              .rename(columns = {'nomgeo': 'nombre_municipio'}))

df_cve_mun['len_nombre'] = (df_cve_mun['nombre_municipio']
                            .apply(lambda x: len(x.split(" "))))


# %%
#| label: show-num-mun-num-palabras-nombre
#| echo: false
Markdown(
    pd.DataFrame(
        df_cve_mun['len_nombre']
        .value_counts()
        .sort_values(ascending = True))
    .reset_index()
    .rename(
        columns= {'count': 'Número de municipios',
                  'len_nombre': 'Número de palabras en el nombre'})
    .to_markdown(index = False))


# %% [markdown]
"""
Existen 11 municipios con 6 palabras o más en el nombre, por lo que se 
revisarán para identificar si cuentan con un nombre _más corto_
"""

# %%
#| label: show-mun-nombre-mas-6-palabras
#| echo: false
Markdown(
  df_cve_mun
  .query("len_nombre >= 6")
  .to_markdown(index = False))

# %% [markdown]
"""
Los nombres que tendrán un cambio con los siguientes:

* Dolores Hidalgo Cuna de la Independencia Nacional → Dolores Hidalgo

* Heroica Villa Tezoatlán de Segura y Luna, Cuna de la Independencia 
de Oaxaca → Tezoatlan de Segura y Luna

* Heroica Ciudad de Ejutla de Crespo → Ejutla de Crespo

* Heroica Ciudad de Huajuapan de León → Huajuapan de León

* Heroica Villa de San Blas Atempa → San Blas Atempa

* Heroica Ciudad de Tlaxiac → Tlaxiac
"""

# %%
#| label: create-func_rename_mun

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

# %% [markdown]
"""
Se renombran los municipios y se elimina la columna de longitud del nombre
"""

# %%
#| label: trans_cols-rename_municipios
df_cve_mun['nombre_municipio'] = (df_cve_mun['nombre_municipio']
                                  .apply(func_renamte_mun))

df_cve_mun = (df_cve_mun
              .drop(columns = ['len_nombre'])
              .rename(columns = {'cvegeo': 'cve_mun'}))


# %% [markdown]
"""
Finalmente se unen los datos de `df_cve_mun` con el archivo 
**`cve_nom_estados.csv`** para tener una base de datos que tenga no solo 
la clave de los municipios con sus nombres, también el estado al que 
pertenecen.
"""

# %%
#| label: update-df_cve_mun-con_cve_nom_ent

df_cve_ent = pd.read_csv(
    filepath_or_buffer= path2gobmex + "/cve_nom_estados.csv",
    dtype = 'object')

df_cve_mun['cve_ent'] = df_cve_mun['cve_mun'].apply(lambda x: x[:2])

db_cve_nom_mun = (pd.merge(
    left = df_cve_mun,
    right = df_cve_ent,
    how = 'left',
    on = "cve_ent")
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun']])


# %%
#| label: show-db_cve_nom_mun
#| echo: false
Markdown(
  db_cve_nom_mun
  .sample(n = 5, random_state= 11)
  .to_markdown(index = False))


# %% [markdown]
"""
Esta nueva base de datos se va a guardar bajo el nombre 
**`cve_nom_municipios.csv`**
"""

# %%
#| label: save-db_cve_nom_mun

(db_cve_nom_mun
  .to_csv(
      path_or_buf= path2gobmex + "/cve_nom_municipios.csv",
      index = False))

# %% [markdown]
"""
## Cortar islas

La decisión de cortar o _ignorar_ las islas es con fines estéticos, ya que 
existen islas lejanas al territorio del estado. El tipo de mapa en el que 
se usarían estas geometrías son resúmenes de la demarcación (geometría del 
estado o del municipio), por lo que no es necesario entrar a detalle ya 
que las islas forman parte del municipio, caso contrario a Cozumel, donde 
**la isla es el municipio**.
"""

# %%
#| label: create-mun_no_ent_islas-mun_ent_islas

list_mun_no_ent_islas = ["02", "06", "18", "31"]
mask_list_mun_no_ent_islas = og_mun['cve_ent'].isin(list_mun_no_ent_islas)

mun_no_ent_islas = (og_mun[~(mask_list_mun_no_ent_islas)]
                    .reset_index(drop = True))

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

from shapely.geometry import Polygon
def recorte_cuadro(shp, minX, maxX, minY, maxY):

    bbox = Polygon([(minX, minY), (maxX, minY), (maxX, maxY), (minX, maxY)])
    
    bbox_gdf = geopandas.GeoDataFrame(geometry = [bbox], crs = 4326)
    
    edo_sin_islas = geopandas.overlay(shp, bbox_gdf, how='intersection')
    
    return edo_sin_islas

# %% [markdown]
"""
### Cortando islas: Islas Revillagigedo, Colima
"""

# %%
#| label: create-mun_colima_no_islas

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

# %% [markdown]
"""
### Cortando islas: Islas Marias, Nayarit
"""

# %%
#| label: create-mun_nayarit_no_islas

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

# %% [markdown]
"""
### Cortando islas: Arrecife Alacranes, Yucatán
"""

# %%
#| label: create-mun_yucatan_no_islas

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