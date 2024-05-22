# Procesamiento y transformación de datos: Sequía en México
Isaac Arroyo
21 de mayo de 2024

## Introducción y objetivos

En este documento se encuentra documentado el código usado para la
extracción, transformación, estandarización y la creación de nuevos
conjuntos de datos a partir del registro de sequía en los municipios del
país del [**Monitor de Sequía de México
(MSM)**](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico).

A través del registro de sequía en los municipios se espera tener 3
bases de datos:

1.  El registro de sequía en formato *tidy*
2.  El registro del tiempo de duración del tipo de sequía (racha)
3.  El registro del tiempo de duración máximo del tipo de sequía (racha
    máxima)

## Descarga y transformación del registro de sequía en los municipios

Como primer paso es modificar la base de datos del MSM para que este en
formato *tidy*, ya que originalmente las columnas son la fecha del
registro.

``` python
import pandas as pd

msm_og = pd.read_excel(io = "".join(["https://smn.conagua.gob.mx/tools/",
                            "RESOURCES/Monitor%20de%20Sequia%20en%",
                            "20Mexico/MunicipiosSequia.xlsx"]),
                       dtype= 'object')
```

> \[!NOTE\]  
> La tabla muestra únicamente una muestra de las columnas de fecha del
> registro

| CVE_CONCATENADA | CVE_ENT | CVE_MUN | NOMBRE_MUN             | ENTIDAD             | ORG_CUENCA\*            | CLV_OC | CON_CUENCA                 | CVE_CONC | 2016-07-31 00:00:00 | 2009-10-31 00:00:00 | 2010-09-30 00:00:00 | 2019-10-31 00:00:00 |
|----------------:|--------:|--------:|:-----------------------|:--------------------|:------------------------|:-------|:---------------------------|---------:|:--------------------|:--------------------|--------------------:|:--------------------|
|           21098 |      21 |     098 | Molcaxac               | Puebla              | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D0                  |                 nan | nan                 |
|           27012 |      27 |     012 | Macuspana              | Tabasco             | Frontera Sur            | XI     | Rios Grijalva y Usumacinta |       24 | D1                  | D3                  |                 nan | D3                  |
|           20306 |      20 |     306 | San Pedro el Alto      | Oaxaca              | Pacífico Sur            | V      | Costa de Oaxaca            |       11 | D0                  | nan                 |                 nan | nan                 |
|           16086 |      16 |     086 | Tanhuato               | Michoacán de Ocampo | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala            |       15 | D1                  | D2                  |                 nan | D1                  |
|           15004 |      15 |     004 | Almoloya de Alquisiras | Estado de México    | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D1                  |                 nan | D0                  |

A partir de esta tabla, enlistan los cambios necesarios:

1.  Limpiar los nombres de las columnas
2.  Hacer el cambio de *wide format* a *long format*
3.  Eliminar los registros Agosto 2003 y Febrero 2004

### Limpiar los nombres de las columnas

``` python
from janitor import clean_names
msm_og = msm_og.clean_names(remove_special = True)
```

| cve_concatenada | cve_ent | cve_mun | nombre_mun             | entidad             | org_cuenca              | clv_oc | con_cuenca                 | cve_conc | 2016_07_31_00_00_00 | 2009_10_31_00_00_00 | 2010_09_30_00_00_00 | 2019_10_31_00_00_00 |
|----------------:|--------:|--------:|:-----------------------|:--------------------|:------------------------|:-------|:---------------------------|---------:|:--------------------|:--------------------|--------------------:|:--------------------|
|           21098 |      21 |     098 | Molcaxac               | Puebla              | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D0                  |                 nan | nan                 |
|           27012 |      27 |     012 | Macuspana              | Tabasco             | Frontera Sur            | XI     | Rios Grijalva y Usumacinta |       24 | D1                  | D3                  |                 nan | D3                  |
|           20306 |      20 |     306 | San Pedro el Alto      | Oaxaca              | Pacífico Sur            | V      | Costa de Oaxaca            |       11 | D0                  | nan                 |                 nan | nan                 |
|           16086 |      16 |     086 | Tanhuato               | Michoacán de Ocampo | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala            |       15 | D1                  | D2                  |                 nan | D1                  |
|           15004 |      15 |     004 | Almoloya de Alquisiras | Estado de México    | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D1                  |                 nan | D0                  |

### Hacer el cambio de *wide format* a *long format*

``` python
# Wide to Long
msm_long = pd.melt(
    frame = msm_og,
    id_vars = msm_og.columns.tolist()[:9],
    var_name = 'full_date',
    value_name = 'sequia')

# Los espacios vacíos o NaN son en realidad registros Sin sequia
msm_long['sequia'] = msm_long['sequia'].fillna("Sin sequia")
```

| cve_concatenada | cve_ent | cve_mun | nombre_mun                | entidad | org_cuenca   | clv_oc | con_cuenca                 | cve_conc |           full_date | sequia     |
|----------------:|--------:|--------:|:--------------------------|:--------|:-------------|:-------|:---------------------------|---------:|--------------------:|:-----------|
|           20515 |      20 |     515 | Santo Domingo Tehuantepec | Oaxaca  | Pacífico Sur | V      | Costa de Oaxaca            |       11 | 2021_06_15_00_00_00 | Sin sequia |
|           17014 |      17 |     014 | Mazatepec                 | Morelos | Balsas       | IV     | Rio Balsas                 |        9 | 2013_06_30_00_00_00 | Sin sequia |
|           20156 |      20 |     156 | San Ildefonso Villa Alta  | Oaxaca  | Golfo Centro | X      | Rio Papaloapan             |       21 | 2012_11_30_00_00_00 | Sin sequia |
|           20056 |      20 |     056 | Mártires de Tacubaya      | Oaxaca  | Pacífico Sur | V      | Costa de Oaxaca            |       11 | 2017_05_31_00_00_00 | D0         |
|           07031 |      07 |     031 | Chilón                    | Chiapas | Frontera Sur | XI     | Rios Grijalva y Usumacinta |       24 | 2017_07_31_00_00_00 | D0         |

### Eliminar los registros Agosto 2003 y Febrero 2004

En el documento XLSX, en el apartado de Notas, se comunica que por
factores externos, el MSM no se elaboró en esas fechas.

Por lo que se crean *máscaras* para filtrar esas fechas

``` python
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
```

| cve_concatenada | cve_ent | cve_mun | nombre_mun          | entidad                         | org_cuenca   | clv_oc | con_cuenca            | cve_conc | full_date           | sequia     |
|----------------:|--------:|--------:|:--------------------|:--------------------------------|:-------------|:-------|:----------------------|---------:|:--------------------|:-----------|
|           15124 |      15 |     124 | San José del Rincón | Estado de México                | Balsas       | IV     | Rio Balsas            |        9 | 2014-04-15 00:00:00 | D0         |
|           30084 |      30 |     084 | Ixmatlahuacan       | Veracruz de Ignacio de la Llave | Golfo Centro | X      | Rio Papaloapan        |       21 | 2009-09-30 00:00:00 | D0         |
|           21088 |      21 |     088 | Jonotla             | Puebla                          | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2003-11-30 00:00:00 | Sin sequia |
|           30050 |      30 |     050 | Coxquihui           | Veracruz de Ignacio de la Llave | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2012-05-31 00:00:00 | Sin sequia |
|           12038 |      12 |     038 | José Azueta         | Guerrero                        | Pacífico Sur | V      | Costa de Guerrero     |       10 | 2014-07-31 00:00:00 | D0         |

## Cálculo de rachas y rachas máximas

A partir de los datos procesados (**`db_msm`**) se irá iterando por cada
uno de los municipios para obtener sus rachas de sequía y a partir de
estas las de mayor duración.

### Función para conteo de rachas

El resultado de esta función será necesaria para la función de rachas
máximas

``` python
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
```

### Función para aislar las rachas máximas

``` python
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
```

## Aplicar las funciones en la base de datos

Con las funciones listas, se obtienen las bases de datos de rachas de
sequía junto con las rachas máximas de sequía

``` python
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
```

## Guardar bases de datos

``` python
import os

# Cambiar al folder principal del repositorio
os.chdir("../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2msm = path2gobmex + "/msm"
```

### Base de datos de Sequía en Municipios

Muestra del archivo **`sequia_municipios.csv.bz2`**

``` python
db_msm.to_csv(
   path_or_buf = path2msm + "/sequia_municipios.csv.bz2",
   compression = "bz2",
   index = False)
```

| cve_concatenada | cve_ent | cve_mun | nombre_mun             | entidad  | org_cuenca   | clv_oc | con_cuenca            | cve_conc | full_date           | sequia     |
|----------------:|--------:|--------:|:-----------------------|:---------|:-------------|:-------|:----------------------|---------:|:--------------------|:-----------|
|           20404 |      20 |     404 | Santa María Chachoápam | Oaxaca   | Pacífico Sur | V      | Costa de Oaxaca       |       11 | 2016-08-31 00:00:00 | D1         |
|           20167 |      20 |     167 | San José del Peñasco   | Oaxaca   | Pacífico Sur | V      | Costa de Oaxaca       |       11 | 2022-05-15 00:00:00 | D0         |
|           29010 |      29 |     010 | Chiautempan            | Tlaxcala | Balsas       | IV     | Rio Balsas            |        9 | 2015-12-15 00:00:00 | Sin sequia |
|           21213 |      21 |     213 | Zihuateutla            | Puebla   | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2010-03-31 00:00:00 | Sin sequia |
|           20081 |      20 |     081 | San Agustín Atenango   | Oaxaca   | Balsas       | IV     | Rio Balsas            |        9 | 2005-04-30 00:00:00 | Sin sequia |

### Base de datos de Rachas de Sequía en Municipios

Muestra del archivo **`rachas_sequia_municipios.csv`**

``` python
db_rachas_mun.to_csv(
   path_or_buf = path2msm + "/rachas_sequia_municipios.csv",
   index = False)
```

| cve_concatenada | sequia     | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-----------|------:|:----------------------|:--------------------|-----------:|
|           28024 | D1         |     1 | 2022-01-15 00:00:00   | 2022-01-15 00:00:00 |          0 |
|           07037 | D1         |     1 | 2016-08-31 00:00:00   | 2016-08-31 00:00:00 |          0 |
|           21072 | Sin sequia |    29 | 2021-01-31 00:00:00   | 2022-03-31 00:00:00 |        424 |
|           20491 | D0         |     3 | 2005-12-31 00:00:00   | 2006-02-28 00:00:00 |         59 |
|           30208 | D0         |     3 | 2018-05-31 00:00:00   | 2018-06-30 00:00:00 |         30 |

### Base de datos de Máximas Rachas de Sequía en Municipios

Muestra del archivo **`max_rachas_sequia_municipios.csv`**

``` python
db_rachas_max_mun.to_csv(
   path_or_buf = path2msm + "/max_rachas_sequia_municipios.csv",
   index = False)
```

| cve_concatenada | sequia | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-------|------:|:----------------------|:--------------------|-----------:|
|           11030 | D2     |     8 | 2022-04-30 00:00:00   | 2022-08-15 00:00:00 |        107 |
|           20453 | D0     |     8 | 2004-10-31 00:00:00   | 2005-05-31 00:00:00 |        212 |
|           20462 | D2     |     3 | 2023-10-15 00:00:00   | 2023-11-15 00:00:00 |         31 |
|           32024 | D0     |     7 | 2020-10-31 00:00:00   | 2021-01-31 00:00:00 |         92 |
|           07032 | D1     |    11 | 2015-06-30 00:00:00   | 2015-11-30 00:00:00 |        153 |
