/* Utilidad: borra todas las tablas de staging para poder recrearlas limpias
   (ej. despues de un cambio de tipo de columna como el de Valor DECIMAL->FLOAT).
   Correr esto y luego volver a correr 08_staging.sql completo. */

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'DROP TABLE [stg].[' + t.name + N'];' + CHAR(13)
FROM sys.tables t
WHERE SCHEMA_NAME(t.schema_id) = 'stg';

EXEC sp_executesql @sql;
