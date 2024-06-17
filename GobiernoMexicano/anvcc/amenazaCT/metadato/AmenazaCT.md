---
output:
  html_document: default
  pdf_document: default
---


    10 de agosto del 2022, Ciudad de México 

# Amenaza por frecuencia e intensidad de ciclones tropicales en las cuencas de los municipios costeros

En el siguiente metadato presenta un insumo de la evaluación del criterio exposición de la vulnerabilidad de asentamientos humanos por ciclones tropicales a partir del análisis de la frecuencia e intensidad de ciclones tropicales en las cuencas de los municipios costeros, basado en una modificación de la metodología de CENAPRED (2022).

## Insumos

* Cuencas Hidrológicas - CONAGUA,2010
* Línea Costera - CONABIO, 2018
* División municipal - INEGI, 2020
* Registro histórico de Huracanes (1851-2021) - NOAA, 2022

## Diccionario

 1.  **id**: Número de cuenca hidrológica
 2.  **Nombre_RHA**: Nombre de la región hidrológica
 3.  **nombreCuen**: Nombre de la cuenca hidrológica
 4.  **nivAmenaza**: Nivel de amenaza evaluado

## Información del Provedor

  * Almacenamiento: ESRI Shapefile
  * Codificación: UTF-8
  * Geometría: Polígono (MultiPolígono)
  * Extensión: 1071072.6777457795105875,319366.3437911586370319 : 4074899.6883624983020127,2349629.1448305631056428
  * Número de objetos: 491

## Sistema de Cordenadas de Referencia

  * Nombre: EPSG:6372 - Mexico ITRF2008 / LCC
  * Unidades: metros
  * Método: Cónica conforme de Lambert

## Procedimiento

El primer procedimiento consiste en la delimitación del objeto de estudio a partir de la integración de los insumos de CONABIO (2018), INEGI (2020) y CONAGUA(2010), para poder obtener las cuencas de los municipios costeros.

  * A partir del límite costero (CONABIO,2018) e seleccionaron los municipios (INEGI,2020) que tocan este límite, siendo 152 municipios costeros

  * Se seleccionaron las cuencas que intersectan total o parcialmente en los muncipios costeros (152), además se añadieron manualmente tres cuencas hidrológicas (Río Cucharas, Arroyo Carbajal y Tapanatepec) que tienen influencia de lagunas costeras.

Posteriormente se incorporó el insumo de ciclones tropicales de la NOAA (2022) del registro histórico que abarca desde 1851 a 2021 (200 años), utilizando solamente los registros en la escala Saffir Simpson de depresión tropical a huracán caterogría 5.

  * A partir del insumo se realizó un _buffer_ de 20 km a las trayectorias de ciclones tropicales.

  * Con el resultado del buffer se realizó una intersección espacial con las cuencas de los municipios costeros para obtener el dato de frecuencia e intensidad de impacto por cuenca.

  * Se realizó la evaluación de la tasa de excedencia según CENAPRED (2006). Finalmente se múltiplico la tasa de excedencia por la intensidad correspondiente.

## Resultados

Se identificaron 9 (nueve) cuencas hidrológicas en Muy Alto, 41 (cuarenta y uno) en Alto, 60 (sesenta) en Medio, 120 (ciento veinte) en Bajo y 261 (doscientos sesenta y uno) en Muy Bajo.