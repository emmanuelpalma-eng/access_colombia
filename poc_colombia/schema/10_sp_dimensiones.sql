/* ============================================================================
   10. Stored procedures CRUD de dimensiones (esquema app) - poc_colombia

   Pensados para que la futura API/front en React llame a estos SPs en vez
   de tocar dbo.* directamente -- centraliza validaciones de negocio y
   auditoria (dbo.tbl_Auditoria_Cambios) en un solo lugar. El login de la
   API solo necesita EXECUTE sobre el esquema app.

   Lecturas no llevan SP (se sirven con SELECT/vistas directas desde la API).
============================================================================ */

/* Helper generico: cuenta cuantas filas en CUALQUIER tabla con FK real hacia
   (@Tabla, @Columna) referencian @Valor. Se usa antes de cada DELETE para
   dar un mensaje de negocio claro en vez de dejar reventar el constraint. */
CREATE OR ALTER PROCEDURE [app].[usp_Util_ContarReferencias]
    @Tabla      SYSNAME,
    @Columna    SYSNAME,
    @Valor      NVARCHAR(400),
    @Total      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TablaId INT = OBJECT_ID(@Tabla);
    SET @Total = 0;

    DECLARE @Sql NVARCHAR(MAX), @ChildSchema SYSNAME, @ChildTable SYSNAME, @ChildCol SYSNAME, @Parcial INT;

    DECLARE fk_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT sch.name, tp.name, cc.name
        FROM sys.foreign_key_columns fkc
        JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
        JOIN sys.schemas sch ON tp.schema_id = sch.schema_id
        JOIN sys.columns cc ON cc.object_id = fkc.parent_object_id AND cc.column_id = fkc.parent_column_id
        JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
        WHERE fkc.referenced_object_id = @TablaId AND rc.name = @Columna;

    OPEN fk_cur;
    FETCH NEXT FROM fk_cur INTO @ChildSchema, @ChildTable, @ChildCol;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Sql = N'SELECT @P = COUNT(*) FROM ' + QUOTENAME(@ChildSchema) + N'.' + QUOTENAME(@ChildTable)
                 + N' WHERE ' + QUOTENAME(@ChildCol) + N' = @V';
        EXEC sp_executesql @Sql, N'@V NVARCHAR(400), @P INT OUTPUT', @V = @Valor, @P = @Parcial OUTPUT;
        SET @Total += ISNULL(@Parcial, 0);
        FETCH NEXT FROM fk_cur INTO @ChildSchema, @ChildTable, @ChildCol;
    END
    CLOSE fk_cur; DEALLOCATE fk_cur;
END
GO

/* ============================================================
   tbl_Niveles
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Niveles_Insertar]
    @Cod_Nivel INT, @Nom_Nivel NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    INSERT INTO [dbo].[tbl_Niveles] ([Cod_Nivel], [Nom_Nivel]) VALUES (@Cod_Nivel, @Nom_Nivel);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Niveles', 'I', CAST(@Cod_Nivel AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Niveles_Actualizar]
    @Cod_Nivel INT, @Nom_Nivel NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Niveles] SET [Nom_Nivel] = @Nom_Nivel WHERE [Cod_Nivel] = @Cod_Nivel;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Nivel no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Niveles', 'U', CAST(@Cod_Nivel AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Niveles_Eliminar]
    @Cod_Nivel INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Niveles', @Columna = N'Cod_Nivel', @Valor = @Cod_Nivel, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: Cod_Nivel tiene tablas dependientes con FK (tbl_Centros/tbl_Totales/tbl_Valores*)', 1; END
    DELETE FROM [dbo].[tbl_Niveles] WHERE [Cod_Nivel] = @Cod_Nivel;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Nivel no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Niveles', 'D', CAST(@Cod_Nivel AS NVARCHAR(400)));
END
GO

/* ============================================================
   tbl_Tiempos
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Tiempos_Insertar]
    @Cod_Tiempo INT, @Nom_Tiempo NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    INSERT INTO [dbo].[tbl_Tiempos] ([Cod_Tiempo], [Nom_Tiempo]) VALUES (@Cod_Tiempo, @Nom_Tiempo);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Tiempos', 'I', CAST(@Cod_Tiempo AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Tiempos_Actualizar]
    @Cod_Tiempo INT, @Nom_Tiempo NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Tiempos] SET [Nom_Tiempo] = @Nom_Tiempo WHERE [Cod_Tiempo] = @Cod_Tiempo;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Tiempo no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Tiempos', 'U', CAST(@Cod_Tiempo AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Tiempos_Eliminar]
    @Cod_Tiempo INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Tiempos', @Columna = N'Cod_Tiempo', @Valor = @Cod_Tiempo, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: Cod_Tiempo tiene tablas dependientes con FK', 1; END
    DELETE FROM [dbo].[tbl_Tiempos] WHERE [Cod_Tiempo] = @Cod_Tiempo;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Tiempo no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Tiempos', 'D', CAST(@Cod_Tiempo AS NVARCHAR(400)));
END
GO

/* ============================================================
   tbl_Fondos
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Fondos_Insertar]
    @COD_FONDO INT, @COD_FONDO_FIDU INT = NULL, @ABREV_FONDO NVARCHAR(20) = NULL,
    @NOM_CORTO_FONDO NVARCHAR(50) = NULL, @NOM_FONDO NVARCHAR(500) = NULL,
    @FIDU NVARCHAR(255) = NULL, @FONDO NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    INSERT INTO [dbo].[tbl_Fondos] ([COD_FONDO], [COD_FONDO_FIDU], [ABREV_FONDO], [NOM_CORTO_FONDO], [NOM_FONDO], [FIDU], [FONDO])
    VALUES (@COD_FONDO, @COD_FONDO_FIDU, @ABREV_FONDO, @NOM_CORTO_FONDO, @NOM_FONDO, @FIDU, @FONDO);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Fondos', 'I', CAST(@COD_FONDO AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Fondos_Actualizar]
    @COD_FONDO INT, @COD_FONDO_FIDU INT = NULL, @ABREV_FONDO NVARCHAR(20) = NULL,
    @NOM_CORTO_FONDO NVARCHAR(50) = NULL, @NOM_FONDO NVARCHAR(500) = NULL,
    @FIDU NVARCHAR(255) = NULL, @FONDO NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Fondos] SET
        [COD_FONDO_FIDU] = @COD_FONDO_FIDU, [ABREV_FONDO] = @ABREV_FONDO, [NOM_CORTO_FONDO] = @NOM_CORTO_FONDO,
        [NOM_FONDO] = @NOM_FONDO, [FIDU] = @FIDU, [FONDO] = @FONDO
    WHERE [COD_FONDO] = @COD_FONDO;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'COD_FONDO no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Fondos', 'U', CAST(@COD_FONDO AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Fondos_Eliminar]
    @COD_FONDO INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Fondos', @Columna = N'COD_FONDO', @Valor = @COD_FONDO, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: COD_FONDO tiene tablas dependientes con FK (tbl_Centros/tbl_Inmuebles/tbl_Contratos/tbl_EEFF/tbl_Valores*)', 1; END
    DELETE FROM [dbo].[tbl_Fondos] WHERE [COD_FONDO] = @COD_FONDO;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'COD_FONDO no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Fondos', 'D', CAST(@COD_FONDO AS NVARCHAR(400)));
END
GO

/* ============================================================
   tbl_Arrendatarios
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Arrendatarios_Insertar]
    @NIT NVARCHAR(20), @Nom_Arrend NVARCHAR(255) = NULL, @NomCorto_Arrend NVARCHAR(100) = NULL,
    @GRUPO_ECON NVARCHAR(255) = NULL, @Sector_Arrend NVARCHAR(100) = NULL,
    @Calif_Arrend NVARCHAR(20) = NULL, @Contacto_Arrend NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    INSERT INTO [dbo].[tbl_Arrendatarios] ([NIT], [Nom_Arrend], [NomCorto_Arrend], [GRUPO_ECON], [Sector_Arrend], [Calif_Arrend], [Contacto_Arrend])
    VALUES (@NIT, @Nom_Arrend, @NomCorto_Arrend, @GRUPO_ECON, @Sector_Arrend, @Calif_Arrend, @Contacto_Arrend);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Arrendatarios', 'I', @NIT);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Arrendatarios_Actualizar]
    @NIT NVARCHAR(20), @Nom_Arrend NVARCHAR(255) = NULL, @NomCorto_Arrend NVARCHAR(100) = NULL,
    @GRUPO_ECON NVARCHAR(255) = NULL, @Sector_Arrend NVARCHAR(100) = NULL,
    @Calif_Arrend NVARCHAR(20) = NULL, @Contacto_Arrend NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Arrendatarios] SET
        [Nom_Arrend] = @Nom_Arrend, [NomCorto_Arrend] = @NomCorto_Arrend, [GRUPO_ECON] = @GRUPO_ECON,
        [Sector_Arrend] = @Sector_Arrend, [Calif_Arrend] = @Calif_Arrend, [Contacto_Arrend] = @Contacto_Arrend
    WHERE [NIT] = @NIT;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'NIT no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Arrendatarios', 'U', @NIT);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Arrendatarios_Eliminar]
    @NIT NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Arrendatarios', @Columna = N'NIT', @Valor = @NIT, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: NIT tiene contratos asociados', 1; END
    DELETE FROM [dbo].[tbl_Arrendatarios] WHERE [NIT] = @NIT;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'NIT no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Arrendatarios', 'D', @NIT);
END
GO

/* ============================================================
   tbl_Cuentas
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Cuentas_Insertar]
    @Cod_Cuenta INT, @Cuenta NVARCHAR(255) = NULL, @Signo INT = NULL, @Agrupación NVARCHAR(100) = NULL,
    @Agrup_Gastos INT = NULL, @Cálculo INT = NULL, @Por_inmueble INT = NULL, @Divisor DECIMAL(12,2) = NULL,
    @Suma INT = NULL, @Unidades INT = NULL, @Ranking_Inm INT = NULL, @Mostrar_pie INT = NULL,
    @Dispers_EjeX INT = NULL, @Dispers_EjeY INT = NULL, @Dispers_Burb INT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @Divisor IS NOT NULL AND @Divisor NOT BETWEEN 0.01 AND 1000000
        BEGIN THROW 51004, N'Divisor debe estar entre 0.01 y 1,000,000', 1; END
    INSERT INTO [dbo].[tbl_Cuentas]
        ([Cod_Cuenta], [Cuenta], [Signo], [Agrupación], [Agrup_Gastos], [Cálculo], [Por inmueble], [Divisor],
         [Suma], [Unidades], [Ranking_Inm], [Mostrar_pie], [Dispers_EjeX], [Dispers_EjeY], [Dispers_Burb])
    VALUES
        (@Cod_Cuenta, @Cuenta, @Signo, @Agrupación, @Agrup_Gastos, @Cálculo, @Por_inmueble, @Divisor,
         @Suma, @Unidades, @Ranking_Inm, @Mostrar_pie, @Dispers_EjeX, @Dispers_EjeY, @Dispers_Burb);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Cuentas', 'I', CAST(@Cod_Cuenta AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Cuentas_Actualizar]
    @Cod_Cuenta INT, @Cuenta NVARCHAR(255) = NULL, @Signo INT = NULL, @Agrupación NVARCHAR(100) = NULL,
    @Agrup_Gastos INT = NULL, @Cálculo INT = NULL, @Por_inmueble INT = NULL, @Divisor DECIMAL(12,2) = NULL,
    @Suma INT = NULL, @Unidades INT = NULL, @Ranking_Inm INT = NULL, @Mostrar_pie INT = NULL,
    @Dispers_EjeX INT = NULL, @Dispers_EjeY INT = NULL, @Dispers_Burb INT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @Divisor IS NOT NULL AND @Divisor NOT BETWEEN 0.01 AND 1000000
        BEGIN THROW 51004, N'Divisor debe estar entre 0.01 y 1,000,000', 1; END
    UPDATE [dbo].[tbl_Cuentas] SET
        [Cuenta] = @Cuenta, [Signo] = @Signo, [Agrupación] = @Agrupación, [Agrup_Gastos] = @Agrup_Gastos,
        [Cálculo] = @Cálculo, [Por inmueble] = @Por_inmueble, [Divisor] = @Divisor, [Suma] = @Suma,
        [Unidades] = @Unidades, [Ranking_Inm] = @Ranking_Inm, [Mostrar_pie] = @Mostrar_pie,
        [Dispers_EjeX] = @Dispers_EjeX, [Dispers_EjeY] = @Dispers_EjeY, [Dispers_Burb] = @Dispers_Burb
    WHERE [Cod_Cuenta] = @Cod_Cuenta;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Cuenta no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Cuentas', 'U', CAST(@Cod_Cuenta AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Cuentas_Eliminar]
    @Cod_Cuenta INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Cuentas', @Columna = N'Cod_Cuenta', @Valor = @Cod_Cuenta, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: Cod_Cuenta tiene tablas dependientes con FK (tbl_Valores*)', 1; END
    DELETE FROM [dbo].[tbl_Cuentas] WHERE [Cod_Cuenta] = @Cod_Cuenta;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Cod_Cuenta no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Cuentas', 'D', CAST(@Cod_Cuenta AS NVARCHAR(400)));
END
GO

/* ============================================================
   tbl_Totales  (PK compuesta Cod_Nivel + Cod_Total)
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Totales_Insertar]
    @Cod_Nivel INT, @Cod_Total NVARCHAR(10), @Nom_Total NVARCHAR(255) = NULL,
    @Cruce1 NVARCHAR(255) = NULL, @Cruce2 NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM [dbo].[tbl_Niveles] WHERE [Cod_Nivel] = @Cod_Nivel)
        BEGIN THROW 51005, N'Cod_Nivel no existe en tbl_Niveles', 1; END
    INSERT INTO [dbo].[tbl_Totales] ([Cod_Nivel], [Cod_Total], [Nom_Total], [Cruce1], [Cruce2])
    VALUES (@Cod_Nivel, @Cod_Total, @Nom_Total, @Cruce1, @Cruce2);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Totales', 'I', CAST(@Cod_Nivel AS NVARCHAR(20)) + N'|' + @Cod_Total);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Totales_Actualizar]
    @Cod_Nivel INT, @Cod_Total NVARCHAR(10), @Nom_Total NVARCHAR(255) = NULL,
    @Cruce1 NVARCHAR(255) = NULL, @Cruce2 NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Totales] SET [Nom_Total] = @Nom_Total, [Cruce1] = @Cruce1, [Cruce2] = @Cruce2
    WHERE [Cod_Nivel] = @Cod_Nivel AND [Cod_Total] = @Cod_Total;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(Cod_Nivel, Cod_Total) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Totales', 'U', CAST(@Cod_Nivel AS NVARCHAR(20)) + N'|' + @Cod_Total);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Totales_Eliminar]
    @Cod_Nivel INT, @Cod_Total NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DELETE FROM [dbo].[tbl_Totales] WHERE [Cod_Nivel] = @Cod_Nivel AND [Cod_Total] = @Cod_Total;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(Cod_Nivel, Cod_Total) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Totales', 'D', CAST(@Cod_Nivel AS NVARCHAR(20)) + N'|' + @Cod_Total);
END
GO

/* ============================================================
   tbl_Centros  (PK subrogado Id; NO valida unicidad de Cod_Nivel+Cod_Centro
   a proposito -- hay pares legitimos, ej. arrendatario real + fila VACANTE)
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Centros_Insertar]
    @Cod_Nivel INT, @Cod_Fondo INT = NULL, @Cod_Centro NVARCHAR(20), @Nombre NVARCHAR(255) = NULL,
    @Tipologia NVARCHAR(100) = NULL, @Subtipologia NVARCHAR(100) = NULL, @Ubicacion NVARCHAR(255) = NULL,
    @Inmueble NVARCHAR(255) = NULL, @Arrendatario NVARCHAR(255) = NULL, @GRUPO_ECON NVARCHAR(255) = NULL,
    @Sector_Arrend NVARCHAR(100) = NULL, @Riesgo NVARCHAR(50) = NULL, @VENC_YR INT = NULL,
    @Id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM [dbo].[tbl_Niveles] WHERE [Cod_Nivel] = @Cod_Nivel)
        BEGIN THROW 51005, N'Cod_Nivel no existe en tbl_Niveles', 1; END
    INSERT INTO [dbo].[tbl_Centros]
        ([Cod_Nivel], [Cod_Fondo], [Cod_Centro], [Nombre], [Tipologia], [Subtipologia], [Ubicacion],
         [Inmueble], [Arrendatario], [GRUPO_ECON], [Sector_Arrend], [Riesgo], [VENC_YR])
    VALUES
        (@Cod_Nivel, @Cod_Fondo, @Cod_Centro, @Nombre, @Tipologia, @Subtipologia, @Ubicacion,
         @Inmueble, @Arrendatario, @GRUPO_ECON, @Sector_Arrend, @Riesgo, @VENC_YR);
    SET @Id = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Centros', 'I', CAST(@Id AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Centros_Actualizar]
    @Id INT, @Cod_Nivel INT, @Cod_Fondo INT = NULL, @Cod_Centro NVARCHAR(20), @Nombre NVARCHAR(255) = NULL,
    @Tipologia NVARCHAR(100) = NULL, @Subtipologia NVARCHAR(100) = NULL, @Ubicacion NVARCHAR(255) = NULL,
    @Inmueble NVARCHAR(255) = NULL, @Arrendatario NVARCHAR(255) = NULL, @GRUPO_ECON NVARCHAR(255) = NULL,
    @Sector_Arrend NVARCHAR(100) = NULL, @Riesgo NVARCHAR(50) = NULL, @VENC_YR INT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Centros] SET
        [Cod_Nivel] = @Cod_Nivel, [Cod_Fondo] = @Cod_Fondo, [Cod_Centro] = @Cod_Centro, [Nombre] = @Nombre,
        [Tipologia] = @Tipologia, [Subtipologia] = @Subtipologia, [Ubicacion] = @Ubicacion, [Inmueble] = @Inmueble,
        [Arrendatario] = @Arrendatario, [GRUPO_ECON] = @GRUPO_ECON, [Sector_Arrend] = @Sector_Arrend,
        [Riesgo] = @Riesgo, [VENC_YR] = @VENC_YR
    WHERE [Id] = @Id;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Id no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Centros', 'U', CAST(@Id AS NVARCHAR(400)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Centros_Eliminar]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Cod_Centro NVARCHAR(20);
    SELECT @Cod_Centro = [Cod_Centro] FROM [dbo].[tbl_Centros] WHERE [Id] = @Id;
    IF @Cod_Centro IS NULL BEGIN THROW 51001, N'Id no existe', 1; END
    -- Cod_Centro no tiene FK formal desde tbl_Valores* por diseño (ver
    -- 01_dimensiones_maestras.sql) -- se valida igual para no dejar
    -- huerfanos "silenciosos" en las tablas de hechos.
    IF EXISTS (SELECT 1 FROM [dbo].[tbl_Valores] WHERE [Cod_Centro] = @Cod_Centro)
        BEGIN THROW 51003, N'No se puede eliminar: Cod_Centro tiene filas en tbl_Valores (considera borrado logico en vez de fisico)', 1; END
    DELETE FROM [dbo].[tbl_Centros] WHERE [Id] = @Id;
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Centros', 'D', CAST(@Id AS NVARCHAR(400)));
END
GO

/* ============================================================
   tbl_Inmuebles  (PK compuesta Fecha + Cod_Inm)
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Inmuebles_Insertar]
    @Fecha DATETIME2(0), @Cod_Fondo INT = NULL, @Cod_Inm DECIMAL(18,0), @Nom_Inm NVARCHAR(255) = NULL,
    @Ubicacion NVARCHAR(255) = NULL, @Direccion NVARCHAR(255) = NULL, @Tipologia NVARCHAR(100) = NULL,
    @Estado NVARCHAR(50) = NULL, @Latitud FLOAT = NULL, @Longitud FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM [dbo].[tbl_Fechas] WHERE [Mes] = @Fecha)
        BEGIN THROW 51005, N'Fecha no existe en tbl_Fechas', 1; END
    INSERT INTO [dbo].[tbl_Inmuebles] ([Fecha], [Cod_Fondo], [Cod_Inm], [Nom_Inm], [Ubicacion], [Direccion], [Tipologia], [Estado], [Latitud], [Longitud])
    VALUES (@Fecha, @Cod_Fondo, @Cod_Inm, @Nom_Inm, @Ubicacion, @Direccion, @Tipologia, @Estado, @Latitud, @Longitud);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Inmuebles', 'I', CONVERT(NVARCHAR(20), @Fecha, 23) + N'|' + CAST(@Cod_Inm AS NVARCHAR(30)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Inmuebles_Actualizar]
    @Fecha DATETIME2(0), @Cod_Inm DECIMAL(18,0), @Cod_Fondo INT = NULL, @Nom_Inm NVARCHAR(255) = NULL,
    @Ubicacion NVARCHAR(255) = NULL, @Direccion NVARCHAR(255) = NULL, @Tipologia NVARCHAR(100) = NULL,
    @Estado NVARCHAR(50) = NULL, @Latitud FLOAT = NULL, @Longitud FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Inmuebles] SET
        [Cod_Fondo] = @Cod_Fondo, [Nom_Inm] = @Nom_Inm, [Ubicacion] = @Ubicacion, [Direccion] = @Direccion,
        [Tipologia] = @Tipologia, [Estado] = @Estado, [Latitud] = @Latitud, [Longitud] = @Longitud
    WHERE [Fecha] = @Fecha AND [Cod_Inm] = @Cod_Inm;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(Fecha, Cod_Inm) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Inmuebles', 'U', CONVERT(NVARCHAR(20), @Fecha, 23) + N'|' + CAST(@Cod_Inm AS NVARCHAR(30)));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Inmuebles_Eliminar]
    @Fecha DATETIME2(0), @Cod_Inm DECIMAL(18,0)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF EXISTS (SELECT 1 FROM [dbo].[tbl_Contratos] WHERE [FECHA] = @Fecha AND [COD_INM] = @Cod_Inm)
        BEGIN THROW 51002, N'No se puede eliminar: (Fecha, Cod_Inm) tiene contratos asociados', 1; END
    DELETE FROM [dbo].[tbl_Inmuebles] WHERE [Fecha] = @Fecha AND [Cod_Inm] = @Cod_Inm;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(Fecha, Cod_Inm) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Inmuebles', 'D', CONVERT(NVARCHAR(20), @Fecha, 23) + N'|' + CAST(@Cod_Inm AS NVARCHAR(30)));
END
GO

/* ============================================================
   tbl_Contratos  (PK compuesta FECHA + COD_CTR + ESTADO)
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Contratos_Insertar]
    @FECHA DATETIME2(0), @COD_FONDO INT = NULL, @ESTADO NVARCHAR(30), @COD_CTR NVARCHAR(20),
    @NIT NVARCHAR(20) = NULL, @NOM_ARREND NVARCHAR(255) = NULL, @COD_INM DECIMAL(18,0),
    @DET_INM NVARCHAR(255) = NULL, @GLA DECIMAL(18,2) = NULL, @Tipologia NVARCHAR(100) = NULL,
    @Fec_Inicio DATETIME2(0) = NULL, @Fec_Fin DATETIME2(0) = NULL, @IncremCanon NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @ESTADO NOT IN (N'VIGENTE', N'RESTITUIDO', N'NO VIGENTE')
        BEGIN THROW 51004, N'ESTADO debe ser VIGENTE, RESTITUIDO o NO VIGENTE', 1; END
    IF NOT EXISTS (SELECT 1 FROM [dbo].[tbl_Inmuebles] WHERE [Fecha] = @FECHA AND [Cod_Inm] = @COD_INM)
        BEGIN THROW 51005, N'(FECHA, COD_INM) no existe en tbl_Inmuebles', 1; END
    INSERT INTO [dbo].[tbl_Contratos]
        ([FECHA], [COD_FONDO], [ESTADO], [COD_CTR], [NIT], [NOM_ARREND], [COD_INM], [DET_INM], [GLA], [Tipologia], [Fec_Inicio], [Fec_Fin], [IncremCanon])
    VALUES
        (@FECHA, @COD_FONDO, @ESTADO, @COD_CTR, @NIT, @NOM_ARREND, @COD_INM, @DET_INM, @GLA, @Tipologia, @Fec_Inicio, @Fec_Fin, @IncremCanon);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor])
        VALUES ('tbl_Contratos', 'I', CONVERT(NVARCHAR(20), @FECHA, 23) + N'|' + @COD_CTR + N'|' + @ESTADO);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Contratos_Actualizar]
    @FECHA DATETIME2(0), @COD_CTR NVARCHAR(20), @ESTADO NVARCHAR(30), @COD_FONDO INT = NULL,
    @NIT NVARCHAR(20) = NULL, @NOM_ARREND NVARCHAR(255) = NULL, @COD_INM DECIMAL(18,0) = NULL,
    @DET_INM NVARCHAR(255) = NULL, @GLA DECIMAL(18,2) = NULL, @Tipologia NVARCHAR(100) = NULL,
    @Fec_Inicio DATETIME2(0) = NULL, @Fec_Fin DATETIME2(0) = NULL, @IncremCanon NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Contratos] SET
        [COD_FONDO] = @COD_FONDO, [NIT] = @NIT, [NOM_ARREND] = @NOM_ARREND, [COD_INM] = @COD_INM,
        [DET_INM] = @DET_INM, [GLA] = @GLA, [Tipologia] = @Tipologia, [Fec_Inicio] = @Fec_Inicio,
        [Fec_Fin] = @Fec_Fin, [IncremCanon] = @IncremCanon
    WHERE [FECHA] = @FECHA AND [COD_CTR] = @COD_CTR AND [ESTADO] = @ESTADO;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(FECHA, COD_CTR, ESTADO) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor])
        VALUES ('tbl_Contratos', 'U', CONVERT(NVARCHAR(20), @FECHA, 23) + N'|' + @COD_CTR + N'|' + @ESTADO);
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Contratos_Eliminar]
    @FECHA DATETIME2(0), @COD_CTR NVARCHAR(20), @ESTADO NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DELETE FROM [dbo].[tbl_Contratos] WHERE [FECHA] = @FECHA AND [COD_CTR] = @COD_CTR AND [ESTADO] = @ESTADO;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'(FECHA, COD_CTR, ESTADO) no existe', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor])
        VALUES ('tbl_Contratos', 'D', CONVERT(NVARCHAR(20), @FECHA, 23) + N'|' + @COD_CTR + N'|' + @ESTADO);
END
GO

/* ============================================================
   tbl_Fechas  (mantenimiento fila-a-fila + generador de rango en bloque,
   que es el caso de uso real: el calendario se genera de una vez, no fila
   por fila)
   ============================================================ */
CREATE OR ALTER PROCEDURE [app].[usp_Fechas_Actualizar]
    @Mes DATETIME2(0), @Mostrar INT = NULL, @LTM INT = NULL, @YTD INT = NULL,
    @Mostrar_Vista_Años INT = NULL, @Mostrar_Vista_Histórica INT = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    UPDATE [dbo].[tbl_Fechas] SET
        [Mostrar] = @Mostrar, [LTM] = @LTM, [YTD] = @YTD,
        [Mostrar_Vista_Años] = @Mostrar_Vista_Años, [Mostrar_Vista_Histórica] = @Mostrar_Vista_Histórica
    WHERE [Mes] = @Mes;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Mes no existe en tbl_Fechas', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Fechas', 'U', CONVERT(NVARCHAR(20), @Mes, 23));
END
GO
CREATE OR ALTER PROCEDURE [app].[usp_Fechas_Eliminar]
    @Mes DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Refs INT;
    EXEC [app].[usp_Util_ContarReferencias] @Tabla = N'dbo.tbl_Fechas', @Columna = N'Mes', @Valor = @Mes, @Total = @Refs OUTPUT;
    IF @Refs > 0 BEGIN THROW 51002, N'No se puede eliminar: Mes tiene tablas dependientes con FK (tbl_Inmuebles/tbl_EEFF/F351/etc.)', 1; END
    DELETE FROM [dbo].[tbl_Fechas] WHERE [Mes] = @Mes;
    IF @@ROWCOUNT = 0 BEGIN THROW 51001, N'Mes no existe en tbl_Fechas', 1; END
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor]) VALUES ('tbl_Fechas', 'D', CONVERT(NVARCHAR(20), @Mes, 23));
END
GO
/* Genera/completa el calendario para un rango de meses (caso de uso real:
   se corre una vez al año agregando los meses nuevos, no fila por fila). */
CREATE OR ALTER PROCEDURE [app].[usp_Fechas_GenerarRango]
    @FechaInicio DATE, @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    ;WITH Meses AS (
        SELECT DATEFROMPARTS(YEAR(@FechaInicio), MONTH(@FechaInicio), 1) AS PrimerDiaMes
        UNION ALL
        SELECT DATEADD(MONTH, 1, PrimerDiaMes) FROM Meses WHERE PrimerDiaMes < @FechaFin
    ),
    FinDeMes AS (
        SELECT EOMONTH(PrimerDiaMes) AS Mes FROM Meses
    )
    INSERT INTO [dbo].[tbl_Fechas] ([Mes], [Num_Mes], [Año], [Nom_Mes], [Trimestre])
    SELECT
        CAST(f.Mes AS DATETIME2(0)),
        MONTH(f.Mes),
        YEAR(f.Mes),
        DATENAME(MONTH, f.Mes),
        N'T' + CAST(DATEPART(QUARTER, f.Mes) AS NVARCHAR(1))
    FROM FinDeMes f
    WHERE NOT EXISTS (SELECT 1 FROM [dbo].[tbl_Fechas] t WHERE t.[Mes] = CAST(f.Mes AS DATETIME2(0)))
    OPTION (MAXRECURSION 400);
    INSERT INTO [dbo].[tbl_Auditoria_Cambios] ([Tabla], [Operacion], [PK_Valor])
        VALUES ('tbl_Fechas', 'I', N'rango ' + CONVERT(NVARCHAR(10), @FechaInicio, 23) + N' a ' + CONVERT(NVARCHAR(10), @FechaFin, 23));
END
GO
