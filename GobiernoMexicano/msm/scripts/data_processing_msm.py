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
#| echo: false
#| label: show-msm_og-sample
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
#| echo: false
#| label: show-msm_og_clean_names-sample

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
#| echo: false
#| label: show-msm_long-sample
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
datos_sequia_municipios = msm_long[~mask_total]

# %%
#| echo: false
#| label: show-datos_sequia_municipios-sample
Markdown(
  datos_sequia_municipios
  .sample(n = 5, random_state= 11)
  .to_markdown(index= False))

# %% [markdown]
"""
## Cálculo de rachas y rachas máximas
"""

# %%
#| echo: false

# TODO: Documentar la funciónes de conteo de rachas y rachas máximas

# %% [markdown]
"""
```Python

def contar_rachas_municipio(dataframe, cve_concatenada_mun):
	dataframe_mun = dataframe.query(f"cve_concatenada == {int(cve_concatenada_mun)}")
	lista_sequias = dataframe_mun['sequia'].values.tolist()
	lista_fechas = dataframe_mun['full_date'].values.tolist()
	count = 1
	lista_count = list()

	for i in range(1, len(lista_sequias)):
		if lista_sequias[i] == lista_sequias[i-1]:
			count += 1
		else:
			lista_count.append((int(cve_concatenada_mun), lista_sequias[i-1], count, lista_fechas[i-count], lista_fechas[i-1]))
			count = 1
	lista_count.append((int(cve_concatenada_mun), lista_sequias[-1], count, lista_fechas[-count], lista_fechas[-1]))

	dataframe_rachas = pd.DataFrame(lista_count, columns = ['cve_concatenada','sequia','racha','full_date_start_racha','full_date_end_racha'])
	dataframe_rachas['full_date_start_racha'] = pd.to_datetime(dataframe_rachas['full_date_start_racha'])
	dataframe_rachas['full_date_end_racha'] = pd.to_datetime(dataframe_rachas['full_date_end_racha'])
	dataframe_rachas['racha_dias'] = (dataframe_rachas['full_date_end_racha']-dataframe_rachas['full_date_start_racha'])

	return dataframe_rachas

def obtener_rachas_maximas(dataframe, group_by = "sequia", rachas_name = "racha_dias"):
	idx_max = dataframe.groupby(group_by)[rachas_name].idxmax().values.tolist()
	return dataframe.loc[idx_max]



datos_sequia_municipios = pd.read_csv(
	filepath_or_buffer= path2msmdata + "/sequia_municipios.csv.bz2")


lista_cve_concatenada = datos_sequia_municipios['cve_concatenada'].unique().tolist()
lista_dfs_rachas = list()
lista_dfs_rachas_max = list()

for i in range(len(lista_cve_concatenada)):
    print(f"Iteración: {i}")
    df_rachas = contar_rachas_municipio(dataframe = datos_sequia_municipios,
                                        cve_concatenada_mun = lista_cve_concatenada[i])
    print("Lista las rachas")
    df_rachas_max = obtener_rachas_maximas(dataframe = df_rachas)
    print("Lista las rachas máximas")
    lista_dfs_rachas.append(df_rachas)
    lista_dfs_rachas_max.append(df_rachas_max)


df_rachas_mun = pd.concat(lista_dfs_rachas).reset_index(drop=True)

df_rachas_max_mun = pd.concat(lista_dfs_rachas_max).reset_index(drop=True)
```

"""