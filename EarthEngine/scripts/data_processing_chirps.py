# %% [markdown]
# ---
# title: Extracción y procesamiento de datos de lluvia
# subtitle: CHIRPS Daily via Google Earth Engine
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# jupyter: python3
# format:
#   pdf:
#     fontsize: 12pt
#     mainfont: Charter
#     geometry:
#       - top=0.6in
#       - bottom=0.6in
#       - left=1in
#       - right=1in
#     documentclass: report
#     number-sections: true
#     papersize: letter
#     fig-width: 5
#     fig-asp: 0.75
#     fig-dpi: 300
#     code-annotations: below
#     code-line-numbers: true
# 
# execute:
#   echo: true
#   eval: false
#   warning: false
# ---

# %% [markdown]
"""
# Sobre los datos

(Prueba de renderización)

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent 
dignissim, lacus sed tincidunt vehicula, tellus erat dictum libero, vel 
facilisis tellus ipsum eget lorem. Nunc lobortis congue nisl vitae cursus. 
Pellentesque eu fringilla elit, sed tristique neque. Aenean sagittis justo 
vitae posuere consectetur. Integer sit amet nisl consectetur, suscipit 
libero at, aliquet massa. Phasellus eget aliquet tortor. In semper, turpis 
id ornare interdum, risus elit placerat purus, a dapibus enim purus id mi. 
Curabitur suscipit, ante eu tincidunt feugiat, erat nunc pharetra elit, 
sit amet bibendum mi turpis in nibh. Ut non nisi imperdiet, dictum augue 
eget, bibendum mauris. Donec laoreet non arcu vel malesuada. Sed et dictum 
risus, eget tempor tellus.
"""

# %%
import pandas as pd # <1>
import seaborn as sns # <2>

# %% [markdown]
"""
1. Cargar Pandas
2. Importar para hacer datavis decente
"""

# %% [markdown]
"""
# Procesamiento 1

Praesent consectetur blandit felis ut fringilla. Fusce consequat, justo a 
ultricies mattis, est est rhoncus libero, id dapibus neque leo quis ligula. 
Praesent mattis, purus sed pretium tempus, justo ante euismod felis, 
malesuada tristique augue nisl ac urna. Praesent est sem, commodo id mi 
sit amet, dignissim varius diam. Phasellus tincidunt enim et molestie 
malesuada. Phasellus libero dolor, blandit id dolor vel, semper commodo 
purus. Donec eu aliquam turpis, et vestibulum ligula. Nulla aliquam massa 
et augue vulputate, non sodales sem placerat. Integer imperdiet orci quis 
augue efficitur, eget convallis libero tristique. Curabitur porta placerat 
sapien et porttitor^[Holi]. Sed massa nisl, accumsan in libero non, 
iaculis varius massa. Cras imperdiet nulla quis placerat posuere. 
In eu gravida lorem.
"""

# %%
import numpy as np

# %% [markdown]
"""
# Procesamiento 2

Fusce dictum neque quis cursus cursus. Nulla pulvinar **scelerisque** 
pharetra. In at ipsum ac neque interdum mollis. Orci varius _natoque_ 
penatibus et magnis dis parturient montes, nascetur ridiculus mus. Ut 
commodo ex vitae urna mattis, ut semper enim lobortis. Praesent eget 
consectetur leo, ut aliquet enim. Aenean nunc sapien, sodales in tortor 
id, dignissim tempus lorem.
"""

# %%
import ee

# %% [markdown]
"""

# Procesamiento 3

Aliquam fermentum est dapibus convallis aliquam. Praesent tincidunt 
sagittis finibus. Proin bibendum at felis nec blandit. Sed sapien ipsum, 
luctus et nisl et, eleifend tristique urna. Nam quis diam non orci 
hendrerit cursus. Pellentesque venenatis nunc lectus, a sagittis magna 
condimentum eu. Nullam semper elit at sollicitudin rhoncus. Donec cursus 
mi sapien, id dapibus lorem convallis id. Nulla ut arcu eu mauris malesuada 
aliquet et et purus. Nullam bibendum fringilla cursus. Nulla congue 
ligula et consequat pellentesque. Donec id turpis lectus. Vestibulum quam 
nunc, rhoncus non mi ac, placerat interdum eros.
"""

# %% 
import geemap

# %% [markdown]
"""
# Procesamiento 4

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %% 
import eemont