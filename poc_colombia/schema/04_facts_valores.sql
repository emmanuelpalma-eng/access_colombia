/* ============================================================================
   04. Facts "Valores" - poc_colombia

   Familia de tablas de hechos, todas con un grano similar:
   Fecha + Cod_Tiempo + [Cod_Fondo] + Cod_Nivel + Cod_Centro + Cod_Cuenta -> Valor.
   Nombres de columna normalizados a esta convencion aunque el origen use
   mayusculas/nombres distintos (ej. VAL, COD_CTR, COD_CTA) -- ver nota en
   cada tabla.

   Sin PK (son tablas de hechos puras). Sin FK hacia tbl_Centros por diseño:
   tbl_Centros no tiene llave natural 100% unica (ver 01_dimensiones_maestras.sql),
   asi que Cod_Centro se deja solo con indice, nunca con FK forzada -- mismo
   criterio ya usado en SIF_Colombia_351/Info_Portafolio.

   tbl_Valores, tbl_EEFF (05_eeff_351.sql) y tbl_Valores_2011_2023_PYG van
   sobre PS_Fecha_Anual (particionadas). El resto de la familia queda en
   [PRIMARY] por ahora (volumen menor), pero con el mismo indice clustered
   (Fecha primero) para poder convertir a particionada sin rediseño cuando
   crezca -- ver 03_particiones.sql.
============================================================================ */

/* ============================================================
   tbl_Valores  (FACT MAESTRO, particionada)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO]),
    CONSTRAINT [FK_tbl_Valores_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
) ON [PRIMARY];
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Clustered] ON [dbo].[tbl_Valores]([Fecha], [Cod_Nivel], [Cod_Cuenta])
    ON PS_Fecha_Anual([Fecha]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Cod_Fondo] ON [dbo].[tbl_Valores]([Cod_Fondo], [Fecha], [Cod_Nivel])
    INCLUDE ([Cod_Cuenta], [Cod_Centro], [Valor]) ON PS_Fecha_Anual([Fecha]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Cod_Centro] ON [dbo].[tbl_Valores]([Cod_Centro], [Fecha])
    INCLUDE ([Cod_Nivel], [Cod_Cuenta], [Valor]) ON PS_Fecha_Anual([Fecha]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Cod_Cuenta] ON [dbo].[tbl_Valores]([Cod_Cuenta], [Fecha])
    INCLUDE ([Cod_Nivel], [Cod_Centro], [Cod_Fondo], [Valor]) ON PS_Fecha_Anual([Fecha]);
GO

/* Nota: la tabla se crea "ON [PRIMARY]" y el indice clustered se crea
   despues "ON PS_Fecha_Anual" -- en SQL Server, una tabla sin PK/clustered
   index propio en su CREATE TABLE se vuelve particionada recien cuando se
   crea el indice clustered sobre el partition scheme. Si el motor exige
   crear la tabla directamente sobre el esquema, usar en su lugar:
   CREATE TABLE ... ON PS_Fecha_Anual([Fecha]) y omitir el paso de arriba. */

/* ============================================================
   tbl_Valores_Valor_Libros  (~10K filas, fuente 351)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Valor_Libros] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Valor_Libros_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Valor_Libros_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Valor_Libros_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Valor_Libros_Clustered] ON [dbo].[tbl_Valores_Valor_Libros]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Valor_Libros_Cod_Centro] ON [dbo].[tbl_Valores_Valor_Libros]([Cod_Centro], [Fecha]) INCLUDE ([Cod_Nivel], [Cod_Cuenta], [Valor]);
GO

/* ============================================================
   tbl_Valores_Gastos_Otros  (~28.7K filas, fuente Gastos Otros)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Gastos_Otros] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Gastos_Otros_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Gastos_Otros_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO]),
    CONSTRAINT [FK_tbl_Valores_Gastos_Otros_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Gastos_Otros_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Gastos_Otros_Clustered] ON [dbo].[tbl_Valores_Gastos_Otros]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Gastos_Otros_Cod_Fondo] ON [dbo].[tbl_Valores_Gastos_Otros]([Cod_Fondo], [Fecha]) INCLUDE ([Cod_Nivel], [Cod_Cuenta], [Cod_Centro], [Valor]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Valores_Gastos_Otros_Cod_Centro] ON [dbo].[tbl_Valores_Gastos_Otros]([Cod_Centro], [Fecha]) INCLUDE ([Cod_Nivel], [Cod_Cuenta], [Valor]);
GO

/* ============================================================
   tbl_Valores_Gastos  (~16K filas, fuente RE -- consolidado historico de gastos)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Gastos] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Gastos_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Gastos_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Gastos_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Gastos_Clustered] ON [dbo].[tbl_Valores_Gastos]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_Avaluos  (~20.7K filas, fuente RE)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Avaluos] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Avaluos_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Avaluos_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Avaluos_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Avaluos_Clustered] ON [dbo].[tbl_Valores_Avaluos]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_Ingresos  (~7.4K filas, fuente RE)
   Origen usa "VAL" en vez de "Valor" -- normalizado.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Ingresos] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Ingresos_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Ingresos_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Ingresos_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Ingresos_Clustered] ON [dbo].[tbl_Valores_Ingresos]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_Nexus  (~23K filas, fuente RE -- sistema Nexus)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Nexus] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Nexus_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Nexus_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO]),
    CONSTRAINT [FK_tbl_Valores_Nexus_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Nexus_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Nexus_Clustered] ON [dbo].[tbl_Valores_Nexus]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_Viva_Malls  (~21K filas, fuente RE)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_Viva_Malls] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_Viva_Malls_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_Viva_Malls_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_Viva_Malls_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_Viva_Malls_Clustered] ON [dbo].[tbl_Valores_Viva_Malls]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_GLA_2008_2023  (~41.8K filas, fuente RE)
   Origen: FECHA/COD_TIEMPO/COD_NIVEL/COD_CTR/COD_CTA/VAL -- normalizado.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_GLA_2008_2023] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_GLA_2008_2023_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_GLA_2008_2023_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_GLA_2008_2023_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_GLA_2008_2023_Clustered] ON [dbo].[tbl_Valores_GLA_2008_2023]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Valores_2011_2023_PYG  (~152K filas, fuente RE -- particionada)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_2011_2023_PYG] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_2011_2023_PYG_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_2011_2023_PYG_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_2011_2023_PYG_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
) ON [PRIMARY];
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_2011_2023_PYG_Clustered] ON [dbo].[tbl_Valores_2011_2023_PYG]([Fecha], [Cod_Nivel], [Cod_Cuenta])
    ON PS_Fecha_Anual([Fecha]);
GO

/* ============================================================
   tbl_Valores_2011_2023_VlrLibros  (~39.8K filas, fuente RE)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Valores_2011_2023_VlrLibros] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Cod_Tiempo]    INT             NOT NULL,
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Valores_2011_2023_VlrLibros_tbl_Tiempos]
        FOREIGN KEY ([Cod_Tiempo]) REFERENCES [dbo].[tbl_Tiempos]([Cod_Tiempo]),
    CONSTRAINT [FK_tbl_Valores_2011_2023_VlrLibros_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Valores_2011_2023_VlrLibros_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE CLUSTERED INDEX [IX_tbl_Valores_2011_2023_VlrLibros_Clustered] ON [dbo].[tbl_Valores_2011_2023_VlrLibros]([Fecha], [Cod_Nivel], [Cod_Cuenta]);
GO

/* ============================================================
   tbl_Pagos_Inmuebles  (~445 filas, fuente RE -- trivial, sin indices extra)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Pagos_Inmuebles] (
    [Fecha]         DATETIME2(0)    NOT NULL,
    [Fecha_TRN]     DATETIME2(0)    NULL,
    [Cod_Inm]       DECIMAL(18,0)   NULL,
    [Cod_Cuenta]    INT             NOT NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_Pagos_Inmuebles_tbl_Cuentas]
        FOREIGN KEY ([Cod_Cuenta]) REFERENCES [dbo].[tbl_Cuentas]([Cod_Cuenta])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Pagos_Inmuebles_Cod_Inm_Fecha] ON [dbo].[tbl_Pagos_Inmuebles]([Cod_Inm], [Fecha]);
GO
