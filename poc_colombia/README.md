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

Carga/testing de datos reales por ahora solo para FIC-351 e Info Portafolio
(ver `SIF_Colombia_351/` y `SIF_Colombia_Info_portafolio/`, cuyo
`import_data.py` ya apunta a este esquema). Los loaders de Reportes/Gastos
Otros/RE/PowerBI quedan para una fase siguiente.

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
