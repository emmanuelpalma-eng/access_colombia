# SIF Colombia - PowerBI (legacy)

**Supersedido por `Colombia/SIF_Colombia_Parametros/`**. "Informes FIC -
Parámetros.accdb" se confirmó como la fuente autoritativa de las dimensiones
compartidas (conteos de fila exactos con `tbl_Fondos`/`tbl_Arrendatarios` y
el resto del modelo), así que `import_dimensiones.py` se renombró a
`import_dimensiones.py.legacy` y ya no se debe correr contra `poc_colombia`.

Se mantiene solo como referencia histórica del motivo original por el que
existió este mini-proyecto (ver cabecera del `.legacy`): al probar el modelo
consolidado con datos reales, `SIF_Colombia_351` e `SIF_Colombia_Info_portafolio`
fallaban por FKs contra `tbl_Fondos` sin cargar, y PowerBI fue el primer
origen disponible para resolverlo antes de encontrar `Parámetros.accdb`.

El resto de PowerBI (24 tablas: `tbl_Contratos`/`tbl_Inmuebles`/`tbl_Centros`
son copias ya cubiertas por otras fuentes; `tbl_PBI_*`, `tbl_TRM`,
`tbl_Valores_Resumen`, etc. son la capa derivada para dashboards, pendiente
de diseño) sigue fuera de alcance.
