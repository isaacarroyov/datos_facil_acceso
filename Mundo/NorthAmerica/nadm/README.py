# %% [markdown]
# ---
# title: 'Procesamiento de datos: _North American Drought Monitor_'
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# format:
#   gfm:
#     html-math-method: katex
#     fig-width: 5
#     fig-asp: 0.75
#     fig-dpi: 300
#     code-annotations: below
#     df-print: kable
#     wrap: none
# execute:
#   echo: true
#   eval: true
#   warning: false
# ---

# %%
#| label: setworkingdirectory
import os

# Cambiar al folder principal del repositorio
os.chdir("../../../")

# %% [markdown]
"""
## Introducción y objetivos

De acuerdo con el sitio oficial del 
[_North American Drought Monitor_](https://nadm-noaa.hub.arcgis.com/): 

> _The North American Drought Monitor (NADM) is a cooperative effort 
between drought experts in Canada, Mexico and the United States to 
monitor drought across the continent on an ongoing basis_

Traducido a: 

> El Monitor de Sequía de América del Norte (NADM) es un esfuerzo 
continuo y cooperativo entre expertos de Canadá, México y Estados Unidos 
de América para monitorear la sequía a través del continente 
(norteamericano).

En México, el [Monitor de Sequía de México 
(MSM)](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico) 
es encargado de compartir la información de la sequía en México. Los 
datos del MSM han sido procesado y se encuentran en la 
carpeta 
[GobiernoMexicano/msm](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/msm)

A pesar de que se le puede pedir al Servicio Meteorológico Nacional los 
polígonos de las zonas de sequía, el NADM publica mensualmente los 
archivos vectoriales de los mapas. A partir de estas publicaciones es en 
que se crea este archivo.

El resultado de este procesamiento y transformación de los datos es 
una serie de conjuntos vectoriales y tabulares que ayuden al monitoreo 
y al registro histórico de la sequía de Canadá, México y Estados Unidos:

* Tabulares (CSV)
  * a.1
  * b.1
  * c.1
* Vectoriales (GeoJSON, _shapefiles_)
  * a.2
  * b.2
  * c.2
"""

# %%
#| label: load-paths2data_libraries
import pandas as pd
import geopandas

path2main = os.getcwd()
path2mundo = path2main + "/Mundo"
path2northamerica = path2mundo + "/NorthAmerica"
path2nadmfolder = path2northamerica + "/nadm"
path2ogdata_nadm = path2nadmfolder + "/og_data"

# %% [markdown]
"""
## Estructura de la carpeta de datos

Vestibulum felis augue, pharetra sed leo eu, pretium rutrum leo. Sed 
viverra, leo et pulvinar fermentum, massa urna bibendum neque, sit amet 
consequat nunc mi et metus. Etiam et aliquam libero, quis scelerisque 
tellus. Pellentesque sodales metus at aliquet aliquam. Phasellus aliquam 
hendrerit nulla. Cras ut commodo metus. Nulla a lectus mollis, fringilla 
nisi id, iaculis est. Nunc pharetra nulla arcu, vitae aliquet erat 
posuere vel. Aliquam non varius quam. Phasellus sed purus nulla. Praesent 
tempus aliquam iaculis. Curabitur et sapien vel neque lacinia pretium.
"""

# %% [markdown]
"""
## Cambios en los conjuntos de datos 

Nulla vehicula nunc vitae ex commodo convallis. Nullam iaculis urna ac 
condimentum suscipit. Nulla ultricies euismod ligula vitae 
varius. Praesent quam orci, volutpat id ante vitae, suscipit ultricies 
dolor. Nam varius blandit urna quis blandit. Nam eget porttitor 
neque. Maecenas maximus risus ac mauris porta, in tempus dolor 
convallis. Maecenas sagittis malesuada blandit. Duis molestie euismod 
eleifend. Curabitur volutpat leo vitae vestibulum ornare. Duis molestie 
facilisis dui.
"""

# %% [markdown]
"""
## Poligonos de tipos de sequía

Vestibulum felis augue, pharetra sed leo eu, pretium rutrum leo. Sed 
viverra, leo et pulvinar fermentum, massa urna bibendum neque, sit amet 
consequat nunc mi et metus. Etiam et aliquam libero, quis scelerisque 
tellus. Pellentesque sodales metus at aliquet aliquam. Phasellus aliquam 
hendrerit nulla. Cras ut commodo metus. Nulla a lectus mollis, fringilla 
nisi id, iaculis est. Nunc pharetra nulla arcu, vitae aliquet erat 
posuere vel. Aliquam non varius quam. Phasellus sed purus nulla. Praesent 
tempus aliquam iaculis. Curabitur et sapien vel neque lacinia pretium.
"""

# %%
#| label: load_data-og_nadm
#| output: false
recent_date = "202405"

geom_d0 = (geopandas
    .read_file(
        filename = (path2ogdata_nadm + "/nadm-" + 
                    recent_date + "/nadm_d0.shp"))
    .unary_union)
  
geom_d1 = (geopandas
    .read_file(
        filename= (path2ogdata_nadm + "/nadm-" + 
                   recent_date + "/nadm_d1.shp"))
    .unary_union)

geom_d2 = (geopandas
    .read_file(
        filename= (path2ogdata_nadm +"/nadm-" + 
                   recent_date +"/nadm_d2.shp"))
    .unary_union)

geom_d3 = (geopandas
    .read_file(
        filename= (path2ogdata_nadm + "/nadm-" + 
                   recent_date + "/nadm_d3.shp"))
    .unary_union)

geom_d4 = (geopandas
    .read_file(
        filename= (path2ogdata_nadm + "/nadm-" + 
                   recent_date + "/nadm_d4.shp"))
    .unary_union)

dict_colours_msm = dict(
    d0 = "#ffff00",
    d1 = "#ffd37f",
    d2 = "#e69800", 
    d3 = "#e60000", 
    d4 = "#730000")

# %% [markdown]
"""
Nunc vitae ligula magna. Mauris eu urna non lacus suscipit 
maximus. Nullam sodales porttitor magna quis rhoncus. Vestibulum 
elementum nibh quis quam cursus interdum. Vestibulum sit amet justo ut 
ex molestie rhoncus. Praesent tempus posuere urna, vel rutrum quam 
maximus blandit. Vivamus sed dui eu leo euismod congue. Curabitur in 
ante ut ligula finibus porttitor. Fusce iaculis odio et erat finibus, 
egestas vulputate nunc sollicitudin. Cras sollicitudin risus eleifend 
pharetra tincidunt. Quisque eleifend fringilla maximus. Vivamus vitae 
cursus enim.
"""

# %%
#| label: create-sf_sequia_202405
# - - Resta de poligonos de sequias - - #
# ~ Isolate D0: D0 - D1 ~ #
real_d0 = geopandas.GeoDataFrame({
    'cat_sequia': ["D0"],
    'geometry': (geom_d0).difference(geom_d1)})

# ~ Isolate D1: D1 - D2 ~ #
real_d1 = geopandas.GeoDataFrame({
    'cat_sequia': ["D1"],
    'geometry': (geom_d1).difference(geom_d2)})

# ~ Isolate D2: D2 - D3 ~ #
real_d2 = geopandas.GeoDataFrame({
    'cat_sequia': ["D2"],
    'geometry': (geom_d2).difference(geom_d3)})

# ~ Isolate D3: D3 - D4 ~ #
real_d3 = geopandas.GeoDataFrame({
    'cat_sequia': ["D3"],
    'geometry': (geom_d3).difference(geom_d4)})

# ~ Isolate D4: D4 ~ #
real_d4 = geopandas.GeoDataFrame({
    'cat_sequia': ["D4"],
    'geometry': geom_d4})

# - - Crear el GeoDataFrame de las sequias del mes - - #
sf_sequia_202405 = pd.concat([real_d0, real_d1, real_d2, real_d3, real_d4])

# %% [markdown]
"""
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean eu purus 
mattis, ultrices enim eget, efficitur nisl. Nulla ipsum purus, efficitur 
non dignissim eget, consectetur a erat. Vestibulum ante ipsum primis in 
faucibus orci luctus et ultrices posuere cubilia curae; Vivamus feugiat 
finibus urna, vel fermentum tortor sagittis eu. Vestibulum ultrices, 
nunc quis mollis fermentum, nibh odio finibus ante, at scelerisque 
turpis neque sed odio. Praesent ullamcorper velit dui, sed ultricies ex 
eleifend id. Fusce molestie massa tempus odio ultrices, quis dignissim 
libero maximus. Proin posuere vestibulum eros, at aliquam tellus 
convallis in. Nunc a dictum mauris. Proin tincidunt erat erat, vitae 
vulputate mi placerat vitae. Aenean scelerisque, turpis a varius congue, 
diam mi consectetur metus, eu pulvinar dui nisl nec neque.

Suspendisse egestas elementum convallis. Praesent cursus dictum magna, 
non lacinia nibh vehicula et. Ut auctor congue tellus eu interdum. Nam 
non blandit odio, non pretium dolor. Vestibulum facilisis tincidunt 
elit, in ornare dolor pulvinar id. Vivamus id purus in nisl varius 
posuere at id nunc. Fusce id lacus porta, euismod tellus a, tincidunt 
tortor. Sed euismod turpis id urna iaculis, sit amet iaculis justo 
efficitur. In sollicitudin est eu venenatis tincidunt. Maecenas commodo 
neque tincidunt purus vulputate, et congue augue tempor. Nulla non 
ullamcorper arcu. Aliquam sed dolor fermentum, ornare leo sit amet, 
pretium turpis. In pretium posuere libero id rhoncus. Fusce vestibulum, 
nulla ut porttitor pretium, felis sapien pretium arcu, ac convallis 
massa lacus sit amet ligula.

Interdum et malesuada fames ac ante ipsum primis in faucibus. Sed dui 
felis, suscipit a felis ac, venenatis ultrices erat. Nulla semper mauris 
eu justo vulputate vulputate. Morbi nibh eros, elementum in risus quis, 
malesuada commodo ante. Vivamus tincidunt dui id sollicitudin 
cursus. Quisque a aliquam erat. Cras lobortis suscipit massa nec 
vulputate.

Fusce ultrices posuere nulla eget ultricies. Vivamus lorem nibh, varius 
nec commodo id, dignissim at eros. Phasellus vitae elit eros. Etiam in 
aliquet ex. Nullam ut posuere quam, vitae scelerisque diam. Sed porta, 
nibh nec imperdiet luctus, mi orci volutpat est, id laoreet elit metus 
ut quam. Pellentesque ut sem arcu. Suspendisse condimentum nec mi 
egestas imperdiet.

Donec gravida dolor augue, eu consequat nisi bibendum eget. Etiam 
facilisis varius urna vitae hendrerit. Pellentesque maximus orci vitae 
sem fringilla, a congue nisi tristique. Phasellus molestie metus vitae 
tempus varius. Nulla quis ornare lectus. Nam congue sapien sed lorem 
efficitur ullamcorper. Ut ex turpis, pellentesque vitae augue et, tempor 
fermentum est.
"""