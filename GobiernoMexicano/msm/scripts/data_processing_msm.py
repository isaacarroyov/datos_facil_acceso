# %% [markdown]
# ---
# title: 'Sequía en México'
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

En este documento GitHub Flavored Markdown se encuentra documentado el 
código usado para la extracción, transformación, estandarización y la 
creación de nuevos conjuntos de datos a partir del registro de sequía en 
los municipios del país del 
[**Monitor de Sequía de México (MSM)**](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico).

A través del registro de sequía en los municipios se espera tener 3 bases 
de datos:

1. El registro de sequía en formato _tidy_
2. El registro del tiempo de duración del tipo de sequía (racha)
3. El registro del tiempo de duración máximo del tipo de sequía 
(racha máxima)
"""

# %% [markdown]
"""
## Descarga y transformación del registro de sequía en los municipios

Como primer paso es modificar la base de datos del MSM para que este en 
formato _tidy_, ya que originalmente las columnas son la fecha del registro.
"""

#%% 
#| label: load-msm
import pandas as pd

msm_og = pd.read_excel(io = "".join(["https://smn.conagua.gob.mx/tools/",
                            "RESOURCES/Monitor%20de%20Sequia%20en%",
                            "20Mexico/MunicipiosSequia.xlsx"]),
                       dtype= 'object')

# %% [markdown]
"""
> [!NOTE]  
> La tabla muestra únicamente una muestra de las columnas de fecha 
> del registro
"""

# %% 
#| label: show-msm_og-sample
#| echo: false
from numpy.random import randint, seed
from IPython.display import Markdown

seed(11)
random_date_cols = randint(10, 300, size = 4).tolist()

Markdown(
  msm_og
  .sample(n = 5)
  .iloc[:, list(range(9)) + random_date_cols]
  .to_markdown(index= False))

# %% [markdown]
"""
A partir de esta tabla, enlistan los cambios necesarios:

1. Limpiar los nombres de las columnas
2. Hacer el cambio de _wide format_ a _long format_
3. Eliminar los registros Agosto 2003 y Febrero 2004
"""

# %% [markdown]
"""
### Limpiar los nombres de las columnas
"""

# %%
#| label: trans-cols_clean_names

from janitor import clean_names
msm_og = msm_og.clean_names(remove_special = True)

# %%
#| label: show-msm_og_clean_names-sample
#| echo: false

seed(11)
random_date_cols = randint(10, 300, size = 4).tolist()

Markdown(
  msm_og
  .sample(n = 5)
  .iloc[:, list(range(9)) + random_date_cols]
  .to_markdown(index= False))

# %% [markdown]
"""
### Hacer el cambio de _wide format_ a _long format_
"""

# %%
#| label: trans_df-wide2long

# Wide to Long
msm_long = pd.melt(
    frame = msm_og,
    id_vars = msm_og.columns.tolist()[:9],
    var_name = 'full_date',
    value_name = 'sequia')

# Los espacios vacíos o NaN son en realidad registros Sin sequia
msm_long['sequia'] = msm_long['sequia'].fillna("Sin sequia")

# %%
#| label: show-msm_long-sample
#| echo: false

Markdown(
  msm_long
  .sample(n = 5, random_state= 11)
  .to_markdown(index= False))

# %% [markdown]
"""
### Eliminar los registros Agosto 2003 y Febrero 2004

En el documento XLSX, en el apartado de Notas, se comunica que por 
factores externos, el MSM no se elaboró en esas fechas.

Por lo que se crean _máscaras_ para filtrar esas fechas
"""
# %%
#| label: trans_cols-msm_long_full_date-filter_dates

# 1. Limpiar las columnas de caracteres innecesarios
msm_long['full_date'] = (msm_long['full_date']
                         .str.replace("_00_00_00", "")
                         .str.replace("_", "-"))

# 2. Transformar a np.datetime
msm_long['full_date'] = pd.to_datetime(arg = msm_long['full_date'],
                                       errors= 'coerce')

# 3. Crear las máscaras de fechas
mask_2003 = msm_long['full_date'].dt.year == 2003
mask_2004 = msm_long['full_date'].dt.year == 2004
mask_agosto = msm_long['full_date'].dt.month == 8
mask_febrero = msm_long['full_date'].dt.month == 2

mask_agosto_2003 = mask_2003 & mask_agosto
mask_febrero_2004 = mask_2004 & mask_febrero

mask_total = mask_agosto_2003 | mask_febrero_2004

# 4. Filtrar aquellas fechas en las que no hubo MSM
db_msm = msm_long[~mask_total]

# %%
#| label: show-db_msm-sample
#| echo: false

Markdown(
  db_msm
  .sample(n = 5, random_state= 11)
  .to_markdown(index= False))

# %% [markdown]
"""
## Cálculo de rachas y rachas máximas

A partir de los datos procesados (**`db_msm`**) se irá iterando por cada 
uno de los municipios para obtener sus rachas de sequía y a partir de estas 
las de mayor duración.
"""

# %% [markdown]
"""
### Función para conteo de rachas

El resultado de esta función será necesaria para la función de 
rachas máximas
"""

# %%
#| label: create-func_count_sequia_mun

def func_count_sequia_mun(datframe, clave_mun):
    # Aislar el pandas.DataFrame a los datos de un solo municipio
    datframe_mun = datframe.query(f"cve_concatenada == '{clave_mun}'")

    # Obtener los valores de sequia y las fechas en la que fueron tomadas
    lista_sequias = datframe_mun['sequia'].values.tolist()
    lista_fechas = datframe_mun['full_date'].values.tolist()

    # Iniciar contador de rachas: Se inicia con uno porque se asume que ya va 
    # un tiempo con un tipo de categoria hasta que haya un cambio
    count = 1
    lista_count = list()

    # Iterar a partir del segundo elemento hasta el final
    for i in range(1, len(lista_sequias)):
        # Comparar si el elemento anterior es igual al que se tiene 
        # en la iteracion
        if lista_sequias[i] == lista_sequias[i-1]:
          # De ser idéntico, se aumenta la racha
          count += 1
        else:
          # De no ser idéntico, se guarda la fecha de inicio y fin, y el 
          # conteo de la racha
          lista_count.append(
            (clave_mun,
              lista_sequias[i-1],
              count,
              lista_fechas[i-count],
              lista_fechas[i-1]))
          
          # Se reinicia el conteo de las rachas
          count = 1

    # Toda la información se guarda en una lista donde cada elemento es 
    # una tupla
    lista_count.append(
      (clave_mun,
        lista_sequias[-1],
        count,
        lista_fechas[-count],
        lista_fechas[-1]))

    # Se transforma la lista de tuplas en un pandas.DataFrame
    datframe_rachas = pd.DataFrame(
      data= lista_count,
      columns = ['cve_concatenada',
                  'sequia',
                  'racha',
                  'full_date_start_racha',
                  'full_date_end_racha'])
    # Los datos de las fechas estan en formato UNIX, por lo que se tienen 
    # que transformar a np.datetime64
    datframe_rachas['full_date_start_racha'] = pd.to_datetime(
      arg = datframe_rachas['full_date_start_racha'])
    datframe_rachas['full_date_end_racha'] = pd.to_datetime(
      arg = datframe_rachas['full_date_end_racha'])

    # Calcular la diferencia de dias entre las fechas (el resultado es 
    # un string con el numero de días + la palabra 'days')
    datframe_rachas['racha_dias'] = (
       datframe_rachas['full_date_end_racha'] - 
       datframe_rachas['full_date_start_racha'])
    
    # Eliminar la palabra 'days' y transformar a número
    datframe_rachas['racha_dias'] = (datframe_rachas['racha_dias']
                                     .astype(str)
                                     .str.replace(" days", "")
                                     .astype(int))
    
    return datframe_rachas

# %% [markdown]
"""
### Función para aislar las rachas máximas
"""

# %% 
#| label: create-func_get_max_rachas
def func_get_max_rachas(datframe):
    idx_max = (datframe
               # Agrupar por tipo de sequia
               .groupby("sequia")
               # De la columna de racha_dias
               ["racha_dias"]
               # ... obtener el índice del valor máximo
               .idxmax()
               # Se obtienen los valores de los índices
               .values
               # Se transformar en lista (de índices)
               .tolist())
    # Con la lista de índices se crea un nuevo pandas.DataFrame
    datframe_max_rachas = datframe.loc[idx_max]
    return datframe_max_rachas

# %% [markdown]
"""
## Aplicar las funciones en la base de datos

Con las funciones listas, se obtienen las bases de datos de rachas de 
sequía junto con las rachas máximas de sequía
"""

# %%
#| label: create-db_rachas_mun-db_rachas_max_mun
lista_cve_concatenada = db_msm['cve_concatenada'].unique().tolist()
lista_dfs_rachas = list()
lista_dfs_rachas_max = list()

for i in range(len(lista_cve_concatenada)):
    # Obtener rachas
    df_rachas = func_count_sequia_mun(
       datframe = db_msm,
       clave_mun = lista_cve_concatenada[i])
    # Aislar rachas máximas
    df_rachas_max = func_get_max_rachas(datframe = df_rachas)

    # Guardar todos los `pandas.DataFrame`s en listas
    lista_dfs_rachas.append(df_rachas)
    lista_dfs_rachas_max.append(df_rachas_max)

# Concatenar la lista de pandas.DataFrame
db_rachas_mun = pd.concat(lista_dfs_rachas).reset_index(drop=True)
db_rachas_max_mun = pd.concat(lista_dfs_rachas_max).reset_index(drop=True)

# %% [markdown]
"""
## Guardar bases de datos
"""

# %% 
#| label: define_paths2save

import os

# Cambiar al folder principal del repositorio
os.chdir("../../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2msm = path2gobmex + "/msm"

# %% [markdown]
"""
### Base de datos de Sequía en Municipios

Muestra del archivo **`sequia_municipios.csv.bz2`**
"""

# %%
#| label: save-db_ms
db_msm.to_csv(
   path_or_buf = path2msm + "/sequia_municipios.csv.bz2",
   compression = "bz2",
   index = False)

# %%
#| label: show-db_msm
#| echo: false
Markdown(
   db_msm
   .sample(n = 5, random_state= 13)
   .to_markdown(index = False))

# %% [markdown]
"""
### Base de datos de Rachas de Sequía en Municipios

Muestra del archivo **`rachas_sequia_municipios.csv`**
"""

# %%
#| label: save-db_rachas_mun
db_rachas_mun.to_csv(
   path_or_buf = path2msm + "/rachas_sequia_municipios.csv",
   index = False)

# %%
#| label: show-db_rachas_mun
#| echo: false
Markdown(
   db_rachas_mun
   .sample(n = 5, random_state= 13)
   .to_markdown(index = False))

# %% [markdown]
"""
### Base de datos de Máximas Rachas de Sequía en Municipios

Muestra del archivo **`max_rachas_sequia_municipios.csv`**
"""

# %%
#| label: save-db_rachas_max_mun
db_rachas_max_mun.to_csv(
   path_or_buf = path2msm + "/max_rachas_sequia_municipios.csv",
   index = False)

# %%
#| label: show-db_rachas_max_mun
#| echo: false
Markdown(
   db_rachas_max_mun
   .sample(n = 5, random_state= 13)
   .to_markdown(index = False))
