# %% [markdown]
# ---
# title: 'Población a mitad e inicio de año de los estados de México (1950-2070)'
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
> Código creado el 21 de agosto de 2023

## Sobre los datos

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed quis lorem 
augue. Class aptent taciti sociosqu ad litora torquent per conubia nostra, 
per inceptos himenaeos. Sed luctus tempor velit ut interdum. Morbi porta 
placerat diam, vel egestas ante viverra eu. Pellentesque id cursus justo, 
nec congue quam. Curabitur nec libero at mi sollicitudin maximus id eget 
magna. Nam ac tortor ut felis dapibus ornare. Fusce mollis in odio eget 
efficitur. Integer ac luctus tellus. Praesent malesuada turpis sit amet 
tempor pharetra. Vivamus accumsan, turpis ut consequat cursus, orci est 
aliquet neque, id consectetur odio erat at magna. Praesent pulvinar 
gravida leo ut varius. Nunc at nunc varius elit sagittis ultrices. Fusce 
placerat efficitur diam, non laoreet quam.

## El código
"""
# %%
import pandas as pd
import os
# %% [markdown]
"""
Como se mencionó anteriormente, son dos conjuntos de datos de interés:

1. **0_Pob_Inicio_1950_2070.xlsx**
2. **0_Pob_Mitad_1950_2070**
"""
# %%
path2main = os.getcwd() + "/../../../" # <1>
path2foldermex = path2main + "Gobierno-Mexicano/"
path2conapo = path2foldermex + "CONAPO_PROYECCIONES_1950-2070/" # <2>
path2entfolder = path2conapo + "entidades/" # <3>

# TODO: Planear juntar con el procesamiento de municipios
path2ogentdata = path2entfolder + "base_original/" # <4>

df_inicio = pd.read_excel(path2ogentdata + "0_Pob_Inicio_1950_2070.xlsx") # <5>
df_mitad = pd.read_excel(path2ogentdata + "0_Pob_Mitad_1950_2070.xlsx") # <6>

# %% [markdown]
"""
Cambio de nombre de columnas
"""
# %%
df_inicio = (df_inicio
  .rename(
      columns = {
          "AÑO": "date_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_geo",
          "EDAD": "edad",
          "SEXO": "genero",
          "POBLACION": "pob_start_year"})
  .drop(columns = "RENGLON"))

df_mitad = (df_mitad
  .rename(
      columns= {
          "AÑO": "date_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_geo",
          "EDAD": "edad",
          "SEXO": "genero",
          "POBLACION": "pob_mid_year"})
  .drop(columns = "RENGLON"))

# %% [markdown]
"""
Cambio de codigos
"""
# %%
df_inicio["cve_geo"] = (df_inicio["cve_geo"]
                        .apply(lambda x : f"0{x}" if x < 10 else str(x)))
df_mitad["cve_geo"] = (df_mitad["cve_geo"]
                       .apply(lambda x : f"0{x}" if x < 10 else str(x)))

# %% [markdown]
"""
Unir dataframes
"""
# %%
df_proj_ent = (pd.merge(
    left = df_inicio,
    right = df_mitad.drop(columns = "entidad"),
    how = "left",
    on = ["date_year", "cve_geo", "edad","genero"])
  .reset_index(drop = True))

df_proj_ent["pob_mid_year"] = (df_proj_ent["pob_mid_year"]
                               .astype("Int64"))

# %% [markdown]
"""
Renombrar  entidades
"""
# %%
cve_nom_ent = pd.read_csv(path2foldermex + "nombres_claves_entidades.csv")
cve_nom_ent["cve_geo"] = (cve_nom_ent["cve_geo"]
  .fillna(0)
  .apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x))))

list_cols_interes = [
  "date_year",
  "nombre_estado",
  "cve_geo",
  "edad",
  "genero",
  "pob_start_year",
  "pob_mid_year"]

df_proj_ent = (df_proj_ent
               .drop(columns="entidad")
               .merge(cve_nom_ent, on = "cve_geo")
               [list_cols_interes])

# %% [markdown]
"""
Guardar nuevo CSV
"""
# %%
(df_proj_ent
  .to_csv(path2entfolder + "conapo_proj_ent-nac_inicio-mitad_1950-2070",
          index = False))