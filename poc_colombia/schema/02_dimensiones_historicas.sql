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
    [Cod_Inm_TXT]           NVARCHAR(255)   NULL,
    [Nom_Inm]               NVARCHAR(255)   NULL,
    [Ubicacion]             NVARCHAR(255)   NULL,
    [Ubic_Pol_Inv]          NVARCHAR(255)   NULL,
    [Direccion]             NVARCHAR(255)   NULL,
    [Tipologia]             NVARCHAR(255)   NULL,
    [Tipologia_Cons]        NVARCHAR(255)   NULL,
    [Subtipologia]          NVARCHAR(255)   NULL,
    [Estado]                NVARCHAR(255)   NULL,
    [Tipo_Riesgo]           NVARCHAR(255)   NULL,
    [Georef]                NVARCHAR(255)   NULL,
    [Coordenadas]           NVARCHAR(255)   NULL,
    [Latitud]               FLOAT           NULL,
    [Longitud]              FLOAT           NULL,
    [Titularidad]           NVARCHAR(255)   NULL,
    [Subtipologia3]         NVARCHAR(255)   NULL,
    [Certificacion]         NVARCHAR(255)   NULL,
    [Año_de_contruccion]    NVARCHAR(255)   NULL,
    [Conteo]                NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Inmuebles] PRIMARY KEY CLUSTERED ([Fecha], [Cod_Inm]),
    CONSTRAINT [FK_tbl_Inmuebles_tbl_Fechas]
        FOREIGN KEY ([Fecha]) REFERENCES [dbo].[tbl_Fechas]([Mes]),
    CONSTRAINT [FK_tbl_Inmuebles_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   tbl_Contratos

   Sin FK hacia tbl_Inmuebles: tbl_Inmuebles (via fuente 351) solo cubre
   fotos desde 2024-01, pero tbl_Contratos tiene historial desde 2008-10
   (85% de las filas de 351 quedan fuera del rango). Diferencia real de
   profundidad historica entre fuentes, no datos sucios -- confirmado al
   cargar datos reales.

   Sin FK hacia tbl_Arrendatarios: ~3 de 222 NIT reales de contratos de la
   fuente 351 no estan (todavia) en el catalogo maestro de PowerBI (336
   arrendatarios) -- brecha real de cobertura entre fuentes mantenidas por
   separado, confirmado al cargar datos reales.

   Ambos casos se dejan con indice, no FK -- mismo criterio que
   tbl_Cruce351/tbl_ValorLibros_xInmueble en 05_eeff_351.sql.
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
    [Tipologia]     NVARCHAR(255)   NULL,
    [Fec_Inicio]    DATETIME2(0)    NULL,
    [Fec_Fin]       DATETIME2(0)    NULL,
    [IncremCanon]   NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Contratos] PRIMARY KEY CLUSTERED ([FECHA], [COD_CTR], [ESTADO]),
    CONSTRAINT [FK_tbl_Contratos_tbl_Fondos]
        FOREIGN KEY ([COD_FONDO]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_FECHA_COD_INM] ON [dbo].[tbl_Contratos]([FECHA], [COD_INM]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_NIT] ON [dbo].[tbl_Contratos]([NIT]);
GO
