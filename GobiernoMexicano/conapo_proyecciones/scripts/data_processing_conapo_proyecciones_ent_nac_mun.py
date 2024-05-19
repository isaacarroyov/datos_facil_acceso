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
#| label: load-libraries-paths
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
#| label: load-path2conapoentidades
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
#| label: load-df_pob_ent_inicio-mid_year
df_pob_ent_inicio_year = pd.read_excel(
    path2conapoent + "/0_Pob_Inicio_1950_2070.xlsx") 
df_pob_ent_mid_year = pd.read_excel(
    path2conapoent + "/0_Pob_Mitad_1950_2070.xlsx")

# %% [markdown]
"""
### Cambios a los `pandas.DataFrame`s

Ambos conjuntos de datos tienen las mismas columnas con el mismo 
nombre, a continuación se muestra un ejemplo: 
"""

# %%
#| echo: false
#| label: tbl-sample-df-pob-ent-mid-year
# Código para obtener una muestra del `pandas.DataFrame` y convertirlo en 
# formato Markdown
from IPython.display import Markdown

Markdown(df_pob_ent_mid_year
  .sample(
      n = 3,
      random_state= 11)
  .to_markdown(index=False))

# %%[markdown]
"""
A continuación se enlistan las transformaciones y cambios que se le harán 
a ambos conjuntos de datos:

1. Renombrar columnas
2. Unir ambos `pandas.DataFrame`s en uno solo
3. Transformar la columna de códigos de las entidades
4. Renombrar los estados

A partir de este procesamiento, se crean dos bases de datos:

1. Base de datos completa, con la división de género y edades
2. Base de datos con la división de los géneros y uniendo las 
categorías de edades
"""

# %%
#| echo: false
# TODO: Crear categoría de edades (5 años) como en la ONU

# %% [markdown]
"""
### Renombrar columnas
"""
# %%
#| label: rename_cols-df_pob_ent_inicio-mitad_year
df_pob_ent_inicio_year = (df_pob_ent_inicio_year
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

df_pob_ent_mid_year = (df_pob_ent_mid_year
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
### Unir ambos `pandas.DataFrame`s en uno solo
"""
# %%
#| label: unir-df_pob_ent_inicio-mitad_year
db_proj_ent = (pd.merge(
    left = df_pob_ent_inicio_year,
    right = df_pob_ent_mid_year.drop(columns = "entidad"),
    how = "left",
    on = ["n_year", "cve_ent", "edad","genero"])
  .query("n_year <= 2070")
  .reset_index(drop = True))

db_proj_ent['pob_mid_year'] = db_proj_ent['pob_mid_year'].astype(int)

# %% [markdown]
"""
### Transformar columna de códigos de estados

Los códigos de los estados (`cve_ent`) fueron leídos por Python como 
números en lugar de caracteres, por lo que tiene que se tiene que hacer 
ese cambio.
"""

# %%
#| label: trans_cols-cve_ent
# Función lambda para modificar claves de estados
func_trans_cve_ent = lambda x : f"0{int(x)}" if x < 10 else str(int(x))

db_proj_ent["cve_ent"] = (df_pob_ent_inicio_year["cve_ent"]
                          .apply(func = func_trans_cve_ent))

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
#| label: trans_cols-rename_nombre_estado
cve_nom_ent = pd.read_csv(path2gobmex + "/cve_nom_estados.csv")
cve_nom_ent["cve_ent"] = (cve_nom_ent["cve_ent"]
  .fillna(0)
  .apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x))))

list_orden_cols_ent = [
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
               [list_orden_cols_ent])

# %% [markdown]
"""
### Crear un conjunto de datos de la población de ambos géneros sin distinción de la edad

Cuando se dice **sin distinción de edad** se habla de que se suma la 
población de todas las edades
"""
# %%
#| label: group-by_suma_pob_genero
db_proj_ent_all_ages = (db_proj_ent.groupby([
    "n_year",
    "nombre_estado",
    "cve_ent",
    "genero"])
    .sum()[["pob_start_year", "pob_mid_year"]]
    .reset_index())

# %% [markdown]
"""
Ahora se va a transformar los datos de _wide format_ a _long format_ para 
crear una columna donde se sumen las poblaciones de ambos géneros
"""
# %%
#| label: long2wide
db_proj_ent_all_ages = db_proj_ent_all_ages.pivot(
    index = ['n_year', 'nombre_estado', 'cve_ent'],
    columns= ['genero'],
    values = ['pob_start_year', 'pob_mid_year'])

# %% [markdown]
"""
Despues de aplicar `pivot` al `pandas.DataFrame`, se tiene un 
`pandas.DataFrame` con multi-índice en filas y columnas.
"""

# %%
#| echo: false
db_proj_ent_all_ages.sample(n = 3, random_state= 11)

# %% [markdown]
"""
Específicamente, se renombran las columnas con la combinación de 
`{poblacion a inicio o mitad de año}_{genero}`
"""

# %%
#| label: rename_cols-db_proj_ent_all_ages
# Renombrar columnas de población para que tengan como suffix el genero
db_proj_ent_all_ages.columns = ['_'.join(col) for col in 
                                db_proj_ent_all_ages.columns]

# Eliminar el multi-index (sin eliminar las columnas indice)
db_proj_ent_all_ages = db_proj_ent_all_ages.reset_index()

# %% [markdown]
"""
El resultado es el siguiente:
"""

# %%
#| echo: false
db_proj_ent_all_ages.sample(n = 3, random_state= 11)

# %% [markdown]
"""
Ahora solo falta crear la columna de la suma de las poblaciones de 
los géneros
"""

# %%
#| label: create_cols-pob_start-mid_year_Total
# Poblacion total a inicio de año
db_proj_ent_all_ages['pob_start_year_Total'] = (
    db_proj_ent_all_ages['pob_start_year_Hombres'] + 
    db_proj_ent_all_ages['pob_start_year_Mujeres'])

# Poblacion total a mitad de año
db_proj_ent_all_ages['pob_mid_year_Total'] = (
    db_proj_ent_all_ages['pob_mid_year_Hombres'] + 
    db_proj_ent_all_ages['pob_mid_year_Mujeres'])

# %% [markdown]
"""
El objetivo sigue siendo el mismo, mantener los datos _tidy_, por lo que 
se volverá a hacer la transformación de datos _wide format_ a _long format_.
"""

# %%
#| label: wide2long_pob_ent
db_proj_ent_all_ages = (pd.wide_to_long(
    df = db_proj_ent_all_ages,
    stubnames = ['pob_start_year', 'pob_mid_year'],
    i = ['n_year','nombre_estado', 'cve_ent'],
    j = 'genero',
    sep = "_",
    suffix=r'\w+')
  .reset_index())
# %% [markdown]
"""
## Población a mitad de año de los municipios de México (2015-2030)
"""

# %%
path2conapomun = path2conapo + "/municipios"

# %% [markdown]
"""
> [!NOTE]
> 
> * Actualización de los datos: Septiembre 02, 2019.
> * Este código fue originalmente creado el 21 de agosto de 2023
> * Estos datos ya no se encuentran en la página de la CONAPO, fueron 
>   descargados a mediados de 2023

Los datos publicados por la CONAPO incluyen dos archivos en CSV, y a 
diferencia de la proyección de los estados, la de los municipios esta 
dividida por la gran cantidad de datos (son más de 2 mil municipios) y no 
porque una sea población al inicio del año.


El nombre de los archivos son:

* base_municipios_final_datos_01.csv
* base_municipios_final_datos_02.csv
"""

# %%
#| label: load-df_pob_mun_mid_year_01-02
df_pob_mun_mid_year_01 = pd.read_csv(
    filepath_or_buffer = (path2conapomun + 
                          "/base_municipios_final_datos_01.csv"),
    encoding = "latin1")

df_pob_mun_mid_year_02 = pd.read_csv(
    filepath_or_buffer = (path2conapomun + 
                          "/base_municipios_final_datos_02.csv"),
    encoding = "latin1")

# %% [markdown]
"""
### Cambios a los `pandas.DataFrame`s

Ambos conjuntos de datos tienen las mismas columnas con el mismo 
nombre, a continuación se muestra un ejemplo: 
"""

# %%
#| echo: false
#| label: sample-df_pob_mun_mid_year_01
Markdown(df_pob_mun_mid_year_01
  .sample(
      n = 3,
      random_state= 11)
  .to_markdown(index=False))

# %% [markdown]
"""
A continuación se enlistan las transformaciones y cambios que se le hará a 
la base de datos de manera general.

1. Concatenar ambos `pandas.DataFrame`s en uno solo
2. Renombrar columnas
3. Transformar la columna de códigos de las entidades y de los municipios
4. Transformar la columna de códigos de edades
5. Renombrar los estados

A partir de este procesamiento, se crean dos bases de datos:

1. Base de datos completa, con la división de género y edades
2. Base de datos con la división de los géneros y uniendo las 
categorías de edades
"""

# %% [markdown]
"""
### Concatenar ambos `pandas.DataFrame`s en uno solo
"""

# %%
#| label: concat-df_pob_mun_mid_year_01-02
df_union_pob_mun = (pd.concat([df_pob_mun_mid_year_01,
                               df_pob_mun_mid_year_02])
            .reset_index(drop=True)
            # Eliminar columnas que no aportan o no son necesarias en la 
            # base de datos
            .drop(columns = ["RENGLON", "NOM_ENT"]))

# %% [markdown]
"""
### Renombrar columnas
"""

# %%
#| label: rename_cols-df_union_pob_mun
db_proj_mun = (df_union_pob_mun
    .rename(columns = {
        "CLAVE": "cve_mun",
        "CLAVE_ENT": "cve_ent",
        "MUN": "nombre_municipio",
        "SEXO": "genero",
        "AÑO": "n_year",
        "EDAD_QUIN": "rango_edad",
        "POB": "pob_mid_year"}))

# %% [markdown]
"""
### Transformar la columna de códigos de las entidades y de los municipios

Tanto los códigos de los estados (`cve_ent`) como el de los municipios 
(`cve_mun`) fueron leídos por Python como números en lugar de caracteres, 
por lo que tiene que se tiene que hacer ese cambio.
"""

# %%
#| label: trans_cols-cve_ent_mun
# Función lambda para modificar claves de municipio
func_trans_cve_mun = lambda x : f"0{int(x)}" if x < 10_000 else str(int(x))

db_proj_mun["cve_ent"] = (db_proj_mun["cve_ent"]
                         .apply(func = func_trans_cve_ent))
db_proj_mun["cve_mun"] = (db_proj_mun["cve_mun"]
                         .apply(func = func_trans_cve_mun))

# %% [markdown]
"""
### Transformar la columna de códigos de edades

Los códigos de las edades estan organizados por rangos de 5 años,
"""

# %%
#| label: trans_cols-rango_edad
# Función para modificar códigos de edades
def func_trans_rango_edad(cat_age):
    cat_age_clean = (cat_age
                     .replace("pobm_","Age")
                     .replace("mm", "more"))
    return cat_age_clean

db_proj_mun["rango_edad"] = (db_proj_mun["rango_edad"]
                            .apply(func = func_trans_rango_edad))

# %% [markdown]
"""
### Adjuntar el nombre de los estados

La manera en la que están escritos los nombres de algunos estados no son 
como comúnmente se nombran, por ejemplo, en la base de datos de la CONAPO, 
**Coahuila** esta bajo el nombre de _Coahuila de Zaragoza_.

Es por eso que se usarán los nombres _comunes_ de los estados, que se 
encuentran en el archivo `cve_nom_estados.csv`, previamente cargados en 
el script.
"""

# %%
#| label: trasn_cols-rename_nombre_estados_db_mun
list_orden_cols_mun = [
  "n_year",
  "nombre_estado",
  "cve_ent",
  "nombre_municipio",
  "cve_mun",
  "rango_edad",
  "genero",
  "pob_mid_year"]

db_proj_mun = (pd.merge(left = db_proj_mun,
                        right = cve_nom_ent,
                        how = "left",
                        on = "cve_ent")
              .reset_index(drop = True)
              [list_orden_cols_mun])

# %% [markdown]
"""
### Crear un conjunto de datos de la población de ambos géneros sin distinción de la edad

Cuando se dice **sin distinción de edad** se habla de que se suma la 
población de todas las edades

> [!NOTE]
> 
> El procesamiento es más sencillo que el de los estados ya que solamente 
> hay una columna de información

"""
# %%
#| label: group-by_suma_pob_genero_db_mun
db_proj_mun_all_ages = (db_proj_mun.groupby([
    "n_year",
    "nombre_estado",
    "cve_ent",
    "nombre_municipio",
    "cve_mun",
    "genero"])
    .sum()["pob_mid_year"]
    .reset_index()
    # Long2Wide
    .pivot(
        index = [
            "n_year", 
            "nombre_estado",
            "cve_ent",
            "nombre_municipio",
            "cve_mun"],
        columns = ["genero"],
        values = "pob_mid_year")
    .reset_index())

# Poblacion total a mitad de año
db_proj_mun_all_ages['Total'] = (db_proj_mun_all_ages['Hombres'] + 
                                 db_proj_mun_all_ages['Mujeres'])


# %% [markdown]
"""
El objetivo sigue siendo el mismo, mantener los datos _tidy_, por lo que 
se volverá a hacer la transformación de datos _wide format_ a _long format_.
"""

# %%
#| label: wide2long_pob_mun
db_proj_mun_all_ages = pd.melt(
    db_proj_mun_all_ages,
    id_vars = ['n_year', 'nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun'],
    value_vars = ['Hombres', 'Mujeres', 'Total'],
    var_name= "genero",
    value_name = "pob_mid_year")

# %% [markdown]
"""
## Guardar bases de datos
"""

# %%
#| echo: false
#| eval: false
# TODO: Repensar nombres de los archivos finales
