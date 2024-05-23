# Procesamiento y transformación de datos: Sequía en México
Isaac Arroyo
23 de mayo de 2024

## Introducción y objetivos

En este documento se encuentra documentado el código usado para la
extracción, transformación, estandarización y la creación de nuevos
conjuntos de datos a partir del registro de sequía en los municipios del
país del [**Monitor de Sequía de México
(MSM)**](https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico).

A través del registro de sequía en los municipios se espera tener 4
bases de datos:

1.  El registro mensual o quincenal (depende de la fecha) de sequía en
    formato *tidy*
2.  El registro diario de sequía en formato *tidy*
3.  El registro del tiempo de duración del tipo de sequía (racha)
4.  El registro del tiempo de duración máximo del tipo de sequía (racha
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

### Asignar unidad de fecha a la columna `full_date`

Tras la transformación *wide2long*, hace falta transformar la columna
`full_date` a lo que es, una fecha.

Previo transformar los valores a `np.datetime`, se tiene que eliminar
los caracteres `'_00_00_00'` y sustiuir los guiones bajos (`_`) por
guiones medios (`-`)

``` python
msm_long['full_date'] = (msm_long['full_date']
                         .str.replace("_00_00_00", "")
                         .str.replace("_", "-"))

msm_long['full_date'] = pd.to_datetime(arg = msm_long['full_date'],
                                       errors= 'coerce')
```

## El registro de sequía en formato *tidy* (registro mensual, quincenal y diario)

Para esta ocasión, el registro de sequía se completará con el tipo de
sequía diaria, esto asumiendo que cuando la publicación era mensual
representa la sequía del mes del registro, mientras que para las
publicaciones quincenales es de los últimos 15 días.

> *Ejemplo:*
>
> • *Fecha publicación y tipo de sequia : Mayo 31 del 2005, D3*
>
> Se traduce a que del Mayo 01 - Mayo 31 de 2005, todos los días serán
> etiquetados con sequía D3
>
> • *Fecha publicación y tipo de sequia : Mayo 31 del 2024, D3*
>
> Se traduce a que del Mayo 01 - Mayo 14 de 2024, todos los días serán
> etiquetados con sequía D3

### Función para completar días

Esta función toma un grupo (un municipios) y completará la serie de
tiempo por día. Con los valores `NaN` de sequía, se llenarán con el
registro siguiente al que se tiene (que no sea `NaN`)

``` python
def func_llenado_dias_sequia(group):
    
    # La fecha inicia el el inicio del 2003
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
  .groupby('cve_concatenada')
  .apply(func_llenado_dias_sequia, include_groups = False)
  .reset_index(drop = False)
  .drop(columns = ["level_1"]))
```

| cve_concatenada | full_date           | sequia     |
|----------------:|:--------------------|:-----------|
|           20464 | 2016-08-30 00:00:00 | D0         |
|           20306 | 2007-12-09 00:00:00 | Sin sequia |
|           11040 | 2023-10-22 00:00:00 | D3         |
|           32036 | 2007-10-15 00:00:00 | Sin sequia |
|           08045 | 2004-07-16 00:00:00 | Sin sequia |

## Cálculo de rachas y rachas máximas

A partir de los datos procesados (**`msm_long_filled`**) se irá iterando
por cada uno de los municipios para obtener sus rachas de sequía y a
partir de estas las de mayor duración.

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
|           30102 | D0         |    30 | 2008-04-01 00:00:00   | 2008-04-30 00:00:00 |         29 |
|           21153 | Sin sequia |    31 | 2005-10-01 00:00:00   | 2005-10-31 00:00:00 |         30 |
|           20043 | D0         |    30 | 2007-06-01 00:00:00   | 2007-06-30 00:00:00 |         29 |
|           19016 | D1         |    30 | 2020-04-01 00:00:00   | 2020-04-30 00:00:00 |         29 |
|           20532 | D0         |    31 | 2021-01-01 00:00:00   | 2021-01-31 00:00:00 |         30 |

Muestra de `db_rachas_max_mun`

| cve_concatenada | sequia | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-------|------:|:----------------------|:--------------------|-----------:|
|           20414 | D1     |   304 | 2022-08-01 00:00:00   | 2023-05-31 00:00:00 |        303 |
|           30013 | D3     |    61 | 2024-03-16 00:00:00   | 2024-05-15 00:00:00 |         60 |
|           05011 | D3     |   182 | 2011-09-01 00:00:00   | 2012-02-29 00:00:00 |        181 |
|           15119 | D2     |   153 | 2023-06-16 00:00:00   | 2023-11-15 00:00:00 |        152 |
|           08053 | D2     |   289 | 2023-08-01 00:00:00   | 2024-05-15 00:00:00 |        288 |

## Reasignar nombre de Estados, Municipios y Cuencas

A partir de la creación de `msm_long_filled`, todos los conjuntos de
datos excluyen las claves y nombres de los Estados, Municipios (este
únicamente el nombre) y Cuencas.

Por lo que se completaran a las bases de datos de interés, previo a ser
guardadas.

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
                                   right_on = 'cve_mun')
                          .drop(columns = ['cve_concatenada']))
```

``` python
Markdown(
   cve_nom_ent_mun_cuenca
   .sample(n = 5, random_state = 11)
   .to_markdown(index = False))
```

| org_cuenca              | clv_oc | con_cuenca            | cve_conc | nombre_estado | cve_ent | nombre_municipio   | cve_mun |
|:------------------------|:-------|:----------------------|---------:|:--------------|--------:|:-------------------|--------:|
| Golfo Centro            | X      | Rios Tuxpan al Jamapa |       20 | Puebla        |      21 | Camocuautla        |   21028 |
| Golfo Centro            | X      | Rio Papaloapan        |       21 | Oaxaca        |      20 | San Pedro Ocotepec |   20323 |
| Lerma-Santiago-Pacífico | VIII   | Costa Pacifico Centro |       17 | Jalisco       |      14 | Ayutla             |   14017 |
| Golfo Centro            | X      | Rio Papaloapan        |       21 | Veracruz      |      30 | Carrillo Puerto    |   30031 |
| Río Bravo               | VI     | Rio Bravo             |       12 | Chihuahua     |      08 | Satevó             |   08061 |

Unir con las bases de datos de interés y reordenar las columnas

``` python
msm_long = (pd.merge(
    left = msm_long[['cve_concatenada', 'full_date', 'sequia']],
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_mun')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'full_date', 'sequia']])

msm_long_filled = (pd.merge(
    left = msm_long_filled,
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_mun')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'full_date', 'sequia']])

db_rachas_mun = (pd.merge(
    left = db_rachas_mun,                      
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_mun')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento y selección de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'sequia', 'full_date_start_racha', 'full_date_end_racha',
    'racha_dias']])

db_rachas_max_mun = (pd.merge(
    left = db_rachas_max_mun,
    right = cve_nom_ent_mun_cuenca,
    how = 'left',
    left_on = 'cve_concatenada',
    right_on = 'cve_mun')
  .drop(columns = ['cve_concatenada'])
  # Reordenamiento y selección de las columnas
  [['nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun',
    'org_cuenca', 'clv_oc', 'con_cuenca', 'cve_conc',
    'sequia', 'full_date_start_racha', 'full_date_end_racha',
    'racha_dias']])
```

## Guardar bases de datos

### Bases de datos de Sequía en Municipios

Se crearán dos bases de datos a partir de este procesamiento de datos:

- **`msm_long`** : Datos de sequía de la CONAGUA en *long format*
- **`msm_long_filled`** : Datos de sequía diarios en *long format*
  (Modificado)

Para ambos casos se eliminarán las los registros de Agosto 2003 y
Febrero 2004. En el documento XLSX, en el apartado de Notas, se comunica
que por factores externos, el MSM no se elaboró en esas fechas.

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

Las máscaras identifican las fechas donde no hubo MSM, sin embargo lo
que busca es **omitirlas**, no aislarlas, es por eso que para crear la
base de datos se *niegan* las condiciones, para que se incluya todo lo
que no cumpla la máscara.

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

| nombre_estado    | cve_ent | nombre_municipio      | cve_mun | org_cuenca   | clv_oc | con_cuenca            | cve_conc | full_date           | sequia     |
|:-----------------|--------:|:----------------------|--------:|:-------------|:-------|:----------------------|---------:|:--------------------|:-----------|
| Estado de México |      15 | San José del Rincón   |   15124 | Balsas       | IV     | Rio Balsas            |        9 | 2014-04-15 00:00:00 | D0         |
| Veracruz         |      30 | Ixmatlahuacan         |   30084 | Golfo Centro | X      | Rio Papaloapan        |       21 | 2009-09-30 00:00:00 | D0         |
| Puebla           |      21 | Jonotla               |   21088 | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2003-11-30 00:00:00 | Sin sequia |
| Veracruz         |      30 | Coxquihui             |   30050 | Golfo Centro | X      | Rios Tuxpan al Jamapa |       20 | 2012-05-31 00:00:00 | Sin sequia |
| Guerrero         |      12 | Zihuatanejo de Azueta |   12038 | Pacífico Sur | V      | Costa de Guerrero     |       10 | 2014-07-31 00:00:00 | D0         |

Muestra del archivo **`sequia_municipios_days.csv.bz2`**

``` python
db_msm_mod.to_csv(
   path_or_buf = path2msm + "/sequia_municipios_days.csv.bz2",
   compression = "bz2",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio           | cve_mun | org_cuenca           | clv_oc | con_cuenca                 | cve_conc | full_date           | sequia     |
|:--------------|--------:|:---------------------------|--------:|:---------------------|:-------|:---------------------------|---------:|:--------------------|:-----------|
| Tlaxcala      |      29 | Santa Ana Nopalucan        |   29056 | Balsas               | IV     | Rio Balsas                 |        9 | 2014-02-18 00:00:00 | Sin sequia |
| Tabasco       |      27 | Macuspana                  |   27012 | Frontera Sur         | XI     | Rios Grijalva y Usumacinta |       24 | 2012-10-07 00:00:00 | Sin sequia |
| Oaxaca        |      20 | Santa Cruz Tacache de Mina |   20381 | Balsas               | IV     | Rio Balsas                 |        9 | 2004-04-30 00:00:00 | Sin sequia |
| Yucatán       |      31 | Teya                       |   31088 | Península De Yucatán | XII    | Peninsula de Yucatan       |       25 | 2011-05-19 00:00:00 | D3         |
| Chiapas       |      07 | Teopisca                   |   07094 | Frontera Sur         | XI     | Rios Grijalva y Usumacinta |       24 | 2012-08-23 00:00:00 | Sin sequia |

### Base de datos de Rachas de Sequía en Municipios

> \[!WARNING\]
>
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se
> publicó el registro del Monitor de Sequía de México

Muestra del archivo **`rachas_sequia_municipios.csv`**

``` python
db_rachas_mun.to_csv(
   path_or_buf = path2msm + "/rachas_sequia_municipios.csv",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio    | cve_mun | org_cuenca           | clv_oc | con_cuenca           | cve_conc | sequia     | full_date_start_racha | full_date_end_racha | racha_dias |
|:--------------|--------:|:--------------------|--------:|:---------------------|:-------|:---------------------|---------:|:-----------|:----------------------|:--------------------|-----------:|
| Guerrero      |      12 | Xochihuehuetlán     |   12070 | Balsas               | IV     | Rio Balsas           |        9 | Sin sequia | 2003-08-01 00:00:00   | 2003-08-31 00:00:00 |         30 |
| Tamaulipas    |      28 | Camargo             |   28007 | Río Bravo            | VI     | Rio Bravo            |       12 | D0         | 2014-09-01 00:00:00   | 2014-09-15 00:00:00 |         14 |
| Tlaxcala      |      29 | San Juan Huactzinco |   29053 | Balsas               | IV     | Rio Balsas           |        9 | Sin sequia | 2005-10-01 00:00:00   | 2005-10-31 00:00:00 |         30 |
| Yucatán       |      31 | Ticul               |   31089 | Península De Yucatán | XII    | Peninsula de Yucatan |       25 | D0         | 2003-02-01 00:00:00   | 2003-02-28 00:00:00 |         27 |
| Yucatán       |      31 | Motul               |   31052 | Península De Yucatán | XII    | Peninsula de Yucatan |       25 | D0         | 2022-12-01 00:00:00   | 2022-12-31 00:00:00 |         30 |

### Base de datos de Máximas Rachas de Sequía en Municipios

> \[!WARNING\]
>
> Tomar en cuenta las fechas (Agosto 2003 y Febrero 2004) que no se
> publicó el registro del Monitor de Sequía de México

Muestra del archivo **`max_rachas_sequia_municipios.csv`**

``` python
db_rachas_max_mun.to_csv(
   path_or_buf = path2msm + "/max_rachas_sequia_municipios.csv",
   index = False)
```

| nombre_estado | cve_ent | nombre_municipio       | cve_mun | org_cuenca              | clv_oc | con_cuenca       | cve_conc | sequia | full_date_start_racha | full_date_end_racha | racha_dias |
|:--------------|--------:|:-----------------------|--------:|:------------------------|:-------|:-----------------|---------:|:-------|:----------------------|:--------------------|-----------:|
| Guanajuato    |      11 | San Felipe             |   11030 | Lerma-Santiago-Pacífico | VIII   | Rio Panuco       |       19 | D2     | 2022-04-16 00:00:00   | 2022-08-15 00:00:00 |        121 |
| Oaxaca        |      20 | Santiago Astata        |   20453 | Pacífico Sur            | V      | Costa de Oaxaca  |       11 | D0     | 2004-10-01 00:00:00   | 2005-05-31 00:00:00 |        242 |
| Oaxaca        |      20 | Santiago Huajolotitlán |   20462 | Balsas                  | IV     | Rio Balsas       |        9 | D2     | 2023-10-01 00:00:00   | 2023-11-15 00:00:00 |         45 |
| Zacatecas     |      32 | Loreto                 |   32024 | Lerma-Santiago-Pacífico | VIII   | Rio Santiago     |       16 | D0     | 2008-03-01 00:00:00   | 2008-06-30 00:00:00 |        121 |
| Chiapas       |      07 | Escuintla              |   07032 | Frontera Sur            | XI     | Costa de Chiapas |       23 | D1     | 2015-06-16 00:00:00   | 2015-11-30 00:00:00 |        167 |
