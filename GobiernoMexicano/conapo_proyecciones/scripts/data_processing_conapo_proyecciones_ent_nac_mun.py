# %% [markdown]
# ---
# title: 'Proyecciones de población de México'
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
#   eval: false
#   warning: false
# ---

# %% [markdown]
"""
## Introducción

En este documento GitHub Flavored Markdown se encuentra documentado el 
código usado para la transformación y estandarización de los datos de la 
Proyección de población de México que emite el **Consejo Nacional de 
Población (CONAPO)**, tanto para nivel Nacional, Estatal y Municipal.

> [!NOTE]
> 
> Cuando se habla de una _estandarización_ es completamente subjetivo, 
> ya que la manera en la que están estructuradas las bases de datos pueden 
> ser las ideales para otro tipo de usuarios. En el caso personal una 
> estrucura [_tidy_](https://tidyr.tidyverse.org/articles/tidy-data.html#tidy-data) 
> es la que mejor se ajusta a mis requerimientos y proyectos.
"""

# %%
import pandas as pd
import os

# Cambiar al folder principal del repositorio
os.chdir("../../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2conapo = path2gobmex + "/conapo_proyecciones"

# %% [markdown]
"""
## Población a mitad e inicio de año de los estados de México (1950-2070)
"""

# %%
path2conapoent = path2conapo + "/entidades"

# %% [markdown]
"""
> [!NOTE]
> 
> * Actualización de los datos: Agosto 04, 2023.
> * Este código fue originalmente creado el 21 de agosto de 2023

Los datos publicados por la CONAPO incluyen 9 archivos:

* 0_Pob_Inicio_1950_2070.xlsx
* 0_Pob_Mitad_1950_2070.xlsx
* 1_Defunciones_1950_2070.xlsx
* 2_mig_inter_quinquen_proyecciones.xlsx
* 3_mig_interest_quinquenal_proyecciones.xlsx
* 4_Tasas_Especificas_Fecundidad_proyecciones.xlsx
* 5_Indicadores_demográficos_proyecciones.xlsx
* 6_Esperanza_Vida_Nacer_1950_2070.xlsx
* DICCIONARIO_2023_v3_07082023.pdf

De los cuales, para esta ocasión (y por ahora) se usarán 2:

* **0_Pob_Inicio_1950_2070.xlsx**
* **0_Pob_Mitad_1950_2070.xlsx**

> _Es común que en los cálculos de tasado por cada 1,000 (mil) ó 100,000 
> (cien mil) habitantes se use la **población a mitad de año** en lugar de 
> la población al inicio del año. Sin embargo, pertenecen a la misma base 
> de datos e información._
"""
# %%
df_inicio = pd.read_excel(path2conapoent + "/0_Pob_Inicio_1950_2070.xlsx") 
df_mitad = pd.read_excel(path2conapoent + "/0_Pob_Mitad_1950_2070.xlsx")

# %% [markdown]
"""
### Cambios a los `pandas.DataFrame`s

Ambos conjuntos de datos tienen las mismas columnas con el mismo 
nombre, a continuación se muestra un ejemplo: 

|   RENGLON |   AÑO | ENTIDAD   |   CVE_GEO |   EDAD | SEXO    |   POBLACION |
|----------:|------:|:----------|----------:|-------:|:--------|------------:|
|    397482 |  2024 | Campeche  |         4 |     80 | Mujeres |        1007 |
|    687945 |  2064 | Coahuila  |         5 |      2 | Hombres |       20189 |
|    156305 |  1990 | Veracruz  |        30 |     52 | Hombres |       20082 |

A continuación se enlistan las transformaciones y cambios que se le harán 
a ambos conjuntos de datos:

1. Renombrar columnas
2. Transformar la columna de códigos de las entidades
3. Unir ambos `pandas.DataFrame`s en uno solo
4. Renombrar los estados
"""
# %%
#| echo: false

# Código para obtener una muestra del `pandas.DataFrame` y convertirlo en 
# formato Markdown
from IPython.display import Markdown

print(df_mitad.sample(3).to_markdown(index=False))

# %% [markdown]
"""
### Renombrar columnas
"""
# %%
df_inicio = (df_inicio
  .rename(
      columns = {
          "AÑO": "n_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_ent",
          "EDAD": "edad",
          "SEXO": "genero",
          # Dejar en claro que es la población al inicio del año
          "POBLACION": "pob_start_year"})
  # Eliminar columna que no aporta en la base de datos
  .drop(columns = "RENGLON"))

df_mitad = (df_mitad
  .rename(
      columns= {
          "AÑO": "n_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_ent",
          "EDAD": "edad",
          "SEXO": "genero",
          # Dejar en claro que es la población a mitad del año
          "POBLACION": "pob_mid_year"})
  # Eliminar columna que no aporta en la base de datos
  .drop(columns = "RENGLON"))

# %% [markdown]
"""
### Transformar columna de códigos de estados

Los códigos de los estados (`cve_ent`) fueron leídos por Python como 
números en lugar de caracteres, por lo que tiene que se tiene que hacer 
ese cambio.
"""

# %%
df_inicio["cve_ent"] = (df_inicio["cve_ent"]
                        .apply(lambda x : f"0{x}" if x < 10 else str(x)))
df_mitad["cve_ent"] = (df_mitad["cve_ent"]
                       .apply(lambda x : f"0{x}" if x < 10 else str(x)))

# %% [markdown]
"""
### Unir ambos `pandas.DataFrame`s en uno solo
"""
# %%
db_proj_ent = (pd.merge(
    left = df_inicio,
    right = df_mitad.drop(columns = "entidad"),
    how = "left",
    on = ["n_year", "cve_ent", "edad","genero"])
  .reset_index(drop = True))

db_proj_ent["pob_mid_year"] = (db_proj_ent["pob_mid_year"]
                               .astype("Int64"))

# %% [markdown]
"""
### Renombrar el nombre de los estados

La manera en la que están escritos los nombres de algunos estados no son 
como comúnmente se nombran, por ejemplo, en la base de datos de la CONAPO, 
**Coahuila** esta bajo el nombre de _Coahuila de Zaragoza_.

Es por eso que se usarán los nombres _comunes_ de los estados, que se 
encuentran en el archivo `cve_nom_estados.csv`, que se encuentra en la 
carpeta `GobiernoMexicano`

"""
# %%
cve_nom_ent = pd.read_csv(path2gobmex + "/cve_nom_estados.csv")
cve_nom_ent["cve_ent"] = (cve_nom_ent["cve_ent"]
  .fillna(0)
  .apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x))))

list_cols_interes = [
  "n_year",
  "nombre_estado",
  "cve_ent",
  "edad",
  "genero",
  "pob_start_year",
  "pob_mid_year"]

db_proj_ent = (db_proj_ent
               .drop(columns="entidad")
               .merge(cve_nom_ent, on = "cve_ent")
               [list_cols_interes])

# %%
#| echo: false
(db_proj_ent
  .to_csv(path2conapo + "conapo_proj_ent-nac_inicio-mitad_1950-2070",
          index = False))



# %%
#| echo: false

# TODO: Crear conjuntos de datos donde se junten ambos géneros 
#       de todas las edades (para db_proj_ent)
