# poc_colombia — Modelo físico consolidado (6 fuentes Access → 1 SQL Server)

Reemplaza el enfoque anterior de un `schema.sql` por proyecto (`SIF_Colombia_351`,
`SIF_Colombia_Info_portafolio`) por **un solo modelo físico**, porque varias
tablas (`tbl_Fechas`, `tbl_Contratos`, `tbl_Inmuebles`, `tbl_Centros`,
`tbl_Cuentas`, `tbl_Niveles`, `tbl_Tiempos`, `tbl_Totales`, `tbl_Arrendatarios`,
`tbl_Fondos`) son en realidad la misma dimensión compartida entre varias de las
6 fuentes Access — partirlas por proyecto generaba definiciones duplicadas y
acoplamiento implícito entre carpetas (ya nos pasó: un proyecto rompía el FK
del otro).

**Importante**: este script define la estructura que el modelo *debería*
tener. No valida que los datos reales de los 6 Access ya la cumplan — eso es
un problema de carga/reconciliación de datos, deliberadamente fuera de
alcance de este release. Ver el diagrama `Bases_Colombia/SIF Colombia -
Modelo General (flujo de datos entre las 6 bases Access).json` para el mapa
de quién alimenta a quién.

**Estado**: probado de punta a punta con datos reales de FIC-351 e Info
Portafolio (ver sección "Carga de datos probada" más abajo) -- 0 FKs no
confiables, todos los conteos de fila esperados.

## Orden de ejecución

1. `Verificar_Version_SQL.sql` — confirmar que el servidor soporta particionamiento nativo (SQL Server 2017+, o 2016 SP1+) antes de seguir.
2. `schema/00_esquemas_y_control.sql`
3. `schema/01_dimensiones_maestras.sql`
4. `schema/02_dimensiones_historicas.sql`
5. `schema/03_particiones.sql` — **si el paso 1 indicó que no hay soporte**, saltar este paso y usar el plan B (ver abajo) antes de continuar con 04/05.
6. `schema/04_facts_valores.sql`
7. `schema/05_eeff_351.sql`
8. `schema/06_gastos_otros_raw.sql`
9. `schema/07_reportes.sql`
10. `schema/08_staging.sql`
11. `schema/09_sp_etl.sql`
12. `schema/10_sp_dimensiones.sql`
13. `schema/11_detalle_contratos_inmuebles.sql`

## Plan B si no hay particionamiento nativo disponible

Si `Verificar_Version_SQL.sql` muestra SQL Server 2016 RTM (sin SP1) o
anterior: no crear `03_particiones.sql`, y en su lugar dejar `tbl_Valores`,
`tbl_EEFF` y `tbl_Valores_2011_2023_PYG` como tablas normales (quitar la
cláusula `ON PS_Fecha_Anual(...)` de sus índices clustered en `04` y `05`).
Se puede simular particionamiento con vistas por año (`UNION ALL` + `CHECK`
constraints) más adelante si el volumen lo justifica, sin bloquear el resto
del release.

## Alcance de este release

Cubre el inventario completo de las 6 fuentes Access (ver el diagrama de
flujo), **excepto**:
- La capa derivada de Power BI (`tbl_PBI_*`, `tbl_TRM`, `tbl_Valores_Resumen`,
  `tbl_Perfil_Vcmtos_Viva_Malls`) — candidatas a convertirse en vistas SQL
  más adelante, requieren entender su lógica de cálculo primero.
- Artefactos de Access que no son datos reales (`*$_ErroresDeImportación`,
  `tbl_Fondos_Filtro`).

Carga/testing de datos reales para FIC-351, Info Portafolio y ahora todas
las dimensiones compartidas + detalle contractual/inmuebles (ver
`SIF_Colombia_Parametros/`, `SIF_Colombia_351/` y
`SIF_Colombia_Info_portafolio/`, cuyos `import_data.py` ya apuntan a este
esquema). Los loaders completos de Reportes/Gastos Otros/RE quedan para una
fase siguiente.

`Informes FIC - Parámetros.accdb` (+ 4 hojas de `Bases_Colombia\Input\*.xlsx`
sin tabla Access equivalente) se confirmó como la fuente autoritativa de las
dimensiones compartidas (conteos de fila exactos con las copias que traían
351/Info Portafolio/PowerBI) — ver `SIF_Colombia_Parametros/README.md`. Trae
además detalle nunca modelado antes: `tbl_Contratos_Detalle` (~80 columnas de
detalle legal/financiero por contrato), `tbl_Inmuebles_Estrategia`,
`tbl_Inmuebles_Compras`, `tbl_Inmuebles_MI_Contratos`, `tbl_MI`,
`tbl_Inmuebles_Otros`, `tbl_Contratos_Otros_Fondos`,
`tbl_Contratos_Restituidos_OtrosFondos` (ver `schema/11_detalle_contratos_
inmuebles.sql`). `SIF_Colombia_PowerBI/import_dimensiones.py` quedó
`.legacy` (supersedido).

## Carga de datos probada (orden real usado)

1. `SIF_Colombia_Parametros/import_data.py` -- carga **todas** las
   dimensiones compartidas (`tbl_Fechas`, `tbl_Niveles`, `tbl_Tiempos`,
   `tbl_Totales`, `tbl_Cuentas`, `tbl_Fondos`, `tbl_Arrendatarios`,
   `tbl_Centros`, `tbl_Usuarios`, `tbl_Inmuebles`, `tbl_Contratos`,
   `VL_Disp_xa_Venta`) + las tablas nuevas de detalle. **Requisito duro**:
   sin esto, los imports de 351 e Info Portafolio fallan por FK.
2. `SIF_Colombia_Info_portafolio/import_data.py` -- carga solo `tbl_Valores`
   (su hecho propio; las dimensiones que cargaba antes ahora las trae el
   paso 1).
3. `SIF_Colombia_351/import_data.py` -- carga solo sus hechos/EEFF propios
   (`tbl_Cuentas_EEFF`, `tbl_Cruce_SIF`, `tbl_Cruce351`,
   `tbl_Valores_Valor_Libros`, `tbl_ValorLibros_xInmueble`, `VL_CentralPoint`,
   `tbl_EEFF`, `F351`; las dimensiones que cargaba antes ahora las trae el
   paso 1).

Durante esta prueba se ajustaron, contra datos reales (no se habían
validado al escribir el schema por primera vez):
- Varias columnas de texto adivinadas demasiado angostas (truncamiento) →
  se ensancharon a `NVARCHAR(255)`.
- `[Valor]`/`SALDO`/campos de moneda de la familia de facts →
  `DECIMAL(18,4)`/`(19,4)` desbordaba con valores reales grandes →
  `DECIMAL(24,4)`/`(25,4)`.
- `F351.[Unidad de Captura]` y `[No asignado por la entidad]` tienen
  decimales reales pese al nombre → de `DECIMAL(18,0)` a `DECIMAL(18,4)`.
- 3 FKs adicionales resultaron insostenibles con datos reales (mismo patrón
  que las ya documentadas en cada schema): `tbl_Contratos` → `tbl_Inmuebles`,
  `tbl_EEFF` → `tbl_Cuentas_EEFF`, `tbl_Contratos` → `tbl_Arrendatarios`.
  Se eliminaron, se dejó índice.

## Esquemas SQL

- `dbo` — tablas de negocio.
- `stg` — staging: mismo layout que su tabla destino en `dbo`, sin PK/FK/
  IDENTITY. El proceso de carga puebla `stg.*` y llama a los SPs de `etl.*`
  para mover los datos a `dbo` con las validaciones correspondientes.
- `etl` — SPs de carga masiva (`usp_ReemplazarDimension`,
  `usp_CargarFactoParticionado`, `usp_Particion_AgregarAnio`,
  `usp_RegistrarCarga`, `usp_ValidarFKsNoConfiables`) + bitácora
  `etl.tbl_Etl_Log`.
- `app` — SPs CRUD de dimensiones, pensados para que la futura API/front en
  React los llame en vez de tocar `dbo` directamente. Auditoría centralizada
  en `dbo.tbl_Auditoria_Cambios`.

## Particionamiento

Función `PF_Fecha_Anual` / esquema `PS_Fecha_Anual`, rangos anuales
2009–2028, sobre la columna `Fecha`/`FECHA` de `tbl_Valores`, `tbl_EEFF` y
`tbl_Valores_2011_2023_PYG` (las 3 tablas de hechos más grandes). Mantenimiento
anual: `EXEC etl.usp_Particion_AgregarAnio @Anio = <año>` antes de que la
última partición acumule más de un año de datos nuevos.
