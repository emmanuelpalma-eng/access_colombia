/* ============================================================================
   09. Stored procedures de carga masiva (esquema etl) - poc_colombia

   Formalizan el patron que hoy vive ad-hoc en import_data.py (DELETE +
   NOCHECK + INSERT + WITH CHECK CHECK CONSTRAINT). El login de ETL solo
   necesita EXECUTE sobre el esquema etl, no acceso directo a dbo.

   Los SPs son genericos por nombre de tabla (@TablaDestino/@TablaStaging):
   la columna a insertar se calcula dinamicamente como la interseccion (por
   nombre) entre sys.columns de destino y staging, excluyendo columnas
   IDENTITY del destino -- asi tbl_Centros.Id (IDENTITY) se autogenera sin
   necesitar manejo especial.
============================================================================ */

CREATE OR ALTER PROCEDURE [etl].[usp_RegistrarCarga]
    @TablaDestino   SYSNAME,
    @FilasCargadas  INT = NULL,
    @Resultado      NVARCHAR(20),
    @Mensaje        NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [etl].[tbl_Etl_Log] ([TablaDestino], [FilasCargadas], [Resultado], [Mensaje])
    VALUES (@TablaDestino, @FilasCargadas, @Resultado, @Mensaje);
END
GO

CREATE OR ALTER PROCEDURE [etl].[usp_ValidarFKsNoConfiables]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        fk.name AS ConstraintName,
        sch.name + '.' + tp.name AS Tabla,
        fk.is_not_trusted AS NoConfiable
    FROM sys.foreign_keys fk
    JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
    JOIN sys.schemas sch ON tp.schema_id = sch.schema_id
    WHERE fk.is_not_trusted = 1;
END
GO

CREATE OR ALTER PROCEDURE [etl].[usp_Particion_AgregarAnio]
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Boundary DATETIME2(0) = CAST(CAST(@Anio AS NVARCHAR(4)) + N'-01-01' AS DATETIME2(0));
    ALTER PARTITION SCHEME PS_Fecha_Anual NEXT USED [PRIMARY];
    ALTER PARTITION FUNCTION PF_Fecha_Anual() SPLIT RANGE (@Boundary);
END
GO

/* Reemplaza el contenido completo de una tabla DIMENSION desde su staging.
   Desactiva las FKs de OTRAS tablas que referencian a @TablaDestino (para
   poder hacer DELETE sin violarlas durante la recarga), y las revalida al
   final con WITH CHECK CHECK CONSTRAINT (no solo CHECK) -- si algun dato
   real queda huerfano, esto falla explicitamente en vez de dejarlo pasar
   en silencio. */
CREATE OR ALTER PROCEDURE [etl].[usp_ReemplazarDimension]
    @TablaDestino   SYSNAME,
    @TablaStaging   SYSNAME
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DestId INT = OBJECT_ID(@TablaDestino);
    DECLARE @StgId  INT = OBJECT_ID(@TablaStaging);
    IF @DestId IS NULL BEGIN THROW 50001, N'Tabla destino no existe', 1; END
    IF @StgId  IS NULL BEGIN THROW 50002, N'Tabla staging no existe', 1; END

    DECLARE @FKs TABLE (ConstraintName SYSNAME, ChildSchema SYSNAME, ChildTable SYSNAME);
    INSERT INTO @FKs
    SELECT fk.name, sch.name, tp.name
    FROM sys.foreign_keys fk
    JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
    JOIN sys.schemas sch ON tp.schema_id = sch.schema_id
    WHERE fk.referenced_object_id = @DestId;

    DECLARE @Sql NVARCHAR(MAX), @Filas INT = 0;
    DECLARE @cName SYSNAME, @cSchema SYSNAME, @cTable SYSNAME;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE fk_off CURSOR LOCAL FAST_FORWARD FOR
            SELECT ConstraintName, ChildSchema, ChildTable FROM @FKs;
        OPEN fk_off;
        FETCH NEXT FROM fk_off INTO @cName, @cSchema, @cTable;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Sql = N'ALTER TABLE ' + QUOTENAME(@cSchema) + N'.' + QUOTENAME(@cTable)
                     + N' NOCHECK CONSTRAINT ' + QUOTENAME(@cName);
            EXEC sp_executesql @Sql;
            FETCH NEXT FROM fk_off INTO @cName, @cSchema, @cTable;
        END
        CLOSE fk_off; DEALLOCATE fk_off;

        SET @Sql = N'DELETE FROM ' + @TablaDestino;
        EXEC sp_executesql @Sql;

        DECLARE @Cols NVARCHAR(MAX);
        SELECT @Cols = STRING_AGG(QUOTENAME(c.name), N', ')
        FROM sys.columns c
        JOIN sys.columns s ON s.object_id = @StgId AND s.name = c.name
        WHERE c.object_id = @DestId AND c.is_identity = 0;

        SET @Sql = N'INSERT INTO ' + @TablaDestino + N' (' + @Cols + N') SELECT ' + @Cols + N' FROM ' + @TablaStaging;
        EXEC sp_executesql @Sql;
        SET @Filas = @@ROWCOUNT;

        DECLARE fk_on CURSOR LOCAL FAST_FORWARD FOR
            SELECT ConstraintName, ChildSchema, ChildTable FROM @FKs;
        OPEN fk_on;
        FETCH NEXT FROM fk_on INTO @cName, @cSchema, @cTable;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Sql = N'ALTER TABLE ' + QUOTENAME(@cSchema) + N'.' + QUOTENAME(@cTable)
                     + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(@cName);
            EXEC sp_executesql @Sql;
            FETCH NEXT FROM fk_on INTO @cName, @cSchema, @cTable;
        END
        CLOSE fk_on; DEALLOCATE fk_on;

        COMMIT TRANSACTION;
        EXEC [etl].[usp_RegistrarCarga] @TablaDestino = @TablaDestino, @FilasCargadas = @Filas, @Resultado = N'OK';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        EXEC [etl].[usp_RegistrarCarga] @TablaDestino = @TablaDestino, @FilasCargadas = NULL, @Resultado = N'ERROR', @Mensaje = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

/* Carga (completa o solo un año) una tabla de HECHOS. Si @Anio viene
   informado, borra e inserta solo ese año (reproceso incremental de un
   cierre puntual); si es NULL, recarga completa. Deshabilita los indices
   no-clustered antes del insert y los reconstruye despues -- para POC se
   hace dentro de la misma transaccion por simplicidad; en un volumen mayor
   conviene sacar el REBUILD fuera de la transaccion para no alargar los
   locks. */
CREATE OR ALTER PROCEDURE [etl].[usp_CargarFactoParticionado]
    @TablaDestino           SYSNAME,
    @TablaStaging           SYSNAME,
    @Anio                   INT = NULL,
    @ReconstruirIndices     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DestId INT = OBJECT_ID(@TablaDestino);
    DECLARE @StgId  INT = OBJECT_ID(@TablaStaging);
    IF @DestId IS NULL BEGIN THROW 50001, N'Tabla destino no existe', 1; END
    IF @StgId  IS NULL BEGIN THROW 50002, N'Tabla staging no existe', 1; END

    DECLARE @FechaCol SYSNAME;
    SELECT @FechaCol = c.name FROM sys.columns c
    WHERE c.object_id = @DestId AND c.name IN (N'Fecha', N'FECHA');
    IF @FechaCol IS NULL BEGIN THROW 50003, N'No se encontro columna Fecha/FECHA en la tabla destino', 1; END

    DECLARE @Sql NVARCHAR(MAX), @Filas INT = 0;
    DECLARE @Where NVARCHAR(300) = N'';
    IF @Anio IS NOT NULL
        SET @Where = N' WHERE ' + QUOTENAME(@FechaCol) + N' >= ''' + CAST(@Anio AS NVARCHAR(4)) + N'-01-01'''
                   + N' AND ' + QUOTENAME(@FechaCol) + N' < ''' + CAST(@Anio + 1 AS NVARCHAR(4)) + N'-01-01''';

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @ReconstruirIndices = 1
        BEGIN
            DECLARE @Idx SYSNAME;
            DECLARE idx_off CURSOR LOCAL FAST_FORWARD FOR
                SELECT name FROM sys.indexes WHERE object_id = @DestId AND type = 2 AND is_disabled = 0;
            OPEN idx_off; FETCH NEXT FROM idx_off INTO @Idx;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @Sql = N'ALTER INDEX ' + QUOTENAME(@Idx) + N' ON ' + @TablaDestino + N' DISABLE';
                EXEC sp_executesql @Sql;
                FETCH NEXT FROM idx_off INTO @Idx;
            END
            CLOSE idx_off; DEALLOCATE idx_off;
        END

        SET @Sql = N'DELETE FROM ' + @TablaDestino + @Where;
        EXEC sp_executesql @Sql;

        DECLARE @Cols NVARCHAR(MAX);
        SELECT @Cols = STRING_AGG(QUOTENAME(c.name), N', ')
        FROM sys.columns c
        JOIN sys.columns s ON s.object_id = @StgId AND s.name = c.name
        WHERE c.object_id = @DestId AND c.is_identity = 0;

        SET @Sql = N'INSERT INTO ' + @TablaDestino + N' (' + @Cols + N') SELECT ' + @Cols + N' FROM ' + @TablaStaging + @Where;
        EXEC sp_executesql @Sql;
        SET @Filas = @@ROWCOUNT;

        IF @ReconstruirIndices = 1
        BEGIN
            DECLARE @Idx2 SYSNAME;
            DECLARE idx_on CURSOR LOCAL FAST_FORWARD FOR
                SELECT name FROM sys.indexes WHERE object_id = @DestId AND type = 2 AND is_disabled = 1;
            OPEN idx_on; FETCH NEXT FROM idx_on INTO @Idx2;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @Sql = N'ALTER INDEX ' + QUOTENAME(@Idx2) + N' ON ' + @TablaDestino + N' REBUILD';
                EXEC sp_executesql @Sql;
                FETCH NEXT FROM idx_on INTO @Idx2;
            END
            CLOSE idx_on; DEALLOCATE idx_on;
        END

        COMMIT TRANSACTION;
        EXEC [etl].[usp_RegistrarCarga] @TablaDestino = @TablaDestino, @FilasCargadas = @Filas, @Resultado = N'OK';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        EXEC [etl].[usp_RegistrarCarga] @TablaDestino = @TablaDestino, @FilasCargadas = NULL, @Resultado = N'ERROR', @Mensaje = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
