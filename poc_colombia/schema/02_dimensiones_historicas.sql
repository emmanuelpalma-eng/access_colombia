/* ============================================================================
   02. Dimensiones historicas - poc_colombia

   tbl_Contratos y tbl_Inmuebles son fotos MENSUALES (historico), no
   catalogos estaticos -- la llave natural incluye la fecha. Mismo criterio
   ya validado en los proyectos SIF_Colombia_351 / SIF_Colombia_Info_portafolio:

     - tbl_Contratos: PK (FECHA, COD_CTR, ESTADO). Un mismo COD_CTR puede
       tener una fila VIGENTE y otra RESTITUIDO/NO VIGENTE en el mismo mes
       (contrato que termina y otro que arranca en el mismo espacio).
     - tbl_Inmuebles: PK (Fecha, Cod_Inm). Foto mensual de propiedades.
============================================================================ */

/* ============================================================
   tbl_Inmuebles  (se crea antes que tbl_Contratos porque este la referencia)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles] (
    [Fecha]                 DATETIME2(0)    NOT NULL,
    [Cod_Fondo]             INT             NULL,
    [Cod_Inm]               DECIMAL(18,0)   NOT NULL,
    [Cod_Inm_Nue]           DECIMAL(18,0)   NULL,
    [Cod_Inm1]              DECIMAL(18,0)   NULL,
    [Cod_Inm1_Nue]          DECIMAL(18,0)   NULL,
    [Cod_Inm_TXT]           NVARCHAR(20)    NULL,
    [Nom_Inm]               NVARCHAR(255)   NULL,
    [Ubicacion]             NVARCHAR(255)   NULL,
    [Ubic_Pol_Inv]          NVARCHAR(255)   NULL,
    [Direccion]             NVARCHAR(255)   NULL,
    [Tipologia]             NVARCHAR(100)   NULL,
    [Tipologia_Cons]        NVARCHAR(100)   NULL,
    [Subtipologia]          NVARCHAR(100)   NULL,
    [Estado]                NVARCHAR(50)    NULL,
    [Tipo_Riesgo]           NVARCHAR(50)    NULL,
    [Georef]                NVARCHAR(50)    NULL,
    [Coordenadas]           NVARCHAR(50)    NULL,
    [Latitud]               FLOAT           NULL,
    [Longitud]              FLOAT           NULL,
    [Titularidad]           NVARCHAR(100)   NULL,
    [Subtipologia3]         NVARCHAR(100)   NULL,
    [Certificacion]         NVARCHAR(100)   NULL,
    [Año_de_contruccion]    NVARCHAR(10)    NULL,
    [Conteo]                NVARCHAR(10)    NULL,
    CONSTRAINT [PK_tbl_Inmuebles] PRIMARY KEY CLUSTERED ([Fecha], [Cod_Inm]),
    CONSTRAINT [FK_tbl_Inmuebles_tbl_Fechas]
        FOREIGN KEY ([Fecha]) REFERENCES [dbo].[tbl_Fechas]([Mes]),
    CONSTRAINT [FK_tbl_Inmuebles_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   tbl_Contratos
   ============================================================ */
CREATE TABLE [dbo].[tbl_Contratos] (
    [FECHA]         DATETIME2(0)    NOT NULL,
    [COD_FONDO]     INT             NULL,
    [ESTADO]        NVARCHAR(30)    NOT NULL CONSTRAINT CK_tbl_Contratos_Estado
                        CHECK ([ESTADO] IN (N'VIGENTE', N'RESTITUIDO', N'NO VIGENTE')),
    [COD_CTR]       NVARCHAR(20)    NOT NULL,
    [NIT]           NVARCHAR(20)    NULL,
    [NOM_ARREND]    NVARCHAR(255)   NULL,
    [COD_INM]       DECIMAL(18,0)   NOT NULL,
    [DET_INM]       NVARCHAR(255)   NULL,
    [GLA]           DECIMAL(18,2)   NULL,
    [Tipologia]     NVARCHAR(100)   NULL,
    [Fec_Inicio]    DATETIME2(0)    NULL,
    [Fec_Fin]       DATETIME2(0)    NULL,
    [IncremCanon]   NVARCHAR(100)   NULL,
    CONSTRAINT [PK_tbl_Contratos] PRIMARY KEY CLUSTERED ([FECHA], [COD_CTR], [ESTADO]),
    CONSTRAINT [FK_tbl_Contratos_tbl_Inmuebles]
        FOREIGN KEY ([FECHA], [COD_INM]) REFERENCES [dbo].[tbl_Inmuebles]([Fecha], [Cod_Inm]),
    CONSTRAINT [FK_tbl_Contratos_tbl_Fondos]
        FOREIGN KEY ([COD_FONDO]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO]),
    CONSTRAINT [FK_tbl_Contratos_tbl_Arrendatarios]
        FOREIGN KEY ([NIT]) REFERENCES [dbo].[tbl_Arrendatarios]([NIT])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_FECHA_COD_INM] ON [dbo].[tbl_Contratos]([FECHA], [COD_INM]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_NIT] ON [dbo].[tbl_Contratos]([NIT]);
GO
