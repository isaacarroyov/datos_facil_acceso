# %% [markdown]
# ---
# title: 'Procesamiento y transformación de datos: Sequía en México'
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
#     wrap: none
# execute:
#   echo: true
#   eval: true
#   warning: false
# ---

# %% [markdown]
"""
## Introducción y objetivos

En este documento se encuentra documentado el 
código usado para la extracción, transformación, estandarización y la 
creación de nuevos conjuntos de datos a partir del registro de sequía en 
los municipios del país del 
[**Monitor de Sequía de México (MSM)**](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico).

A través del registro de sequía en los municipios se espera tener 4 bases 
de datos:

1. El registro mensual o quincenal (depende de la fecha) de sequía en formato _tidy_
2. El registro diario de sequía en formato _tidy_
3. El registro del tiempo de duración del tipo de sequía (racha)
4. El registro del tiempo de duración máximo del tipo de sequía 
(racha máxima)
"""

# %% 
#| label: load-libraries
import pandas as pd
from janitor import clean_names
from numpy.random import randint, seed
from IPython.display import Markdown

# %% [markdown]
"""
## Descarga y transformación del registro de sequía en los municipios

Como primer paso es modificar la base de datos del MSM para que este en 
formato _tidy_, ya que originalmente las columnas son la fecha del registro.
"""

# %% 
#| label: load_1st_transform-msm_og
msm_og = pd.read_excel(
   io = "".join(["https://smn.conagua.gob.mx/tools/RESOURCES/Monitor%20de",
                 "%20Sequia%20en%20Mexico/MunicipiosSequia.xlsx"]),
   dtype= 'object')

msm_og = msm_og.clean_names(remove_special = True)

# %% [markdown]
"""
> [!NOTE]  
> La tabla muestra únicamente una muestra de las columnas de fecha 
> del registro
"""

# %% 
#| label: show-msm_og-sample
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
A partir de esta tabla, enlistan los cambios necesarios:

1. Hacer el cambio de _wide format_ a _long format_
2. Eliminar los registros Agosto 2003 y Febrero 2004
<!-- TODO: ESCRIBIR CORRECTAMENTE LOS PASOS A SEGUIR EN EL TRABAJO -->
"""

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
### Asignar unidad de fecha a la columna `full_date`

Tras la transformación _wide2long_, hace falta transformar la columna 
`full_date` a lo que es, una fecha. 

Previo transformar los valores a `np.datetime`, se tiene que eliminar los 
caracteres `'_00_00_00'` y sustiuir los guiones bajos (`_`) por guiones 
medios (`-`)
"""

# %%
#| label: trans_cols-msm_long_full_date

msm_long['full_date'] = (msm_long['full_date']
                         .str.replace("_00_00_00", "")
                         .str.replace("_", "-"))

msm_long['full_date'] = pd.to_datetime(arg = msm_long['full_date'],
                                       errors= 'coerce')


# %% [markdown]
"""
## El registro de sequía en formato _tidy_ (registro mensual, quincenal y diario)

Para esta ocasión, el registro de sequía se completará con el tipo de 
sequía diaria, esto asumiendo que cuando la publicación era mensual 
representa la sequía del mes del registro, mientras que para las 
publicaciones quincenales es de los últimos 15 días.

> _Ejemplo:_
> 
> • _Fecha publicación y tipo de sequia : Mayo 31 del 2005, D3_
> 
> Se traduce a que del Mayo 01 - Mayo 31 de 2005, todos los días serán 
> etiquetados con sequía D3
>
> • _Fecha publicación y tipo de sequia : Mayo 31 del 2024, D3_
> 
> Se traduce a que del Mayo 01 - Mayo 14 de 2024, todos los días serán 
> etiquetados con sequía D3
"""

# %% [markdown]
"""
### Función para completar días

Esta función toma un grupo (un municipios) y completará la serie de tiempo 
por día. Con los valores `NaN` de sequía, se llenarán con el registro 
siguiente al que se tiene (que no sea `NaN`)
"""
# %%
#| label: create-func_llenado_dias_sequia
def func_llenado_dias_sequia(group):
    
    # La fecha inicia en Enero 01, 2003
    min_date = "2003-01-01"
    
    # La fecha final es la última actualización disponible
    max_date = group['full_date'].max().strftime("%Y-%m-%d")

    # Rango con frecuencia de 1 día
    date_range = pd.date_range(start=min_date, end=max_date, freq='D')

    # Completar las fechas del grupo
    complete_group = group.set_index('full_date').reindex(date_range)

    # Llenado de NaNs
    complete_group = complete_group.bfill()

    # Reset index y renombralo como 'full_date'
    complete_group = (complete_group
                      .reset_index(drop = False)
                      .rename(columns = {'index': 'full_date'}))

    return complete_group

# %% [markdown]
"""
Se usarán únicamente las columnas de las claves de los municipios
"""
# %%
#| label: create-msm_long_filled

msm_long_filled = (msm_long[['full_date','cve_concatenada', 'sequia']]
  .groupby(by = 'cve_concatenada')
  .apply(lambda x: func_llenado_dias_sequia(group=x))
  .reset_index(drop = True))

# %%
#| label: show-msm_long_filled
#| echo: false

Markdown(
   msm_long_filled
   .sample(n = 5, random_state= 11)
   .to_markdown(index = False))

# %% [markdown]
"""
## Cálculo de rachas y rachas máximas

A partir de los datos procesados (**`msm_long_filled`**) se irá iterando 
por cada uno de los municipios para obtener sus rachas de sequía y a partir 
de estas las de mayor duración.
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

lista_cve_concatenada = msm_long_filled['cve_concatenada'].unique().tolist()
lista_dfs_rachas = list()
lista_dfs_rachas_max = list()

for i in range(len(lista_cve_concatenada)):
    # Obtener rachas
    df_rachas = func_count_sequia_mun(
       datframe = msm_long_filled,
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
Muestra de `db_rachas_mun`
"""

# %% 
#| label: show-db_rachas_mun
#| echo: false

Markdown(
   db_rachas_mun
   .sample(n = 5, random_state = 11)
   .to_markdown(index = False))

# %% [markdown]
"""
Muestra de `db_rachas_max_mun`
"""

# %% 
#| label: show-db_rachas_max_mun
#| echo: false

Markdown(
   db_rachas_max_mun
   .sample(n = 5, random_state = 11)
   .to_markdown(index = False))

# %% [markdown]
"""
## Reasignar nombre de Estados, Municipios y Cuencas

A partir de la creación de `msm_long_filled`, todos los conjuntos de datos 
excluyen las claves y nombres de los Estados, Municipios (este únicamente 
el nombre) y Cuencas. 

Por lo que se completaran a las bases de datos de interés, previo a ser 
guardadas.
"""

# %%
#| label: load-paths

import os

# Cambiar al folder principal del repositorio
os.chdir("../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2msm = path2gobmex + "/msm"

# %% [markdown]
"""
Claves y nombres de municipios y entidades
"""

# %%
#| label: create-cve_nom_ent_mun_cuenca

cve_nom_mun = pd.read_csv(
   filepath_or_buffer = path2gobmex + "/cve_nom_municipios.csv",
   dtype= "object")

cve_nom_mun_cuenca = (msm_long
                      .groupby(['cve_concatenada',
                                'org_cuenca',
                                'clv_oc',
                                'con_cuenca',
                                'cve_conc'])
                      .nunique()
                      .reset_index()
                      [['cve_concatenada',
                        'org_cuenca',
                        'clv_oc',
                        'con_cuenca',
                        'cve_conc']])

cve_nom_ent_mun_cuenca = (pd.merge(left = cve_nom_mun_cuenca,
                                   right= cve_nom_mun,
                                   how = 'left',
                                   left_on = 'cve_concatenada',
                                   right_on = 'cve_geo')
                          .drop(columns = ['cve_concatenada']))

# %%
#| label: show-cve_nom_ent_mun_cuenca

Markdown(
   cve_nom_ent_mun_cuenca
   .sample(n = 5, random_state = 11)
   .to_markdown(index = False))

# %% [markdown]
"""
Unir con las bases de datos de interés y reordenar las columnas
"""

# %%
#| label: trans_dfs-unir_cve_nom_ent_mun_cuenca_a_dbs

msm_long = (pd.merge(
    left = msm_long[['cve_concatenada', 'full_date', 'sequia']],
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_geo')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_geo',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'full_date', 'sequia']])

msm_long_filled = (pd.merge(
    left = msm_long_filled,
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_geo')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_geo',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'full_date', 'sequia']])

db_rachas_mun = (pd.merge(
    left = db_rachas_mun,                      
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_geo')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento y selección de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_geo',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'sequia', 'full_date_start_racha', 'full_date_end_racha',
    'racha_dias']])

db_rachas_max_mun = (pd.merge(
    left = db_rachas_max_mun,
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_geo')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento y selección de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_geo',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'sequia', 'full_date_start_racha', 'full_date_end_racha',
    'racha_dias']])

# %% [markdown]
"""
## Guardar bases de datos
"""

# %% [markdown]
"""
### Bases de datos de Sequía en Municipios

Se crearán dos bases de datos a partir de este procesamiento de datos: 

* **`msm_long`** : Datos de sequía de la CONAGUA en _long format_
* **`msm_long_filled`** : Datos de sequía diarios en _long format_ (Modificado)

Para ambos casos se eliminarán las los registros de Agosto 2003 y 
Febrero 2004. En el documento XLSX, en el apartado de Notas, se comunica que por 
factores externos, el MSM no se elaboró en esas fechas.

Por lo que se crean _máscaras_ para filtrar esas fechas
"""
# %%
#| label: remove-agosto_2003-febrero_2004

# 1. Se crean las máscaras para los filtros
#   1.1 Para los datos de sequía de la CONAGUA en long format
mask_dates_nowork_msm_long = (
    # Agosto 2003
    ((msm_long['full_date'].dt.year == 2003) & 
     (msm_long['full_date'].dt.month == 8))
    |
    # Febrero 2004
    ((msm_long['full_date'].dt.year == 2004) & 
     (msm_long['full_date'].dt.month == 2))
)
#   1.2 Para los datos de sequía diarios en long format (Modificado)
mask_dates_nowork_msm_long_filled = (
    # Agosto 2003
    ((msm_long_filled['full_date'].dt.year == 2003) & 
     (msm_long_filled['full_date'].dt.month == 8))
    |
    # Febrero 2004
    ((msm_long_filled['full_date'].dt.year == 2004) & 
     (msm_long_filled['full_date'].dt.month == 2))
)

# %% [markdown]
"""
Las máscaras identifican las fechas donde no hubo MSM, sin embargo lo que 
busca es **omitirlas**, no aislarlas, es por eso que para crear la 
base de datos se _niegan_ las condiciones, para que se incluya todo lo que 
no cumpla la máscara.

Para negar las máscaras, se usa **`~`**
"""

# %%
#| label: create-db_msm_og-db_msm_mod

# Datos de sequía de la CONAGUA en long format
db_msm_og = msm_long[~mask_dates_nowork_msm_long]

# Datos de sequía diarios en long format (Modificado)
db_msm_mod = msm_long_filled[~mask_dates_nowork_msm_long_filled]

# %% [markdown]
"""
Como último paso se guardan ambas bases de datos
"""

# %% [markdown]
"""
Muestra del archivo **`sequia_municipios.csv.bz2`**
"""

# %%
#| label: save-db_msm_og

db_msm_og.to_csv(
   path_or_buf = path2msm + "/sequia_municipios.csv.bz2",
   compression = "bz2",
   index = False)

# %%
#| label: show-db_msm_og-sample
#| echo: false

Markdown(
  db_msm_og
  .sample(n = 5, random_state= 11)
  .to_markdown(index= False))

# %% [markdown]
"""
Muestra del archivo **`sequia_municipios_days.csv.bz2`**
"""

# %%
#| label: save-db_msm_mod

db_msm_mod.to_csv(
   path_or_buf = path2msm + "/sequia_municipios_days.csv.bz2",
   compression = "bz2",
   index = False)

# %%
#| label: show-db_msm_mod-sample
#| echo: false

Markdown(
  db_msm_mod
  .sample(n = 5, random_state= 11)
  .to_markdown(index= False))


# %% [markdown]
"""
### Base de datos de Rachas de Sequía en Municipios

> [!WARNING]
> 
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se publicó el registro del Monitor de Sequía de México

Muestra del archivo **`rachas_sequia_municipios.csv`**
"""

# %%
#| label: save-db_rachas_mun

db_rachas_mun.to_csv(
   path_or_buf = path2msm + "/rachas_sequia_municipios.csv",
   index = False)

# %%
#| label: show-db_rachas_mun_final
#| echo: false

Markdown(
   db_rachas_mun
   .sample(n = 5, random_state= 13)
   .to_markdown(index = False))

# %% [markdown]
"""
### Base de datos de Máximas Rachas de Sequía en Municipios

> [!WARNING]
> 
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se publicó el registro del Monitor de Sequía de México

Muestra del archivo **`max_rachas_sequia_municipios.csv`**
"""

# %%
#| label: save-db_rachas_max_mun

db_rachas_max_mun.to_csv(
   path_or_buf = path2msm + "/max_rachas_sequia_municipios.csv",
   index = False)

# %%
#| label: show-db_rachas_max_mun_final
#| echo: false

Markdown(
   db_rachas_max_mun
   .sample(n = 5, random_state= 13)
   .to_markdown(index = False))

# %% [markdown]
"""
> [!NOTE]
> 
> Fecha de actualización del Monitor de Sequía de 
México: `{python} msm_long['full_date'].max().strftime("%B %d, %Y")`
"""