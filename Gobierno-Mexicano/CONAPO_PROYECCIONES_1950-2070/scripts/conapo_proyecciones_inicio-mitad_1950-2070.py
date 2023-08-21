"""
Script que combina los archivos 0_Pob_Inicio_1950_2070.xlsx y 0_Pob_Mitad_1950_2070.xlsx 
en un solo archivo CSV con los nombres 'comunes' de las entidades

Autor: Isaac Arroyo
Fecha de creación: 2023-08-21
Fecha de última modificación: 2023-08-21
"""

import pandas as pd
import os

# = = CARGAR AMBOS ARCHIVOS DE EXCEL = = #
df_inicio = pd.read_excel(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/entidades/base_original/0_Pob_Inicio_1950_2070.xlsx")
df_mitad = pd.read_excel(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/entidades/base_original/0_Pob_Mitad_1950_2070.xlsx")

# = = CAMBIO DE NOMBRE DE COLUMNAS = = #
# - - Tambien se elimina la columna RENGLON - - #
df_inicio = df_inicio.rename(columns= {"AÑO": "date_year_n", "ENTIDAD": "entidad", "CVE_GEO": "cve_geo", "EDAD": "edad", "SEXO": "genero", "POBLACION": "poblacion_inicio_date_year_n"}).drop(columns = "RENGLON")
df_mitad = df_mitad.rename(columns= {"AÑO": "date_year_n", "ENTIDAD": "entidad", "CVE_GEO": "cve_geo", "EDAD": "edad", "SEXO": "genero", "POBLACION": "poblacion_mitad_date_year_n"}).drop(columns = "RENGLON")


# = = AGREGAR 0's A CLAVES DE ESTADOS = = #
df_inicio["cve_geo"] = df_inicio["cve_geo"].apply(lambda x : f"0{x}" if x < 10 else str(x))
df_mitad["cve_geo"] = df_mitad["cve_geo"].apply(lambda x : f"0{x}" if x < 10 else str(x))

# = = COMBINAR DATAFRAMES = = #
df_proyecciones_ent = pd.merge(left = df_inicio, right = df_mitad.drop(columns = "entidad"),
                               how = "left", on = ["date_year_n", "cve_geo", "edad","genero"]).reset_index(drop = True)
# - - Combinar enteros la columna de poblacion a mitad de año - - #
df_proyecciones_ent["poblacion_mitad_date_year_n"] = df_proyecciones_ent["poblacion_mitad_date_year_n"].astype("Int64")

# = = CAMBIAR LOS NOMBRES DE LOS ESTADOS A SUS NOMBRES 'COMUNES' = = #
# - - Cargar los datos del repositorio de N+ Focus - - #
nombres_entidades = pd.read_csv("https://raw.githubusercontent.com/nmasfocusdatos/desplazamiento-climatico/main/datos/base_nombres_entidades.csv")
nombres_entidades["cve_geo"] = nombres_entidades["cve_geo"].fillna(0).apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x)))

df_proyecciones_ent = df_proyecciones_ent.drop(columns="entidad").merge(nombres_entidades, on = "cve_geo").rename(columns = {"nombre_estado_2": "nombre_estado"})[["date_year_n", "nombre_estado", "cve_geo","edad","genero","poblacion_inicio_date_year_n","poblacion_mitad_date_year_n"]]

# = = GUARDAR CSV = = #
df_proyecciones_ent.to_csv(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/entidades/conapo_proyecciones_inicio-mitad_1950-2070.csv", index = False)