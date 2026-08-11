/* ============================================================================
   07. Fuente "Reportes" - tablas exclusivas - poc_colombia

   Analisis: las 14 tablas de "Informes FIC - Reportes.accdb" resultaron ser
   TODAS copias de dimensiones/facts ya cubiertos en 01-06 (tbl_Arrendatarios,
   tbl_Centros, tbl_Contratos, tbl_Cuentas, tbl_Fechas, tbl_Inmuebles,
   tbl_Niveles, tbl_Tiempos, tbl_Totales, tbl_Valores) o de las tablas
   compartidas con Gastos Otros ya unificadas en 06_gastos_otros_raw.sql
   (PREDIAL_AVALCAT, Seguros_Rentas_Anual, SegurosTRDM_Anual). No queda
   ninguna tabla exclusiva de Reportes por crear.

   Se deja aqui solo tbl_Usuarios (aparece en 351/PowerBI/Reportes/Gastos
   Otros/RE, 2 filas -- login basico de Access). Se incluye por completitud;
   lo mas probable es que quede obsoleta cuando exista autenticacion real en
   el aplicativo/API futuro.
============================================================================ */

CREATE TABLE [dbo].[tbl_Usuarios] (
    [Usuario]   NVARCHAR(100)   NOT NULL,
    CONSTRAINT [PK_tbl_Usuarios] PRIMARY KEY CLUSTERED ([Usuario])
);
GO
