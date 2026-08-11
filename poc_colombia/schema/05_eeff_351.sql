/* ============================================================================
   05. Submodelo contable EEFF - fuente "351" - poc_colombia

   Estas tablas son especificas de la fuente "Informes FIC - 351.accdb" y no
   generalizan al resto (submodelo de estados financieros/formato
   regulatorio 351). Migradas desde SIF_Colombia_351/schema.sql.legacy,
   ajustando las FK que ahora apuntan a las dimensiones maestras compartidas
   (tbl_Fechas, tbl_Fondos, tbl_Inmuebles) en vez de copias propias.
============================================================================ */

/* ============================================================
   tbl_Cuentas_EEFF  (catalogo de cuentas contables EEFF -- DISTINTO de
   tbl_Cuentas, el catalogo de gestion de portafolio de 01_dimensiones_maestras.sql)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Cuentas_EEFF] (
    [COD_CTA]           DECIMAL(18,0)   NOT NULL,
    [NOM_CTA]           NVARCHAR(255)   NULL,
    [SIGNO_CTA]         INT             NULL,
    [SIGNO_REPORTE]     INT             NULL,
    [TIPO_CTA]          INT             NULL,
    [SUMA]              INT             NULL,
    [Clasif_Contable]   NVARCHAR(255)   NULL,
    [COD_AGRUP]         NVARCHAR(50)    NULL,
    [NOM_AGRUP]         NVARCHAR(255)   NULL,
    [Cod_Nivel1]        NVARCHAR(50)    NULL,
    [Nom_Nivel1]        NVARCHAR(255)   NULL,
    [Cod_Nivel2]        NVARCHAR(50)    NULL,
    [Nom_Nivel2]        NVARCHAR(255)   NULL,
    [Cod_Nivel3]        NVARCHAR(50)    NULL,
    [Nom_Nivel3]        NVARCHAR(255)   NULL,
    [Cod_Nivel4]        NVARCHAR(50)    NULL,
    [Nom_Nivel4]        NVARCHAR(255)   NULL,
    [Cod_Nivel5]        NVARCHAR(50)    NULL,
    [Nom_Nivel5]        NVARCHAR(255)   NULL,
    [Cod_Nivel3A]       NVARCHAR(50)    NULL,
    [Nom_Nivel3A]       NVARCHAR(255)   NULL,
    [Cod_Nivel4A]       NVARCHAR(50)    NULL,
    [Nom_Nivel4A]       NVARCHAR(255)   NULL,
    [Cod_Nivel5A]       NVARCHAR(50)    NULL,
    [Nom_Nivel5A]       NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Cuentas_EEFF] PRIMARY KEY CLUSTERED ([COD_CTA])
);
GO

/* ============================================================
   tbl_EEFF  (~192K filas -- particionada)
   ============================================================ */
CREATE TABLE [dbo].[tbl_EEFF] (
    [FECHA]         DATETIME2(0)    NOT NULL,
    [COD_FONDO]     INT             NULL,
    [COD_CTA]       DECIMAL(18,0)   NOT NULL,
    [NIT_TERCERO]   DECIMAL(18,0)   NULL,
    [SALDO]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_EEFF_tbl_Fechas]
        FOREIGN KEY ([FECHA]) REFERENCES [dbo].[tbl_Fechas]([Mes]),
    CONSTRAINT [FK_tbl_EEFF_tbl_Fondos]
        FOREIGN KEY ([COD_FONDO]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO]),
    CONSTRAINT [FK_tbl_EEFF_tbl_Cuentas_EEFF]
        FOREIGN KEY ([COD_CTA]) REFERENCES [dbo].[tbl_Cuentas_EEFF]([COD_CTA])
) ON [PRIMARY];
GO
CREATE CLUSTERED INDEX [IX_tbl_EEFF_Clustered] ON [dbo].[tbl_EEFF]([FECHA], [COD_CTA])
    ON PS_Fecha_Anual([FECHA]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_EEFF_COD_FONDO] ON [dbo].[tbl_EEFF]([COD_FONDO], [FECHA])
    INCLUDE ([COD_CTA], [SALDO]) ON PS_Fecha_Anual([FECHA]);
GO

/* ============================================================
   F351  (~31.5K filas -- formato regulatorio 351)
   "######" del origen (encabezado ilegible) se llama aqui [Campo13],
   igual que en SIF_Colombia_351. [Fecha emisión] queda FLOAT porque en el
   origen es DOUBLE a pesar del nombre.
   ============================================================ */
CREATE TABLE [dbo].[F351] (
    [FECHA]                                     DATETIME2(0)    NOT NULL,
    [INMUEBLE]                                  NVARCHAR(255)   NULL,
    [matrícula]                                 NVARCHAR(50)    NULL,
    [Unidad de Captura]                         DECIMAL(18,0)   NULL,
    [No asignado por la entidad]                DECIMAL(18,0)   NULL,
    [Fecha emisión]                             FLOAT           NULL,
    [Valor nominal]                             DECIMAL(19,4)   NULL,
    [Valor de compra moneda original]           DECIMAL(19,4)   NULL,
    [Valor de compra en pesos]                  DECIMAL(19,4)   NULL,
    [Vr mercado o valor presente en $]          DECIMAL(19,4)   NULL,
    [Campo11]                                   NVARCHAR(255)   NULL,
    [Campo12]                                   FLOAT           NULL,
    [Campo13]                                   DECIMAL(19,4)   NULL,
    [Campo14]                                   DECIMAL(19,4)   NULL,
    [F15]                                       FLOAT           NULL,
    CONSTRAINT [FK_F351_tbl_Fechas]
        FOREIGN KEY ([FECHA]) REFERENCES [dbo].[tbl_Fechas]([Mes])
);
GO
CREATE NONCLUSTERED INDEX [IX_F351_FECHA] ON [dbo].[F351]([FECHA]);
GO

/* ============================================================
   VL_CentralPoint  (35 filas -- valorizacion consolidada)
   ============================================================ */
CREATE TABLE [dbo].[VL_CentralPoint] (
    [FECHA]             DATETIME2(0)    NOT NULL,
    [VLR_FINAL_E1]      DECIMAL(18,4)   NULL,
    [VLR_FINAL_E2]      DECIMAL(18,4)   NULL,
    [VLR_E1]            DECIMAL(18,4)   NULL,
    [VLR_E2]            DECIMAL(18,4)   NULL,
    [MVA]               DECIMAL(18,4)   NULL,
    [TOTAL_ACTIVOS_PA]  DECIMAL(18,4)   NULL,
    [PASIVO_PA]         DECIMAL(18,4)   NULL,
    [ANT_DF]            DECIMAL(18,4)   NULL,
    [TOTAL]             DECIMAL(18,4)   NULL,
    [351]               DECIMAL(18,4)   NULL,
    [DIF]               DECIMAL(18,4)   NULL,
    [UVR_E1]            DECIMAL(18,4)   NULL,
    [UVR_E2]            DECIMAL(18,4)   NULL,
    [UVR_E1_#2]         DECIMAL(18,4)   NULL,
    [UVR_E2_#2]         DECIMAL(18,4)   NULL,
    [AVAL_E1]           DECIMAL(18,4)   NULL,
    [AVAL_E2]           DECIMAL(18,4)   NULL,
    [VLR_AVAL_E1]       DECIMAL(18,4)   NULL,
    [VLR_AVAL_E2]       DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_VL_CentralPoint_tbl_Fechas]
        FOREIGN KEY ([FECHA]) REFERENCES [dbo].[tbl_Fechas]([Mes])
);
GO

/* ============================================================
   VL_Disp_xa_Venta  (388 filas)
   ============================================================ */
CREATE TABLE [dbo].[VL_Disp_xa_Venta] (
    [FECHA]         DATETIME2(0)    NOT NULL,
    [COD_INM]       DECIMAL(18,0)   NOT NULL,
    [DESCR_INM]     NVARCHAR(255)   NULL,
    [VALOR]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_VL_Disp_xa_Venta_tbl_Inmuebles]
        FOREIGN KEY ([FECHA], [COD_INM]) REFERENCES [dbo].[tbl_Inmuebles]([Fecha], [Cod_Inm])
);
GO

/* ============================================================
   tbl_ValorLibros_xInmueble  (~3.9K filas)
   COD_CTA no lleva FK: en 351 vale consistentemente 1800 y no calza con
   tbl_Cuentas_EEFF; podria corresponder al catalogo tbl_Cuentas (portafolio)
   ahora que esta unificado, pero se deja sin forzar hasta confirmar con
   datos reales durante la carga. Se deja indice.
   ============================================================ */
CREATE TABLE [dbo].[tbl_ValorLibros_xInmueble] (
    [DESCR]     NVARCHAR(255)   NULL,
    [FECHA]     DATETIME2(0)    NOT NULL,
    [Cod_Inm]   DECIMAL(18,0)   NOT NULL,
    [COD_CTA]   DECIMAL(18,0)   NOT NULL,
    [VALOR]     DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_tbl_ValorLibros_xInmueble_tbl_Inmuebles]
        FOREIGN KEY ([FECHA], [Cod_Inm]) REFERENCES [dbo].[tbl_Inmuebles]([Fecha], [Cod_Inm])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_ValorLibros_xInmueble_COD_CTA] ON [dbo].[tbl_ValorLibros_xInmueble]([COD_CTA]);
GO

/* ============================================================
   tbl_Cruce_SIF  (30 filas)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Cruce_SIF] (
    [Cod_Cta]       DECIMAL(18,0)   NOT NULL,
    [Nom_Cta]       NVARCHAR(255)   NULL,
    [Grupo_Cuenta]  NVARCHAR(100)   NULL,
    [NIT_Tercero]   DECIMAL(18,0)   NULL,
    [Nom_Tercero]   NVARCHAR(255)   NULL,
    [Cod_SIF]       NVARCHAR(50)    NULL,
    [Nom_SIF]       NVARCHAR(255)   NULL,
    CONSTRAINT [FK_tbl_Cruce_SIF_tbl_Cuentas_EEFF]
        FOREIGN KEY ([Cod_Cta]) REFERENCES [dbo].[tbl_Cuentas_EEFF]([COD_CTA])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Cruce_SIF_Cod_Cta] ON [dbo].[tbl_Cruce_SIF]([Cod_Cta]);
GO

/* ============================================================
   tbl_Cruce351  (~2.5K filas). Cod_Inm admite NULL (hay filas reales sin
   asignar); sin FK hacia tbl_Inmuebles porque no tiene columna Fecha propia
   y tbl_Inmuebles usa PK compuesta (Fecha, Cod_Inm).
   ============================================================ */
CREATE TABLE [dbo].[tbl_Cruce351] (
    [COD_ASIGN_FIDU]    DECIMAL(18,0)   NULL,
    [Descripción351]    NVARCHAR(100)   NULL,
    [Cod_Inm]           DECIMAL(18,0)   NULL
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Cruce351_Cod_Inm] ON [dbo].[tbl_Cruce351]([Cod_Inm]);
GO
