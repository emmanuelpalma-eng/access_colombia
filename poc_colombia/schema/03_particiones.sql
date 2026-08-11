/* ============================================================================
   03. Particionamiento por año - poc_colombia

   Antes de correr este script, correr Verificar_Version_SQL.sql (en la
   carpeta raiz de poc_colombia) y confirmar que el servidor lo soporta.

   Una sola funcion y esquema de particion, reutilizados por todas las
   tablas de hechos con grano mensual (04_facts_valores.sql). Rango RANGE
   RIGHT anual: el limite (1-enero) pertenece a la particion de la derecha,
   asi el 31-dic de un año queda correctamente en la particion de ese año.
   Rango desde 2009 (el historico mas antiguo visto es 2008-10) hasta 2028
   (colchon de 2+ años hacia adelante).

   Mantenimiento: correr etl.usp_Particion_AgregarAnio (ver 09_sp_etl.sql)
   una vez al año para dividir la ultima particion antes de que acumule mas
   de un año de datos.
============================================================================ */

CREATE PARTITION FUNCTION PF_Fecha_Anual (DATETIME2(0))
AS RANGE RIGHT FOR VALUES (
    '2009-01-01', '2010-01-01', '2011-01-01', '2012-01-01', '2013-01-01',
    '2014-01-01', '2015-01-01', '2016-01-01', '2017-01-01', '2018-01-01',
    '2019-01-01', '2020-01-01', '2021-01-01', '2022-01-01', '2023-01-01',
    '2024-01-01', '2025-01-01', '2026-01-01', '2027-01-01', '2028-01-01'
);
GO

CREATE PARTITION SCHEME PS_Fecha_Anual
AS PARTITION PF_Fecha_Anual ALL TO ([PRIMARY]);
GO
