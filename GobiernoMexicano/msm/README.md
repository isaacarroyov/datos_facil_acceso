# Procesamiento y transformación de datos: Sequía en México
Isaac Arroyo
16 de julio de 2024

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

``` python
import pandas as pd
from janitor import clean_names
from numpy.random import randint, seed
from IPython.display import Markdown
```

## Descarga y transformación del registro de sequía en los municipios

Como primer paso es modificar la base de datos del MSM para que este en
formato *tidy*, ya que originalmente las columnas son la fecha del
registro.

``` python
msm_og = pd.read_excel(
   io = "".join(["https://smn.conagua.gob.mx/tools/RESOURCES/Monitor%20de",
                 "%20Sequia%20en%20Mexico/MunicipiosSequia.xlsx"]),
   dtype= 'object')

msm_og = msm_og.clean_names(remove_special = True)
```

> \[!NOTE\]  
> La tabla muestra únicamente una muestra de las columnas de fecha del
> registro

| cve_concatenada | cve_ent | cve_mun | nombre_mun             | entidad             | org_cuenca              | clv_oc | con_cuenca                 | cve_conc | 2016_07_31_00_00_00 | 2009_10_31_00_00_00 | 2010_09_30_00_00_00 | 2019_10_31_00_00_00 |
|----------------:|--------:|--------:|:-----------------------|:--------------------|:------------------------|:-------|:---------------------------|---------:|:--------------------|:--------------------|--------------------:|:--------------------|
|           21098 |      21 |     098 | Molcaxac               | Puebla              | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D0                  |                 nan | nan                 |
|           27012 |      27 |     012 | Macuspana              | Tabasco             | Frontera Sur            | XI     | Rios Grijalva y Usumacinta |       24 | D1                  | D3                  |                 nan | D3                  |
|           20306 |      20 |     306 | San Pedro el Alto      | Oaxaca              | Pacífico Sur            | V      | Costa de Oaxaca            |       11 | D0                  | nan                 |                 nan | nan                 |
|           16086 |      16 |     086 | Tanhuato               | Michoacán de Ocampo | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala            |       15 | D1                  | D2                  |                 nan | D1                  |
|           15004 |      15 |     004 | Almoloya de Alquisiras | Estado de México    | Balsas                  | IV     | Rio Balsas                 |        9 | nan                 | D1                  |                 nan | D0                  |

A partir de esta tabla, enlistan los cambios necesarios:

1.  Hacer el cambio de *wide format* a *long format*
2.  Eliminar los registros Agosto 2003 y Febrero 2004
    <!-- TODO: ESCRIBIR CORRECTAMENTE LOS PASOS A SEGUIR EN EL TRABAJO -->

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

| cve_concatenada | cve_ent | cve_mun | nombre_mun           | entidad                         | org_cuenca              | clv_oc | con_cuenca      | cve_conc |           full_date | sequia     |
|----------------:|--------:|--------:|:---------------------|:--------------------------------|:------------------------|:-------|:----------------|---------:|--------------------:|:-----------|
|           11026 |      11 |     026 | Romita               | Guanajuato                      | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala |       15 | 2017_10_31_00_00_00 | Sin sequia |
|           19021 |      19 |     021 | Gral. Escobedo       | Nuevo León                      | Río Bravo               | VI     | Rio Bravo       |       12 | 2014_07_15_00_00_00 | D1         |
|           30195 |      30 |     195 | Xoxocotla            | Veracruz de Ignacio de la Llave | Golfo Centro            | X      | Rio Papaloapan  |       21 | 2017_02_28_00_00_00 | Sin sequia |
|           20434 |      20 |     434 | Santa María Teopoxco | Oaxaca                          | Golfo Centro            | X      | Rio Papaloapan  |       21 | 2007_10_31_00_00_00 | Sin sequia |
|           16050 |      16 |     050 | Maravatío            | Michoacán de Ocampo             | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala |       15 | 2021_12_31_00_00_00 | D0         |

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
| 2021-02-20 00:00:00 |           12080 | D1         |
| 2012-09-04 00:00:00 |           30106 | Sin sequia |
| 2003-10-17 00:00:00 |           15024 | Sin sequia |
| 2008-11-19 00:00:00 |           16100 | D1         |
| 2014-05-09 00:00:00 |           24002 | Sin sequia |

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
|           15101 | D0         |    30 | 2003-09-01 00:00:00   | 2003-09-30 00:00:00 |         29 |
|           31097 | Sin sequia |    15 | 2016-04-01 00:00:00   | 2016-04-15 00:00:00 |         14 |
|           30064 | D1         |    15 | 2016-04-16 00:00:00   | 2016-04-30 00:00:00 |         14 |
|           30118 | D1         |    61 | 2011-04-01 00:00:00   | 2011-05-31 00:00:00 |         60 |
|           07106 | D2         |    16 | 2024-05-16 00:00:00   | 2024-05-31 00:00:00 |         15 |

Muestra de `db_rachas_max_mun`

| cve_concatenada | sequia | racha | full_date_start_racha | full_date_end_racha | racha_dias |
|----------------:|:-------|------:|:----------------------|:--------------------|-----------:|
|           30138 | D3     |    30 | 2011-06-01 00:00:00   | 2011-06-30 00:00:00 |         29 |
|           14101 | D0     |   184 | 2019-07-01 00:00:00   | 2019-12-31 00:00:00 |        183 |
|           26039 | D3     |   182 | 2020-10-01 00:00:00   | 2021-03-31 00:00:00 |        181 |
|           31034 | D3     |   181 | 2009-09-01 00:00:00   | 2010-02-28 00:00:00 |        180 |
|           25008 | D0     |   242 | 2016-11-16 00:00:00   | 2017-07-15 00:00:00 |        241 |

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

| nombre_estado | cve_ent | nombre_municipio               | cve_geo | org_cuenca              | clv_oc | con_cuenca            | cve_conc | full_date           | sequia     |
|:--------------|--------:|:-------------------------------|--------:|:------------------------|:-------|:----------------------|---------:|:--------------------|:-----------|
| Oaxaca        |      20 | La Reforma                     |   20076 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2017-07-31 00:00:00 | D0         |
| Jalisco       |      14 | Tuxcacuesco                    |   14106 | Lerma-Santiago-Pacífico | VIII   | Costa Pacifico Centro |       17 | 2019-03-31 00:00:00 | D0         |
| Oaxaca        |      20 | San Juan Bautista Guelache     |   20178 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2023-10-31 00:00:00 | D0         |
| Oaxaca        |      20 | Santa María Jalapa del Marqués |   20418 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2015-02-15 00:00:00 | Sin sequia |
| Oaxaca        |      20 | San Juan Ozolotepec            |   20211 | Pacífico Sur            | V      | Costa de Oaxaca       |       11 | 2012-10-31 00:00:00 | Sin sequia |

Muestra del archivo **`sequia_municipios_days.csv.bz2`**

``` python
db_msm_mod.to_csv(
   path_or_buf = path2msm + "/sequia_municipios_days.csv.bz2",
   compression = "bz2",
   index = False)
```

| nombre_estado    | cve_ent | nombre_municipio | cve_geo | org_cuenca           | clv_oc | con_cuenca           | cve_conc | full_date           | sequia     |
|:-----------------|--------:|:-----------------|--------:|:---------------------|:-------|:---------------------|---------:|:--------------------|:-----------|
| Quintana Roo     |      23 | Bacalar          |   23010 | Península De Yucatán | XII    | Peninsula de Yucatan |       25 | 2018-07-27 00:00:00 | Sin sequia |
| Estado de México |      15 | Temascaltepec    |   15086 | Balsas               | IV     | Rio Balsas           |        9 | 2010-11-30 00:00:00 | Sin sequia |
| Sonora           |      26 | Opodepe          |   26045 | Noroeste             | II     | Alto Noroeste        |        3 | 2014-12-01 00:00:00 | Sin sequia |
| Oaxaca           |      20 | San Pedro Yólox  |   20336 | Golfo Centro         | X      | Rio Papaloapan       |       21 | 2009-05-16 00:00:00 | D0         |
| Hidalgo          |      13 | Atlapexco        |   13011 | Golfo Norte          | IX     | Rio Panuco           |       19 | 2011-11-16 00:00:00 | D0         |

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

| nombre_estado | cve_ent | nombre_municipio     | cve_geo | org_cuenca              | clv_oc | con_cuenca        | cve_conc | sequia     | full_date_start_racha | full_date_end_racha | racha_dias |
|:--------------|--------:|:---------------------|--------:|:------------------------|:-------|:------------------|---------:|:-----------|:----------------------|:--------------------|-----------:|
| Chihuahua     |      08 | Guadalupe            |   08028 | Río Bravo               | VI     | Rio Bravo         |       12 | D2         | 2008-04-01 00:00:00   | 2008-05-31 00:00:00 |         60 |
| Guanajuato    |      11 | Cortazar             |   11011 | Lerma-Santiago-Pacífico | VIII   | Lerma - Chapala   |       15 | D1         | 2017-05-16 00:00:00   | 2017-07-15 00:00:00 |         60 |
| Veracruz      |      30 | Isla                 |   30077 | Golfo Centro            | X      | Rio Papaloapan    |       21 | D0         | 2011-08-01 00:00:00   | 2011-08-31 00:00:00 |         30 |
| Guerrero      |      12 | Juchitán             |   12080 | Pacífico Sur            | V      | Costa de Guerrero |       10 | Sin sequia | 2014-10-01 00:00:00   | 2015-03-31 00:00:00 |        181 |
| Oaxaca        |      20 | San Miguel el Grande |   20269 | Pacífico Sur            | V      | Costa de Oaxaca   |       11 | D1         | 2014-09-01 00:00:00   | 2014-09-30 00:00:00 |         29 |

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

| nombre_estado    | cve_ent | nombre_municipio       | cve_geo | org_cuenca                | clv_oc | con_cuenca        | cve_conc | sequia | full_date_start_racha | full_date_end_racha | racha_dias |
|:-----------------|--------:|:-----------------------|--------:|:--------------------------|:-------|:------------------|---------:|:-------|:----------------------|:--------------------|-----------:|
| Hidalgo          |      13 | Tepehuacán de Guerrero |   13062 | Golfo Norte               | IX     | Rio Panuco        |       19 | D0     | 2004-08-01 00:00:00   | 2005-01-31 00:00:00 |        183 |
| Ciudad de México |      09 | La Magdalena Contreras |   09008 | Aguas del Valle de México | XIII   | Valle de Mexico   |       26 | D2     | 2009-01-01 00:00:00   | 2009-08-31 00:00:00 |        242 |
| Oaxaca           |      20 | San Juan Cacahuatepec  |   20185 | Pacífico Sur              | V      | Costa de Oaxaca   |       11 | D0     | 2021-09-01 00:00:00   | 2023-01-15 00:00:00 |        501 |
| Veracruz         |      30 | Mecayapan              |   30104 | Golfo Centro              | X      | Rio Coatzacoalcos |       22 | D0     | 2022-07-16 00:00:00   | 2023-02-15 00:00:00 |        214 |
| Jalisco          |      14 | Degollado              |   14033 | Lerma-Santiago-Pacífico   | VIII   | Lerma - Chapala   |       15 | D1     | 2008-11-01 00:00:00   | 2009-07-31 00:00:00 |        272 |
