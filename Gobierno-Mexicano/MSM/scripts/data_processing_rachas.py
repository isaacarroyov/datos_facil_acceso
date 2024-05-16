# TODO: Documentar como GFM
# TODO: Tomar en cuenta los cambios de nombre de columnas del script de R
"""
Script hecho para crear dos archivos CSV:
    - rachas_sequia_municipios -> archivo que tiene en orden cronológico el inicio y final de 
      la categoría de sequía de un determinado municipio
    - rachas_maximas_sequia_municipios -> archivo que contiene únicamente las rachas máximas (mayor duración)
      de cada categoría de sequía del MSM
"""


import pandas as pd
import os

path2main = os.getcwd()
path2gobmexicano = path2main + "/Gobierno-Mexicano"
path2msmdata = path2gobmexicano + "/MSM/datos"
file_rachas = "/rachas_sequia_municipios.csv"
file_rachas_maximas = "/max_rachas_sequia_municipios.csv"


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
print("Guardando archivo de rachas...")
df_rachas_mun.to_csv(
	path_or_buf = path2msmdata + file_rachas,
	index=False)
print("Guardado!")
print("Guardando archivo de rachas máximas...")

df_rachas_max_mun = pd.concat(lista_dfs_rachas_max).reset_index(drop=True)
df_rachas_max_mun.to_csv(
	path_or_buf = path2msmdata + file_rachas_maximas,
	index=False)
print("Guardado!")