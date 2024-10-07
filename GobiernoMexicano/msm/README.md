# Procesamiento y transformación de datos: Sequía en México
Isaac Arroyo
9 de septiembre de 2024

## Introducción y objetivos

En este documento se encuentra documentado el código usado para la extracción, transformación, estandarización y la creación de nuevos conjuntos de datos a partir del registro de sequía en los municipios del país del [**Monitor de Sequía de México (MSM)**](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico).

A través del registro de sequía en los municipios se espera tener 4 bases de datos:

1.  El registro mensual o quincenal (depende de la fecha) de sequía en formato *tidy*
2.  El registro diario de sequía en formato *tidy*
3.  El registro del tiempo de duración del tipo de sequía (racha)
4.  El registro del tiempo de duración máximo del tipo de sequía (racha máxima)

``` python
import pandas as pd
from janitor import clean_names
from numpy.random import randint, seed
from IPython.display import Markdown
```

## Descarga y transformación del registro de sequía en los municipios

Como primer paso es modificar la base de datos del MSM para que este en formato *tidy*, ya que originalmente las columnas son la fecha del registro.

``` python
msm_og = pd.read_excel(
   io = "".join(["https://smn.conagua.gob.mx/tools/RESOURCES/Monitor%20de",
                 "%20Sequia%20en%20Mexico/MunicipiosSequia.xlsx"]),
   dtype= 'object')

msm_og = msm_og.clean_names(remove_special = True)
```

> \[!NOTE\]  
> La tabla muestra únicamente una muestra de las columnas de fecha del registro

| cve_concatenada | cve_ent | cve_mun | nombre_mun             | entidad             | org_cuenca              | clv_oc | con_cuenca                 | cve_conc | 2016_07_31_00_00_00 | 2009_10_31_00_00_00 | 2010_09_30_00_00_00 | 2019_10_31_00_00_00 |
|----------------:|--------:|--------:|:-----------------------|:--------------------|:------------------------|:-------|:---------------------------|---------:|:--------------------|:--------------------|--------------------:|:--------------------|
|           21098 |      21 |     098 | Molcaxac               | Puebla              | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D0                  |                 nan | nan                 |
|           27012 |      27 |     012 | Macuspana              | Tabasco             | Frontera Sur            | XI     | Rios Grijalva y Usumacinta |       24 | D1                  | D3                  |                 nan | D3                  |
|           20306 |      20 |     306 | San Pedro el Alto      | Oaxaca              | Pacífico Sur            | V      | Costa de Oaxaca            |       11 | D0                  | nan                 |                 nan | nan                 |
|           16086 |      16 |     086 | Tanhuato               | Michoacán de Ocampo | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala            |       15 | D1                  | D2                  |                 nan | D1                  |
|           15004 |      15 |     004 | Almoloya de Alquisiras | Estado de México    | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D1                  |                 nan | D0                  |

A partir de esta tabla, enlistan los cambios necesarios:

1.  Hacer el cambio de *wide format* a *long format*
2.  Eliminar los registros Agosto 2003 y Febrero 2004 <!-- TODO: ESCRIBIR CORRECTAMENTE LOS PASOS A SEGUIR EN EL TRABAJO -->

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

| cve_concatenada | cve_ent | cve_mun | nombre_mun               | entidad                         | org_cuenca   | clv_oc | con_cuenca            | cve_conc |           full_date | sequia     |
|----------------:|--------:|--------:|:-------------------------|:--------------------------------|:-------------|:-------|:----------------------|---------:|--------------------:|:-----------|
|           30050 |      30 |     050 | Coxquihui                | Veracruz de Ignacio de la Llave | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2021_11_15_00_00_00 | D0         |
|           30101 |      30 |     101 | Mariano Escobedo         | Veracruz de Ignacio de la Llave | Golfo Centro | X      | Rio Papaloapan        |       21 | 2011_11_30_00_00_00 | D0         |
|           15113 |      15 |     113 | Villa Guerrero           | Estado de México                | Balsas       | IV     | Rio Balsas            |        9 | 2021_07_15_00_00_00 | D0         |
|           16057 |      16 |     057 | Nocupétaro               | Michoacán de Ocampo             | Balsas       | IV     | Rio Balsas            |        9 | 2006_04_30_00_00_00 | D2         |
|           20156 |      20 |     156 | San Ildefonso Villa Alta | Oaxaca                          | Golfo Centro | X      | Rio Papaloapan        |       21 | 2021_07_31_00_00_00 | Sin sequia |

### Asignar unidad de fecha a la columna `full_date`

Tras la transformación *wide2long*, hace falta transformar la columna `full_date` a lo que es, una fecha.

Previo transformar los valores a `np.datetime`, se tiene que eliminar los caracteres `'_00_00_00'` y sustiuir los guiones bajos (`_`) por guiones medios (`-`)

``` python
msm_long['full_date'] = (msm_long['full_date']
                         .str.replace("_00_00_00", "")
                         .str.replace("_", "-"))

msm_long['full_date'] = pd.to_datetime(arg = msm_long['full_date'],
                                       errors= 'coerce')
```

## El registro de sequía en formato *tidy* (registro mensual, quincenal y diario)

Para esta ocasión, el registro de sequía se completará con el tipo de sequía diaria, esto asumiendo que cuando la publicación era mensual representa la sequía del mes del registro, mientras que para las publicaciones quincenales es de los últimos 15 días.

> *Ejemplo:*
>
> • *Fecha publicación y tipo de sequia : Mayo 31 del 2005, D3*
>
> Se traduce a que del Mayo 01 - Mayo 31 de 2005, todos los días serán etiquetados con sequía D3
>
> • *Fecha publicación y tipo de sequia : Mayo 31 del 2024, D3*
>
> Se traduce a que del Mayo 01 - Mayo 14 de 2024, todos los días serán etiquetados con sequía D3

### Función para completar días

Esta función toma un grupo (un municipios) y completará la serie de tiempo por día. Con los valores `NaN` de sequía, se llenarán con el registro siguiente al que se tiene (que no sea `NaN`)

``` python
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
```

Se usarán únicamente las columnas de las claves de los municipios

``` python
msm_long_filled = (msm_long[['full_date','cve_concatenada', 'sequia']]
  .groupby(by = 'cve_concatenada')
  .apply(lambda x: func_llenado_dias_sequia(group=x))
  .reset_index(drop = True))
```

| full_date           | cve_concatenada | sequia     |
|:--------------------|----------------:|:-----------|
| 2009-04-28 00:00:00 |           19005 | D0         |
| 2024-03-11 00:00:00 |           20239 | D1         |
| 2010-08-19 00:00:00 |           30087 | Sin sequia |
| 2005-10-26 00:00:00 |           20361 | Sin sequia |
| 2003-11-17 00:00:00 |           21190 | Sin sequia |

## Cálculo de rachas y rachas máximas

A partir de los datos procesados (**`msm_long_filled`**) se irá iterando por cada uno de los municipios para obtener sus rachas de sequía y a partir de estas las de mayor duración.

### Función para conteo de rachas

El resultado de esta función será necesaria para la función de rachas máximas

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

Con las funciones listas, se obtienen las bases de datos de rachas de sequía junto con las rachas máximas de sequía

``` python
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
```

Muestra de `db_rachas_mun`

| cve_concatenada | sequia     | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-----------|------:|:----------------------|:--------------------|-----------:|
|           31013 | Sin sequia |    61 | 2003-10-01 00:00:00   | 2003-11-30 00:00:00 |         60 |
|           19029 | Sin sequia |    31 | 2014-05-16 00:00:00   | 2014-06-15 00:00:00 |         30 |
|           16033 | Sin sequia |   243 | 2003-01-01 00:00:00   | 2003-08-31 00:00:00 |        242 |
|           30135 | D0         |    31 | 2007-01-01 00:00:00   | 2007-01-31 00:00:00 |         30 |
|           30202 | D1         |    46 | 2018-11-16 00:00:00   | 2018-12-31 00:00:00 |         45 |

Muestra de `db_rachas_max_mun`

| cve_concatenada | sequia     | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-----------|------:|:----------------------|:--------------------|-----------:|
|           19046 | D3         |   153 | 2011-08-01 00:00:00   | 2011-12-31 00:00:00 |        152 |
|           14100 | D0         |   365 | 2004-08-01 00:00:00   | 2005-07-31 00:00:00 |        364 |
|           17011 | Sin sequia |  1995 | 2011-09-01 00:00:00   | 2017-02-15 00:00:00 |       1994 |
|           31034 | D3         |   181 | 2009-09-01 00:00:00   | 2010-02-28 00:00:00 |        180 |
|           25007 | D4         |   244 | 2024-01-16 00:00:00   | 2024-09-15 00:00:00 |        243 |

## Reasignar nombre de Estados, Municipios y Cuencas

A partir de la creación de `msm_long_filled`, todos los conjuntos de datos excluyen las claves y nombres de los Estados, Municipios (este únicamente el nombre) y Cuencas.

Por lo que se completaran a las bases de datos de interés, previo a ser guardadas.

``` python
import os

# Cambiar al folder principal del repositorio
os.chdir("../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2msm = path2gobmex + "/msm"
```

Claves y nombres de municipios y entidades

``` python
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
```

``` python
Markdown(
   cve_nom_ent_mun_cuenca
   .sample(n = 5, random_state = 11)
   .to_markdown(index = False))
```

| org_cuenca              | clv_oc | con_cuenca            | cve_conc | cve_geo | nombre_estado | cve_ent | nombre_municipio   | cve_mun |
|:------------------------|:-------|:----------------------|---------:|--------:|:--------------|--------:|:-------------------|--------:|
| Golfo Centro            | X      | Rios Tuxpan al Jamapa |       20 |   21028 | Puebla        |      21 | Camocuautla        |     028 |
| Golfo Centro            | X      | Rio Papaloapan        |       21 |   20323 | Oaxaca        |      20 | San Pedro Ocotepec |     323 |
| Lerma-Santiago-Pacífico | VIII   | Costa Pacifico Centro |       17 |   14017 | Jalisco       |      14 | Ayutla             |     017 |
| Golfo Centro            | X      | Rio Papaloapan        |       21 |   30031 | Veracruz      |      30 | Carrillo Puerto    |     031 |
| Río Bravo               | VI     | Rio Bravo             |       12 |   08061 | Chihuahua     |      08 | Satevó             |     061 |

Unir con las bases de datos de interés y reordenar las columnas

``` python
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
```

## Guardar bases de datos

### Bases de datos de Sequía en Municipios

Se crearán dos bases de datos a partir de este procesamiento de datos:

- **`msm_long`** : Datos de sequía de la CONAGUA en *long format*
- **`msm_long_filled`** : Datos de sequía diarios en *long format* (Modificado)

Para ambos casos se eliminarán las los registros de Agosto 2003 y Febrero 2004. En el documento XLSX, en el apartado de Notas, se comunica que por factores externos, el MSM no se elaboró en esas fechas.

Por lo que se crean *máscaras* para filtrar esas fechas

``` python
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
```

Las máscaras identifican las fechas donde no hubo MSM, sin embargo lo que busca es **omitirlas**, no aislarlas, es por eso que para crear la base de datos se *niegan* las condiciones, para que se incluya todo lo que no cumpla la máscara.

Para negar las máscaras, se usa **`~`**

``` python
# Datos de sequía de la CONAGUA en long format
db_msm_og = msm_long[~mask_dates_nowork_msm_long]

# Datos de sequía diarios en long format (Modificado)
db_msm_mod = msm_long_filled[~mask_dates_nowork_msm_long_filled]
```

Como último paso se guardan ambas bases de datos

Muestra del archivo **`sequia_municipios.csv.bz2`**

``` python
db_msm_og.to_csv(
   path_or_buf = path2msm + "/sequia_municipios.csv.bz2",
   compression = "bz2",
   index = False)
```

| nombre_estado    | cve_ent | nombre_municipio     | cve_geo | org_cuenca                | clv_oc | con_cuenca                 | cve_conc | full_date           | sequia     |
|:-----------------|--------:|:---------------------|--------:|:--------------------------|:-------|:---------------------------|---------:|:--------------------|:-----------|
| Chiapas          |      07 | Tapilula             |   07091 | Frontera Sur              | XI     | Rios Grijalva y Usumacinta |       24 | 2023-01-15 00:00:00 | Sin sequia |
| Oaxaca           |      20 | San Juan Ñumí        |   20210 | Balsas                    | IV     | Rio Balsas                 |        9 | 2010-10-31 00:00:00 | Sin sequia |
| Oaxaca           |      20 | Santo Tomás Ocotepec |   20532 | Balsas                    | IV     | Rio Balsas                 |        9 | 2018-03-15 00:00:00 | D0         |
| Puebla           |      21 | Palmar de Bravo      |   21110 | Balsas                    | IV     | Rio Balsas                 |        9 | 2021-05-15 00:00:00 | D0         |
| Estado de México |      15 | Papalotla            |   15069 | Aguas del Valle de México | XIII   | Valle de Mexico            |       26 | 2006-07-31 00:00:00 | D0         |

Muestra del archivo **`sequia_municipios_days.csv.bz2`**

``` python
db_msm_mod.to_csv(
   path_or_buf = path2msm + "/sequia_municipios_days.csv.bz2",
   compression = "bz2",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio         | cve_geo | org_cuenca              | clv_oc | con_cuenca            | cve_conc | full_date           | sequia     |
|:--------------|--------:|:-------------------------|--------:|:------------------------|:-------|:----------------------|---------:|:--------------------|:-----------|
| Oaxaca        |      20 | Magdalena Mixtepec       |   20048 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2010-05-31 00:00:00 | Sin sequia |
| Jalisco       |      14 | Atengo                   |   14011 | Lerma-Santiago-Pacífico | VIII   | Costa Pacifico Centro |       17 | 2003-10-18 00:00:00 | Sin sequia |
| Oaxaca        |      20 | Santo Domingo Tomaltepec |   20519 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2006-04-25 00:00:00 | Sin sequia |
| Oaxaca        |      20 | Santa Ana Ateixtlahuaca  |   20354 | Golfo Centro            | X      | Rio Papaloapan        |       21 | 2007-08-07 00:00:00 | Sin sequia |
| Oaxaca        |      20 | San Pedro Ocotepec       |   20323 | Golfo Centro            | X      | Rio Papaloapan        |       21 | 2022-10-11 00:00:00 | Sin sequia |

### Base de datos de Rachas de Sequía en Municipios

> \[!WARNING\]
>
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se publicó el registro del Monitor de Sequía de México

Muestra del archivo **`rachas_sequia_municipios.csv`**

``` python
db_rachas_mun.to_csv(
   path_or_buf = path2msm + "/rachas_sequia_municipios.csv",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio | cve_geo | org_cuenca              | clv_oc | con_cuenca                 | cve_conc | sequia     | full_date_start_racha | full_date_end_racha | racha_dias |
|:--------------|--------:|:-----------------|--------:|:------------------------|:-------|:---------------------------|---------:|:-----------|:----------------------|:--------------------|-----------:|
| Michoacán     |      16 | Zacapu           |   16107 | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala            |       15 | D1         | 2020-06-01 00:00:00   | 2020-06-15 00:00:00 |         14 |
| Hidalgo       |      13 | La Misión        |   13040 | Golfo Norte             | IX     | Rio Panuco                 |       19 | Sin sequia | 2016-09-16 00:00:00   | 2016-10-15 00:00:00 |         29 |
| Chiapas       |      07 | La Concordia     |   07020 | Frontera Sur            | XI     | Rios Grijalva y Usumacinta |       24 | Sin sequia | 2003-08-01 00:00:00   | 2003-08-31 00:00:00 |         30 |
| Veracruz      |      30 | Oteapan          |   30120 | Golfo Centro            | X      | Rio Coatzacoalcos          |       22 | D0         | 2008-03-01 00:00:00   | 2008-03-31 00:00:00 |         30 |
| Veracruz      |      30 | Colipa           |   30042 | Golfo Centro            | X      | Rios Tuxpan al Jamapa      |       20 | D0         | 2015-08-01 00:00:00   | 2015-09-30 00:00:00 |         60 |

### Base de datos de Máximas Rachas de Sequía en Municipios

> \[!WARNING\]
>
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se publicó el registro del Monitor de Sequía de México

Muestra del archivo **`max_rachas_sequia_municipios.csv`**

``` python
db_rachas_max_mun.to_csv(
   path_or_buf = path2msm + "/max_rachas_sequia_municipios.csv",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio                | cve_geo | org_cuenca   | clv_oc | con_cuenca        | cve_conc | sequia     | full_date_start_racha | full_date_end_racha | racha_dias |
|:--------------|--------:|:--------------------------------|--------:|:-------------|:-------|:------------------|---------:|:-----------|:----------------------|:--------------------|-----------:|
| Hidalgo       |      13 | Mineral del Monte               |   13039 | Golfo Norte  | IX     | Rio Panuco        |       19 | Sin sequia | 2013-06-01 00:00:00   | 2017-05-15 00:00:00 |       1444 |
| Querétaro     |      22 | Peñamiller                      |   22013 | Golfo Norte  | IX     | Rio Panuco        |       19 | D3         | 2023-09-01 00:00:00   | 2023-12-31 00:00:00 |        121 |
| Guerrero      |      12 | Alcozauca de Guerrero           |   12004 | Balsas       | IV     | Rio Balsas        |        9 | Sin sequia | 2003-10-01 00:00:00   | 2005-12-31 00:00:00 |        822 |
| Oaxaca        |      20 | Guevea de Humboldt              |   20036 | Golfo Centro | X      | Rio Coatzacoalcos |       22 | Sin sequia | 2011-06-01 00:00:00   | 2012-11-30 00:00:00 |        548 |
| Tlaxcala      |      29 | Apetatitlán de Antonio Carvajal |   29002 | Balsas       | IV     | Rio Balsas        |        9 | Sin sequia | 2013-06-01 00:00:00   | 2017-02-15 00:00:00 |       1355 |

> \[!NOTE\]
>
> Fecha de actualización del Monitor de Sequía de México: September 15, 2024
