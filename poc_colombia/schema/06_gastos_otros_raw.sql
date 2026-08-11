/* ============================================================================
   06. Fuentes crudas "Gastos Otros" - poc_colombia

   Capa cruda/staging-like: alimenta (fuera del alcance de este script) a
   tbl_Valores_Gastos_Otros (04_facts_valores.sql) despues de un proceso de
   consolidacion. Se mantienen los nombres de columna del origen tal cual
   (incluye typos y nombres con espacios/tildes/"#") -- solo se renombran
   nombres de TABLA con caracteres problematicos para tooling
   (PREDIAL+AVALCAT -> PREDIAL_AVALCAT, documentado aqui). Sin FK hacia el
   modelo de produccion: son fuentes crudas, no facts consolidados.

   Se excluyen a proposito (no son datos reales, son artefactos de Access):
   AVALUOS$_ErroresDeImportación, Hoja1$_ErroresDeImportación,
   SEGUROS_TRDM$_ErroresDeImportación.
============================================================================ */

/* ============================================================
   AVALUOS  (~282 filas)
   ============================================================ */
CREATE TABLE [dbo].[AVALUOS] (
    [Códifgo Fro]                       NVARCHAR(50)    NULL,
    [CIUDAD DEL PREDIO]                 NVARCHAR(100)   NULL,
    [DESCRIPCIÓN]                       NVARCHAR(255)   NULL,
    [INMUEBLE UNIFICADO]                NVARCHAR(255)   NULL,
    [AREA]                              DECIMAL(18,2)   NULL,
    [TIPOLOGÍA]                         NVARCHAR(100)   NULL,
    [DIRECCIÓN]                         NVARCHAR(255)   NULL,
    [ARRENDATARIO]                      NVARCHAR(255)   NULL,
    [Ppto 2023_(SIN IVA)]               DECIMAL(18,4)   NULL,
    [Tipo de informe 2023]              NVARCHAR(100)   NULL,
    [ASIGNACIÓN (2023)]                 NVARCHAR(100)   NULL,
    [VALOR PROYECTADO]                  DECIMAL(18,4)   NULL,
    [ASIGNACIÓN (2024)]                 NVARCHAR(100)   NULL,
    [Tipo de informe 2024]              NVARCHAR(100)   NULL,
    [Fecha vencimiento avalúo 2024]     DATETIME2(0)    NULL,
    [Mes avalúo  2024]                  NVARCHAR(50)    NULL,
    [Fecha probable de entrega avaluador] DATETIME2(0)  NULL,
    [Mes de contabilización 2024]       NVARCHAR(50)    NULL,
    [Ppto 2024_(SIN IVA)]               DECIMAL(18,4)   NULL,
    [Variación 2024 vs 2023]            DECIMAL(18,4)   NULL,
    [F21]                               DECIMAL(19,4)   NULL,
    [F22]                               DECIMAL(18,4)   NULL,
    [F23]                               DECIMAL(18,4)   NULL
);
GO

/* ============================================================
   AVALUOS_NEXUS  (~111 filas)
   ============================================================ */
CREATE TABLE [dbo].[AVALUOS_NEXUS] (
    [Fecha]                         DATETIME2(0)    NULL,
    [Cod_Fondo]                     INT             NULL,
    [Codigo_Inmueble_Consolidado]   DECIMAL(18,0)   NULL,
    [No# FACTURA]                   DECIMAL(18,0)   NULL,
    [FECHA FACTURA]                 DATETIME2(0)    NULL,
    [MES FACTURA]                   NVARCHAR(50)    NULL,
    [VALOR BRUTO]                   DECIMAL(19,4)   NULL,
    [IVA]                           DECIMAL(19,4)   NULL,
    [VALOR TOTAL]                   DECIMAL(19,4)   NULL,
    [COMPARTIMENTO]                 NVARCHAR(100)   NULL,
    [INMUEBLE]                      NVARCHAR(255)   NULL,
    [VALOR FACTURA]                 DECIMAL(19,4)   NULL,
    [VALOR COTIZADO]                DECIMAL(19,4)   NULL,
    [MES AVALÚO]                    NVARCHAR(50)    NULL,
    [AVALUADOR 2025]                NVARCHAR(100)   NULL,
    [VALOR FACTURA 2024]            DECIMAL(19,4)   NULL,
    [VARIACIÓN 2024 VS 2025]        NVARCHAR(50)    NULL,
    [AVALUADOR 2024]                DECIMAL(18,4)   NULL,
    [OBSERVACIONES]                 NVARCHAR(255)   NULL,
    [F20]                           NVARCHAR(255)   NULL,
    [F21]                           NVARCHAR(255)   NULL,
    CONSTRAINT [FK_AVALUOS_NEXUS_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   PREDIAL  (~5.9K filas)
   ============================================================ */
CREATE TABLE [dbo].[PREDIAL] (
    [FECHA]                             DATETIME2(0)    NULL,
    [COD_INM]                           DECIMAL(18,0)   NULL,
    [NOM_INM]                           NVARCHAR(255)   NULL,
    [MI_TXT]                            NVARCHAR(100)   NULL,
    [MI_NUM]                            DECIMAL(18,0)   NULL,
    [OTRO_ID]                           NVARCHAR(100)   NULL,
    [DESCRIPCION]                       NVARCHAR(255)   NULL,
    [CIUDAD]                            NVARCHAR(100)   NULL,
    [TITULAR]                           NVARCHAR(255)   NULL,
    [PREDIAL_T1]                        NVARCHAR(50)    NULL,
    [PREDIAL_T2]                        DECIMAL(18,4)   NULL,
    [PREDIAL_T3]                        NVARCHAR(50)    NULL,
    [PREDIAL_T4]                        NVARCHAR(50)    NULL,
    [PREDIAL_ANUAL]                     DECIMAL(18,4)   NULL,
    [AVAL_CATASTRAL]                    DECIMAL(18,4)   NULL,
    [NUM_PAQUETE]                       DECIMAL(18,0)   NULL,
    [FEC_VENC]                          DATETIME2(0)    NULL,
    [DOC_COBRO]                         DECIMAL(18,0)   NULL,
    [FREC_PAGO]                         NVARCHAR(50)    NULL,
    [NUM_RADICADO]                      DECIMAL(18,0)   NULL,
    [Gestión]                           NVARCHAR(100)   NULL,
    [Numero Paquete 2do pago]           NVARCHAR(50)    NULL,
    [Fecha Vencimineto 2do pago]        DATETIME2(0)    NULL,
    [Documento_Cobro 2do pago]          DECIMAL(18,0)   NULL,
    [Forma de Pago 2do pago]            NVARCHAR(50)    NULL,
    [Numero de Radicado 2do pago]       DECIMAL(18,0)   NULL,
    [Gestión 2do pago]                  NVARCHAR(100)   NULL,
    [PROCESO PAGO]                      NVARCHAR(100)   NULL,
    [Numero Paquete 3er pago]           NVARCHAR(50)    NULL,
    [Fecha Vencimineto 3er pago]        NVARCHAR(50)    NULL,
    [Documento_Cobro 3er pago]          NVARCHAR(50)    NULL,
    [Forma de Pago 3er pago]            NVARCHAR(50)    NULL,
    [Numero de Radicado 3er pago]       NVARCHAR(50)    NULL,
    [Gestión 3er pago]                  NVARCHAR(100)   NULL,
    [Numero Paquete 4to pago]           NVARCHAR(50)    NULL,
    [Fecha Vencimineto 4to pago]        NVARCHAR(50)    NULL,
    [Documento_Cobro 4to pago]          NVARCHAR(50)    NULL,
    [Forma de Pago 4to pago]            NVARCHAR(50)    NULL,
    [Numero de Radicado 4to pago]       NVARCHAR(50)    NULL,
    [Gestión 4to pago]                  NVARCHAR(100)   NULL
);
GO
CREATE NONCLUSTERED INDEX [IX_PREDIAL_FECHA_COD_INM] ON [dbo].[PREDIAL]([FECHA], [COD_INM]);
GO

/* ============================================================
   PREDIAL_NEXUS  (~3.8K filas)
   ============================================================ */
CREATE TABLE [dbo].[PREDIAL_NEXUS] (
    [Fecha]                             DATETIME2(0)    NULL,
    [Codigo_inmueble]                   DECIMAL(18,0)   NULL,
    [#]                                 DECIMAL(18,0)   NULL,
    [Codigo_Compartimento]              DECIMAL(18,0)   NULL,
    [Inmueble]                          NVARCHAR(255)   NULL,
    [Nombre_Inmueble]                   NVARCHAR(255)   NULL,
    [No_de_Matricula_Inmobiliaria]      NVARCHAR(100)   NULL,
    [CHIP_Cedula_Catastral_ID_Predio]   NVARCHAR(100)   NULL,
    [Ciudad]                            NVARCHAR(100)   NULL,
    [Valor_Pagado_2025]                 DECIMAL(19,4)   NULL,
    [Observaciones]                     NVARCHAR(255)   NULL,
    [F12]                               NVARCHAR(255)   NULL,
    [F13]                               NVARCHAR(255)   NULL
);
GO

/* ============================================================
   PREDIAL_AVALCAT  (renombrada de "PREDIAL+AVALCAT" por el "+" en el
   nombre original; mismo layout visto en Reportes y Gastos Otros, unificado
   con Cod_Fondo como superset)
   ============================================================ */
CREATE TABLE [dbo].[PREDIAL_AVALCAT] (
    [Mes]           DATETIME2(0)    NOT NULL,
    [Mes_Reporte]   INT             NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [PREDIAL]       DECIMAL(18,4)   NULL,
    [AVALCAT]       DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_PREDIAL_AVALCAT_tbl_Fechas]
        FOREIGN KEY ([Mes]) REFERENCES [dbo].[tbl_Fechas]([Mes]),
    CONSTRAINT [FK_PREDIAL_AVALCAT_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   SEGUROS_NEXUS  (~220 filas)
   ============================================================ */
CREATE TABLE [dbo].[SEGUROS_NEXUS] (
    [Fecha]         DATETIME2(0)    NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Inm]       DECIMAL(18,0)   NULL,
    [Inmueble]      NVARCHAR(255)   NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    [F6]            NVARCHAR(255)   NULL,
    [F7]            NVARCHAR(255)   NULL,
    [F8]            DECIMAL(19,4)   NULL,
    CONSTRAINT [FK_SEGUROS_NEXUS_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   SEGUROS_RENTAS  (~297 filas)
   ============================================================ */
CREATE TABLE [dbo].[SEGUROS_RENTAS] (
    [FECHA]                 DATETIME2(0)    NULL,
    [COD FRO]               NVARCHAR(50)    NULL,
    [INMUEBLE]               NVARCHAR(255)   NULL,
    [ARRENDATARIO]           NVARCHAR(255)   NULL,
    [ÚLTIMO CANON]           DECIMAL(18,4)   NULL,
    [TOTAL CANON ANUAL]      DECIMAL(18,4)   NULL,
    [Tasa]                   DECIMAL(9,6)    NULL,
    [Prima]                  DECIMAL(18,4)   NULL,
    [F9]                     NVARCHAR(255)   NULL
);
GO

/* ============================================================
   SEGUROS_TRDM  (~382 filas)
   ============================================================ */
CREATE TABLE [dbo].[SEGUROS_TRDM] (
    [FECHA]             DATETIME2(0)    NULL,
    [COD CONTRATO]      DECIMAL(18,0)   NULL,
    [NOMBRE INMUEBLE]   NVARCHAR(255)   NULL,
    [PRIMA ANUAL]       DECIMAL(18,4)   NULL
);
GO

/* ============================================================
   Seguros_Rentas_Anual  (0 filas actualmente; se define igual la estructura)
   ============================================================ */
CREATE TABLE [dbo].[Seguros_Rentas_Anual] (
    [Mes]           DATETIME2(0)    NOT NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Valor]         DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_Seguros_Rentas_Anual_tbl_Fechas]
        FOREIGN KEY ([Mes]) REFERENCES [dbo].[tbl_Fechas]([Mes])
);
GO

/* ============================================================
   SegurosTRDM_Anual  (unificado con Cod_Fondo como superset, visto tambien
   en Reportes)
   ============================================================ */
CREATE TABLE [dbo].[SegurosTRDM_Anual] (
    [Mes]           DATETIME2(0)    NOT NULL,
    [Mes_Reporte]   INT             NULL,
    [Cod_Fondo]     INT             NULL,
    [Cod_Centro]    NVARCHAR(20)    NULL,
    [Prima TRDM]    DECIMAL(18,4)   NULL,
    CONSTRAINT [FK_SegurosTRDM_Anual_tbl_Fechas]
        FOREIGN KEY ([Mes]) REFERENCES [dbo].[tbl_Fechas]([Mes]),
    CONSTRAINT [FK_SegurosTRDM_Anual_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO

/* ============================================================
   tbl_Inmuebles_Avalúos  (~139 filas)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles_Avalúos] (
    [COD_INM]   DECIMAL(18,0)   NULL,
    [NON_INM]   NVARCHAR(255)   NULL
);
GO

/* ============================================================
   tbl_MI  (~2.36K filas -- matriculas inmobiliarias)
   ============================================================ */
CREATE TABLE [dbo].[tbl_MI] (
    [MI_NUM]        DECIMAL(18,0)   NULL,
    [MI_TXT]        NVARCHAR(50)    NULL,
    [DESCRIPCION]   NVARCHAR(255)   NULL,
    [COD_INM]       DECIMAL(18,0)   NULL
);
GO

/* ============================================================
   Honorarios  (~268 filas)
   ============================================================ */
CREATE TABLE [dbo].[Honorarios] (
    [Fecha]         DATETIME2(0)    NULL,
    [Cod_Inmueble]  DECIMAL(18,0)   NULL,
    [Inmueble]      NVARCHAR(255)   NULL,
    [Valor]         DECIMAL(18,4)   NULL
);
GO
